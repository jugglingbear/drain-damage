extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	game.boss_intro.seen = {"cockroach-swarm": true, "clogfather": true}
	game.set_process(false)
	game.set_physics_process(false)
	var dialogue = game.dialogue
	var conversations: Array = [game.Story.OPENING, game.Story.COMPLETION_TONY,
		game.Story.COMPLETION_SEAN, game.Story.DEATH_LINES]
	var originals := JSON.stringify(conversations)
	for employee in game.Crew.EMPLOYEES:
		game.employee = employee
		for mode in ["hard", "normal", "hard", "easy"]:
			game.difficulty = mode
			game.reset_game()
			for conversation in conversations:
				dialogue.start(conversation)
				for index in range(conversation.size()):
					var entry: Dictionary = conversation[index]
					assert(dialogue.line_index == index)
					var expected: String = entry.text
					if mode == "hard" and entry.who in ["tony", "sean"]:
						expected = expected.to_upper()
					assert(dialogue.current_text() == expected)
					var paragraph := TextParagraph.new()
					paragraph.width = dialogue.TEXT_WIDTH
					paragraph.add_string(expected, ThemeDB.fallback_font, dialogue.fitted_font_size(expected))
					assert(paragraph.get_size().y <= dialogue.TEXT_HEIGHT, "Dialogue must fit above skip controls")
					dialogue.tick(0.01, false)
					assert(dialogue.revealed > 0 and dialogue.revealed < expected.length())
					dialogue.advance()
					assert(dialogue.revealed == expected.length() and dialogue.line_index == index)
					dialogue.advance()
				assert(not dialogue.active and dialogue.awaiting_release)
				dialogue.start(conversation)
				dialogue.release_guard = 0
				# Let the prior release cross an input frame before asserting a fresh press.
				await create_timer(0.02).timeout
				Input.action_press("dialogue_skip")
				dialogue.tick(0.01, false)
				assert(not dialogue.active and dialogue.awaiting_release)
				Input.action_release("dialogue_skip")
				await process_frame
	assert(JSON.stringify(conversations) == originals, "Authored dialogue must remain unchanged")
	game.queue_free()
	await process_frame
	print("PASS: Hard dialogue, both heroes, radio/endings, BJ, mode switching, wrapping, reveal and skip")
	quit()
