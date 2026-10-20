extends SceneTree

class Menu:
	extends "res://scripts/title_screen.gd"
	var launches: Array = []
	func start_game(_launch: Dictionary = {}) -> void:
		launches.append([selected,difficulty_index])
		starting = false

func _initialize() -> void: call_deferred("run_checks")

func press(menu: Node, code: int, controller := false, shift := false) -> void:
	var event: InputEvent
	if controller:
		event = InputEventJoypadButton.new()
		event.button_index = code
	else:
		event = InputEventKey.new()
		event.physical_keycode = code
		event.shift_pressed = shift
	event.pressed = true
	menu._unhandled_input(event)
	event.pressed = false
	menu._unhandled_input(event)

func prepare(menu: Node, hero: int, mode: int) -> void:
	menu.selecting = true
	menu.choosing_difficulty = true
	menu.selected = hero
	menu.difficulty_index = mode
	menu.difficulty_focus = mode
	menu.selection_guard = 0
	menu.confirm_blocked = false
	menu.stick_latched = false
	menu.difficulty_stick = Vector2.ZERO

func run_checks() -> void:
	var menu = Menu.new()
	root.add_child(menu)
	menu.hide()
	menu.set_process(false)
	for hero in [0,1]:
		for mode in range(3):
			for controller in [false,true]:
				prepare(menu,hero,mode)
				press(menu,JOY_BUTTON_DPAD_RIGHT if controller else KEY_RIGHT,controller)
				assert(menu.difficulty_focus == 4 and menu.difficulty_index == mode)
				press(menu,JOY_BUTTON_DPAD_LEFT if controller else KEY_LEFT,controller)
				assert(menu.difficulty_focus == 3 and menu.difficulty_index == mode)
				press(menu,JOY_BUTTON_A if controller else KEY_ENTER,controller)
				assert(not menu.choosing_difficulty and menu.selected == hero and menu.difficulty_index == mode)
				menu.selection_guard = 0
				menu.request_start()
				assert(menu.difficulty_focus == mode and menu.difficulty_index == mode)
				press(menu,JOY_BUTTON_A if controller else KEY_ENTER,controller)
				assert(menu.launches.is_empty(),"Held transition confirmation cannot launch")
				menu.selection_guard = 0
				press(menu,JOY_BUTTON_DPAD_RIGHT if controller else KEY_RIGHT,controller)
				press(menu,JOY_BUTTON_A if controller else KEY_ENTER,controller)
				await process_frame
				assert(menu.launches == [[hero,mode]])
				menu.launches.clear()
	prepare(menu,0,1)
	for expected in [2,3,4,0,1]:
		press(menu,KEY_TAB)
		assert(menu.difficulty_focus == expected)
	press(menu,KEY_TAB,false,true)
	assert(menu.difficulty_focus == 0)
	press(menu,KEY_UP)
	assert(menu.difficulty_focus == 4)
	press(menu,KEY_UP)
	assert(menu.difficulty_focus == 2)
	for axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
		prepare(menu,0,2)
		var stick := InputEventJoypadMotion.new()
		stick.axis = axis
		stick.axis_value = 0.8
		menu._unhandled_input(stick)
		assert(menu.difficulty_focus == 4)
		menu._unhandled_input(stick)
		assert(menu.difficulty_focus == 4,"Held stick must not repeat")
		stick.axis_value = 0
		menu._unhandled_input(stick)
		stick.axis_value = -0.8
		menu._unhandled_input(stick)
		assert(menu.difficulty_focus == (3 if axis == JOY_AXIS_LEFT_X else 2))
	for control in [3,4]:
		var rect: Rect2 = menu.DifficultyScreen.BACK if control == 3 else menu.DifficultyScreen.CONFIRM
		for point in [rect.position+Vector2.ONE,rect.get_center(),rect.end-Vector2.ONE]:
			prepare(menu,1,2)
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = point
			click.pressed = true
			menu._unhandled_input(click)
			click.pressed = false
			menu._unhandled_input(click)
			await process_frame
			assert(not menu.choosing_difficulty if control == 3 else menu.launches == [[1,2]])
			menu.launches.clear()
	menu.queue_free()
	await process_frame
	print("PASS: both heroes/all difficulties, Back/Start keyboard/pad/stick/tab focus, mouse edges, choice preservation and release guards")
	quit()
