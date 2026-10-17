extends SceneTree
const Controls = preload("res://scripts/controls_screen.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	assert(Controls.KEYBOARD.get_size() == Vector2(2172, 724))
	assert(Controls.GAMEPAD.get_size() == Vector2(1536, 1024))
	for page in Controls.PRIMARY:
		for action in page:
			assert(ThemeDB.fallback_font.get_string_size(action[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x < 274)
	assert(not Controls.MUSIC_RECT.intersects(Controls.HEALTH_RECT))
	assert(Controls.setting_at_point(Controls.MUSIC_RECT.get_center()) == "music")
	assert(Controls.setting_at_point(Controls.HEALTH_RECT.get_center()) == "health")
	assert(Controls.setting_at_point(Vector2(480, 508)) == "")
	assert(Controls.setting_at_point(Vector2(500, 75)) == "", "Old health hit area must not toggle")
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	title.showing_controls = true
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = Controls.MUSIC_RECT.get_center()
	title.handle_controls(click)
	assert(title.muted and not title.show_enemy_health_bars)
	click.position = Controls.HEALTH_RECT.get_center()
	title.handle_controls(click)
	assert(title.muted and title.show_enemy_health_bars)
	title.muted = false
	title.show_enemy_health_bars = false
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = KEY_H
	title.handle_controls(event)
	assert(title.show_enemy_health_bars)
	event.physical_keycode = KEY_RIGHT
	title.handle_controls(event)
	assert(title.controls_page == 1)
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	pad.button_index = JOY_BUTTON_BACK
	title.handle_controls(pad)
	assert(not title.show_enemy_health_bars)
	pad.button_index = JOY_BUTTON_Y
	title.handle_controls(pad)
	assert(title.muted)
	pad.button_index = JOY_BUTTON_B
	title.handle_controls(pad)
	assert(not title.showing_controls)
	title.queue_free()
	await create_timer(0.3).timeout
	print("PASS: hardware textures, primary label widths, separate settings targets, keyboard and controller navigation/toggles")
	quit()
