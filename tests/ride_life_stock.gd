extends SceneTree
## Run with -- --level=2-course --difficulty=normal --screenshot-mode=1 and optionally --invincible=1.

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var title = load("res://main.tscn").instantiate()
	root.add_child(title)
	while title.game == null: await process_frame
	var game = title.game
	while not game.startup_complete: await process_frame
	var flush = game.flush
	var seed_before: int = game.run_seed
	print("ENTRY ",flush.state," ",game.lives)
	assert(flush.state == "ride" and game.has_node("ScreenshotFreeze"))
	game.set_process(false)
	game.set_physics_process(false)
	var immune := "--invincible=1" in OS.get_cmdline_user_args()
	for stock in [3,2,1]:
		assert(game.lives == stock and game.life_state == "alive")
		game.health = 1
		game.invulnerable = 0
		for frame in 1800:
			flush.ride.tick(game,1.0/60,Vector2.ZERO,false)
			if flush.ride.events.has("hit"): break
		assert(game.lives == (stock if immune else stock-1))
		if immune:
			assert(game.health == 1)
			for obstacle in flush.ride.course.obstacles:
				if obstacle.kind == "gap":
					flush.ride.encounter_scroll = float(obstacle.x)-300
					flush.ride.position.y = obstacle.y
					flush.ride.tick(game,1.0/60,Vector2.ZERO,false)
					if game.life_state == "dying": break
			assert(flush.ride.events.has("fall"))
		assert(game.life_state == "dying")
		var previous: int = flush.audio.starts.get("button_gag",0)
		game.step_death(0.64)
		assert(flush.audio.starts.get("button_gag",0) == previous)
		game.step_death(0.1)
		game.step_death(2)
		assert(flush.audio.starts.get("button_gag",0) == previous+int(not immune and not AudioServer.is_bus_mute(0)))
		print("RESULT ",stock," ",game.lives," ",game.life_state)
		assert(game.life_state == ("game_over" if stock == 1 else "death_popup"))
		game.update_death_popup_guard(1.0)
		game.resume_or_retry()
		if stock > 1:
			assert(flush.state == "ride" and flush.ride.clock == 0 and game.run_seed == seed_before)
	while not title.card_ready: await process_frame
	var start := InputEventJoypadButton.new()
	start.pressed = true
	title._unhandled_input(start)
	game = title.game
	assert(game.lives == 3 and game.life_state == "alive" and not game.flush.active and game.dialogue.active)
	print("LAUNCH_LIVES_PASS")
	game.free()
	quit()
