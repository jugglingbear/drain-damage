extends SceneTree
const DIRECTIONS := [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
const KEYS := [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]
const PADS := [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]
var checks := 0
func _initialize() -> void: call_deferred("run_checks")
func key(host: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	host._unhandled_input(event)
	event.pressed = false
	host._unhandled_input(event)
func pad(host: Node, code: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = code
	event.pressed = true
	host._unhandled_input(event)
	event.pressed = false
	host._unhandled_input(event)
func stick(host: Node, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	host._unhandled_input(event)
func configure(host: Node, screen: String, focus: int, page: int) -> void:
	host.showing_controls = screen == "controls"
	host.selecting = screen == "selection" or screen == "difficulty"
	host.choosing_difficulty = screen == "difficulty"
	host.menu_index = focus if screen == "main" else 0
	host.controls_focus = focus if screen == "controls" else 0
	host.controls_page = page
	host.selection_focus = focus if screen == "selection" else 0
	host.selected = focus if screen == "selection" and focus < 2 else 0
	host.difficulty_focus = focus if screen == "difficulty" else 0
	host.difficulty_index = focus if screen == "difficulty" and focus < 3 else 0
	host.selection_guard = 0
	host.confirm_blocked = false
	host.stick_latched = false
	host.navigation_stick = Vector2.ZERO
func focus_of(host: Node, screen: String) -> int:
	return int(host.get({"main":"menu_index","controls":"controls_focus","selection":"selection_focus",
		"difficulty":"difficulty_focus"}[screen]))
func run_checks() -> void:
	create_timer(15).timeout.connect(func() -> void: quit(1))
	var host = load("res://scripts/title_screen.gd").new()
	root.add_child(host)
	var was_muted := AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0,true)
	# Traverse actual input transitions from every starting button, on both Controls tabs.
	for screen in ["main","controls","selection","difficulty"]:
		var count: int = {"main":3,"controls":5,"selection":4,"difficulty":5}[screen]
		for page in range(2 if screen == "controls" else 1):
			for device in range(3):
				for start in range(count):
					var reached := [start]
					var pending := [start]
					while not pending.is_empty():
						var current: int = pending.pop_front()
						for index in range(4):
							configure(host,screen,current,page)
							if device == 0: key(host,KEYS[index])
							elif device == 1: pad(host,PADS[index])
							else:
								var direction: Vector2i = DIRECTIONS[index]
								stick(host,0 if direction.x else 1,float(direction.x if direction.x else direction.y))
							var next := focus_of(host,screen)
							assert(next >= 0 and next < count)
							if next not in reached:
								reached.append(next)
								pending.append(next)
					assert(reached.size() == count,"Every button reachable from every start: "+screen)
					checks += 1
	for page in range(2):
		for focus in [3,4]:
			for code in [KEY_ENTER,KEY_SPACE,KEY_KP_ENTER]:
				configure(host,"controls",focus,page)
				var before: bool = host.muted if focus == 3 else host.show_enemy_health_bars
				key(host,code)
				assert((host.muted if focus == 3 else host.show_enemy_health_bars) != before)
			for code in [JOY_BUTTON_A,JOY_BUTTON_START]:
				configure(host,"controls",focus,page)
				var before: bool = host.muted if focus == 3 else host.show_enemy_health_bars
				pad(host,code)
				assert((host.muted if focus == 3 else host.show_enemy_health_bars) != before)
		configure(host,"controls",2,page)
		key(host,KEY_ENTER)
		assert(not host.showing_controls)
		configure(host,"controls",4,page)
		pad(host,JOY_BUTTON_B)
		assert(not host.showing_controls)
		configure(host,"controls",3,page)
		key(host,KEY_ESCAPE)
		assert(not host.showing_controls)
	# Neutral on the OTHER axis cannot retrigger a held stick; release both before a new move.
	configure(host,"controls",0,0)
	stick(host,JOY_AXIS_LEFT_Y,0.9)
	assert(host.controls_focus == 3)
	stick(host,JOY_AXIS_LEFT_X,0)
	stick(host,JOY_AXIS_LEFT_Y,0.9)
	assert(host.controls_focus == 3)
	stick(host,JOY_AXIS_LEFT_Y,0)
	stick(host,JOY_AXIS_LEFT_X,0.9)
	assert(host.controls_focus == 4)
	for screen in ["main","controls","selection","difficulty"]:
		configure(host,screen,0,0)
		var event := InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_DPAD_DOWN
		event.pressed = true
		host._unhandled_input(event)
		var after := focus_of(host,screen)
		host._unhandled_input(event)
		assert(focus_of(host,screen) == after,"Held D-pad must not repeat")
		event.pressed = false
		host._unhandled_input(event)
		var repeat_key := InputEventKey.new()
		repeat_key.physical_keycode = KEY_DOWN
		repeat_key.pressed = true
		repeat_key.echo = true
		host._unhandled_input(repeat_key)
		assert(focus_of(host,screen) == after,"Key echo must not move focus")
	# A mouse click establishes focus; subsequent arrow input continues from that button.
	for focus in range(5):
		configure(host,"controls",0,0)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.position = [host.Controls.tab_rect(0),host.Controls.tab_rect(1),host.Controls.BACK_RECT,
			host.Controls.MUSIC_RECT,host.Controls.HEALTH_RECT][focus].get_center()
		host._unhandled_input(event)
		assert(host.controls_focus == focus)
		if focus != 2:
			key(host,KEY_RIGHT)
			assert(host.controls_focus == host.Controls.neighbor(focus,Vector2i.RIGHT))
	assert(host.difficulty_copy.confirm == "Save the World!")
	var size: int = host.Buttons.label_size(host.difficulty_copy.confirm,host.DifficultyScreen.CONFIRM,20)
	assert(size >= 14,"Longer confirmation label remains readable")
	AudioServer.set_bus_mute(0,was_muted)
	host.queue_free()
	await process_frame
	print("PASS: ",checks," all-start/menu/device reachability graphs; Controls confirmation/back,mouse,stick latch,label fit")
	quit()
