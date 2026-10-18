extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for path in ["res://scripts/opening_trial_game.gd", "res://scripts/integrated_first_call.gd"]:
		var game = load(path).new()
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.finish()
		assert(game.Data.bundle.monsters.size() == 7)
		assert(game.creature_audio.size() == 5 and not game.creature_audio.has("clogfather"))
		for id in game.Data.bundle.monsters:
			for event in ["hit", "death"]:
				for cue in game.Data.monster(id).audio[event].variants:
					var stream: AudioStreamWAV = load("res://" + str(cue.path))
					assert(stream != null and stream.get_length() > 0)
		for id in game.creature_audio:
			var bank = game.creature_audio[id]
			var spec: Dictionary = game.Data.monster(id).audio
			assert(bank.hit_voices.size() == int(spec.hit.max_voices))
			assert(bank.death_voices.size() == int(spec.death.max_voices))
			for event in ["hit", "death"]:
				for index in range(spec[event].variants.size()):
					var cue: Dictionary = spec[event].variants[index]
					assert(bank.streams[event][index].resource_path == "", "Per-bank nonlooping stream copy")
					assert(bank.streams[event][index].loop_mode == AudioStreamWAV.LOOP_DISABLED)
			var actor := {"hp":10.0,"age":0.0}
			var other := {"hp":10.0,"age":0.0}
			bank.play_hit(actor)
			bank.play_hit(actor)
			bank.play_hit(other)
			assert(bank.hit_starts == 2, "Cooldown is per enemy")
			actor.age = 1.0
			bank.play_hit(actor)
			assert(bank.hit_starts == 3)
			for count in range(10): bank.play_defeat()
			assert(bank.death_voices.size() == int(spec.death.max_voices))
			bank.stop()
		# Verify every opening role dispatches by canonical identity, including the Widow art alias.
		for role in game.AUDIO_IDS:
			game.actors.clear()
			game.create_actor({"id":"audio-"+role,"role":role,"warning_seconds":0},Vector2(500,200))
			var actor: Dictionary = game.actors[0]
			actor.active = true
			var bank = game.creature_audio[game.AUDIO_IDS[role]]
			var hits: int = bank.hit_starts
			var deaths: int = bank.death_starts
			game.damage_trial_actor(actor,0)
			game.damage_trial_actor(actor,-1)
			assert(bank.hit_starts == hits and bank.death_starts == deaths)
			game.damage_trial_actor(actor,1)
			assert(bank.hit_starts == hits+1 and bank.death_starts == deaths)
			game.damage_trial_actor(actor,10000)
			game.damage_trial_actor(actor,10000)
			game.finish_trial_defeat(actor)
			assert(bank.hit_starts == hits+1 and bank.death_starts == deaths+1)
		# The legacy campaign path and swarm signal must use the same profile-backed controllers.
		for id in ["toilet", "spider"]:
			game.enemies.clear()
			var bank = game.creature_audio[id]
			var hits: int = bank.hit_starts
			var deaths: int = bank.death_starts
			game.enemies.append(game.Data.spawn(id,Vector2(500,200)))
			game.damage_enemy(0,1,Vector2.ZERO)
			game.damage_enemy(0,10000,Vector2.ZERO,false)
			assert(bank.hit_starts == hits+1 and bank.death_starts == deaths+1)
		game.swarms.reset()
		var swarm_bank = game.creature_audio["sewer-fly-swarm"]
		var hits: int = swarm_bank.hit_starts
		var deaths: int = swarm_bank.death_starts
		game.swarms.damage(0,1)
		game.swarms.damage(0,10000)
		game.swarms.damage(0,10000)
		assert(swarm_bank.hit_starts == hits+1 and swarm_bank.death_starts == deaths+1)
		game.set_paused(true)
		for bank in game.creature_audio.values():
			var count: int = bank.death_starts
			bank.play_defeat()
			assert(bank.paused and bank.death_starts == count)
		game.set_paused(false)
		AudioServer.set_bus_mute(0,true)
		for bank in game.creature_audio.values():
			var count: int = bank.death_starts
			bank.play_defeat()
			assert(bank.death_starts == count)
		AudioServer.set_bus_mute(0,false)
		game.lives = 2
		game.respawn_after_death()
		for bank in game.creature_audio.values():
			assert(bank.cooldowns.is_empty())
			for voice in bank.hit_voices + bank.death_voices: assert(not voice.playing)
		var banks: Array = game.creature_audio.values()
		game.queue_free()
		await process_frame
		for bank in banks: assert(bank.hit_voices.is_empty() and bank.death_voices.is_empty())
	# Let the audio server drain deferred playback removals before checking process shutdown.
	await create_timer(0.3).timeout
	print("PASS: six complete audio profiles, five runtime controllers, all damage paths, caps/cooldowns and lifecycle")
	quit()
