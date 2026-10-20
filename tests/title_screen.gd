extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func key(code: Key, pressed := true) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	return event

func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	assert(ProjectSettings.get_setting("application/config/name") == "Drain Damage")
	for index in range(title.MENU_LABELS.size()):
		assert(title.menu_at_point(title.menu_rect(index).get_center()) == index)
		assert(title.menu_at_point(title.menu_rect(index).position + Vector2(20, 50)) == -1,
			"Decorative drips below the plate must not activate menu items")
	assert(title.menu_at_point(Vector2(40, 320)) == -1)
	assert(title.game == null)
	assert(title.MENU_LABELS == ["START", "CONTROLS", "QUIT"])
	assert(title.selected == 0, "Tony is the launch default")
	assert(title.music.stream is AudioStreamOggVorbis)
	assert(not title.music.stream.loop and title.music.stream.get_length() > 150.0)
	assert(title.music.playing)
	title._unhandled_input(key(KEY_DOWN))
	title._unhandled_input(key(KEY_ENTER))
	assert(title.showing_controls and title.game == null)
	title._unhandled_input(key(KEY_RIGHT))
	assert(title.controls_page == 1)
	title._unhandled_input(key(KEY_ESCAPE))
	assert(not title.showing_controls)
	title._unhandled_input(key(KEY_UP))
	title.toggle_sound()
	assert(title.muted and title.music.volume_db < -70)
	title._unhandled_input(key(KEY_ENTER))
	assert(title.selecting and title.game == null, "Start must lead to crew selection")
	assert(title.selected == 0)
	assert(not title.CLOCK_IN_RECT.intersects(Rect2(180, 110, 600, 400)))
	var photo_bounds: Rect2 = title.EmployeePhoto.bounds()
	assert(photo_bounds.position.y > 219 and photo_bounds.end.x < 430,
		"Rotated photo must clear employee heading and biography")
	assert(not photo_bounds.intersects(title.CLOCK_IN_RECT))
	title._unhandled_input(key(KEY_ENTER))
	assert(not title.starting, "Opening press cannot skip selection")
	title.selected = 1
	title._unhandled_input(key(KEY_ESCAPE))
	assert(not title.selecting, "Back returns to title")
	for index in range(2):
		title._unhandled_input(key(KEY_ENTER,false))
		title._unhandled_input(key(KEY_ENTER))
		assert(title.selected == 0, "Reopening selection resets to Tony")
		title.selection_guard = 0
		if index == 0:
			title._unhandled_input(key(KEY_LEFT))
		else:
			var pad := InputEventJoypadButton.new()
			pad.button_index = JOY_BUTTON_DPAD_RIGHT
			pad.pressed = true
			title._unhandled_input(pad)
		assert(title.selected == index)
		title._unhandled_input(key(KEY_ENTER,false))
		title._unhandled_input(key(KEY_ENTER))
		assert(title.choosing_difficulty and title.game == null)
		title.selection_guard = 0
		title._unhandled_input(key(KEY_ENTER,false))
		title._unhandled_input(key(KEY_ENTER))
		await process_frame
		assert(title.music_director.requested == "level", "Gameplay requests the level track")
		assert(title.game.employee.id == ["tony", "sean"][index])
		assert(title.game.health == [4, 5][index])
		assert(title.game.employee.move_speed == [270.0, 235.0][index])
		title.game.health = 1
		title.game.activate_checkpoint()
		assert(title.game.health == 1, "Checkpoint cannot interrupt opening dialogue")
		assert(title.game.dialogue.active and title.game.dialogue.lines.size() == 7)
		title.game.dialogue.finish()
		title.game.activate_checkpoint()
		assert(title.game.health == [4,5][index] and title.game.dispenser.active)
		var previous = title.game
		title._unhandled_input(key(KEY_ENTER))
		assert(title.game == previous)
		title.game.reset_game()
		assert(title.game.employee.id == ["tony", "sean"][index], "Restart preserves employee")
		title.game.paused = true
		Input.action_press("return_title")
		title.game._process(0.016)
		Input.action_release("return_title")
		await process_frame
		assert(title.game == null and not title.selecting and title.muted)
	for button in [JOY_BUTTON_A, JOY_BUTTON_START]:
		var pad := InputEventJoypadButton.new()
		pad.button_index = button
		pad.pressed = false
		title._unhandled_input(pad)
		pad.pressed = true
		title._unhandled_input(pad)
		assert(title.selecting)
		title.selection_guard = 0
		title._unhandled_input(pad)
		assert(not title.choosing_difficulty,"Held confirm cannot skip selection")
		pad.pressed = false
		title._unhandled_input(pad)
		pad.pressed = true
		title._unhandled_input(pad)
		assert(title.choosing_difficulty)
		title.selection_guard = 0
		pad.pressed = false
		title._unhandled_input(pad)
		pad.pressed = true
		title._unhandled_input(pad)
		await process_frame
		assert(title.game != null)
		title.return_to_title()
		await process_frame
	title.toggle_sound()
	assert(title.music.playing and not title.muted)
	title.queue_free()
	await create_timer(0.3).timeout
	print("PASS: guarded selection, both employees, difficulty confirmation, restart identity, return, controller start, mute")
	quit()
