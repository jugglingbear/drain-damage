extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func seek(game: Node2D, state: String, kind: String) -> void:
	for tick in range(120*45):
		if game.clogfather.encounter.state == state and game.clogfather.encounter.pressure_kind == kind: return
		game.clogfather.advance(game,1.0/120)
		game.step_campaign_swarms(1.0/120)
	assert(false,"Pressure state not reached: "+state+" "+kind)

func run_checks() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
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
			assert(boss.hazards.size() == {"easy":1,"normal":4,"hard":6}[mode])
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
			# Real shared projectiles disperse each cloud after exactly five active-weapon hits.
			var cloud_count: int = boss.hazards.size()
			for cloud_index in range(cloud_count):
				var cloud: Dictionary = boss.hazards[0]
				assert(cloud.hp == game.weapon.damage*5)
				for hit_index in range(5):
					game.shot_serial += 1
					game.shots.append({"pos":cloud.rect.get_center()+game.clogfather.ORIGIN-Vector2(10,0),
						"dir":Vector2.RIGHT,"damage":game.weapon.damage,"speed":500.0,
						"distance":0.0,"range":800.0,"fired_airborne":false})
					game.step_trial_shots(.05)
					assert(game.shots.is_empty(),"Gas consumes the impacting projectile")
					assert(boss.hazards.size() == cloud_count-cloud_index-(1 if hit_index == 4 else 0))
			assert(boss.gas_targets().is_empty())
			game.player = Vector2(14550,394)
			for cycle in range(3):
				var survivors: Array = game.swarms.actors.filter(func(a: Dictionary) -> bool: return a.hp > 0)
				seek(game,"pressure_warning","reinforcements")
				assert(game.swarms.actors.filter(func(a: Dictionary) -> bool: return a.hp > 0).size() == survivors.size(),
					"Warning adds no new attackers")
				seek(game,"pressure_active","reinforcements")
				var count: int = game.swarms.actors.size()
				var wave_count: int = {"easy":2,"normal":4,"hard":8}[mode]
				var living: Array = game.swarms.actors.filter(func(a: Dictionary) -> bool: return a.hp > 0)
				assert(living.size() == survivors.size()+wave_count,"Every promised reinforcement must spawn")
				game.clogfather.spawn_reinforcements(game)
				assert(game.swarms.actors.size() == count,"Repeated event cannot refill a wave")
				var actor: Dictionary = game.swarms.actors[count-wave_count]
				assert(actor.hp == 24 and actor.clogfather_reinforcement and game.swarms.entry_active(actor))
				assert(not actor.contact_ready and actor.pos.y+128 < 0,"Reinforcements begin completely above view")
				game.player = actor.pos-Vector2(13,23)
				game.invulnerable = 0
				game.swarms.hero_cooldown = 0
				var before_contact: int = game.health
				game.step_campaign_swarms(1.0/120)
				assert(game.health == before_contact,"Arriving reinforcements cannot hurt the hero")
				for tick in range(145): game.step_campaign_swarms(1.0/120)
				assert(not game.swarms.entry_active(actor),"Reinforcement reaches its playable plane")
				game.player = actor.pos-Vector2(13,23)
				game.step_campaign_swarms(1.0/120)
				assert(game.health == before_contact-1,"Landed reinforcement resumes normal contact")
				game.health = game.employee.max_health
				game.invulnerable = 1000
				game.player = Vector2(14550,394)
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
					game.step_campaign_swarms(1.0/120)
					for swarm: Dictionary in game.swarms.actors:
						assert(swarm.bounds.encloses(Rect2(swarm.pos-Vector2(4,4),Vector2(8,8))),"Hunting swarm center stays inside its bounds")
						if survivors.has(swarm) or swarm.hp <= 0: continue
						var safe_lane := Rect2(boss.safe_corridor.position+game.clogfather.ORIGIN,boss.safe_corridor.size)
						assert(not game.swarms.overlaps(swarm,safe_lane),"Safe lane also excludes actual contact damage")
						var half_size: float = 4*lerpf(1,game.swarms.WEAPON_SCALE,smoothstep(0,1,swarm.morph))
						for offset: Vector2 in game.swarms.fly_offsets(swarm):
							var glyph := Rect2(swarm.pos+offset-game.clogfather.ORIGIN-Vector2.ONE*half_size,
								Vector2.ONE*half_size*2)
							assert(not glyph.intersects(boss.safe_corridor),"Every visible/contact fly preserves safe lane")
				assert(game.swarms.shot_hit(actor.pos-Vector2(100,0),actor.pos,game.swarms.actors.find(actor),2) >= 0)
				# Isolate the projectile target: surviving clouds/adds can now intercept these fixture shots.
				var saved_actors: Array = game.swarms.actors.duplicate()
				var saved_hazards: Array = boss.hazards.duplicate()
				game.swarms.actors.clear()
				game.swarms.actors.append(actor)
				boss.hazards.clear()
				for shot_index in range(2):
					game.shots.append({"pos":actor.pos-Vector2(20,0),"dir":Vector2.RIGHT,
						"damage":game.weapon.damage,"speed":game.weapon.projectile.speed_pixels_per_second,
						"distance":0.0,"range":game.weapon.projectile.max_travel_distance_pixels,
						"fired_airborne":true})
					game.step_trial_shots(0.1)
				assert(actor.hp == 0,"Canonical swarm damage must kill reinforcements")
				game.swarms.actors.assign(saved_actors)
				boss.hazards.assign(saved_hazards)
				game.clogfather.spawn_reinforcements(game)
				# Earlier corpses may retire during the elapsed simulation. Compare the live
				# snapshot immediately before this repeated call, preserving identity and death.
				assert(game.swarms.actors == saved_actors and actor.hp == 0,
					"Repeated reinforcement call must neither add actors nor revive its dead target")
				seek(game,"recovery","")
				assert(game.swarms.actors.filter(func(a: Dictionary) -> bool: return a.hp > 0).size() == living.size()-1,
					"Only the killed reinforcement loses contact/damage")
				for survivor in survivors: assert(game.swarms.actors.has(survivor))
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
