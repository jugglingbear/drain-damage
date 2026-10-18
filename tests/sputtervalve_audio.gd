extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func shoot(game: Node2D, actor: Dictionary, damage: float) -> void:
	var target: Vector2 = game.actor_projectile_rect(actor).get_center()
	game.shots.assign([{"pos":target-Vector2(60,0),"dir":Vector2.RIGHT,"damage":damage,
		"speed":1000.0,"range":300.0,"distance":0.0,"trial_id":"fixture"}])
	game.step_trial_shots(0.1)

func run_checks() -> void:
	for path in ["res://scripts/opening_trial_game.gd", "res://scripts/integrated_first_call.gd"]:
		var game = load(path).new()
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		game.actors.clear()
		game.hostile_shots.clear()
		var sound = game.sputtervalve_audio
		assert(sound.hit_voices.size() == 2 and sound.death_voices.size() == 2)
		for voice in sound.hit_voices + sound.death_voices:
			assert(voice.stream is AudioStreamWAV and voice.stream.mix_rate == 44100)
			assert(not voice.stream.stereo)
			assert(voice.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED and voice.volume_db == -3)
		game.create_actor({"id":"sound-a","role":"perched_shooter","warning_seconds":0},Vector2(500,200))
		var actor: Dictionary = game.actors[0]
		actor.active = true
		shoot(game,actor,4)
		assert(actor.hp == 32 and sound.hit_starts == 1 and sound.hit_cursor == 1)
		shoot(game,actor,4)
		assert(actor.hp == 28 and sound.hit_starts == 1, "Same actor cooldown")
		actor.age = 0.11
		shoot(game,actor,4)
		assert(sound.hit_starts == 2 and sound.hit_cursor == 0, "Alternating variants")
		game.create_actor({"id":"sound-b","role":"perched_shooter","warning_seconds":0},Vector2(700,200))
		var other: Dictionary = game.actors[1]
		other.active = true
		shoot(game,other,4)
		assert(sound.hit_starts == 3, "Independent actor cooldown")
		shoot(game,actor,100)
		assert(actor.hp == 0 and sound.death_starts == 1 and sound.hit_starts == 3)
		game.finish_trial_defeat(actor)
		shoot(game,actor,100)
		assert(sound.death_starts == 1, "Duplicate defeat and corpse hits are silent")
		var before: int = sound.hit_starts
		other.age = 1
		shoot(game,other,0)
		assert(sound.hit_starts == before, "No damage is silent")
		other.active = false
		shoot(game,other,4)
		assert(sound.hit_starts == before, "Inactive actor is silent")
		other.active = true
		game.set_paused(true)
		assert(sound.paused)
		for voice in sound.hit_voices + sound.death_voices:
			if voice.playing: assert(voice.stream_paused)
		sound.play_hit(other)
		assert(sound.hit_starts == before)
		game.set_paused(false)
		AudioServer.set_bus_mute(0,true)
		sound.play_hit(other)
		sound.play_defeat()
		assert(sound.hit_starts == before and sound.death_starts == 1)
		AudioServer.set_bus_mute(0,false)
		var music = load("res://scripts/music_director.gd").new()
		root.add_child(music)
		music.set_muted(true)
		sound.play_hit(other)
		assert(sound.hit_starts == before + 1, "Music-only mute preserves SFX")
		before = sound.hit_starts
		music.queue_free()
		other.role = "floor_emerger"
		shoot(game,other,4)
		shoot(game,other,100)
		assert(sound.hit_starts == before and sound.death_starts == 1, "Other roles are silent")
		for reset in ["reset_game", "respawn_after_death", "request_title"]:
			sound.play_defeat()
			game.lives = 2
			game.call(reset)
			assert(sound.cooldowns.is_empty())
			for voice in sound.hit_voices + sound.death_voices:
				assert(not voice.playing and not voice.stream_paused)
		game.queue_free()
		await process_frame
		assert(sound.hit_voices.is_empty() and sound.death_voices.is_empty())
	print("PASS: both routes actual hits/deaths, variants, cooldowns, exclusions, bounded pools and lifecycle")
	quit()
