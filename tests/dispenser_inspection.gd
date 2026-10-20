extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	create_timer(45).timeout.connect(func() -> void: quit(1))
	for mode in ["normal","hard"]:
		for hero in [0,1]:
			var game = Game.new()
			game.difficulty = mode
			game.employee = game.Crew.EMPLOYEES[hero]
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			var dispenser = game.dispenser
			for hp in range(1,game.employee.max_health):
				game.reset_game()
				game.dialogue.finish()
				game.dialogue.release_guard = 0
				game.health = hp
				game.activate_checkpoint(0)
				assert(game.health == game.employee.max_health and dispenser.arrival_health == hp)
				assert(is_equal_approx(dispenser.diagnosis_fraction(),float(hp)/game.employee.max_health))
				assert(dispenser.events == ["grab"] and dispenser.hides_hero())
				dispenser.tick(game,1.65)
				assert(dispenser.events == ["grab","inspection_arm_deploy","inspect","diagnosis"])
				assert(dispenser.stocked and not dispenser.overlay_visible())
				var before: Array = dispenser.events.duplicate()
				game.set_paused(true)
				dispenser.tick(game,10)
				assert(dispenser.events == before and is_equal_approx(dispenser.elapsed,1.65))
				game.set_paused(false)
				dispenser.tick(game,1.51)
				assert(dispenser.events[-1] == "throw" and dispenser.overlay_visible() and dispenser.stocked)
				dispenser.tick(game,.70)
				assert(dispenser.events[-1] == "vend" and not dispenser.stocked)
				dispenser.tick(game,2.95)
				assert(not dispenser.active and dispenser.finalizations == 1 and game.lives == 3)
				assert(dispenser.events.count("vend") == 1 and dispenser.events.count("release") == 1)
				assert(dispenser.hero == game.employee.id and dispenser.hard_mode == (mode == "hard"))
				assert(dispenser.arrival_health == hp,"Healing must not rewrite the diagnosis snapshot")
			game.queue_free()
			await process_frame
	print("PASS: normal/Hard and both heroes, actual preheal HP, ordered inspection, pause, 6.8s release and life/stock accounting")
	quit()
