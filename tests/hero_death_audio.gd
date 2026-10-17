extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var audio = game.hero_death_audio
	assert(audio.voice.stream.get_length() >= 2.8 and audio.voice.stream.get_length() <= 3.2)
	assert(audio.voice.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	for hero in game.Crew.EMPLOYEES:
		for lives in [3,1]:
			game.employee = hero
			game.reset_game()
			game.dispenser.cancel()
			game.dialogue.finish()
			game.invulnerable = 0
			game.health = 1
			game.lives = lives
			var before: int = audio.starts
			game.hurt_player()
			assert(game.life_state == "dying" and audio.starts == before+1 and audio.voice.playing)
			for index in range(5):
				game.invulnerable = 0
				game.hurt_player()
			assert(audio.starts == before+1)
			game.set_paused(true)
			assert(audio.voice.stream_paused)
			game.set_paused(false)
			for index in range(300): game.step_death(1.0/120)
			assert(game.life_state == ("game_over" if lives == 1 else "death_popup"))
			assert(not audio.voice.stream_paused,"Automatic death popup must let the cue finish")
			if lives > 1:
				game.set_paused(false)
				game.respawn_after_death()
				assert(audio.starts == before+1 and audio.voice.playing)
			game.reset_game()
			assert(not audio.voice.playing)
	# Enemy defeats and the dispenser do not trigger the hero cue.
	var before: int = audio.starts
	game.enemies.append(game.Data.spawn("toilet",Vector2(1000,404)))
	game.damage_enemy(0,10000,Vector2.ZERO)
	game.health = 1
	game.activate_checkpoint(0)
	game.hurt_player()
	game.dispenser.tick(game,6)
	assert(audio.starts == before)
	game.reset_game()
	AudioServer.set_bus_mute(0,true)
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	assert(audio.starts == before and not audio.voice.playing)
	AudioServer.set_bus_mute(0,false)
	game.reset_game()
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	# Headless dummy mixing can trail the scene clock; allow its completion callback to drain.
	await create_timer(4.5).timeout
	assert(not audio.voice.playing,"Flush must finish naturally without gameplay callbacks")
	game.reset_game()
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	game.death_popup_locked = false
	game.request_title()
	assert(not audio.voice.playing)
	game.queue_free()
	await process_frame
	assert(audio.voice == null)
	print("PASS: both heroes/all lives, one death cue, popup/respawn continuity, pause/mute/cleanup and no enemy/gag trigger")
	quit()
