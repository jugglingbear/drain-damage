extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	var pool: Array = title.Story.DEATH_LINES
	assert(pool.size() == 12)
	var previous := ""
	for index in range(100):
		var entry: Dictionary = title.Story.choose_death_line()
		assert(entry in pool and entry.text != previous)
		previous = entry.text
	for entry: Dictionary in pool:
		assert(title.Portraits.expression("bj", entry.emotion) != null)
		var paragraph := TextParagraph.new()
		paragraph.width = 425
		paragraph.add_string(entry.text, ThemeDB.fallback_font, 21)
		assert(paragraph.get_size().y <= 130, "Full quip must fit without truncation")
	for hero in range(2):
		title.selected = hero
		title.start_game()
		var game = title.game
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.finish()
		game.activate_checkpoint(0)
		game.dispenser.tick(game,5.6)
		game.health = 1
		game.invulnerable = 0
		Input.action_press("shoot")
		game.hurt_player()
		var chosen: Dictionary = game.death_message.duplicate()
		for frame in range(180): game.step_death(1.0 / 60)
		assert(game.life_state == "death_popup" and game.lives == 2 and game.paused)
		var position: Vector2 = game.player
		var elapsed: float = game.elapsed
		game._physics_process(5)
		game._process(1)
		assert(game.player == position and game.elapsed == elapsed and game.death_message == chosen)
		assert(game.death_popup_locked and game.resume_button.disabled and game.title_button.disabled)
		game.resume_button.pressed.emit()
		game.request_title()
		assert(title.game == game and game.life_state == "death_popup")
		Input.action_release("shoot")
		game.update_death_popup_guard(0.2)
		assert(game.death_popup_locked)
		game.update_death_popup_guard(0.2)
		assert(not game.death_popup_locked and game.resume_button.has_focus())
		if hero == 0:
			key(KEY_ENTER)
			assert(game.life_state == "alive" and game.player == game.respawn_point)
			assert(game.lives == 2 and game.health == game.employee.max_health and not game.dialogue.active)
			assert(game.dialogue.awaiting_release and game.shots.is_empty())
			title.return_to_title()
		else:
			for button in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_A]:
				var event := InputEventJoypadButton.new()
				event.button_index = button
				event.pressed = true
				root.push_input(event, true)
				event = event.duplicate()
				event.pressed = false
				root.push_input(event, true)
			await process_frame
			assert(title.game == null and title.music_director.requested == "title")
		await process_frame
	title.queue_free()
	await process_frame
	print("PASS: twelve approved quips, emotional portraits, full text fit, stable/no-repeat selection, freeze, guards and both hero menu routes")
	quit()
