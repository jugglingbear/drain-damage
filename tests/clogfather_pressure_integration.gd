extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func seek(game: Node2D, state: String, kind: String) -> void:
	for tick in range(120*45):
		if game.clogfather.encounter.state == state and game.clogfather.encounter.pressure_kind == kind: return
		game.clogfather.advance(game,1.0/120)
		game.swarms.step(game,1.0/120)
	assert(false,"Pressure state not reached: "+state+" "+kind)

func run_checks() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(1))
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			var game = Game.new()
			game.difficulty = mode
			game.employee = game.Crew.EMPLOYEES[hero]
			game.seed_override = 42
			root.add_child(game)
			game.boss_intro.seen = {"cockroach-swarm": true, "clogfather": true}
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.dispenser.cancel()
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.restart_guard_device = -1
			game.invulnerable = 1000
			game.checkpoint_index = 1
			game.skitterling.restore_completed()
			game.player = Vector2(14550,394)
			game.clogfather.advance(game,0)
			var boss = game.clogfather.encounter
			seek(game,"pressure_active","gas")
			var hazard: Rect2 = boss.hazards[0].rect
			game.player = hazard.get_center()+game.clogfather.ORIGIN-Vector2(13,23)
			game.invulnerable = 0
			var health: int = game.health
			game.clogfather.advance(game,0.01)
			assert(game.health < health and game.invulnerable > 0,"Gas uses ordinary damage and immunity")
			health = game.health
			game.clogfather.advance(game,0.01)
			assert(game.health == health,"Gas must respect immunity")
			game.invulnerable = 1000
			game.player = Vector2(14550,394)
			for cycle in range(3):
				seek(game,"pressure_warning","reinforcements")
				assert(game.swarms.actors.is_empty(),"Warning must remain harmless")
				seek(game,"pressure_active","reinforcements")
				var count: int = game.swarms.actors.size()
				assert(count >= 1 and count <= (1 if boss.phase == 1 else 2))
				game.clogfather.spawn_reinforcements(game)
				assert(game.swarms.actors.size() == count,"Repeated event cannot refill a wave")
				var actor: Dictionary = game.swarms.actors[0]
				assert(actor.hp == 24 and actor.clogfather_reinforcement)
				var position: Vector2 = actor.pos
				var elapsed: float = boss.elapsed
				game.set_paused(true)
				game._physics_process(0.5)
				assert(actor.pos == position and boss.elapsed == elapsed)
				game.set_paused(false)
				game.dialogue.release_guard = 0
				game.dialogue.awaiting_release = false
				game.dispenser.just_finished = false
				game._physics_process(1.0/120)
				for tick in range(60):
					game.clogfather.advance(game,1.0/120)
					game.swarms.step(game,1.0/120)
					for swarm: Dictionary in game.swarms.actors:
						assert(swarm.bounds.grow(-48).has_point(swarm.pos))
						assert(not Rect2(swarm.pos-game.clogfather.ORIGIN-Vector2(64,64),
							Vector2(128,128)).intersects(boss.safe_corridor))
				assert(game.swarms.shot_hit(actor.pos-Vector2(100,0),actor.pos,0,2) >= 0)
				for shot_index in range(2):
					game.shots.append({"pos":actor.pos-Vector2(20,0),"dir":Vector2.RIGHT,
						"damage":game.weapon.damage,"speed":game.weapon.projectile.speed_pixels_per_second,
						"distance":0.0,"range":game.weapon.projectile.max_travel_distance_pixels,
						"fired_airborne":true})
					game.step_trial_shots(0.1)
				assert(actor.hp == 0,"Canonical swarm damage must kill reinforcements")
				game.clogfather.spawn_reinforcements(game)
				assert(game.swarms.actors.size() == count and game.swarms.actors[0].hp == 0)
				seek(game,"recovery","")
				assert(game.swarms.actors.is_empty() and boss.hazards.is_empty())
				if cycle < 2: game.clogfather.damage(game,360,"phase-"+str(cycle),true)
			seek(game,"pressure_active","reinforcements")
			game.clogfather.reset(42)
			assert(game.swarms.actors.is_empty(),"Direct reset purges pending and live reinforcements")
			game.clogfather.advance(game,0)
			seek(game,"pressure_active","reinforcements")
			# Force a terminal event with stale adds to test defensive adapter cleanup.
			boss.state = "recovery"
			game.clogfather.damage(game,10000,"terminal",true)
			assert(game.swarms.actors.is_empty() and boss.hp == 0)
			game.reset_game()
			assert(not game.clogfather.entered and boss.pressure_wave == 0)
			game.queue_free()
			await process_frame
	print("PASS: pressure adapter all heroes/modes; gas immunity, bounded waves, pause, kill/no refill, windows, reset and death")
	quit()
