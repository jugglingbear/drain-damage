extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
# Same continuous-forward/fire route against the preserved Prototype 83 PCK, seeds 7/42/913.
const BASELINE_83 := {"easy":[[27,27,27],[26,26,26]],
	"normal":[[26,26,27],[27,26,27]],"hard":[[34,34,34],[34,34,34]]}

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			for seed_value in [7,42,913]:
				var game = Game.new()
				game.difficulty = mode
				game.seed_override = seed_value
				game.employee = game.Crew.EMPLOYEES[hero]
				root.add_child(game)
				game.hide()
				game.set_process(false)
				game.set_physics_process(false)
				game.dialogue.finish()
				game.dialogue.release_guard = 0
				game.invulnerable = 0
				var contact_hits := 0
				var peak_population := 0
				var peak_additions := 0
				var peak_projectiles := 0
				Input.action_press("right")
				Input.action_press("shoot")
				var hz := 60 if seed_value == 7 else 120
				for tick in range(180*hz):
					if game.intro_input_release:
						# A player must release held fire after a boss introduction before rearming it.
						Input.action_release("shoot")
						if Input.is_action_pressed("jump"): Input.action_release("jump")
					elif game.dispenser.actions_locked:
						Input.action_release("shoot")
						game.dispenser.tick(game,1.0/hz)
					else: Input.action_press("shoot")
					if game.grounded:
						for solid: Rect2 in game.trial_level.plinths:
							var gap: float = solid.position.x-(game.player.x+26)
							if gap >= 0 and gap < 70 and solid.position.y < game.player.y+46:
								game.jump_buffer = 0.14
					if game.skitterling.locked() and not game.skitterling.encounter.exit_open:
						var boss = game.skitterling.encounter
						var gap: float = boss.position.x+6570-game.player.x
						Input.action_release("left")
						Input.action_release("right")
						if not is_zero_approx(gap): game.facing = signf(gap)
						if absf(gap) > game.weapon.projectile.max_travel_distance_pixels*.65:
							Input.action_press("right" if gap > 0 else "left")
						game.jump_buffer = 0
					else:
						Input.action_release("left")
						Input.action_press("right")
					# Exercise real contact while preventing bot deaths from truncating distribution coverage.
					game.health = game.employee.max_health
					game._physics_process(1.0/hz)
					if game.health < game.employee.max_health: contact_hits += 1
					game.swarm_audio.tick(game,1.0/hz)
					assert(game.swarm_audio.voice.volume_db <= game.swarm_audio.MAX_GAIN_DB)
					peak_population = maxi(peak_population,game.crowd_population())
					peak_additions = maxi(peak_additions,game.swarm_schedule.additional_population(game))
					peak_projectiles = maxi(peak_projectiles,game.hostile_shots.size())
					if game.player.x >= 9450 and game.skitterling.encounter.exit_open: break
					if game.dispenser.active: game.dispenser.tick(game,0.1)
					var report: Dictionary = game.trial_state.results()
					assert(report.shooters <= 3 and report.bullets <= 6 and report.patterns <= 3)
					assert(game.ordinary_population() <= game.run_plan.crowd_cap)
					assert(game.swarm_schedule.additional_population(game) <= 2)
					assert(game.crowd_population() <= game.run_plan.crowd_cap+2)
					var widows := 0
					for actor in game.actors:
						if actor.hp > 0 and actor.role == "aggressive_flyer": widows += 1
					assert(widows <= 1)
					if widows > 0: assert(game.ordinary_population() <= 6)
				if game.player.x < 9450:
					print("STALLED ",mode," hero",hero," seed",seed_value," x",game.player,
						" life",game.life_state," paused",game.paused," dialogue",game.dialogue.active,
						" guard",game.dialogue.release_guard," dispenser",game.dispenser.active,
						" intro_guard",game.intro_input_release," axis",Input.get_axis("left","right"),
						" boss",game.skitterling.encounter.snapshot()," shots",game.shots.size()," aim",game.current_aim)
				assert(not game.won and game.player.x >= 9450, "The former exit continues toward Clogfather")
				print("MODE ",mode," hero",hero," seed",seed_value," x",game.player.x,
					" issued",game.trial_state.results().issued," waves",game.wave_spawned)
				var swarm_report: Dictionary = game.swarm_schedule.report()
				var ordinary_issued: int = game.trial_state.results().issued
				if mode != "normal":
					for count in game.wave_spawned: ordinary_issued += count
				var potential: int = swarm_report.potential-game.ClogfatherRoute.SWARMS.size()
				for event in game.run_plan.opening:
					if event.enabled: potential += 1
				for event in game.run_plan.later:
					if event.enabled and event.wave < 4 and (event.trigger < 5610 or event.trigger >= 7530): potential += 1
				print("ENCOUNTERS ",JSON.stringify({"mode":mode,"hero":hero,"seed":seed_value,"hz":hz,
					"potential":potential,"ordinary_issued":ordinary_issued,"swarm_issued":swarm_report.issued,
					"total_issued":ordinary_issued+swarm_report.issued,
					"not_issued":potential-ordinary_issued-swarm_report.issued}))
				assert(swarm_report.issued == (9 if mode == "easy" else 13 if mode == "normal" else 11) and swarm_report.visible == swarm_report.issued)
				var baseline: int = BASELINE_83[mode][hero][[7,42,913].find(seed_value)]
				var actual: int = ordinary_issued+swarm_report.issued
				assert(actual == baseline if mode == "easy" else actual >= ceili(baseline*1.25),
					"Actual admitted count must meet the 25% increase over the identical Prototype 83 route")
				print("SWARMS ",JSON.stringify({"mode":mode,"hero":hero,"seed":seed_value,
					"summary":swarm_report,"ledger":game.swarm_schedule.ledger,"contact_hits":contact_hits,
					"peak_population":peak_population,"peak_additions":peak_additions,
					"peak_hostile_projectiles":peak_projectiles}))
				Input.action_release("right")
				Input.action_release("shoot")
				# Moving checkpoint respawn intentionally bypasses short4700 tail during grace.
				game.checkpoint_active = true
				game.checkpoint_index = 0
				game.respawn_point = Vector2(4650,394)
				game.respawn_after_death()
				game.dispenser.cancel()
				for tick in range(hz*2):
					game.player.x = 4650+game.employee.move_speed*float(tick+1)/hz
					game.camera_x = game.player.x-320
					var before: int = game.crowd_population()
					game.step_encounters(1.0/hz)
					if float(tick+1)/hz < 1.25: assert(game.crowd_population() == 0)
					assert(game.crowd_population()-before <= 1)
				assert(game.encounter_states["normal-route-08" if mode == "normal" else "wave-0-07"] == "bypassed")
				game.queue_free()
				await process_frame
				# Manual simulation loops do not advance Godot's input-edge bookkeeping.
				await physics_frame
	print("PASS:18mode/hero/seed traversals60/120Hz,all caps,unique Widow,moving respawn grace and safe tail bypass")
	quit()
