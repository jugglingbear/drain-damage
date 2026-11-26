extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("checks")

func press(game: Node2D, action: String) -> void:
	Input.action_press(action)
	await physics_frame
	game._physics_process(1.0/60)
	Input.action_release(action)
	await physics_frame

func checks() -> void:
	AudioServer.set_bus_mute(0,false)
	var game = Game.new()
	root.add_child(game)
	while not game.startup_complete: await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	await game.flush.prepare_bowl(game)
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		await game.begin_level_two()
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		var flush = game.flush
		flush.input_guard = false
		flush.audio.starts.clear()
		await press(game,"shoot")
		assert(flush.audio.starts.get("button_fire",0) == 1)
		await press(game,"shoot")
		assert(flush.audio.starts.button_fire == 1)
		flush.audio.voices.vocal.stop()
		await press(game,"special")
		assert(flush.audio.starts.get("button_gag",0) == 1)
		game.set_paused(true)
		await press(game,"shoot")
		assert(flush.audio.starts.button_fire == 1)
		game.set_paused(false)
		AudioServer.set_bus_mute(0,true)
		flush.process_audio(game,.02)
		assert(not flush.audio.voices.vocal.playing)
		await press(game,"shoot")
		AudioServer.set_bus_mute(0,false)
		assert(flush.audio.starts.button_fire == 1)
		flush.enter_landing(game)
		await press(game,"special")
		assert(not flush.audio.voices.vocal.playing and flush.audio.starts.button_gag == 1)
		assert(flush.shots_fired == 0)
	game.free()
	print("PASS: both heroes, flush fire/special, repeat suppression, pause, mute and landing exit")
	quit()
