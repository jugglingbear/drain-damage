extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for scenario in range(4):
		var hero := scenario % 2
		var aggressive := scenario < 2
		var game = load("res://scripts/opening_trial_game.gd").new()
		game.employee = game.Crew.EMPLOYEES[hero]
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.release_guard = 0
		game.dialogue.awaiting_release = false
		assert(not game.dialogue.active)
		assert(not game.dispenser.active and not game.dispenser.actions_locked)
		assert(game.player_shot_solids().has(Rect2(0,440,6000,100)))
		Input.action_press("shoot")
		game._physics_process(1.0/120)
		assert(game.trial_state.results().shots == 1, "First eligible shot was locked")
		Input.action_release("shoot")
		game.reset_game()
		game.dialogue.release_guard = 0
		game.dialogue.awaiting_release = false
		assert(game.weapon.damage == (12 if hero == 0 else 18))
		assert(game.Data.weapon(game.employee.weapon_id,game.employee.id).damage == (6 if hero == 0 else 24))
		game.invulnerable = 100
		if aggressive:
			Input.action_press("right")
			Input.action_press("shoot")
		for frame in range(2401):
			if aggressive and frame % 60 == 0: Input.action_press("jump")
			if aggressive and frame % 60 == 40: Input.action_release("jump")
			game._physics_process(1.0/120)
			if frame % 120 == 0:
				game.queue_redraw()
				await process_frame
			assert(game.trial_state.results().visible <= 6)
			assert(game.hostile_shots.size() <= 6)
			assert(game.trial_state.results().patterns <= 3)
			assert(game.trial_state.results().shooters <= 3)
			for actor: Dictionary in game.actors:
				if actor.active and actor.role == "floor_emerger": assert(actor.age >= 1.45)
		for action in ["right","shoot","jump"]: Input.action_release(action)
		assert(game.result_shown and game.paused and not game.won)
		assert(game.trial_state.elapsed == 20)
		var report: Dictionary = game.trial_state.results()
		assert(report.issued <= 12 and report.killed <= report.issued)
		assert(report.issued >= (8 if aggressive else 4), "Spawn queue stalled")
		assert(report.issued == report.killed+report.active+report.retired)
		assert(report.issued+report.deferred+report.unavailable == 12)
		print("TRIAL ","aggressive " if aggressive else "idle ",game.employee.id," ",report.issued," issued; ",report.killed," killed; ",report.deferred," deferred; x=",game.player.x)
		for event: Dictionary in report.events:
			if event.state == "pending": print("  deferred ",event.id," ",event.role," ",event.reason)
		game.death_popup_locked = false
		game.resume_or_retry()
		assert(game.lives == 3 and game.trial_state.elapsed == 0 and not game.result_shown)
		game.lives = 2
		game.respawn_after_death()
		assert(game.lives == 2 and game.trial_state.elapsed == 0)
		check_queue_and_shooter(game)
		game.queue_free()
		await process_frame
	await process_frame
	print("PASS: isolated trial profiles, twenty-second results, bounded threats, both heroes, retry/life preservation")
	quit()

func check_queue_and_shooter(game: Node) -> void:
	game.reset_observation()
	game.trial_state.advance(7.0)
	for id in ["opening-01", "opening-02", "opening-03"]:
		assert(game.trial_state.mark_unavailable(id,"fixture: isolate later roles"))
	game.player = Vector2(1200,250)
	game.camera_x = 900
	game.velocity = Vector2(235,0)
	game.issue_event()
	assert(game.actors.size() == 1)
	var shooter: Dictionary = game.actors[0]
	assert(shooter.role == "perched_shooter", "Unsafe rear entry blocked a safe later shooter")
	game.trial_state.advance(0.8)
	assert(game.trial_state.activate(shooter.event_id))
	shooter.active = true
	var fire_times: Array[float] = []
	var previous := 0
	for tick in range(340):
		shooter.age += 0.01
		game.step_shooter(shooter,0.01,true)
		assert(game.trial_state.results().patterns <= 1)
		if game.hostile_shots.size() > previous:
			fire_times.append((tick+1)*0.01)
			previous = game.hostile_shots.size()
	assert(fire_times.size() == 2)
	assert(absf(fire_times[0]-1.45) < 0.03)
	assert(absf(fire_times[1]-fire_times[0]-1.8) < 0.03)
	game.step_shooter(shooter,0.01,false)
	assert(not shooter.winding and game.trial_state.results().patterns == 0)
	assert(game.hostile_shots.size() == 2, "Canceling a shooter must preserve existing bullets")
	game.trial_state.death(shooter.event_id)
	assert(game.trial_state.results().bullets == 2)
	game.reset_observation()
