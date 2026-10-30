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
	game.flush.enter_ride(game,10)
	var ride = game.flush.ride
	var obstacle: Dictionary = ride.visual_obstacles[0]
	var manifest: Dictionary = ride.obstacle_art.manifest
	assert(ride.checkpoint_index == 10 and ride.course.obstacles.size() == 1)
	var plane: Dictionary = manifest.frames.maintenance_hand_gap.layers[0]
	assert(ride.frame_bounds(plane,Transform2D.IDENTITY) == Rect2(-70,-100,140,200))
	assert(not plane.occludes_fall)
	for step in range(501):
		ride.clock = float(step)/100.0
		var assembly: Dictionary = ride.hand_assembly(obstacle)
		assert(ride.obstacle_active(obstacle) == (ride.clock >= 2.9))
		if ride.clock < 1.25:
			assert(assembly.parts.is_empty())
			continue
		assert(is_equal_approx(assembly.pivot.y,100))
		var bounds: Rect2 = ride.visual_bounds(obstacle)
		for part: Dictionary in assembly.parts:
			var box: Rect2 = ride.frame_bounds(manifest.frames[part.id],part.transform)
			assert(bounds.grow(0.001).encloses(box),"All visible hand parts participate in culling")
			if ride.clock >= 3.05 and part.id != "hand_hatch":
				assert(box.end.y <= 120.001,"Entire reaching hand clears the highest Tony hop")
			if ride.clock >= 3.05: assert(part.id != "hand_contact")
			if part.id == "hand_forearm":
				assert((part.transform*Vector2.ZERO).is_equal_approx(assembly.pivot))
				assert((part.transform*Vector2(300,0)).is_equal_approx(assembly.wrist))
			else: assert(is_equal_approx(part.transform.determinant(),1),"Fist and hatch remain rigid")
		if ride.clock >= 3.65: assert(assembly.parts.size() == 1)
	ride.clock = 2.9
	assert(is_equal_approx(ride.obstacle_position(obstacle).x-70,786))
	assert(ride.visual_bounds(obstacle).intersects(ride.VIEWPORT,true))
	# Exact boundary and rest must not resurrect the unbroken surface or reset its world origin.
	ride.clock = 2.9-0.000001
	assert(not ride.obstacle_active(obstacle))
	ride.clock = 2.9
	assert(ride.obstacle_active(obstacle))
	game.paused = true
	var frozen: Dictionary = ride.hand_assembly(obstacle)
	ride.tick(game,0.5,Vector2.ZERO,false)
	assert(ride.hand_assembly(obstacle) == frozen)
	game.paused = false
	game.flush.enter_ride(game,10)
	assert(ride.clock == 0 and not ride.obstacle_active(ride.visual_obstacles[0]))
	game.queue_free()
	await process_frame
	print("PASS:501 actual wrapper hand poses, exact pit activation, rigid joints, full reaching-arm clearance, culling, pause and retry")
	quit()
