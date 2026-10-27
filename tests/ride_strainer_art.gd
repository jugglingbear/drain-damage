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
	var ride = game.flush.ride
	var count := 0
	for index in [11,12]:
		game.flush.enter_ride(game,index)
		var obstacle: Dictionary = ride.visual_obstacles[0]
		var frames: Dictionary = ride.obstacle_art.manifest.frames
		for step in range(401):
			ride.clock = step/100.0
			var assembly: Dictionary = ride.hazard_assembly(obstacle)
			assert(ride.obstacle_active(obstacle) == (ride.clock >= 2.9))
			var bounds: Rect2 = ride.visual_bounds(obstacle)
			for part: Dictionary in assembly.parts:
				var box: Rect2 = ride.frame_bounds(frames[part.id],part.transform)
				assert(bounds.grow(.001).encloses(box))
				if ride.clock >= 3.05: assert(box.end.y <= 118.001,"Hoisted assembly clears Tony's highest hop")
				if part.id == "strainer_chain":
					assert((part.transform*Vector2.ZERO).is_equal_approx(part.start))
					assert((part.transform*Vector2(0,100)).is_equal_approx(part.end))
				else: assert(is_equal_approx(part.transform.determinant(),1),"Authored basket poses stay rigid")
			count += 1
	game.queue_free()
	await process_frame
	print("PASS: ",count," integrated strainer poses, chain endpoints, culling, simultaneous pit activation and complete hoist clearance")
	quit()
