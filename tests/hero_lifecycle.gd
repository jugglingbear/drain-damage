extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func settle(game: Node2D) -> void:
	for frame in range(180): game.step_death(1.0 / 60)

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	for person in game.Crew.EMPLOYEES:
		game.employee = person
		game.reset_game()
		game.activate_checkpoint(0)
		game.dispenser.tick(game,5.6)
		game.encounter_triggered[0] = true
		var survivor: Dictionary = game.Data.spawn("toilet", Vector2(3450, 404))
		survivor.aggro = true
		game.enemies.append(survivor)
		assert(game.lives == 3)
		for remaining in [2, 1, 0]:
			game.player = Vector2(3400, 200)
			game.health = 1
			game.invulnerable = 0
			game.hurt_player()
			assert(game.life_state == "dying" and game.lives == remaining and game.health == 0)
			for hit in range(4): game.hurt_player()
			assert(game.lives == remaining, "One fatal event consumes one life")
			Input.action_press("shoot")
			game.step_player(0.2)
			assert(game.shots.is_empty())
			Input.action_release("shoot")
			var before: Vector2 = game.player
			game.set_paused(true)
			game._physics_process(1)
			assert(game.player == before and game.death_time == 0)
			game.set_paused(false)
			game.step_death(0.1)
			assert(game.player != before and not game.grounded)
			settle(game)
			assert(game.enemies.size() == 1 and game.enemies[0].aggro)
			assert(game.checkpoint_index == 0 and game.encounter_triggered[0])
			game.update_death_popup_guard(0.4)
			if remaining > 0:
				assert(game.life_state == "death_popup")
				game.resume_or_retry()
				assert(game.life_state == "alive" and game.player == game.respawn_point)
				assert(game.health == person.max_health and game.invulnerable == 3)
				game.dispenser.tick(game,1.95)
			else:
				assert(game.life_state == "game_over" and game.paused and game.pause_menu.visible)
				assert(game.resume_button.text == "Retry")
				game._physics_process(10)
				assert(game.health == 0 and game.lives == 0)
		game.resume_button.pressed.emit()
		assert(game.life_state == "alive" and game.lives == 3 and not game.paused)
		assert(game.checkpoint_index == -1 and game.enemies.is_empty())
		assert(game.employee.id == person.id and game.health == person.max_health)
	game.queue_free()
	await process_frame
	print("PASS: both heroes, three total lives, death fall/lock, pause, persistence, game over and deliberate retry")
	quit()
