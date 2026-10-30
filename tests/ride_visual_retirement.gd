extends SceneTree
## Independent camera projection guards against retiring still-visible 3D machinery.
const Game = preload("res://scripts/integrated_first_call.gd")
const Launch = preload("res://scripts/playtest_launch.gd")
const SCREEN := Rect2(0,0,960,540)

func _initialize() -> void: call_deferred("checks")

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func visible_mesh(node: Node, camera: Camera3D) -> bool:
	if node is Node3D and not node.is_visible_in_tree(): return false
	if node is MeshInstance3D:
		var box: AABB = node.get_aabb()
		var projected := Rect2()
		var started := false
		for corner in 8:
			var point: Vector3 = node.to_global(box.get_endpoint(corner))
			if camera.is_position_behind(point): continue
			var pixel := camera.unproject_position(point)
			if not started:
				projected = Rect2(pixel,Vector2.ZERO)
				started = true
			else: projected = projected.expand(pixel)
		if started and projected.intersects(SCREEN,true): return true
	for child in node.get_children():
		if visible_mesh(child,camera): return true
	return false

func checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	Launch.initialize(game,Launch.parse(["--level=2-landing"]).target)
	if not require(game.flush.ride.audio.cues.has("track_smash"),"Fracture cue must load before validation"): return
	var view = game.flush.world_view
	view.set_process(false)
	view._process(0)
	var inspected := 0
	var legacy_visible_removals := 0
	for angle in [-18.0,18.0]:
		game.flush.enter_ride(game,11)
		var ride = game.flush.ride
		ride.position.y = 270
		view.yaw = angle
		var transitioned := false
		var exited := false
		var seen: Dictionary = {}
		var retired: Dictionary = {}
		for step in range(401):
			# Isolate retirement from hero collision: advance the presentation's continuous clock,
			# using the actual encounter-transition method at the authored clear boundary.
			ride.clock = step*.05
			ride.encounter_clock = ride.clock-(4.55 if transitioned else 0.0)
			ride.encounter_scroll = ride.encounter_clock*ride.scroll_speed
			if not transitioned and ride.clock >= 4.55:
				ride._advance_encounter(game)
				transitioned = true
			if not exited and ride.clock >= 9.1:
				ride._advance_encounter(game)
				exited = true
			view.update_world()
			var visible: Dictionary = {}
			for key in view.actors:
				seen[key] = true
				if visible_mesh(view.actors[key],view.camera):
					visible[key] = true
					var obstacle: Dictionary = view.actors[key].get_meta("obstacle")
					if ride.visual_bounds(obstacle).end.x < 0: legacy_visible_removals += 1
			ride.prune_departed_visuals()
			view.update_world()
			for key in visible:
				if not require(view.actors.has(key),"Visible machinery retired at yaw%s time%s: %s" % [angle,ride.clock,key]): return
			for key in seen:
				if not view.actors.has(key): retired[key] = true
			inspected += 1
		if not require(transitioned and exited and seen.size() == 2,"Both strainers and exit must be exercised"): return
		if not require(retired.size() == 2 and ride.visual_obstacles.is_empty(),"All departed machinery eventually retires"): return
	if not require(legacy_visible_removals > 0,"Regression must exercise visible geometry beyond legacy bounds"): return
	# Absolute visual clocks retain their impact identity across encounter changes.
	for index in [10,11,12]:
		game.flush.enter_ride(game,index)
		var ride = game.flush.ride
		var impact: float = ride.visual_obstacles[0].activates_at
		var before: int = ride.audio.starts.get("track_smash",0)
		ride.clock = impact-.001
		ride.update_fracture_audio(impact-.01)
		if not require(ride.audio.starts.get("track_smash",0) == before,"No fracture before activation"): return
		# Ordinary contact cooldown must not suppress an authored structural impact.
		ride.audio.play("metal_impact")
		ride.audio.cooldown = .12
		ride.clock = impact
		ride.update_fracture_audio(impact-.001)
		if not require(ride.audio.starts.get("track_smash",0) == before+1,"Fracture sounds exactly at activation"): return
		for repeat in 3:
			ride.update_fracture_audio(impact-.001)
		if not require(ride.audio.starts.get("track_smash",0) == before+1,"Repeated processing cannot replay impact"): return
		ride.clock += .5
		ride.update_fracture_audio(impact)
		if not require(ride.audio.starts.get("track_smash",0) == before+1,"Retreat cannot replay impact"): return
		# Retry must clear the per-attempt latch.
		ride.begin(game,index)
		ride.clock = impact+.1
		ride.update_fracture_audio(0)
		if not require(ride.audio.starts.get("track_smash",0) == before+2,"Retry and skipped frames preserve one impact"): return
		ride.begin(game,index)
		ride.position = Vector2(180,270)
		ride.clock = impact-.01
		ride.encounter_clock = ride.clock
		ride.encounter_scroll = ride.clock*ride.scroll_speed
		ride.tick(game,.02,Vector2.ZERO,false)
		if not require(ride.audio.starts.get("track_smash",0) == before+3,"Normal tick dispatches activation sound"): return
	game.free()
	print("PASS: ",inspected," projected machinery snapshots at both yaw angles, strainer12→13 and exit retirement; hand/strainer one-shot fracture audio")
	quit()
