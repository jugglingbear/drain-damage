extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	for mode in ["keyboard", "controller", "stick", "mouse"]:
		title.start_game()
		var game = title.game
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.dialogue.awaiting_release = false
		await process_frame
		Input.action_press("pause_game")
		game._process(0.01)
		Input.action_release("pause_game")
		await process_frame
		assert(game.paused and game.pause_menu.visible and game.resume_button.has_focus())
		assert(game.title_button.text == "Return to Main Menu")
		var position: Vector2 = game.player
		game._physics_process(1)
		assert(game.player == position)
		for focus_title in [false,true]:
			game.set_paused(true)
			if focus_title: game.title_button.grab_focus()
			Input.action_press("dialogue_skip")
			game._process(0.01)
			assert(not game.paused and title.game == game)
			assert(game.player == position and game.lives == 3)
			assert(game.dialogue.awaiting_release and not game.dispenser.skip_armed)
			await process_frame
			game._process(0.4)
			assert(title.game == game and not game.paused)
			Input.action_release("dialogue_skip")
			await process_frame
		game.set_paused(true)
		Input.action_press("shoot")
		game.resume_button.pressed.emit()
		game._physics_process(0.1)
		assert(not game.paused and not game.pause_menu.visible and game.shots.is_empty())
		assert(game.dialogue.awaiting_release)
		Input.action_release("shoot")
		game.set_paused(true)
		await process_frame
		if mode == "keyboard":
			press_key(KEY_DOWN)
			assert(game.title_button.has_focus())
			press_key(KEY_ENTER)
		elif mode == "controller":
			for button in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_A]:
				var event := InputEventJoypadButton.new()
				event.button_index = button
				event.pressed = true
				root.push_input(event, true)
				event = event.duplicate()
				event.pressed = false
				root.push_input(event, true)
				await process_frame
		elif mode == "stick":
			var motion := InputEventJoypadMotion.new()
			motion.axis = JOY_AXIS_LEFT_Y
			motion.axis_value = 0.8
			root.push_input(motion, true)
			assert(game.title_button.has_focus())
			root.push_input(motion, true)
			assert(game.title_button.has_focus(), "Held stick must not cycle repeatedly")
			var confirm := InputEventJoypadButton.new()
			confirm.button_index = JOY_BUTTON_A
			confirm.pressed = true
			root.push_input(confirm, true)
		else:
			var event := InputEventMouseButton.new()
			event.position = game.title_button.get_global_rect().get_center()
			event.global_position = event.position
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = true
			root.push_input(event, true)
			event = event.duplicate()
			event.pressed = false
			root.push_input(event, true)
		await process_frame
		assert(title.game == null, mode + " must return to the main menu")
		assert(not title.selecting and not title.starting)
		assert(title.music_director.requested == "title")
	title.queue_free()
	await process_frame
	print("PASS: pause freeze, visible buttons, resume guard, keyboard/controller/mouse return and title music")
	quit()
