extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			game.seed_override = 42
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.begin_level_two()
			game.flush.enter_ride(game,0)
			game.flush.input_guard = false
			game.invulnerable = 0
			var ride = game.flush.ride
			var stage := -1
			var next_jump := 0
			var health: int = game.health
			for frame in range(180*60):
				if ride.complete: break
				if stage != ride.encounter_index:
					stage = ride.encounter_index
					next_jump = 0
				var target := 330.0
				var jump := false
				if ride.phase == "encounter":
					var route: Dictionary = ride.encounter.witness
					var next_x: float = ride.position.x+ride.encounter_scroll+ride.scroll_speed/60.0
					for waypoint: Dictionary in route.bank_targets:
						if next_x >= float(waypoint.at_world_x): target = float(waypoint.target_y)
					if next_jump < route.jump_press_world_x.size() and next_x >= float(route.jump_press_world_x[next_jump]):
						jump = true
						next_jump += 1
				var steering := Vector2(0,clampf((target-ride.position.y)/(ride.bank_speed/60.0),-1,1))
				game.flush.tick(game,1.0/60,steering,jump,true)
				assert(game.health == health and game.lives == 3 and game.life_state == "alive")
			assert(ride.complete and game.won and ride.events.encounter_started == 10 and ride.events.rest_started == 10)
			assert(ride.events.jump == 6 and ride.events.ramp == 1 and game.flush.shots_fired == 0)
			assert(game.flush.radio.current.is_empty())
			print("PASS GAME SHOWCASE ",game.employee.id," ",mode," seconds ",ride.clock)
			game.queue_free()
			await process_frame
	print("PASS: six full integrated showcase routes, sixty encounters, shared game health/lives, no flush replay or firing")
	quit()
