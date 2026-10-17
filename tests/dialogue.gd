extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	assert(not game.dialogue.active, "Basement starts without a tutorial")
	var conversation: Array[Dictionary] = [{"who": "TONY", "emotion": "neutral", "text": "A story conversation."}]
	game.dialogue.start(conversation)
	var position: Vector2 = game.player
	game._physics_process(0.1)
	assert(game.player == position, "Dialogue must freeze the world")
	game.dialogue.revealed = 0.0
	game.dialogue.advance()
	assert(game.dialogue.line_index == 0 and game.dialogue.revealed > 0, "First press reveals the line")
	game.dialogue.advance()
	assert(not game.dialogue.active, "Second press dismisses the brief")
	game.dialogue.finish()
	assert(not game.dialogue.active and game.dialogue.release_guard > 0, "Skip guards against input spillover")
	game.dialogue.tick(0.3, false)
	game._physics_process(1.0 / 60.0)
	assert(game.grounded, "Gameplay resumes after dialogue")
	game.enemies.clear()
	game.complete_job()
	assert(game.won and game.dialogue.active, "Victory starts the outro")
	for index in range(game.dialogue.lines.size()):
		game.dialogue.advance()
		game.dialogue.advance()
	assert(not game.dialogue.active, "Outro must finish")
	game.reset_game()
	assert(not game.dialogue.active and not game.won, "Restart returns directly to play")
	game.dialogue.tick(0.1, true)
	assert(not game.dialogue.visible, "Pause hides dialogue so pause controls remain readable")
	print("PASS: intro, freeze, reveal, advance, skip, input guard, resume, outro, restart, pause")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
