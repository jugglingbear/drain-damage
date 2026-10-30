extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Freeze = preload("res://scripts/screenshot_freeze.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void: call_deferred("checks")

func button(pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_Y
	event.pressed = pressed
	return event

func snapshot(game: Node2D) -> Array:
	return [game.player,game.camera_x,game.animation_time,game.particles.duplicate(true),
		game.flush.clock,game.flush.ride.clock,game.health,game.lives,game.dialogue.release_guard,
		game.skitterling.encounter.state,game.ending.clock]

func checks() -> void:
	assert(Launch.parse(["--screenshot-mode=1"]).screenshot_mode)
	assert(Launch.parse(["--screenshot-mode=0"]).is_empty())
	assert(Launch.parse(["--level=2-landing","--screenshot-mode=1"]).screenshot_mode)
	for arguments in [["--screenshot-mode=yes"],["--screenshot-mode=1","--screenshot-mode=0"],
		["--screenshot-mode=1","--verify-playtest-launch"]]:
		assert(Launch.parse(PackedStringArray(arguments)).has("error"))
	var game = Game.new()
	root.add_child(game)
	game.hide()
	var capture := Freeze.new()
	capture.host = game
	game.add_child(capture)
	var count := 0
	for target: Dictionary in Launch.registry().targets:
		if target.id not in ["1","skitterling","2","2-landing","2-02","2-06","2-10"]: continue
		game.flush.reset()
		game.reset_game()
		Launch.initialize(game,target)
		Input.action_press("ui_right")
		var stick := InputEventJoypadMotion.new()
		stick.axis = JOY_AXIS_LEFT_X
		stick.axis_value = .8
		Input.parse_input_event(stick)
		Input.flush_buffered_events()
		assert(Input.get_joy_axis(0,JOY_AXIS_LEFT_X) > .7)
		root.push_input(button(true))
		assert(paused and capture.frozen and not game.paused and not game.pause_menu.visible)
		assert(not game.can_process() and capture.can_process())
		var audio_state: Dictionary = capture.saved_audio.duplicate()
		var state := snapshot(game)
		for voice in capture.saved_audio: assert(not voice.playing or voice.stream_paused)
		await create_timer(0.06,true).timeout
		assert(snapshot(game) == state,"Gameplay/animation/camera/dialogue/particles must remain frozen")
		root.push_input(button(true))
		assert(capture.frozen,"Held Y must not repeat toggle")
		root.push_input(button(false))
		root.push_input(button(true))
		assert(not capture.frozen and Input.is_action_pressed("ui_right") and Input.get_joy_axis(0,JOY_AXIS_LEFT_X) > .7,
			"Y resumes immediately while movement remains held")
		root.push_input(button(true))
		assert(not capture.frozen,"Held Y must not refreeze after immediate resume")
		root.push_input(button(false))
		Input.action_release("ui_right")
		var neutral := InputEventJoypadMotion.new()
		neutral.axis = JOY_AXIS_LEFT_X
		neutral.axis_value = 0
		Input.parse_input_event(neutral)
		Input.flush_buffered_events()
		assert(not paused and not capture.frozen and not game.paused and not game.pause_menu.visible)
		for voice in audio_state:
			if is_instance_valid(voice): assert(voice.stream_paused == audio_state[voice])
		count += 1
	game.set_paused(true)
	capture.begin_freeze()
	assert(not capture.frozen and game.pause_menu.visible,"Do not replace ordinary pause/menu state")
	game.set_paused(false)
	capture.begin_freeze()
	capture._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(capture.frozen,"Focus loss must not auto-resume")
	capture.resume()
	game.queue_free()
	await process_frame
	print("PASS: screenshot flag parsing, seven gameplay contexts frozen without pause UI, audio, immediate Y edges while movement held, focus guard")
	quit()
