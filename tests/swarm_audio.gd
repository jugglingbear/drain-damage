extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	var buzz = game.swarm_audio
	game.player = Vector2.ZERO
	buzz.tick(game,1)
	assert(not buzz.voice.playing)
	game.player = game.swarms.actors[0].pos-game.PLAYER_SIZE*0.5
	buzz.tick(game,1)
	assert(buzz.voice.playing and buzz.starts == 1 and buzz.voice.volume_db <= -8)
	for index in range(20): buzz.tick(game,0.016)
	assert(buzz.starts == 1)
	game.paused = true
	buzz.tick(game,1)
	assert(buzz.voice.stream_paused and buzz.starts == 1)
	game.paused = false
	buzz.tick(game,0.01)
	assert(not buzz.voice.stream_paused and buzz.starts == 1)
	AudioServer.set_bus_mute(0,true)
	buzz.tick(game,0.01)
	assert(not buzz.voice.playing)
	AudioServer.set_bus_mute(0,false)
	buzz.tick(game,1)
	assert(buzz.voice.playing)
	for actor in game.swarms.actors: actor.hp = 0
	buzz.tick(game,0.01)
	assert(not buzz.voice.playing)
	game.reset_game()
	assert(not buzz.voice.playing)
	game.queue_free()
	await process_frame
	print("PASS: swarm buzz proximity, bounded voice, pause/resume, mute, death and cleanup")
	quit()
