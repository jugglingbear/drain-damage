extends SceneTree
const Plan = preload("res://scripts/difficulty_plan.gd")
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var variants: Dictionary = {}
	for mode in Plan.IDS:
		for seed_value in range(100):
			var plan := Plan.resolve(mode,seed_value)
			assert(plan == Plan.resolve(mode,seed_value), "Seed must reproduce all choices")
			assert(plan.opening.size() == (12 if mode == "easy" else 15))
			assert(plan.later.size() == (43 if mode == "hard" else 34 if mode == "normal" else 36))
			var previous := 0.0
			for event in plan.opening:
				assert(event.trigger > previous and event.trigger < 3120)
				previous = event.trigger
			var before := 0
			var after := 0
			previous = 0
			for event in plan.later.filter(func(e: Dictionary) -> bool: return not e.id.ends_with("-extra")):
				assert(event.trigger > previous and event.trigger < event.end)
				assert(event.spacing >= 0.65)
				assert(event.owner_origin == (85.0 if event.trigger < 4650 else 4650.0))
				previous = event.trigger
				if event.owner_origin == 85: before += 1
				else: after += 1
			assert(before == 7 and after == (23 if mode == "normal" else 29))
			var tail_id := "normal-route-08" if mode == "normal" else "wave-0-07"
			var first_tail: Dictionary = plan.later.filter(func(e: Dictionary) -> bool: return e.id == tail_id)[0]
			assert(first_tail.trigger == 4700 and first_tail.side == 1)
			var arrangement := plan.duplicate(true)
			arrangement.erase("seed")
			if mode == "easy":
				var reference := Plan.resolve(mode,0)
				reference.erase("seed")
				assert(arrangement == reference, "Easy arrangement must be authored and fixed")
			else: variants[mode+str(arrangement)] = true
	assert(variants.size() > 150, "Normal/Hard must resolve actual variations")
	for hero in [0,1]:
		for mode in Plan.IDS:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			game.seed_override = 12345
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			var arrangement: Dictionary = game.run_plan.duplicate(true)
			game.player.x = 100
			game.issue_event()
			assert(game.actors.size() == 1)
			var first: Dictionary = game.actors[0]
			first.hp = 1
			game.corpses.append({"fixture":true})
			game.hostile_shots.append({"fixture":true})
			game.shots.append({"fixture":true})
			game.particles.append({"fixture":true})
			game.trial_state.add_bullet("old-bullet")
			game.trial_state.begin_pattern("old-pattern",first.event_id)
			game.lives = 2
			game.respawn_after_death()
			assert(game.lives == 2 and game.health == game.employee.max_health)
			assert(game.player == Vector2(85,394) and game.run_plan == arrangement)
			assert(game.actors.is_empty() and game.enemies.is_empty() and game.corpses.is_empty())
			assert(game.hostile_shots.is_empty() and game.shots.is_empty() and game.particles.is_empty())
			assert(game.trial_state.results().bullets == 0 and game.trial_state.results().patterns == 0)
			assert(game.swarms.actors.size() == 1 and game.swarms.actors[0].hp == 24)
			game.player.x = 100
			game.issue_event()
			assert(game.actors.size() == 1 and game.actors[0].hp == 24)
			# Enemy ownership, not its chased position, determines which events return.
			var old_enemy: Dictionary = game.Data.spawn("toilet",Vector2(6000,404))
			old_enemy.encounter_id = "wave-0-00"
			old_enemy.owner_origin = 85.0
			game.enemies.append(old_enemy)
			game.checkpoint_active = true
			game.checkpoint_index = 0
			game.respawn_point = Vector2(4650,394)
			game.dispenser.stocked = false
			for repeat in range(2):
				game.respawn_after_death()
				assert(game.run_plan == arrangement and game.run_seed == 12345)
				assert(game.lives == 2 and not game.dispenser.stocked and game.checkpoint_index == 0)
				assert(game.enemies.is_empty() and game.actors.is_empty() and game.swarms.actors.is_empty())
				var excluded_count: int = game.run_plan.opening.size()
				for event in game.run_plan.later:
					if mode == "normal" and (event.owner_origin < 4650 or (event.trigger >= 5610 and event.trigger < 7530)):
						excluded_count += 1
				assert(game.trial_state.results().unavailable == excluded_count)
				for event in game.run_plan.later:
					assert(game.encounter_states[event.id] == ("pending" if event.enabled and event.owner_origin == 4650 and not (event.trigger >= 5610 and event.trigger < 7530) else "excluded"))
				game.dispenser.cancel()
				game.player = Vector2(4700,394)
				game.camera_x = 4380
				game.step_encounters(1.24)
				assert(game.enemies.is_empty() and game.actors.is_empty(), "No immediate checkpoint ambush")
				for quiet_x in [5610.0,6000.0,6570.0,7529.0]:
					game.player = Vector2(quiet_x,394)
					game.step_encounters(0.1)
					assert(game.actors.is_empty() and game.enemies.is_empty(), "Authored approach/room stays empty")
				# Isolate ordinary post-boss admission; encounter lifecycle is tested separately.
				game.skitterling.released = true
				game.player = Vector2(7900,394)
				game.camera_x = 7580
				game.step_encounters(0.1)
				assert(game.crowd_population() == 1)
				var admitted: Dictionary = game.actors[0] if mode == "normal" else game.enemies[0]
				assert(admitted.hp == 24 and admitted.owner_origin == 4650)
				assert((admitted.feet.x if mode == "normal" else admitted.pos.x) >= 4650)
				admitted.hp = 1
			check_admission(game)
			check_checkpoint_crossing(game)
			for checkpoint in [false,true]: check_lethal_path(game,checkpoint)
			game.seed_override = -1
			game.reset_game()
			assert(game.lives == 3 and game.dispenser.stocked and game.checkpoint_index == -1)
			assert(game.run_seed != 12345 and game.difficulty == mode)
			game.queue_free()
			await process_frame
	print("PASS:300resolved plans,3modes,both heroes,origin ownership,full reset,seed retention,stock/lives and new runs")
	quit()

