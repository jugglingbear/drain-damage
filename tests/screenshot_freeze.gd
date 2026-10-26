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
		capture._input(button(true))
		assert(paused and capture.frozen and not game.paused and not game.pause_menu.visible)
		assert(not game.can_process() and capture.can_process())
		var state := snapshot(game)
		for voice in capture.saved_audio: assert(not voice.playing or voice.stream_paused)
		await create_timer(0.06,true).timeout
		assert(snapshot(game) == state,"Gameplay/animation/camera/dialogue/particles must remain frozen")
		capture._input(button(true))
		assert(not capture.resuming,"Held Y must not repeat toggle")
		capture._input(button(false))
		capture._input(button(true))
		assert(capture.resuming and not capture.controls_released())
		capture._input(button(false))
		assert(capture.controls_released())
		capture.resume()
		assert(not paused and not capture.frozen and not game.paused and not game.pause_menu.visible)
		count += 1
	game.set_paused(true)
	capture.begin_freeze()
	assert(not capture.frozen and game.pause_menu.visible,"Do not replace ordinary pause/menu state")
	game.set_paused(false)
	capture.begin_freeze()
	capture.resuming = true
	capture._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(capture.frozen and not capture.resuming,"Focus loss must not auto-resume")
	capture.resume()
	game.queue_free()
	await process_frame
	print("PASS: screenshot flag parsing, seven gameplay contexts frozen without pause UI, audio, edge/release/focus guards")
	quit()
