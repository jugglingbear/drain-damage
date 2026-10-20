extends SceneTree
## Gameplay sweeps use authored geometry classes, while bodies keep deck collision.

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for path in ["res://scripts/opening_trial_game.gd","res://scripts/integrated_first_call.gd"]:
		for hero in range(2):
			var game = load(path).new()
			game.employee = game.Crew.EMPLOYEES[hero]
			root.add_child(game)
			game.set_process(false)
			game.set_physics_process(false)
			game.dialogue.finish()
			game.dispenser.cancel()
			game.actors.clear()
			game.enemies.clear()
			game.swarms.actors.clear()
			game.player = Vector2(4000,394)
			var center := Vector2(2000,200)
			game.trial_state.advance(10)
			var shooter_id := "opening-05"
			assert(game.trial_state.reserve(shooter_id))
			game.trial_state.advance(1)
			assert(game.trial_state.activate(shooter_id))
			for solid in [false,true]:
				game.trial_level.plinths.clear()
				game.trial_level.decks.clear()
				var obstacle := Rect2(center-Vector2(40,8),Vector2(80,16))
				if solid: game.trial_level.plinths.append(obstacle)
				else: game.trial_level.decks.append(obstacle)
				assert(obstacle in game.actor_solids())
				assert((obstacle in game.player_shot_solids()) == solid,
					"Collision classification, not size/pixels, controls projectile blocking")
				for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,
					Vector2(1,1).normalized(),Vector2(-1,1).normalized(),
					Vector2(1,-1).normalized(),Vector2(-1,-1).normalized()]:
					for dt in [0.01,0.1,1.0]:
						game.shots.assign([{"pos":center-direction*150,"dir":direction,"speed":300/dt,
							"range":1000.0,"distance":0.0,"damage":12.0,"trial_id":"fixture"}])
						game.step_trial_shots(dt)
						assert(game.shots.is_empty() == solid,"Friendly swept classification failed")
						if not solid: assert(game.shots[0].pos.is_equal_approx(center+direction*150))
						game.shots.clear()
					game.hostile_shots.assign([{"id":"fixture","pos":center-direction*150,
						"dir":direction,"age":0.0}])
					game.step_trial_shots(2.0)
					assert(game.hostile_shots.is_empty() == solid,"Hostile swept classification failed")
					game.hostile_shots.clear()
				game.player = center+Vector2(-13,77)
				var shooter := {"event_id":shooter_id,"hp":36.0,"visible_age":1.0,"feet":center-Vector2(22,80),
					"target":center+Vector2(0,100),"facing":1.0,"winding":true,
					"shot_clock":2.5,"fire_age":-1.0,"age":1.0}
				game.step_shooter(shooter,0,true)
				assert(game.hostile_shots.is_empty() == solid,"Shooter sightline must match projectile geometry")
				for shot in game.hostile_shots: game.trial_state.remove_bullet(shot.id)
				game.hostile_shots.clear()
				game.trial_state.end_pattern("fire-"+shooter_id)
				game.player = Vector2(4000,394)
				var body: Dictionary = game.trial_level.move_body(center-Vector2(13,100),
					Vector2(0,900),Vector2(26,46),0.2)
				assert(body.grounded and is_equal_approx(body.pos.y+46,obstacle.position.y))
				assert(not game.position_safe(center+Vector2(0,10),"aggressive_flyer"),
					"Spawn safety must retain the deck")
			game.queue_free()
			await process_frame
	print("PASS: both heroes/gameplay paths, eight directions, fast friendly/hostile sweeps, solid blocking and actor decks")
	quit()
