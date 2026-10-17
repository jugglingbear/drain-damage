extends SceneTree
const Story = preload("res://scripts/story_dialogue.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	for selected in range(2):
		for skip in [false, true]:
			title.selected = selected
			title.start_game()
			var game = title.game
			game.set_process(false)
			game.set_physics_process(false)
			game.dialogue.finish()
			var position: Vector2 = game.player
			game.complete_job()
			assert(game.won and game.dialogue.active)
			assert(game.dialogue.lines == Story.completion(game.employee.id))
			assert(game.dialogue.lines.size() == 9)
			for line in game.dialogue.lines:
				assert(line.radio == (line.who != game.employee.id and line.who != "bj"))
			game.dialogue.advance()
			game.complete_job()
			assert(game.dialogue.revealed > 0, "Repeated completion cannot restart the scene")
			if skip:
				Input.action_press("dialogue_skip")
				game.dialogue.tick(0.5, false)
				Input.action_release("dialogue_skip")
			else:
				while game.dialogue.active:
					game.dialogue.advance()
			assert(game.won and game.player == position)
			assert(game.dialogue.awaiting_release and game.dialogue.release_guard > 0)
			game.reset_game()
			assert(not game.won and not game.dialogue.active)
			title.return_to_title()
			await process_frame
	title.queue_free()
	await create_timer(0.3).timeout
	print("PASS: both completion routes, radio support, skip/advance, replay guard and retry/title")
	quit()
