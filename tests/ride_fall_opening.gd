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
	var count := 0
	for index in [1,6,7,9,10,11,12]:
		for bank in [260.0,330.0,400.0]:
			game.reset_game()
			game.flush.enter_ride(game,index)
			var ride = game.flush.ride
			ride.position.y = bank
			for step in range(1500):
				if game.life_state != "alive" or ride.encounter_index != index or ride.complete: break
				ride.tick(game,1.0/120,Vector2.ZERO,false)
			if not ride.events.has("fall"): continue
			var opening: Rect2 = ride.fall_opening()
			assert(opening.has_area())
			for obstacle: Dictionary in ride.course.obstacles:
				if obstacle.kind != "deck": continue
				var size := Vector2(float(obstacle.width),float(obstacle.depth))
				var solid := Rect2(ride.obstacle_position(obstacle)-size*0.5,size)
				assert(not opening.intersection(solid).has_area(),"Fall opening must exclude EVERY solid island")
				if opening.position.y >= solid.end.y:
					assert(not ride.deck_occludes_fall(obstacle),"Near-edge fall must draw IN FRONT of the island face")
			game.death_time = 0.22
			var anchor: Vector2 = ride.rider_transform(game).origin
			# Undo only vertical falling displacement; the supported-plane anchor has entered the opening.
			anchor.y -= pow(0.22-0.10,2)*460
			assert(opening.grow(.001).has_point(anchor),"Continuous carry reaches actual unsupported floor")
			if index == 6 and bank == 330:
				assert(anchor.x >= opening.position.x+minf(55,opening.size.x*.5)-.001,
					"Regression: fall carries the board fully into the opening after half-footprint entry")
			count += 1
	game.queue_free()
	await process_frame
	print("PASS: ",count," actual fatal entries select unsupported openings, subtract every island, and carry into real hole")
	quit()
