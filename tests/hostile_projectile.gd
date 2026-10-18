extends SceneTree
## Verify visible-core registration and unchanged collision through both gameplay paths.

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for path in ["res://scripts/opening_trial_game.gd", "res://scripts/integrated_first_call.gd"]:
		var game = load(path).new()
		root.add_child(game)
		game.hide()
		game.set_process(false)
		game.set_physics_process(false)
		game.dispenser.cancel()
		game.shots.clear()
		game.actors.clear()
		game.enemies.clear()
		game.swarms.actors.clear()
		for effect: Dictionary in game.trial_data.environment.effects:
			if effect.id != "hostile-projectile": continue
			var scale := Vector2(effect.logical_size[0], effect.logical_size[1]) / 512.0
			var anchor := Vector2(effect.anchor[0], effect.anchor[1])
			# Measured authored bright-core center must sit on the simulated trajectory.
			assert((Vector2(321, 259.5) * scale - anchor).length() < 0.2)
			assert(is_equal_approx(68 * scale.x, 8.5))
			assert(is_equal_approx(49 * scale.y, 6.125))
		for offset in [-4.1, -3.9, 49.9, 50.1]:
			game.player = Vector2(1000, 100)
			game.health = 5
			game.invulnerable = 0
			game.hostile_shots.assign([{"id":"edge", "pos":Vector2(950, 100 + offset),
				"dir":Vector2.RIGHT, "age":0.0}])
			game.step_trial_shots(1.0)
			var should_hit: bool = offset > -4 and offset < 50
			assert(game.health == (4 if should_hit else 5), "Radius4 edge or damage changed")
			assert(game.hostile_shots.is_empty() == should_hit)
			if not should_hit:
				assert(game.hostile_shots[0].pos == Vector2(1100, 100 + offset), "Speed must remain150")
		# A long frame must sweep the floor before reaching a player below it.
		game.player = Vector2(1000, 480)
		game.health = 5
		game.invulnerable = 0
		game.hostile_shots.assign([{"id":"wall", "pos":Vector2(1013, 400),
			"dir":Vector2.DOWN, "age":0.0}])
		game.step_trial_shots(1.0)
		assert(game.hostile_shots.is_empty() and game.health == 5, "Scenery must intercept swept shot")
		game.queue_free()
		await process_frame
	print("PASS: both paths bright-core registration, radius4 edge hits/misses, damage1, speed150 and solid sweep")
	quit()
