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
	var checked := 0
	for hero in [0,1]:
		game.employee = game.Crew.EMPLOYEES[hero]
		for anchor in [180.0,650.0]:
			for index in range(13):
				game.life_state = "alive"
				game.flush.enter_ride(game,index)
				ride.position = Vector2(anchor,330)
				var far_edge := 0.0
				for obstacle: Dictionary in ride.course.obstacles:
					far_edge = maxf(far_edge,float(obstacle.x)+float(obstacle.width)*0.5)
				ride.encounter_scroll = far_edge-134
				ride.clock = ride.encounter_scroll/ride.scroll_speed
				ride.encounter_clock = ride.clock
				var last: Dictionary = ride.visual_obstacles[-1]
				var before: Vector2 = ride.obstacle_position(last)
				ride.tick(game,1.0/120,Vector2.ZERO,false)
				assert(ride.phase != "rest" and ride.rest_remaining == 0)
				assert(ride.complete if index == 12 else ride.encounter_index == index+1)
				assert(ride.visual_obstacles.has(last),"Visible final prop survives immediate encounter transition")
				assert(ride.visual_bounds(last).intersects(ride.VIEWPORT,true))
				if not ride.complete:
					ride.tick(game,0.1,Vector2.ZERO,false)
					assert(ride.obstacle_position(last).x < before.x-50,"Departing visuals keep their world clock")
					assert(game.life_state == "alive")
					ride.clock += 3
					ride.prune_departed_visuals()
					assert(not ride.visual_obstacles.has(last),"Offscreen old prop must not respawn")
				checked += 1
	# Every authored footprint, including shadows and the rotated sweep arm, at both horizontal edges.
	for index in range(13):
		game.flush.enter_ride(game,index)
		for visual: Dictionary in ride.visual_obstacles:
			for phase in [0.0,0.6,1.2,1.8]:
				ride.clock = phase
				var original_x: float = visual.x
				var bounds: Rect2 = ride.visual_bounds(visual)
				visual.x += 959-bounds.position.x
				assert(ride.visual_bounds(visual).intersects(ride.VIEWPORT,true))
				bounds = ride.visual_bounds(visual)
				visual.x += 1-bounds.end.x
				assert(ride.visual_bounds(visual).intersects(ride.VIEWPORT,true))
				ride.prune_departed_visuals()
				assert(ride.visual_obstacles.has(visual),"Any visible artwork must be retained")
				visual.x = original_x
	# An oversized layered prop can outlive the rest: its origin must never reset with the next encounter.
	game.flush.enter_ride(game,1)
	var retained: Dictionary = ride.visual_obstacles[0]
	retained.x = 5000
	var origin: Vector2 = ride.obstacle_position(retained)
	game.paused = true
	ride.tick(game,0.5,Vector2.ZERO,false)
	assert(ride.obstacle_position(retained) == origin,"Pause freezes departing visuals")
	game.paused = false
	ride.clock += 0.5
	ride._start_encounter(2)
	assert(ride.visual_obstacles.has(retained))
	assert(is_equal_approx(ride.obstacle_position(retained).x,origin.x-280))
	game.flush.enter_ride(game,2)
	assert(not ride.visual_obstacles.has(retained),"Explicit retry clears the prior visual run")
	game.queue_free()
	await process_frame
	print("PASS: ",checked," zero-rest visual transitions; all authored edge footprints/moving phases; independent origins and retry cleanup")
	quit()
