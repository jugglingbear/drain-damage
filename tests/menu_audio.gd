extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func key(code: Key, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	return event

func pad(button: JoyButton, pressed := true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event

func stick(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event

func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	var voice: AudioStreamPlayer = title.navigation_voice
	assert(absf(voice.stream.get_length()-0.24) < 0.001)
	assert(voice.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED and voice.volume_db == 0)
	title._unhandled_input(key(KEY_DOWN))
	assert(title.menu_index == 1 and title.navigation_plays == 1)
	title._unhandled_input(key(KEY_DOWN,true))
	title._unhandled_input(key(KEY_RIGHT))
	assert(title.navigation_plays == 1, "Echo and ineffective direction stay silent")
	title._unhandled_input(pad(JOY_BUTTON_DPAD_UP))
	title._unhandled_input(pad(JOY_BUTTON_DPAD_UP))
	assert(title.menu_index == 0 and title.navigation_plays == 2)
	title._unhandled_input(pad(JOY_BUTTON_DPAD_UP,false))
	title._unhandled_input(stick(JOY_AXIS_LEFT_Y,0.8))
	title._unhandled_input(stick(JOY_AXIS_LEFT_Y,0.9))
	assert(title.navigation_plays == 3)
	title._unhandled_input(stick(JOY_AXIS_LEFT_Y,0))
	title._unhandled_input(stick(JOY_AXIS_LEFT_Y,-0.8))
	assert(title.navigation_plays == 4)
	title._unhandled_input(stick(JOY_AXIS_LEFT_Y,0))
	title.showing_controls = true
	title._unhandled_input(key(KEY_RIGHT))
	title._unhandled_input(key(KEY_RIGHT))
	assert(title.controls_page == 1 and title.navigation_plays == 5)
	title._unhandled_input(pad(JOY_BUTTON_DPAD_LEFT))
	title._unhandled_input(pad(JOY_BUTTON_DPAD_LEFT,false))
	assert(title.controls_page == 0 and title.navigation_plays == 6)
	title.showing_controls = false
	title.selecting = true
	title._unhandled_input(stick(JOY_AXIS_LEFT_X,0.8))
	title._unhandled_input(stick(JOY_AXIS_LEFT_X,0.9))
	assert(title.selected == 1 and title.navigation_plays == 7)
	title._unhandled_input(stick(JOY_AXIS_LEFT_X,0))
	title.toggle_sound()
	title._unhandled_input(key(KEY_LEFT))
	assert(title.muted and title.navigation_plays == 8, "Music mute must not mute SFX")
	var bus := AudioServer.get_bus_index(voice.bus)
	AudioServer.set_bus_mute(bus,true)
	title._unhandled_input(key(KEY_RIGHT))
	assert(title.selected == 1 and title.navigation_plays == 8)
	AudioServer.set_bus_mute(bus,false)
	title._unhandled_input(key(KEY_LEFT))
	assert(voice.playing and title.navigation_plays == 9)
	title.start_game()
	assert(not voice.playing, "Gameplay transition stops menu cue")
	title._unhandled_input(key(KEY_DOWN))
	assert(title.navigation_plays == 9)
	title.return_to_title()
	await process_frame
	title._unhandled_input(key(KEY_DOWN))
	assert(title.navigation_plays == 10)
	var reference: WeakRef = weakref(voice)
	title.queue_free()
	await process_frame
	assert(reference.get_ref() == null)
	print("PASS: menu/crew/controls navigation, keyboard/D-pad/stick, repeats/no-op silence, mute and cleanup")
	quit()
