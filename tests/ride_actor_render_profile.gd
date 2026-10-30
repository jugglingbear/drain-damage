extends SceneTree
## Opt-in small-window rendering profile; never used by headless validation.
const Game = preload("res://scripts/integrated_first_call.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960,540)
	root.position = Vector2i(80,80)
	call_deferred("checks")

func checks() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This profile requires an explicitly approved small test window")
		quit(1)
		return
	root.title = "Drain Damage — Actor Profile"
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	Launch.initialize(game,Launch.parse(["--level=2-landing"]).target)
	var view = game.flush.world_view
	view.set_process(false)
	view._process(0)
	print("GRAPHICS_WARMUP_US ",view.graphics_warmup_usec)
	await process_frame
	await RenderingServer.frame_post_draw
	var prepared: int = view.actor_build_count
	for index in range(13):
		game.flush.enter_ride(game,index)
		var model = game.flush.ride
		var age: float = (float(model.encounter.obstacles[0].x)-520)/560
		if index == 10: age = 2.9
		if index in [11,12]: age = 3.1
		model.clock = age
		model.encounter_clock = age
		model.encounter_scroll = age*560
		var start := Time.get_ticks_usec()
		view.update_world()
		var cpu := Time.get_ticks_usec()-start
		await process_frame
		await RenderingServer.frame_post_draw
		var first := Time.get_ticks_usec()-start
		var frames: Array[int] = []
		for frame in 30:
			start = Time.get_ticks_usec()
			view.update_world()
			await process_frame
			await RenderingServer.frame_post_draw
			frames.append(Time.get_ticks_usec()-start)
		frames.sort()
		print("RENDER_PROFILE ",JSON.stringify({"encounter":index+1,"cpu_us":cpu,"first_present_us":first,
			"warm_median_us":frames[15],"warm_max_us":frames[-1],
			"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}))
		assert(view.actor_build_count == prepared)
		if "--inspect" in OS.get_cmdline_user_args():
			print("INSPECT_READY ",index+1)
			await create_timer(10.0).timeout
	game.flush.enter_ride(game,0)
	var model = game.flush.ride
	model.jump_age = .2
	model.render_height = 48
	assert(model.fidget.step(model,true,0).triggered)
	var cloud_start := Time.get_ticks_usec()
	view.update_world()
	print("CLOUD_CPU_US ",Time.get_ticks_usec()-cloud_start)
	await process_frame
	await RenderingServer.frame_post_draw
	print("CLOUD_FIRST_PRESENT_US ",Time.get_ticks_usec()-cloud_start)
	print("PASS: actual renderer first-visible frame probe; present intervals include pacing, not isolated GPU timer")
	game.free()
	quit()
