extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for mode in modes():
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
				begin_observation()
				var contact_hits := 0
				var peak_population := 0
				var peak_swarms := 0
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
						for pit in game.campaign.level.pits:
							if game.player.x+game.PLAYER_SIZE.x >= pit.x-15 and game.player.x < pit.y:
								game.jump_buffer = 0.14
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
					observe(game,1.0/hz)
					game.swarm_audio.tick(game,1.0/hz)
					assert(game.swarm_audio.voice.volume_db <= game.swarm_audio.MAX_GAIN_DB)
					peak_population = maxi(peak_population,game.crowd_population())
					peak_swarms = maxi(peak_swarms,game.swarms.actors.size())
					peak_projectiles = maxi(peak_projectiles,game.hostile_shots.size())
					if game.player.x >= 9450 and game.skitterling.encounter.exit_open: break
					if game.dispenser.active: game.dispenser.tick(game,0.1)
					assert(game.live_population() <= game.crowd_limit())
					assert(game.hostile_shots.size() <= int(game.tuning.hostile_projectiles_max))
					var shooters := 0
					var flyers := 0
					for actor in game.actors:
						if actor.hp > 0 and actor.role == "perched_shooter": shooters += 1
						if actor.hp > 0 and actor.role == "aggressive_flyer": flyers += 1
					assert(shooters <= int(game.tuning.shooter_cap) and flyers <= int(game.tuning.flyer_cap))
				if game.player.x < 9450:
					print("STALLED ",mode," hero",hero," seed",seed_value," x",game.player,
						" life",game.life_state," paused",game.paused," dialogue",game.dialogue.active,
						" guard",game.dialogue.release_guard," dispenser",game.dispenser.active,
						" intro_guard",game.intro_input_release," axis",Input.get_axis("left","right"),
						" boss",game.skitterling.encounter.snapshot()," shots",game.shots.size()," aim",game.current_aim)
				assert(not game.won and game.player.x >= 9450, "The former exit continues toward Clogfather")
				print("CAMPAIGN ",mode," hero",hero," seed",seed_value," x",game.player.x,
					" peak population",peak_population," swarms",peak_swarms," projectiles",peak_projectiles,
					" contact hits",contact_hits," admissions",game.arrival_log.size())
				report_observation()
				Input.action_release("right")
				Input.action_release("shoot")
				game.queue_free()
				await process_frame
				# Manual simulation loops do not advance Godot's input-edge bookkeeping.
				await physics_frame
	print("PASS: ",modes().size()*6," mode/hero/seed traversals at60/120Hz; shared caps, pits and boss traversal")
	quit()

func modes() -> Array[String]: return ["easy","normal","hard"]

func begin_observation() -> void: pass
func observe(_game: Node, _delta: float) -> void: pass
func report_observation() -> void: pass
