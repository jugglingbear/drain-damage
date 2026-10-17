extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	var director = title.music_director
	await create_timer(0.6).timeout
	assert(director.current == "title" and title.music.playing)
	assert(not title.music.stream.loop and absf(title.music.stream.get_length() - 154.29) < 0.1)
	assert(is_equal_approx(title.music.volume_db, -16))
	title.toggle_sound()
	title.start_game()
	title.game.set_process(false)
	title.game.set_physics_process(false)
	assert(director.current == "title", "Outgoing track fades before switching")
	await create_timer(0.6).timeout
	assert(director.current == "level" and title.music.stream.loop)
	assert(absf(title.music.stream.get_length() - 59.08) < 0.1)
	assert(title.music.volume_db == -80, "Mute follows the player into the level")
	title.toggle_sound()
	assert(is_equal_approx(title.music.volume_db, -20))
	title.game.paused = true
	title.game._process(0.01)
	assert(title.music.stream_paused)
	title.game.reset_game()
	assert(not title.music.stream_paused and director.current == "level")
	var position: float = title.music.get_playback_position()
	await create_timer(0.2).timeout
	assert(title.music.get_playback_position() >= position, "Restart keeps the level soundtrack moving")
	title.return_to_title()
	await create_timer(0.6).timeout
	assert(director.current == "title" and not title.music.stream.loop and title.music.playing)
	title.music.stop()
	director._on_finished()
	assert(title.music.playing, "Nonseamless title song repeats after its complete ending")
	director.play_track("level")
	director.play_track("title")
	await create_timer(0.6).timeout
	assert(director.current == "title", "Cancelled transitions cannot start a stale level track")
	assert(director.get_child_count() == 1, "Exactly one music voice prevents track overlap")
	var reference = weakref(director)
	title.queue_free()
	await create_timer(0.3).timeout
	assert(reference.get_ref() == null, "Music controller is freed with its owner")
	print("PASS: track identity, duration, gain, fades, mute, pause, restart, return, repeat, cancellation, cleanup")
	quit()
