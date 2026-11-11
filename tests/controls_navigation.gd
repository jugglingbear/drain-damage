extends SceneTree
func _initialize() -> void: call_deferred("run_checks")
func press(title: Node, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	title._unhandled_input(event)
	event.pressed = false
	title._unhandled_input(event)
func run_checks() -> void:
	create_timer(15).timeout.connect(func() -> void: quit(1))
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	title.showing_controls = true
	press(title,JOY_BUTTON_DPAD_RIGHT)
	assert(title.controls_focus == 1 and title.controls_page == 1)
	var sounds: int = title.navigation_plays
	press(title,JOY_BUTTON_DPAD_RIGHT)
	assert(title.controls_focus == 2 and title.controls_page == 1)
	assert(title.navigation_plays == sounds+1,"Back focus plays navigation sound")
	press(title,JOY_BUTTON_DPAD_LEFT)
	assert(title.controls_focus == 1 and title.controls_page == 1)
	press(title,JOY_BUTTON_DPAD_RIGHT)
	press(title,JOY_BUTTON_A)
	assert(not title.showing_controls,"A on Back exits")
	title.showing_controls = true
	press(title,JOY_BUTTON_START)
	assert(not title.showing_controls,"Menu on Back exits")
	title.showing_controls = true
	press(title,JOY_BUTTON_DPAD_RIGHT)
	assert(title.controls_focus == 0 and title.controls_page == 0,"Right wraps to Keyboard")
	press(title,JOY_BUTTON_DPAD_LEFT)
	assert(title.controls_focus == 2 and title.controls_page == 0,"Left wraps to Back, retains content")
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_ENTER
	title._unhandled_input(key)
	assert(not title.showing_controls,"Keyboard confirmation on Back exits")
	title.showing_controls = true
	title.controls_focus = 0
	title.controls_page = 0
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	stick.axis_value = 0.9
	title._unhandled_input(stick)
	title._unhandled_input(stick)
	assert(title.controls_focus == 1,"Held stick advances only once")
	stick.axis_value = 0
	title._unhandled_input(stick)
	stick.axis_value = 0.9
	title._unhandled_input(stick)
	assert(title.controls_focus == 2,"Release and move stick reaches Back")
	press(title,JOY_BUTTON_B)
	assert(not title.showing_controls,"B still exits")
	title.selecting = true
	title.selected = 1
	title.selection_focus = 1
	title.selection_guard = 0
	title.confirm_blocked = false
	press(title,JOY_BUTTON_DPAD_DOWN)
	assert(title.selection_focus == 2 and title.selected == 1,"Down reaches Back without changing employee")
	press(title,JOY_BUTTON_DPAD_RIGHT)
	assert(title.selection_focus == 3,"Right from Back reaches Clock In")
	press(title,JOY_BUTTON_DPAD_LEFT)
	assert(title.selection_focus == 2)
	press(title,JOY_BUTTON_DPAD_UP)
	assert(title.selection_focus == 1 and title.selected == 1)
	press(title,JOY_BUTTON_DPAD_DOWN)
	press(title,JOY_BUTTON_A)
	assert(not title.selecting and not title.choosing_difficulty,"Confirm Back returns to title")
	title.selecting = true
	title.selection_focus = 0
	key.physical_keycode = KEY_DOWN
	title._unhandled_input(key)
	assert(title.selection_focus == 2)
	key.physical_keycode = KEY_RIGHT
	title._unhandled_input(key)
	assert(title.selection_focus == 3)
	key.physical_keycode = KEY_ENTER
	title._unhandled_input(key)
	assert(title.choosing_difficulty and not title.starting,"Clock In opens difficulty, not gameplay")
	title.queue_free()
	await process_frame
	print("PASS: Controls header focus, both directions/wrap, Back confirmation, sound, stick latch and B cancel")
	quit()
