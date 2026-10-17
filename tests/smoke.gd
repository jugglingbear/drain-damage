extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.step_player(1.0 / 60.0)
	assert(game.grounded, "Sean should start on the floor")
	game.jump_buffer = 0.14
	game.step_player(1.0 / 60.0)
	assert(game.velocity.y < 0, "Jump should move Sean upward")
	game.player = Vector2(330,300)
	game.velocity = Vector2(0,300)
	game.step_player(0.2)
	assert(game.grounded and game.player.y==334, "Land on the visible pipe bundle")
	for key in [KEY_ENTER, KEY_KP_ENTER]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.pressed = true
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		game.fire_timer = 0
		var before: int = game.shots.size()
		game.step_player(1.0 / 60.0)
		assert(game.shots.size() == before + 1, "Enter must fire a plunger")
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	var pad := InputEventJoypadButton.new()
	pad.device = 0
	pad.button_index = JOY_BUTTON_X
	pad.pressed = true
	Input.parse_input_event(pad)
	Input.flush_buffered_events()
	assert(Input.is_action_pressed("shoot"), "Controller X must map to fire")
	pad = pad.duplicate()
	pad.pressed = false
	Input.parse_input_event(pad)
	Input.flush_buffered_events()
	for binding in [[JOY_BUTTON_A, "jump"], [JOY_BUTTON_DPAD_LEFT, "left"],
		[JOY_BUTTON_DPAD_RIGHT, "right"], [JOY_BUTTON_START, "pause_game"]]:
		var button := InputEventJoypadButton.new()
		button.button_index = binding[0]
		button.pressed = true
		Input.parse_input_event(button)
		Input.flush_buffered_events()
		assert(Input.is_action_pressed(binding[1]), "Controller button must activate its action")
		button = button.duplicate()
		button.pressed = false
		Input.parse_input_event(button)
		Input.flush_buffered_events()
	for binding in [[JOY_AXIS_LEFT_X, -1.0, "left"], [JOY_AXIS_LEFT_X, 1.0, "right"],
		[JOY_AXIS_TRIGGER_RIGHT, 1.0, "shoot"]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = binding[0]
		axis.axis_value = binding[1]
		Input.parse_input_event(axis)
		Input.flush_buffered_events()
		assert(Input.is_action_pressed(binding[2]), "Stick and trigger must activate their actions")
		axis = axis.duplicate()
		axis.axis_value = 0.1
		Input.parse_input_event(axis)
		Input.flush_buffered_events()
		assert(not Input.is_action_pressed(binding[2]), "Deadzone must reject small axis deflections")
	game._on_joy_connection_changed(0, false)
	assert(game.paused, "Disconnect must pause gameplay")
	game.reset_game()
	game.dialogue.release_guard = 0
	game.invulnerable = 0
	game.hurt_player()
	assert(game.health == 4)
	game.hurt_player()
	assert(game.health == 4, "Invulnerability should prevent repeated contact damage")
	game.invulnerable = 0
	game.health = 1
	game.hurt_player()
	for frame in range(180): game.step_death(1.0 / 60)
	game.update_death_popup_guard(0.4)
	game.resume_or_retry()
	assert(game.health == 5 and game.player.x == 85, "Defeat should respawn with full health")
	game.reset_game()
	assert(not game.won and game.enemies.is_empty() and game.mission.remaining()==30)
	print("PASS: movement, solid landing, Enter/numpad/controller firing, disconnect, damage, respawn and reset")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
