extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func trigger(game: Node2D, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	game._input(event)

func start(game: Node2D, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_START
	event.pressed = pressed
	game._input(event)

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	assert(not InputMap.has_action("restart"))
	game.dialogue.finish()
	game.kills = 7
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	game._process(0.01)
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_Y
	button.pressed = true
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	game._process(0.01)
	button = button.duplicate()
	button.pressed = false
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	assert(game.kills == 7, "Standalone R and Y must not reset progress")
	trigger(game, JOY_AXIS_TRIGGER_LEFT, 1)
	trigger(game, JOY_AXIS_TRIGGER_RIGHT, 1)
	Input.action_press("shoot")
	game.step_player(0)
	assert(game.shots.is_empty())
	start(game, true)
	assert(game.kills == 0 and game.lives == 3 and not game.paused)
	assert(game.restart_guard_device == 0)
	game.kills = 4
	start(game, true)
	game.step_player(0.5)
	assert(game.kills == 4 and game.shots.is_empty())
	start(game, false)
	start(game, true)
	assert(game.kills == 4, "All chord controls must be released before rearming")
	start(game, false)
	trigger(game, JOY_AXIS_TRIGGER_LEFT, 0)
	trigger(game, JOY_AXIS_TRIGGER_RIGHT, 0)
	Input.action_release("shoot")
	assert(game.restart_guard_device == -1)
	for context in ["pause", "dialogue"]:
		game.set_paused(context == "pause")
		if context == "dialogue": game.dialogue.start(game.Story.OPENING)
		trigger(game, JOY_AXIS_TRIGGER_LEFT, 1)
		trigger(game, JOY_AXIS_TRIGGER_RIGHT, 1)
		start(game, true)
		assert(game.kills == 4)
		start(game, false)
		trigger(game, JOY_AXIS_TRIGGER_LEFT, 0)
		trigger(game, JOY_AXIS_TRIGGER_RIGHT, 0)
	game.dialogue.finish()
	game.set_paused(false)
	game.suppress_pause_frame = false
	await process_frame
	Input.action_press("pause_game")
	game._process(0.01)
	Input.action_release("pause_game")
	assert(game.paused and game.kills == 4, "Ordinary Start pauses without resetting")
	game.queue_free()
	await process_frame
	print("PASS: no standalone restart action, chord priority, fire suppression, release/rearm and menu/dialogue safety")
	quit()
