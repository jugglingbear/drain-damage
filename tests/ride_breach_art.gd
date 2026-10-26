extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	game.flush.enter_ride(game,1)
	var ride = game.flush.ride
	var animations := 0
	for visual: Dictionary in ride.visual_obstacles:
		var id: String = ride.obstacle_frame_id(visual)
		var bounds: Rect2 = ride.visual_bounds(visual)
		for overlay: Dictionary in ride.obstacle_art.manifest.get("obstacle_overlays",{}).get(id,[]):
			var animation: Dictionary = ride.obstacle_art.manifest.animations[str(overlay.animation)]
			assert(animation.loop and animation.fps > 0 and animation.frames.size() > 1)
			var variants: Dictionary = {}
			for frame: Dictionary in animation.frames:
				var rect: Rect2 = ride.frame_bounds(frame,Transform2D(0,ride.obstacle_position(visual)))
				assert(bounds.encloses(rect),"Every cascade frame must survive visual culling")
				variants[JSON.stringify(frame)] = true
			assert(variants.size() > 1,"Cascade needs actual distinct authored frames")
			var first: Dictionary = ride.obstacle_art.frame_at(str(overlay.animation),0)
			var second: Dictionary = ride.obstacle_art.frame_at(str(overlay.animation),1.01/animation.fps)
			assert(first != second)
			animations += 1
	assert(animations > 0,"Broken channel must visibly cascade rather than use only a static pit")
	var pit: Dictionary = {}
	for obstacle: Dictionary in ride.course.obstacles:
		if obstacle.kind == "gap": pit = obstacle
	assert(not pit.is_empty() and pit.width >= 700 and pit.y-pit.depth*0.5 == 300)
	var pit_frame: Dictionary = ride.obstacle_art.manifest.frames[ride.obstacle_frame_id(pit)]
	assert(pit_frame.get("has_fall_occlusion",false),"Broken rim must occlude the descending hero")
	var solids := 0
	var backgrounds := 0
	for layer: Dictionary in pit_frame.layers:
		assert(layer.has("occludes_fall"),"Every pit layer must explicitly choose fall ordering")
		if layer.occludes_fall: solids += 1
		else: backgrounds += 1
	assert(solids > 0 and backgrounds > 0,"Void stays behind the hero; only solid rim goes in front")
	assert(270+ride.HALF.y < pit.y-pit.depth*0.5,"Far-bank witness stays outside the visible pit")
	game.queue_free()
	await process_frame
	print("PASS: authored cascade animation advances, all frames retained in visual bounds, actual pit and far-bank corridor")
	quit()
