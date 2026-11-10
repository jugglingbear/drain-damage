extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value and message not in failures:
		failures.append(message)
		push_error(message)

func reset(game, origin := 85.0) -> void:
	game.respawn_origin = origin
	game.reset_observation()
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.paused = false
	game.life_state = "alive"
	game.player = Vector2(origin,394)
	game.velocity = Vector2.ZERO
	game.grounded = true
	game.invulnerable = 1000
	game.camera_x = maxf(0,origin-320)

func run_checks() -> void:
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	reset(game)
	check(game.event_specs().size() == game.campaign.contract.encounters.size(),"Every authored slot normalized")
	check(game.campaign.level.pits.size() == 2,"Both campaign pits replace floor support")
	check(game.enemies.is_empty() and game.swarms.actors.is_empty(),"No legacy population after reset")
	for origin in [85.0,4650.0,7650.0,13800.0]:
		reset(game,origin)
		for spec: Dictionary in game.event_specs():
			check((game.ledger[spec.id] == "excluded") == (float(spec.owner_origin) < origin \
				or game.difficulty not in spec.enabled_difficulties),"Checkpoint ownership "+spec.id)
	for opening: Vector2 in game.campaign.level.pits:
		for percent in [0.64,0.65,0.66]:
			var body := Rect2(opening.x-game.PLAYER_SIZE.x*(1-percent),394,game.PLAYER_SIZE.x,46)
			var moved: Dictionary = game.campaign.level.move_body(body.position,Vector2(0,10),body.size,0.01)
			check(moved.falling == (percent >= 0.65),"Pit threshold "+str(percent))
	reset(game)
	for spec: Dictionary in game.event_specs():
		var possible := false
		for hero_x in range(int(spec.trigger),int(spec.end),10):
			game.player = Vector2(hero_x,394)
			game.camera_x = clampf(hero_x-320,0,14240)
			if game.in_pressure_dip() or game.crossing_reserved(): continue
			if spec.feet.x < game.camera_x+40 or spec.feet.x > game.camera_x+920: continue
			var route: Dictionary = game.entry_route(spec)
			if not route.is_empty():
				possible = true
				if spec.entry.mode == "bottom": print("Bottom ingress feasible at ",hero_x," full cloud ",game.swarm_cloud_bounds())
				break
		check(possible,"Authored ingress can fit within its window: "+spec.id)
	for difficulty in ["easy","normal","hard"]:
		game.difficulty = difficulty
		for hz in [30,60,120]:
			reset(game)
			var admissions := {}
			for position in [120,300,550,800,1100,1450,1800,2100,2450,2700,3200,3600,4050,4400,
				4850,5100,5500,5800,7900,8200,8500,9000,9600,10000,10500,11000,11500,12000,12500,13000,13500,13800]:
				game.player = Vector2(position,394)
				game.camera_x = clampf(position-320,0,14240)
				for tick in range(hz*2):
					var dt: float = 1.0/hz
					game.trial_clock += dt
					game.issue_event()
					game.step_trial_actors(dt)
					game.step_campaign_swarms(dt)
					game.step_hostile_projectiles(dt)
					check(game.live_population() <= game.crowd_limit(),"Shared population cap "+difficulty)
					check(game.hostile_shots.size() <= int(game.tuning.hostile_projectiles_max),"Projectile cap "+difficulty)
					check(game.pattern_owners().size() <= int(game.tuning.active_patterns_max),"Pattern cap "+difficulty)
					var shooters := 0
					var flyers := 0
					for actor: Dictionary in game.actors:
						admissions[actor.event_id] = true
						if actor.hp > 0 and actor.role == "perched_shooter": shooters += 1
						if actor.hp > 0 and actor.role == "aggressive_flyer": flyers += 1
					check(shooters <= int(game.tuning.shooter_cap),"Shooter cap")
					check(flyers <= int(game.tuning.flyer_cap),"Shared angel/devil cap")
				# Simulate successful combat between pockets, without reopening finite slots.
				for actor: Dictionary in game.actors:
					if actor.active and actor.hp > 0: game.damage_trial_actor(actor,10000)
				for index in range(game.swarms.actors.size()): game.swarms.damage(index,10000)
			check(admissions.size() >= 12,"Meaningful campaign admissions "+difficulty+str(hz))
			print("Campaign route ",difficulty," ",hz,"Hz: ",admissions.size()," actor slots")
			game.player.x = 85
			game.issue_event()
			for state in game.ledger.values(): check(state != "pending","No deferred backlog after end/backtrack")
	game.free()
	print("Campaign encounters: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
