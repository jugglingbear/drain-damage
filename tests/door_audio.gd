extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.mission.current_zone = 1
	game.step_gates(0.3)
	assert(game.door_audio.events == ["0:opening"])
	var progress: float = game.gate_progress[0]
	game.set_paused(true)
	game.step_gates(1)
	assert(game.gate_progress[0] == progress)
	assert(game.door_audio.voices[0][1].stream_paused)
	game.set_paused(false)
	game.step_gates(0.61)
	assert(game.door_audio.events == ["0:opening","0:open"])
	assert(not game.door_audio.voices[0][1].playing)
	game.step_gates(1)
	game.respawn_after_death()
	game.step_gates(1)
	assert(game.door_audio.events.size() == 2)
	game.reset_game()
	assert(game.door_audio.events.is_empty())
	for gate in game.door_audio.voices:
		for voice in gate: assert(not voice.playing)
	game.gate_progress[0] = 1
	game.mission.current_zone = 1
	game.step_gates(1)
	assert(game.door_audio.events.is_empty(),"Restored open gates must be silent")
	game.death_message = game.Story.choose_death_line()
	for state in ["death_popup","game_over"]:
		game.life_state = state
		game.lives = 0 if state == "game_over" else 2
		game.set_paused(true)
		Input.action_press("dialogue_skip")
		game._process(0.01)
		assert(game.paused and game.life_state == state)
		Input.action_release("dialogue_skip")
		await process_frame
	game.queue_free()
	await process_frame
	print("PASS: gate audio transitions, freeze, restore, cleanup and death cancel guards")
	quit()
