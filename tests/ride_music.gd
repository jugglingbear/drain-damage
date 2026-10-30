extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Director = preload("res://scripts/music_director.gd")
const Freeze = preload("res://scripts/screenshot_freeze.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	var director := Director.new()
	game.add_child(director)
	game.music_director = director
	game.begin_level_two()
	var ride = game.flush.ride
	var voice: AudioStreamPlayer = ride.music.voice
	assert(voice.stream.loop and voice.stream.get_length() > 70)
	game.flush.enter_ride(game,0)
	ride.process_audio(game,.01)
	assert(not voice.playing,"Entry guard must not start music")
	game.flush.input_guard = false
	ride.process_audio(game,.01)
	assert(voice.playing and voice.volume_db == -8 and ride.music.starts == 1)
	assert(not game.flush.music.voice.playing,"Flush score must not overlap ride")
	game.paused = true
	ride.process_audio(game,.01)
	assert(voice.stream_paused)
	game.paused = false
	ride.process_audio(game,.01)
	assert(not voice.stream_paused and ride.music.starts == 1)
	director.set_muted(true)
	ride.process_audio(game,.01)
	assert(voice.volume_db == -80 and voice.playing)
	ride.audio.play("board_fart")
	assert(ride.audio.voices.fidget.playing,"Music mute must leave effects audible")
	director.set_muted(false)
	ride.process_audio(game,.01)
	assert(voice.volume_db == -8 and ride.music.starts == 1)
	var freeze := Freeze.new()
	freeze.host = game
	game.add_child(freeze)
	freeze.begin_freeze()
	assert(voice.stream_paused)
	freeze.resume()
	assert(not voice.stream_paused)
	game.life_state = "dying"
	ride.process_audio(game,.01)
	assert(not voice.playing)
	game.life_state = "alive"
	game.flush.enter_ride(game,0)
	game.flush.input_guard = false
	ride.process_audio(game,.01)
	assert(voice.playing and ride.clock == 0)
	game.flush.finish(game)
	assert(not voice.playing)
	game.flush.enter_ride(game,0)
	game.won = false
	game.flush.input_guard = false
	ride.process_audio(game,.01)
	assert(voice.playing)
	game.flush.begin(game)
	assert(not voice.playing)
	game.flush.enter_ride(game,0)
	game.flush.input_guard = false
	ride.process_audio(game,.01)
	AudioServer.set_bus_mute(0,true)
	ride.process_audio(game,.01)
	assert(not voice.playing)
	AudioServer.set_bus_mute(0,false)
	ride.process_audio(game,.01)
	assert(voice.playing)
	game.flush.reset()
	assert(not voice.playing)
	game.flush.dispose()
	assert(voice.stream == null)
	game.queue_free()
	await process_frame
	print("PASS: looping ride score, flush isolation, music/SFX mute separation, pause/freeze/death/retry/exit/reset/disposal")
	quit()