func check_admission(game: Node) -> void:
	game.reset_game()
	game.dispenser.cancel()
	game.swarms.actors.clear()
	game.player = Vector2(100,394)
	game.camera_x = 0
	var cap: int = game.run_plan.crowd_cap
	for index in range(cap): game.enemies.append(game.Data.spawn("toilet",Vector2(700+index*50,404)))
	game.issue_event()
	assert(game.actors.is_empty(), "Actual opening admission must enforce mode cap")
	game.enemies.pop_back()
	game.issue_event()
	assert(game.actors.size() == 1 and game.crowd_population() == cap)
	game.reset_game()
	game.dispenser.cancel()
	game.swarms.actors.clear()
	game.player = Vector2(1700,394)
	game.camera_x = 1380
	for event in game.trial_state.results().events:
		if event.role != "aggressive_flyer": game.trial_state.mark_unavailable(event.id,"fixture")
	for index in range(mini(cap,6)-1):
		game.enemies.append(game.Data.spawn("toilet",Vector2(1800+index*50,404)))
	game.issue_event()
	assert(game.actors.size() == 1 and game.actors[0].role == "aggressive_flyer", "Normal must admit Widow")
	assert(not game.actors[0].active and game.crowd_population() == mini(cap,6))
	game.next_opening_spawn = 0
	game.issue_event()
	assert(game.actors.size() == 1, "Warning Widow consumes population and unique-Widow slot")
	game.reset_game()
	game.dispenser.cancel()
	game.swarms.actors.clear()
	# Isolate ordinary post-boss admission; encounter lifecycle is tested separately.
	game.skitterling.released = true
	game.player = Vector2(7900,394)
	game.camera_x = 7580
	for index in range(cap): game.enemies.append(game.Data.spawn("toilet",Vector2(8100+index*40,404)))
	game.step_encounters(2)
	assert(game.enemies.size() == cap and game.wave_spawned == [0,0,0,0])
	game.enemies.pop_back()
	game.step_encounters(0)
	if game.difficulty == "normal":
		assert(game.crowd_population() == cap-1 and game.wave_spawned == [0,0,0,0])
		game.enemies.clear()
		game.step_encounters(0)
		assert(game.crowd_population() == 1 and game.wave_spawned.reduce(func(total: int, count: int) -> int: return total+count,0) == 1)
	else:
		assert(game.crowd_population() == cap and game.wave_spawned.reduce(func(total: int, count: int) -> int: return total+count,0) == 1)

