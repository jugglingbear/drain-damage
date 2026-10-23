extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const SAFE_SPAWN := Vector2(7650,394)
const STEP := 1.0/120

func _initialize() -> void: call_deferred("run_checks")

func unlock(game: Node) -> void:
	game.set_paused(false)
	game.dispenser.cancel()
	game.dispenser.actions_locked = false
	game.dispenser.just_finished = false
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.invulnerable = 1000

func defeat(game: Node) -> void:
	game.player = Vector2(6690,394)
	var room = game.skitterling
	for tick in range(120*45):
		room.advance(game,STEP)
		if not room.encounter.damageable(): continue
		if room.encounter.phase == "alligator":
			game.health = 2
			var lives: int = game.lives
			var stock: Dictionary = game.dispenser.spent_checkpoints.duplicate(true)
			room.damage(game,9999)
			assert(room.encounter.hp == 0 and room.encounter.state == "terminal_death")
			assert(not room.encounter.exit_open,"Save before the death animation finishes")
			assert(game.post_skitterling_checkpoint and game.checkpoint_active)
			assert(game.respawn_point == SAFE_SPAWN and game.checkpoint_index == 0)
			assert(game.health == 2 and game.lives == lives,"Victory grants no heal or life")
			assert(not game.dispenser.active and game.dispenser.spent_checkpoints == stock)
			game.save_skitterling_checkpoint()
			assert(game.health == 2 and game.lives == lives and game.dispenser.spent_checkpoints == stock)
			return
		room.damage(game,9999)
		assert(not game.post_skitterling_checkpoint,"Rat defeat is not final victory")
	assert(false,"Both forms must reach terminal defeat")

func die_and_retry(game: Node) -> void:
	unlock(game)
	game.health = 1
	game.invulnerable = 0
	var lives: int = game.lives
	var stock: Dictionary = game.dispenser.spent_checkpoints.duplicate(true)
	game.hurt_player()
	assert(game.life_state == "dying" and game.lives == lives-1)
	for tick in range(120*4):
		game.step_death(STEP)
		if game.life_state == "death_popup": break
	assert(game.life_state == "death_popup",str([game.life_state,game.player,game.grounded,
		game.death_time,game.death_ground_time,game.paused]))
	game.respawn_after_death()
	assert(game.life_state == "alive" and game.player == SAFE_SPAWN)
	assert(game.lives == lives-1 and game.health == game.employee.max_health)
	assert(game.post_skitterling_checkpoint and game.respawn_origin == SAFE_SPAWN.x)
	assert(not game.dispenser.active and game.dispenser.spent_checkpoints == stock,
		"Virtual checkpoint must not consume either dispenser or play a clone sequence")
	assert(game.skitterling.encounter.hp == 0 and game.skitterling.encounter.exit_open)
	assert(game.skitterling.released and not game.skitterling.locked())
	assert(game.skitterling.encounter.hazards.is_empty() and game.hostile_shots.is_empty())
	assert(not game.boss_hud.active)
	for solid: Rect2 in game.actor_solids():
		assert(not Rect2(game.player,game.PLAYER_SIZE).grow(-0.01).intersects(solid),"Safe exit spawn")
	for event in game.run_plan.opening:
		for report in game.trial_state.results().events:
			if report.id == event.id: assert(report.state == "unavailable")
	var pending_after := 0
	for event in game.run_plan.later:
		if event.trigger >= 7650 and event.trigger < 9450 and event.enabled:
			assert(event.owner_origin >= 7650 and game.encounter_states[event.id] == "pending",
				"Post-boss encounters must survive checkpoint ownership filtering")
			pending_after += 1
	assert(pending_after > 0)

func check_later_checkpoint(game: Node) -> void:
	unlock(game)
	game.player = Vector2(13800,394)
	game.health = 1
	game.activate_checkpoint(1)
	assert(game.checkpoint_index == 1 and game.respawn_point == Vector2(13800,394))
	assert(game.dispenser.active,"Physical checkpoint retains normal dispenser presentation")
	game.save_skitterling_checkpoint()
	assert(game.respawn_point == Vector2(13800,394),"Old boss completion cannot overwrite later checkpoint")
	unlock(game)
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	assert(game.life_state == "dying")
	game.respawn_after_death()
	assert(game.player == Vector2(13800,394) and game.checkpoint_index == 1)
	assert(game.skitterling.encounter.hp == 0 and game.skitterling.released)

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
			for location in ["terminal","exit","farther"]:
				game.reset_game()
				unlock(game)
				assert(not game.post_skitterling_checkpoint and game.respawn_point.x == 85)
				game.save_skitterling_checkpoint()
				assert(not game.post_skitterling_checkpoint and game.respawn_point.x == 85,
					"Unfinished encounter cannot save a checkpoint")
				game.checkpoint_active = true
				game.checkpoint_index = 0
				game.respawn_point = Vector2(4650,394)
				defeat(game)
				if location != "terminal":
					for tick in range(120*10):
						game.skitterling.advance(game,STEP)
						if game.skitterling.encounter.exit_open: break
					assert(game.skitterling.encounter.exit_open)
					game.player.x = 7500 if location == "exit" else 8500
					game.skitterling.advance(game,STEP)
				die_and_retry(game)
				if location == "farther":
					unlock(game)
					game.player = Vector2(7900,394)
					game.camera_x = 7580
					game.step_encounters(2)
					assert(game.ordinary_population() > 0,"Post-boss route still admits enemies")
					die_and_retry(game)
				else:
					check_later_checkpoint(game)
			game.reset_game()
			assert(not game.post_skitterling_checkpoint and not game.skitterling.entered)
			assert(game.skitterling.encounter.hp == game.skitterling.encounter.MAX_HP)
			assert(game.respawn_point.x == 85 and game.checkpoint_index == -1)
			game.queue_free()
			await process_frame
	print("PASS: Skitterling terminal checkpoint all modes/heroes, death animation/exit/route retries, ownership, no victory grant and later checkpoint")
	quit()
