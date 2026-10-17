extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	var dispenser = game.dispenser
	assert(dispenser.art.machine.states.idle.path.ends_with("glass-cabinet-v1.png"))
	assert(dispenser.art.machine.attachment.hero_exit_feet == [82.0,166.0])
	assert(dispenser.art.machine.attachment.opening_rect == [56.0,151.0,64.0,20.0])
	for hero in ["tony","sean"]:
		for clock_value in [0.0,0.4,0.8,1.6,100.0]:
			var frames: Array = dispenser.sleeping_frames(hero,clock_value)
			assert(frames.size() == 1)
			for index in range(1):
				var frame: Dictionary = frames[index].frame
				assert(dispenser.textures.has(frame.path))
				var belongs := false
				for source in dispenser.art.sleeping_heroes.heroes[hero]:
					if source.source_rect == frame.source_rect: belongs = true
				assert(belongs, "Each stock slot must use selected hero only")
				var visible: Rect2 = dispenser.rect(frame.destination).intersection(frames[index].clip)
				assert(visible.has_area() and frames[index].clip.encloses(visible))
	game.set_paused(true)
	var before: Array = dispenser.sleeping_frames(game.employee.id,game.elapsed)
	game._physics_process(1)
	assert(before == dispenser.sleeping_frames(game.employee.id,game.elapsed))
	game.queue_free()
	await process_frame
	print("PASS: one selected-hero stock slot, clipping, cabinet/hatch anchors and pause")
	quit()
