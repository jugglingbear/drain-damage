extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void:
	call_deferred("checks")

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
			game.health = 2
			game.lives = 2
			game.begin_level_two()
			assert(game.health == 2 and game.lives == 2)
			assert(game.flush.active and game.flush.clock == 0)
			assert(game.enemies.is_empty() and game.actors.is_empty() and game.swarms.actors.is_empty())
			game.flush.tick(game,1.0,Vector2.ZERO,false,false)
			var before: float = game.flush.clock
			game.set_paused(true)
			game.flush.tick(game,1.0,Vector2.ONE,true,true)
			assert(game.flush.clock == before)
			game.set_paused(false)
			game.invulnerable = 0
			game.hurt_player()
			game.invulnerable = 0
			game.hurt_player()
			assert(game.life_state == "dying" and game.lives == 1)
			game.flush.tick(game,1.0,Vector2.ZERO,false,false)
			assert(game.flush.clock == before)
			game.respawn_after_death()
			assert(game.health == game.employee.max_health and game.lives == 1 and game.flush.clock == 0)
			assert(game.flush.radio.entries.all(func(line: Dictionary) -> bool: return line.event != "arrival"))
			# Held attacks and jump cannot create weapons, effects or invisible evasion while swimming.
			var weapon_id: String = game.weapon.id
			var shot_starts: Dictionary = game.starter_weapon_audio.starts.duplicate()
			for frame in range(120): game.flush.tick(game,1.0/120,Vector2.RIGHT,true,true)
			assert(game.flush.shots.is_empty() and game.flush.shots_fired == 0 and game.flush.jump_height == 0)
			assert(game.starter_weapon_audio.starts == shot_starts and game.weapon.id == weapon_id)
			game.flush.begin(game,true)
			# Survival alone reaches the landing; test-only invulnerability isolates timing from balance.
			for frame in range(5401):
				game.invulnerable = 10
				game.flush.tick(game,1.0/120,Vector2.ZERO,false,false)
			assert(game.flush.clock == 45 and game.flush.checkpoint_saved and not game.won)
			assert(not game.flush.radio.current.is_empty())
			for frame in range(361): game.flush.tick(game,1.0/120,Vector2.ZERO,false,false)
			assert(game.won)
			assert(game.flush.hazards.is_empty() and game.flush.shots_fired == 0)
			assert(game.flush.debris.safety_failures == 0)
			assert(game.flush.debris.spawned == {"easy":26,"normal":48,"hard":85}[mode])
			assert(game.weapon.id == weapon_id)
			game.reset_game()
			assert(game.flush.active and game.health == game.employee.max_health and game.lives == 3)
			game.queue_free()
			await process_frame
	print("PASS: flush both heroes/all modes, carry state, pause/death/retry, survival-only landing and new attempt")
	quit()
