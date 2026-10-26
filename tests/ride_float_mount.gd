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
	game.flush.enter_ride(game,5)
	var ride = game.flush.ride
	assert(ride.course.obstacles.size() == 1,"Mount and rod must remain decorative, not new colliders")
	var obstacle: Dictionary = ride.visual_obstacles[0]
	assert(obstacle.width == 100 and obstacle.depth == 60)
	assert(obstacle.y == 285 and obstacle.motion.amplitude == 25 and obstacle.motion.period == 2.4)
	var frames: Dictionary = ride.obstacle_art.manifest.frames
	for step in range(481):
		ride.clock = step/200.0
		var assembly: Dictionary = ride.float_assembly(obstacle)
		assert(is_equal_approx(assembly.pivot.y,220),"Pivot stays on the wall throughout the sweep")
		assert(assembly.socket.is_equal_approx(ride.obstacle_position(obstacle)+Vector2(-35,-28)))
		assert(assembly.span >= 150.47 and assembly.span <= 162.38)
		var shaft: Transform2D = assembly.parts[1].transform
		assert((shaft*Vector2.ZERO).is_equal_approx(assembly.pivot))
		assert((shaft*Vector2(150,0)).is_equal_approx(assembly.socket),"Shaft cannot detach at either endpoint")
		for i in [0,2,3]:
			assert(is_equal_approx(assembly.parts[i].transform.determinant(),1),"Hardware must not stretch")
		var mount: Dictionary = assembly.parts[0]
		var clipped: Dictionary = ride.obstacle_art.clipped_region(frames[mount.id],mount.transform.origin,230)
		assert(clipped.target.end.y <= 230 and clipped.target.has_point(assembly.pivot))
		var bounds: Rect2 = ride.visual_bounds(obstacle)
		assert(bounds.has_point(assembly.pivot) and bounds.has_point(assembly.socket))
	# Wall mount extends left of the ball; retain it even with the ball beyond the right edge.
	obstacle.x += 960-ride.obstacle_position(obstacle).x+120
	assert(ride.visual_bounds(obstacle).intersects(ride.VIEWPORT,true))
	game.queue_free()
	await process_frame
	print("PASS:481 full-sweep mount/socket/shaft registrations, fixed wall clipping, rigid joints, visual lifetime and unchanged collider")
	quit()
