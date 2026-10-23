extends SceneTree

func _initialize() -> void: call_deferred("run_checks")

func unlock(game: Node2D) -> void:
	game.dispenser.cancel()
	game.dispenser.just_finished = false
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.restart_guard_device = -1
	game.checkpoint_index = 1
	game.skitterling.restore_completed()
	game.invulnerable = 1000

func enter(game: Node2D) -> void:
	unlock(game)
	game.player = Vector2(14550,394)
	game.clogfather.advance(game,0)

func run_checks() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(1))
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	title.hide()
	title.start_game()
	var game = title.game
	game.set_physics_process(false)
	unlock(game)
	var director = title.music_director
	await create_timer(0.7).timeout
	assert(director.current == "level" and director.transition == null)
	enter(game)
	game.set_paused(true)
	await create_timer(0.6).timeout
	assert(director.current == "level" and director.player.stream_paused)
	game.set_paused(false)
	await create_timer(0.7).timeout
	assert(director.current == "clogfather" and director.requested == "clogfather")
	assert(director.player.playing and director.player.stream.loop and director.transition == null)
	assert(is_equal_approx(director.player.volume_db,director.BOSS_GAIN_DB+director.WARNING_DUCK_DB))
	for state in ["volley_warning","acid_warning","pressure_warning","recovery"]:
		game.clogfather.encounter.state = state
		game.clogfather.encounter.elapsed = 4.3 if state == "recovery" else 0
		game.clogfather.sync_music_warning(game)
		assert(director.warning_active and director.warning_duck_db == -12)
	director.duck_db = -4
	director.apply_volume()
	assert(is_equal_approx(director.player.volume_db,director.BOSS_GAIN_DB-12))
	director.duck_db = 0
	game.clogfather.encounter.state = "volley"
	game.clogfather.sync_music_warning(game)
	await create_timer(0.3).timeout
	assert(is_equal_approx(director.player.volume_db,director.BOSS_GAIN_DB))
	# Repeated host pause refreshes must not try to restart a completed tween.
	for tick in range(10): game._process(0.01)
	assert(director.transition == null)
	var position: float = director.player.get_playback_position()
	game.set_paused(true)
	await create_timer(0.3).timeout
	assert(absf(director.player.get_playback_position()-position) < 0.06)
	game.set_paused(false)
	director.set_muted(true)
	assert(director.player.volume_db == -80)
	game.reset_game()
	unlock(game)
	await create_timer(0.7).timeout
	assert(director.current == "level" and director.player.volume_db == -80)
	enter(game)
	await create_timer(0.7).timeout
	assert(director.current == "clogfather" and director.player.volume_db == -80)
	director.set_muted(false)
	assert(is_equal_approx(director.player.volume_db,director.BOSS_GAIN_DB+director.WARNING_DUCK_DB))
	AudioServer.set_bus_mute(0,true)
	assert(AudioServer.is_bus_mute(0) and not director.muted)
	AudioServer.set_bus_mute(0,false)
	# Exercise the exported loop boundary, not just the import flag.
	director.player.seek(director.player.stream.get_length()-0.15)
	await create_timer(0.4).timeout
	assert(director.player.playing and director.player.get_playback_position() < 0.7)
	game.clogfather.encounter.state = "recovery"
	game.clogfather.damage(game,10000,"music-terminal",true)
	game.clogfather.advance(game,1.21)
	await create_timer(0.7).timeout
	assert(director.current == "level" and director.transition == null)
	title.return_to_title()
	await create_timer(0.7).timeout
	assert(director.current == "title" and not director.player.stream.loop)
	assert(director.get_child_count() == 1)
	title.queue_free()
	await process_frame
	print("PASS: actual host boss entry/retry, finished fades, pause/mute/gain, loop wrap, victory and title transition")
	quit()
