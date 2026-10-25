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
			# Actual cadence must produce two accepted hits, without requiring any kill to finish.
			game.flush.position = Vector2(250,0)
			game.flush.aim = Vector2.RIGHT
			game.flush.clock = 8
			var target := {"id":"test-soft","at":0.0,"warning_seconds":0.0,"lifetime_seconds":20.0,
				"radius_pixels":22.0,"kind":"soft","pos":Vector2(290,0),"hp":24}
			game.flush.hazards.clear()
			game.flush.hazards.append(target)
			game.invulnerable = 10
			game.flush.tick(game,0.04,Vector2.ZERO,false,true)
			game.flush.tick(game,0.04,Vector2.ZERO,false,true)
			assert(game.flush.shots_fired == 1 and target.hp == 24-game.weapon.damage)
			for frame in range(50):
				# Hold the firing lane to isolate weapon cadence from current-driven aim drift.
				game.flush.position = Vector2(250,0)
				game.flush.tick(game,0.01,Vector2.ZERO,false,true)
			assert(target.hp <= 0 and game.flush.hazards.is_empty())
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
			game.reset_game()
			assert(game.flush.active and game.health == game.employee.max_health and game.lives == 3)
			game.queue_free()
			await process_frame
	print("PASS: flush both heroes/all modes, carry state, pause/death/retry, survival-only landing and new attempt")
	quit()
