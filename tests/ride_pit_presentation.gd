extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Freeze = preload("res://scripts/screenshot_freeze.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			var capture := Freeze.new()
			capture.host = game
			game.add_child(capture)
			for index in [1,6,7,9,10]:
				game.reset_game()
				game.begin_level_two()
				game.flush.enter_ride(game,index)
				var ride = game.flush.ride
				var gap: Dictionary = {}
				for obstacle: Dictionary in ride.course.obstacles:
					if obstacle.kind in ["gap","long_pit"]: gap = obstacle
				assert(not gap.is_empty())
				# Force an unsupported edge position, retaining authored gap geometry and ordinary host death.
				ride.position = Vector2(300,330 if index == 1 else 260)
				ride.encounter_scroll = float(gap.x)-300
				ride.clock = ride.encounter_scroll/560
				ride.encounter_clock = ride.clock
				game.health = game.employee.max_health
				game.invulnerable = 10
				ride.tick(game,1.0/120,Vector2.ZERO,false)
				assert(game.life_state == "dying" and game.lives == 2 and ride.events.fall == 1)
				var failed: Vector2 = ride.position
				var start: Vector2 = ride.rider_transform(game).origin
				assert(ride.fall_clip_bottom() == float(gap.y)+float(gap.depth)*0.5)
				game.step_death(0.25)
				var quarter: Vector2 = ride.rider_transform(game).origin
				assert(quarter.x == start.x and quarter.y > start.y+9)
				assert(not game.pause_menu.visible and game.life_state == "dying")
				capture.begin_freeze()
				assert(paused and capture.frozen)
				await create_timer(0.03,true).timeout
				assert(ride.rider_transform(game).origin == quarter)
				capture.resume()
				game.step_death(0.5)
				assert(ride.rider_transform(game).origin.y > quarter.y+100 and not game.pause_menu.visible)
				ride.tick(game,1,Vector2.ONE,true)
				assert(ride.position == failed and game.lives == 2)
				game.step_death(0.26)
				assert(game.life_state == "dying" and not game.pause_menu.visible)
				game.step_death(0.35)
				assert(game.life_state == "death_popup" and game.pause_menu.visible and game.lives == 2)
				game.respawn_after_death()
				assert(game.flush.ride.encounter_index == index and game.life_state == "alive")
			game.queue_free()
			await process_frame
	print("PASS:30 authored pit falls, both heroes/all modes, downward progression before UI, clip rim, freeze, single life and checkpoint")
	quit()
