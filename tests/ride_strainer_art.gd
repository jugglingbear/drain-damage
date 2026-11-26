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
			assert(ride.obstacle_active(obstacle) == (ride.clock >= 3.10))
			var bounds: Rect2 = ride.visual_bounds(obstacle)
			for part: Dictionary in assembly.parts:
				var box: Rect2 = ride.frame_bounds(frames[part.id],part.transform)
				assert(bounds.grow(.001).encloses(box))
				assert(part.id == ride.obstacle_art.manifest.strainer_parts.basket)
				var surface: Vector2 = ride.obstacle_position(obstacle)+Vector2(0,obstacle.depth*.5)
				assert(is_equal_approx(box.get_center().x,surface.x))
				if ride.clock > 3.1: assert(box.end.y > surface.y,"Basket must continue below the opening")
				assert(is_equal_approx(part.transform.determinant(),1),"Basket stays rigid")
			count += 1
	game.queue_free()
	await process_frame
	print("PASS: ",count," integrated strainer poses, fixed registration, culling, timed pit activation and downward exit")
	quit()
