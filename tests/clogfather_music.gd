extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var director = load("res://scripts/music_director.gd").new()
	root.add_child(director)
	director.play_track("level")
	await create_timer(.3).timeout
	director.play_track("clogfather")
	director.set_paused(true)
	await create_timer(.6).timeout
	assert(director.current == "level" and director.player.stream_paused)
	director.set_paused(false)
	await create_timer(.6).timeout
	assert(director.current == "clogfather" and director.player.stream.loop)
	assert(absf(director.player.stream.get_length()-51.2) < .02)
	assert(is_equal_approx(director.player.volume_db,-18))
	assert(director.get_child_count() == 1)
	director.set_muted(true)
	assert(director.player.volume_db == -80)
	director.play_track("clogfather",true)
	await create_timer(.6).timeout
	assert(director.current == "clogfather" and director.player.volume_db == -80)
	director.set_muted(false)
	director.play_track("level")
	director.stop_music()
	await create_timer(.6).timeout
	assert(director.current == "" and not director.player.playing)
	director.play_track("title")
	await create_timer(.3).timeout
	assert(not director.player.stream.loop)
	director.queue_free()
	await create_timer(.2).timeout
	print("PASS: boss music identity/gain/loop, single voice, paused transition, retry/mute/stop cleanup")
	quit()