func check_lethal_path(game: Node, checkpoint: bool) -> void:
	game.reset_game()
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	var saved_plan: Dictionary = game.run_plan.duplicate(true)
	if checkpoint:
		game.checkpoint_active = true
		game.checkpoint_index = 0
		game.respawn_point = Vector2(4650,394)
		game.dispenser.stocked = false
		# Isolate ordinary post-boss admission; encounter lifecycle is tested separately.
		game.skitterling.released = true
		game.player = Vector2(7900,394)
		game.camera_x = 7580
		game.step_encounters(2)
		if game.difficulty == "normal":
			assert(game.actors.size() == 1)
			var actor: Dictionary = game.actors[0]
			game.trial_state.advance(2)
			assert(game.trial_state.activate(actor.event_id))
			actor.active = true
			game.damage_trial_actor(actor,1000)
		else:
			assert(game.enemies.size() == 1)
			game.damage_enemy(0,1000,Vector2.ZERO)
		assert(not game.corpses.is_empty())
	else:
		game.player.x = 100
		game.issue_event()
		var actor: Dictionary = game.actors[0]
		game.trial_state.advance(0.7)
		assert(game.trial_state.activate(actor.event_id))
		actor.active = true
		actor.hp = 0
		game.finish_trial_defeat(actor)
		assert(game.trial_state.results().killed == 1)
	game.player = game.respawn_point
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	assert(game.lives == 2)
	for tick in range(300):
		game.step_death(1.0/120)
		if game.life_state == "death_popup": break
	assert(game.life_state == "death_popup")
	game.update_death_popup_guard(0.4)
	game.resume_or_retry()
	assert(game.life_state == "alive" and game.lives == 2 and game.health == game.employee.max_health)
	assert(game.run_plan == saved_plan and game.corpses.is_empty())
	assert(game.hero_death_audio.voice.playing, "Early Continue must not truncate death flush")
	if checkpoint:
		assert(not game.dispenser.stocked)
		assert(game.encounter_states["normal-route-09" if game.difficulty == "normal" else "wave-1-00"] == "pending")
		game.dispenser.cancel()
		# Isolate ordinary post-boss admission; encounter lifecycle is tested separately.
		game.skitterling.released = true
		game.player = Vector2(7900,394)
		game.camera_x = 7580
		game.step_encounters(2)
		assert(game.crowd_population() == 1)
		assert((game.actors[0] if game.difficulty == "normal" else game.enemies[0]).hp == 24)
	else:
		assert(game.trial_state.results().killed == 0)
		game.player.x = 100
		game.issue_event()
		assert(game.actors.size() == 1 and game.actors[0].hp == 24)

func check_checkpoint_crossing(game: Node) -> void:
	game.reset_game()
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.player = Vector2(4649,394)
	game.velocity = Vector2(game.employee.move_speed,0)
	game.grounded = true
	game.health = 1
	game.invulnerable = 0
	game.enemies.append(game.Data.spawn("toilet",Vector2(4651,404)))
	Input.action_press("right")
	game._physics_process(0.02)
	Input.action_release("right")
	assert(game.life_state == "dying" and game.checkpoint_index == -1)
	assert(game.respawn_point.x == 85, "Lethal crossing cannot save checkpoint after death")
	game.reset_game()
	game.dispenser.cancel()
	game.dialogue.release_guard = 0
	game.player = Vector2(4649,394)
	game._physics_process(0)
	assert(game.checkpoint_index == -1)
	game.player.x = 4650
	game._physics_process(0)
	assert(game.checkpoint_index == 0)
