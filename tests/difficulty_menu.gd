extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func key(code: Key, pressed := true) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	return event

func pad(button: JoyButton, pressed := true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event

func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	var screen = title.DifficultyScreen
	assert(title.difficulty_copy.options[2] == {"id":"hard","label":"The Computer is Cheating!!"})
	assert(title.difficulty_copy.options[0].label == "Easy" and title.difficulty_copy.options[1].label == "Normal")
	var text: String = title.difficulty_copy.options[2].label
	var font_size: int = screen.label_size(2)
	var size := ThemeDB.fallback_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
	var origin: Vector2 = screen.label_origin(2,text)
	var text_bounds := Rect2(origin-Vector2(0,ThemeDB.fallback_font.get_ascent(font_size)),size)
	assert(screen.label_rect(2).encloses(text_bounds), "Exact long label must fit within the original plate")
	assert(screen.row_rect(0) == Rect2(303,150,355,46) and screen.row_rect(1) == Rect2(303,250,355,46))
	for index in range(3):
		assert(screen.row_rect(index) == Rect2(303,150+100*index,355,46))
		assert(screen.art_rect(index) == Rect2(293,142+100*index,375,64))
	assert(not screen.row_rect(1).intersects(screen.row_rect(2)))
	assert(not screen.row_rect(2).intersects(screen.BACK) and not screen.row_rect(2).intersects(screen.CONFIRM))
	for scale in [1.0,1.5,1600.0/960,2.0]:
		var scaled_text := Rect2(text_bounds.position*scale,text_bounds.size*scale)
		var scaled_plate := Rect2(screen.row_rect(2).position*scale,screen.row_rect(2).size*scale)
		assert(scaled_plate.encloses(scaled_text))
	assert(screen.hard_tint(false,false) != screen.hard_tint(false,true))
	assert(screen.hard_tint(true,true) == screen.hard_tint(true,false))
	title.choosing_difficulty = true
	title.difficulty_index = 1
	var hover := InputEventMouseMotion.new()
	hover.position = screen.row_rect(2).get_center()
	title._unhandled_input(hover)
	assert(title.difficulty_hover == 2 and title.difficulty_index == 1 and title.game == null)
	hover.position = Vector2.ZERO
	title._unhandled_input(hover)
	assert(title.difficulty_hover == -1)
	for selected_row in [1,2]:
		for hovered_row in [-1,2]:
			title.difficulty_index = selected_row
			title.difficulty_hover = hovered_row
			title.queue_redraw()
			await process_frame
	title.choosing_difficulty = false
	for hero in [0,1]:
		for mode in range(3):
			title.request_start()
			assert(title.selecting and title.difficulty_index == 1)
			title.selected = hero
			title.selection_guard = 0
			title._unhandled_input(key(KEY_ENTER))
			assert(not title.choosing_difficulty, "Held confirm cannot pass hero selection")
			title._unhandled_input(key(KEY_ENTER,false))
			title._unhandled_input(key(KEY_ENTER))
			assert(title.choosing_difficulty and title.game == null)
			title.selection_guard = 0
			title._unhandled_input(pad(JOY_BUTTON_A))
			assert(title.game == null and not title.starting, "Held confirm cannot skip difficulty")
			title._unhandled_input(pad(JOY_BUTTON_A,false))
			title._unhandled_input(pad(JOY_BUTTON_B))
			assert(not title.choosing_difficulty and title.selecting and title.selected == hero)
			title.selection_guard = 0
			title.request_start()
			title._unhandled_input(key(KEY_ENTER,false))
			title.selection_guard = 0
			title._unhandled_input(key(KEY_DOWN))
			assert(title.difficulty_index == 2)
			title._unhandled_input(pad(JOY_BUTTON_DPAD_UP))
			title._unhandled_input(pad(JOY_BUTTON_DPAD_UP,false))
			assert(title.difficulty_index == 1)
			var stick := InputEventJoypadMotion.new()
			stick.axis = JOY_AXIS_LEFT_Y
			stick.axis_value = -0.8
			title._unhandled_input(stick)
			title._unhandled_input(stick)
			assert(title.difficulty_index == 0, "Stick is latched")
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			click.position = title.DifficultyScreen.row_rect(mode).get_center()
			title._unhandled_input(click)
			assert(title.difficulty_index == mode)
			click.pressed = false
			title._unhandled_input(click)
			click.pressed = true
			click.position = title.DifficultyScreen.CONFIRM.get_center()
			title._unhandled_input(click)
			await process_frame
			assert(title.game != null)
			title.game.set_process(false)
			title.game.set_physics_process(false)
			assert(title.game.employee.id == ["tony","sean"][hero])
			assert(title.game.difficulty == ["easy","normal","hard"][mode])
			assert(title.game.dialogue.active and title.game.dialogue.release_guard > 0)
			title.return_to_title()
			await process_frame
	title.queue_free()
	await process_frame
	print("PASS: exact angry Hard label,equal plate/hit dimensions,label fit/scales,hover/focus,both heroes/3modes, keyboard/pad/stick/mouse,Back preservation,release guards and intro")
	quit()
