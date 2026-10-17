extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var started := Time.get_ticks_usec()
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	var art = game.world_art.damage_art
	assert(art.textures.has("toilet"),"Atlas must be prepared before the first gameplay tick")
	var prepared: Texture2D = art.textures.toilet
	var warm_start := Time.get_ticks_usec()
	for index in range(100): art.prepare("toilet")
	print("PREPARATION startup_ms=",(warm_start-started)/1000.0,
		" cached100_ms=",(Time.get_ticks_usec()-warm_start)/1000.0)
	assert(art.textures.toilet == prepared)
	for hero in game.Crew.EMPLOYEES:
		for role in ["runner","rear_runner"]:
			game.employee = hero
			game.reset_game()
			game.dispenser.cancel()
			game.dialogue.release_guard = 0
			game.actors.clear()
			game.enemies.clear()
			game.swarms.actors.clear()
			game.player = Vector2(1200,394)
			game.create_actor({"id":"fixture","role":role,"warning_seconds":0.5},Vector2(1400,440))
			var actor: Dictionary = game.actors[0]
			actor.active = true
			game.shots.append({"pos":Vector2(1350,410),"dir":Vector2.RIGHT,"damage":24.0,
				"speed":760.0,"range":320.0,"distance":0.0})
			game.step_trial_shots(0.1)
			assert(game.corpses.size() == 1 and game.kills == 1)
			var corpse: Dictionary = game.corpses[0]
			assert(corpse.pos == Vector2(1381,404) and corpse.death_time == 0)
			var first: int = art.frame_for(corpse)
			game.finish_trial_defeat(actor)
			assert(game.corpses.size() == 1 and game.kills == 1,"No duplicate corpse or kill")
			game.step_trial_actors(0.7)
			assert(game.actors.is_empty() and game.corpses.size() == 1)
			game._process(1.0)
			assert(art.frame_for(corpse) > first,"Death animation must advance")
			game._process(3.0)
			assert(game.corpses.size() == 1 and corpse.death_time >= 4)
			assert(art.textures.toilet == prepared)
	game.reset_game()
	assert(game.corpses.is_empty())
	var second = game.world_art.DamageArt.new()
	second.prepare("toilet")
	assert(second.textures.toilet == prepared,"New runs reuse prepared atlas")
	game.queue_free()
	await process_frame
	print("PASS: prewarmed shared atlas, both heroes/runner roles, animated persistent wreckage, one kill and reset")
	quit()
