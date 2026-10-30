extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for hero in [0,1]:
		var game = Game.new()
		game.employee = game.Crew.EMPLOYEES[hero]
		game.difficulty = "hard"
		game.seed_override = 42
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.invulnerable = 100
		assert(game.mission.current_zone == 2 and game.mission.remaining() == 0)
		assert(game.mission.zone_counts.slice(0,2) == [0,0])
		assert(game.trial_level.width == game.ClogfatherRoute.WORLD_WIDTH)
		assert(game.trial_level.decks.size() == 3+game.ClogfatherRoute.LEDGES.size())
		for ledge in game.ClogfatherRoute.LEDGES: assert(game.trial_level.decks.has(ledge))
		assert(game.swarms.actors.size() == 1 and game.swarms.actors[0].pos.x == 4400)
		Input.action_press("right")
		Input.action_press("shoot")
		for frame in range(3600):
			if game.grounded:
				for solid: Rect2 in game.trial_level.plinths:
					var gap: float = solid.position.x-(game.player.x+26)
					if gap >= 0 and gap < 70 and solid.position.y < game.player.y+46:
						game.jump_buffer = 0.14
			game._physics_process(1.0/120)
			if game.dispenser.active:
				game.dispenser.tick(game,0.1)
		Input.action_release("right")
		Input.action_release("shoot")
		assert(game.player.x > 3120, "Both heroes must actually run/jump into continuation")
		assert(game.trial_state.results().issued > 0 and game.trial_state.results().shots > 0)
		print("CONTINUOUS ",game.employee.id," x=",game.player.x," time=",game.trial_state.elapsed,
			" issued=",game.trial_state.results().issued," kills=",game.kills)
		game.dispenser.cancel()
		game.dispenser.just_finished = false
		game.reset_game()
		game.dialogue.release_guard = 0
		game.invulnerable = 100
		game.trial_state.advance(21)
		assert(game.trial_state.elapsed > 20 and not game.trial_state.finished)
		assert(not game.result_shown and not game.paused and not game.won)
		assert(game.weapon.damage == (12 if hero == 0 else 18))
		# A friendly projectile travels once even while both combat systems update.
		game.player = Vector2(3000,394)
		game.camera_x = 2680
		game.shots.append({"pos":Vector2(3100,100),"dir":Vector2.RIGHT,"speed":100.0,
			"range":320.0,"distance":0.0,"damage":12.0})
		game._physics_process(0.1)
		assert(game.shots.size() == 1 and is_equal_approx(game.shots[0].pos.x,3110))
		game.shots.clear()
		# Boundary has continuous floor, no closed old gate, no scene or clock reset.
		game.player = Vector2(3100,394)
		game.camera_x = 2780
		var old_clock: float = game.trial_state.elapsed
		Input.action_press("right")
		for frame in range(30): game._physics_process(1.0/120)
		Input.action_release("right")
		assert(game.player.x > 3120 and game.player.x < 3200)
		assert(game.trial_state.elapsed > old_clock and game.opening_passed)
		assert(not game.won and game.checkpoint_index == -1)
		var body: Dictionary = game.move_player_body(Vector2(3100,394),Vector2(-235,0),Vector2(26,46),0.1)
		assert(body.pos.x < 3100, "Backtracking cannot hit removed gate")
		# Checkpoint death rebuilds its owned segment and excludes the earlier opening.
		assert(game.Level.CHECKPOINTS == [4650.0,game.ClogfatherRoute.CHECKPOINT])
		game.player = Vector2(4649,394)
		game._physics_process(0)
		assert(game.checkpoint_index == -1)
		game.player = Vector2(4651,394)
		game._physics_process(1.0/120)
		assert(game.checkpoint_index == 0)
		game.dispenser.cancel()
		game.lives = 2
		var before: Dictionary = game.run_plan.duplicate(true)
		game.respawn_after_death()
		assert(game.player.x == 4650 and game.lives == 2)
		assert(game.run_plan == before and game.mission.current_zone == 2)
		assert(game.trial_state.results().unavailable == game.run_plan.opening.size() and game.actors.is_empty())
		game.dispenser.cancel()
		game.dialogue.release_guard = 0
		# Former shutters never block either direction or shots, regardless of kills.
		for gate in game.Level.GATES:
			assert(not game.player_shot_solids().has(Rect2(gate,180,48,260)))
			var forward: Dictionary = game.move_player_body(Vector2(gate-40,394),Vector2(235,0),Vector2(26,46),0.4)
			assert(forward.pos.x > gate+48)
			var backward: Dictionary = game.move_player_body(Vector2(gate+70,394),Vector2(-235,0),Vector2(26,46),0.5)
			assert(backward.pos.x < gate)
		# Finite crowds arrive without waiting for kills and respect the global bound.
		game.reset_game()
		game.dispenser.cancel()
		game.invulnerable = 100
		game.player = Vector2(4460,394)
		game.camera_x = 4140
		game.enemies.clear()
		game.actors.clear()
		var initial_kills: int = game.kills
		for index in range(20):
			game.step_encounters(0.65)
			game.step_combat(0.65)
		assert(game.enemies.size() > 4 and game.crowd_population() <= 8)
		assert(game.kills == initial_kills)
		for enemy in game.enemies: assert(enemy.hp == 24 and not enemy.has("mission_id"))
		# A telegraphed Widow immediately reduces the shared crowd budget.
		game.actors.append({"role":"aggressive_flyer","hp":180.0})
		assert(game.crowd_limit() == 6)
		var before_widow: Array = game.wave_spawned.duplicate()
		game.step_encounters(0.65)
		assert(game.wave_spawned == before_widow)
		game.actors.clear()
		assert(game.crowd_limit() == 8)
		var spawned: Array = game.wave_spawned.duplicate()
		game.next_wave_spawn = game.wave_clock+0.65
		game.step_encounters(0)
		assert(game.wave_spawned == spawned, "No accumulated burst")
		game.player = Vector2(4900,394)
		game.camera_x = 4580
		game.step_encounters(0.7)
		assert(game.kills == initial_kills, "Retirement is not a kill")
		var first_wave_count := 0
		for event in game.run_plan.later:
			if event.enabled and event.wave == 0: first_wave_count += 1
		assert(game.wave_bypassed[0]+game.wave_spawned[0] == first_wave_count)
		# The old exit continues toward the finale; defeating Skitterling cannot end the level.
		game.checkpoint_index = 0
		game.dispenser.cancel()
		game.skitterling.entered = true
		game.skitterling.released = true
		game.skitterling.encounter.exit_open = true
		game.player = Vector2(9451,394)
		game.dialogue.release_guard = 0
		game._physics_process(0)
		assert(not game.won and not game.ending.active() and not game.flush.active)
		game.reset_game()
		assert(game.lives == 3 and game.player.x == 85 and game.mission.remaining() == 0)
		assert(game.trial_state.elapsed == 0 and not game.opening_passed)
		game.queue_free()
		await process_frame
	print("PASS: both heroes continuous past20s, seamless boundary, canonical finale/checkpoints, ungated crowds and old-exit continuation")
	quit()
