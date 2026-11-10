extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(1))
	for hero in ["tony","sean"]:
		var game = load("res://scripts/integrated_first_call.gd").new()
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		var dialogue = game.dialogue
		dialogue.start(game.Story.completion(hero))
		dialogue.tick(0.3,false)
		var line_count: int = game.Story.completion(hero).size()
		assert(line_count > 0 and dialogue.lines.size() == line_count)
		for index in range(line_count):
			assert(dialogue.active and dialogue.line_index == index)
			assert(dialogue.lines[index].radio == (dialogue.lines[index].who != hero and dialogue.lines[index].who != "bj"))
			dialogue.revealed = 0
			Input.action_press("dialogue_next")
			dialogue.tick(0.016,false)
			assert(dialogue.line_index == index and dialogue.revealed == dialogue.current_text().length())
			for held_frame in range(5):
				await process_frame
				dialogue.tick(0.016,false)
				assert(dialogue.line_index == index,"Held advance must not skip a radio response")
			Input.action_release("dialogue_next")
			await process_frame
			Input.action_press("dialogue_next")
			dialogue.tick(0.016,false)
			Input.action_release("dialogue_next")
			await process_frame
			assert(dialogue.line_index == index+1)
		assert(not dialogue.active and dialogue.awaiting_release)
		game.queue_free()
		await process_frame
	print("PASS: both canonical endings, radio replies, typewriter, held advance and final release guard")
	quit()
