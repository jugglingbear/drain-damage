extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func prepare(mode: String = "normal", hero: int = 0, seed_value: int = 42) -> Node2D:
	var game = Game.new()
	game.difficulty = mode
	game.employee = game.Crew.EMPLOYEES[hero]
	game.seed_override = seed_value
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.invulnerable = 1000
	return game

func run_checks() -> void:
	var game = prepare()
	var schedule = game.swarm_schedule
	assert(schedule.report().issued == 1 and game.swarms.actors[0].pos.x == 4400)
	for slot in schedule.SLOTS:
		var render_bounds: Rect2 = slot.bounds.grow(16)
		assert(game.skitterling.allowed_body(render_bounds))
		assert(game.swarms.clear_path(slot.home,slot.home,slot.bounds,game.player_shot_solids()),
			"Invalid initial swarm footprint: "+slot.id)
		var actor: Dictionary = game.swarms.spawn(slot.home,slot.bounds,42)
		for tick in range(600):
			game.swarms.step_motion(actor,1.0/60,game.player_shot_solids())
			assert(slot.bounds.grow(-48).has_point(actor.pos))
			for solid in game.player_shot_solids():
				assert(not solid.grow(48).has_point(actor.pos),"Swarm intersects solid: "+slot.id)
	# No admission during pause/dialogue/dispenser/death or checkpoint grace.
	for gate in ["pause","dialogue","dispenser","death"]:
		game.reset_observation()
		game.paused = gate == "pause"
		game.dialogue.active = gate == "dialogue"
		game.dispenser.active = gate == "dispenser"
		game.life_state = "dying" if gate == "death" else "alive"
		schedule.step(game)
		assert(schedule.report().issued == 1)
	game.paused = false
	game.dialogue.active = false
	game.dispenser.active = false
	game.life_state = "alive"
	game.respawn_origin = 4650
	game.reset_observation()
	game.player = Vector2(4650,394)
	game.camera_x = 4330
	game.wave_clock = 1.24
	schedule.step(game)
	assert(schedule.report().issued == 0 and schedule.report().excluded == 5)
	game.wave_clock = 1.25
	schedule.step(game)
	assert(schedule.report().issued == 1 and game.swarms.actors[0].schedule_id == "pump-overhead")
	for x in [5610,6000,6570,7000,7529]:
		game.player.x = x
		game.camera_x = x-320
		schedule.step(game)
		assert(schedule.report().issued == 1)
	game.skitterling.clear_prior(game)
	game.skitterling.released = true
	game.player.x = 7530
	game.camera_x = 6570
	schedule.step(game)
	assert(schedule.ledger["boss-exit"].issued)
	# Offscreen staging cannot consume the visible warning or activate contact.
	var warning: Dictionary = game.swarms.actors[0]
	game.camera_x = 6570
	for tick in range(120): game.swarms.step(game,1.0/120)
	assert(is_equal_approx(warning.warning,0.8) and not warning.get("contact_ready",false))
	game.camera_x = warning.pos.x-900
	for tick in range(60): game.swarms.step(game,1.0/120)
	assert(warning.warning > 0.29 and not warning.get("contact_ready",false))
	# Warning contact stays harmless, including a player stepping into its footprint.
	game.player = warning.pos-Vector2(13,23)
	game.health = game.employee.max_health
	game.invulnerable = 0
	for tick in range(120): game.swarms.step(game,1.0/120)
	assert(game.health == game.employee.max_health and not warning.get("contact_ready",false))
	game.player.x -= 250
	game.swarms.step(game,.01)
	assert(warning.contact_ready)
	game.player = warning.pos-Vector2(13,23)
	game.swarms.step(game,.01)
	assert(game.health < game.employee.max_health)
	var health: int = game.health
	game.swarms.step(game,.01)
	assert(game.health == health,"Shared contact cooldown remains bounded")
	# A checkpoint retry realizes all four owned slots, including three after the boss.
	game.invulnerable = 1000
	game.reset_observation()
	game.wave_clock = 2
	for x in range(4650,9451,20):
		game.player = Vector2(x,394)
		game.camera_x = clampf(x-320,0,8640)
		if x >= 6570 and not game.skitterling.entered:
			game.skitterling.clear_prior(game)
			game.skitterling.entered = true
		game.skitterling.released = x >= 7530
		schedule.step(game)
	assert(schedule.report().issued == 4 and schedule.report().visible == 4)
	assert(schedule.report().excluded == 5)
	# Expired invisible death remains cannot inflate actual visibility telemetry.
	game.reset_observation()
	game.player = Vector2(4650,394)
	game.camera_x = 4330
	game.wave_clock = 2
	schedule.step(game)
	var expired: Dictionary = game.swarms.actors[0]
	expired.hp = 0
	expired.death = 100
	schedule.step(game)
	assert(not schedule.ledger["pump-overhead"].visible)
	game.queue_free()
	await process_frame
	# Compare ordinary admission with identical scripted progress and no combat/contact interference.
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			for seed_value in [7,42,913]:
				var baseline: Dictionary = await admission(mode,hero,seed_value,false)
				var additive: Dictionary = await admission(mode,hero,seed_value,true)
				assert(baseline == additive,"Additions must not steal ordinary admission slots")
	print("PASS: swarm geometry,warnings,cooldown,grace,freeze,boss isolation and18 paired ordinary-admission runs")
	quit()

func admission(mode: String, hero: int, seed_value: int, enabled: bool) -> Dictionary:
	var game = prepare(mode,hero,seed_value)
	game.swarm_schedule.enabled = enabled
	for tick in range(2400):
		game.player = Vector2(85+tick*3.9,394)
		game.camera_x = clampf(game.player.x-320,0,8640)
		game.skitterling.released = game.player.x >= 7530
		if game.player.x >= 6570 and not game.skitterling.entered:
			game.skitterling.entered = true
			game.skitterling.clear_prior(game)
		game.trial_state.advance(1.0/60)
		game.swarm_schedule.step(game)
		game.issue_event()
		game.step_trial_actors(1.0/60)
		game.step_encounters(1.0/60)
		assert(game.swarm_schedule.additional_population(game) <= 2)
		assert(game.ordinary_population() <= game.run_plan.crowd_cap)
	var result := {"events":game.trial_state.results().events,"later":game.encounter_states,
		"waves":game.wave_spawned,"fallbacks":game.route_fallbacks}
	if enabled: assert(game.swarm_schedule.report().issued == 9)
	game.queue_free()
	await process_frame
	return result
