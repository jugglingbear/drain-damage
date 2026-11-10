extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("run_checks")

func unlock(game: Node) -> void:
	game.dispenser.cancel()
	game.dispenser.just_finished = false
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.set_paused(false)

func admit(game: Node, id: String) -> Dictionary:
	var selected: Dictionary
	for spec in game.campaign.specs:
		if spec.id == id: selected = spec
		elif game.ledger[spec.id] == "pending": game.ledger[spec.id] = "expired"
	assert(not selected.is_empty())
	game.player = Vector2(selected.trigger+180,394)
	for solid in game.trial_level.plinths:
		if game.player.x+game.PLAYER_SIZE.x > solid.position.x and game.player.x < solid.end.x:
			game.player.y = minf(game.player.y,solid.position.y-game.PLAYER_SIZE.y)
	game.camera_x = maxf(0,game.player.x-320)
	game.next_warning = 0
	game.velocity = Vector2.ZERO
	game.grounded = true
	game.issue_event()
	assert(game.actors.size() == 1,"Fixture must exercise actual campaign admission")
	return game.actors[0]

func check_ownership(game: Node, origin: float) -> void:
	for spec in game.campaign.specs:
		var eligible: bool = game.difficulty in spec.enabled_difficulties and spec.owner_origin >= origin
		assert(game.ledger[spec.id] == ("pending" if eligible else "excluded"))

func run_checks() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			game.seed_override = 12345
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			unlock(game)
			var arrangement: Array = game.campaign.specs.duplicate(true)
			for origin in [85.0,4650.0,7650.0,13800.0]:
				game.reset_game()
				unlock(game)
				var actor := admit(game,"campaign-entry-a-run1")
				actor.hp = 1
				game.corpses.append({"fixture":true})
				game.hostile_shots.append({"fixture":true})
				game.shots.append({"fixture":true})
				game.particles.append({"fixture":true})
				game.lives = 2
				game.checkpoint_active = origin > 85
				game.checkpoint_index = 1 if origin == 13800 else 0 if origin > 85 else -1
				game.post_skitterling_checkpoint = origin == 7650
				game.respawn_point = Vector2(origin,394)
				if origin > 85:
					game.dispenser.checkpoint = game.checkpoint_index
					game.dispenser.consume_stock()
				for repeat in range(2):
					game.respawn_after_death()
					assert(game.lives == 2 and game.health == game.employee.max_health)
					assert(game.player == Vector2(origin,394) and game.run_seed == 12345)
					assert(game.campaign.specs == arrangement)
					assert(game.actors.is_empty() and game.enemies.is_empty() and game.swarms.actors.is_empty())
					assert(game.corpses.is_empty() and game.hostile_shots.is_empty() and game.shots.is_empty())
					assert(game.particles.is_empty())
					check_ownership(game,origin)
					if origin > 85: assert(not game.dispenser.stocked)
					unlock(game)
					game.issue_event()
					assert(game.live_population() == 0,"No checkpoint ambush")
			check_admission(game)
			check_checkpoint_crossing(game)
			for checkpoint in [false,true]: check_lethal_path(game,checkpoint)
			game.seed_override = -1
			game.reset_game()
			assert(game.lives == 3 and game.dispenser.stocked and game.checkpoint_index == -1)
			assert(game.run_seed != 12345 and game.difficulty == mode)
			game.queue_free()
			await process_frame
	print("PASS: campaign ownership at four origins, all modes/heroes, seed retention, stock, lethal retry and crossing")
	quit()

func check_admission(game: Node) -> void:
	game.reset_game()
	unlock(game)
	game.player = Vector2(300,394)
	game.camera_x = 0
	var cap: int = game.crowd_limit()
	# Swarms and actor arrivals share the ordinary budget, not additive allowances.
	for index in range(cap):
		game.swarms.actors.append(game.swarms.spawn(Vector2(600+index*10,200),Rect2(300,80,600,340),index))
	game.issue_event()
	assert(game.actors.is_empty() and game.live_population() == cap)
	game.swarms.actors.pop_back()
	game.issue_event()
	assert(game.actors.size() == 1 and game.live_population() == cap)
	var id: String = game.actors[0].event_id
	game.next_warning = 0
	game.issue_event()
	assert(game.actors.size() == 1 and game.ledger[id] == "warning","Arrival consumes cap immediately")

func check_lethal_path(game: Node, checkpoint: bool) -> void:
	game.reset_game()
	unlock(game)
	var origin := 4650.0 if checkpoint else 85.0
	if checkpoint:
		game.checkpoint_active = true
		game.checkpoint_index = 0
		game.respawn_point = Vector2(origin,394)
		game.dispenser.checkpoint = 0
		game.dispenser.consume_stock()
	var actor := admit(game,"campaign-entry-a-run1")
	actor.active = true
	game.damage_trial_actor(actor,1000)
	assert(game.ledger[actor.event_id] == "killed")
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
	assert(game.run_seed == 12345 and game.corpses.is_empty())
	assert(game.hero_death_audio.voice.playing,"Early Continue must not truncate death flush")
	check_ownership(game,origin)
	if checkpoint: assert(not game.dispenser.stocked)
	unlock(game)
	var restored := admit(game,"campaign-pump-run1" if checkpoint else "campaign-entry-a-run1")
	assert(restored.hp == 24)

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
