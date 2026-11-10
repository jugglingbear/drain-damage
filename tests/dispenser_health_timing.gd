extends SceneTree
## Health timing at the actual respawn entry point, including the trial cancellation path.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func run_checks() -> void:
	for script in ["opening_trial_game","integrated_first_call"]:
		var game = load("res://scripts/"+script+".gd").new()
		root.add_child(game)
		game.hide()
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.dispenser.cancel()
		game.checkpoint_active = true
		game.checkpoint_index = 0
		game.respawn_point = Vector2(game.Level.CHECKPOINTS[0],394)
		game.lives = 2
		game.health = 0
		game.life_state = "death_popup"
		game.dispenser.reset_stock()
		game.respawn_after_death()
		check(game.dispenser.events.has("vend") and game.health == game.employee.max_health,
			script+": authored immediate vend restores health")
		game.dispenser.cancel()
		game.dispenser.reset_stock()
		game.health = 0
		game.life_state = "death_popup"
		# A delayed per-instance fixture tests the pre-vend interval; shipped respawn vends at t=0.
		game.dispenser.art = game.dispenser.art.duplicate(true)
		game.dispenser.art.short_paths.respawn[0].time = 0.2
		game.respawn_after_death()
		check(game.dispenser.active and game.dispenser.mode == "respawn",script+": respawn sequence survives reset")
		check(game.health == 0,script+": no healing before vend")
		if game.dispenser.active:
			var before: Vector2 = game.player
			game._physics_process(1.0/120)
			game.hurt_player()
			check(game.player == before and game.health == 0 and game.lives == 2,
				script+": zero-HP dispenser presentation cannot simulate or die again")
			var vend := -1.0
			for event in game.dispenser.timeline:
				if event.event == "vend": vend = float(event.time)
			check(vend >= 0,script+": replacement has vend event")
			game.dispenser.tick(game,maxf(0,vend-0.001))
			check(game.health == 0,script+": health stays zero immediately before vend")
			game.dispenser.tick(game,0.002)
			check(game.health == game.employee.max_health,script+": vend restores health")
			game.dispenser.finish(game,true)
		game.dispenser.spent_checkpoints[0] = true
		game.health = 0
		game.life_state = "death_popup"
		game.respawn_after_death()
		if game.dispenser.active: game.dispenser.finish(game,true)
		check(game.health == game.employee.max_health and game.life_state == "alive",
			script+": spent checkpoint fallback remains playable")
		game.dispenser.cancel()
		game.health = 1
		game.dispenser.start(game,"injured",0)
		game.dispenser.finish(game,true)
		check(game.health == 1,script+": empty machine cannot heal an injured arrival")
		game.dispenser.reset_stock()
		game.health = 0
		game.dispenser.start(game,"respawn",0)
		game.dispenser.finish(game,true)
		check(game.health == game.employee.max_health and game.dispenser.dispenses == 1,
			script+": skip/watchdog completes one replacement safely")
		if script == "integrated_first_call":
			game.dispenser.cancel()
			game.dispenser.reset_stock()
			game.post_skitterling_checkpoint = true
			game.checkpoint_active = true
			game.respawn_point = Vector2(game.Level.POST_SKITTERLING_CHECKPOINT,394)
			game.health = 0
			game.life_state = "death_popup"
			game.respawn_after_death()
			check(game.health == game.employee.max_health and game.life_state == "alive",
				"Automatic post-Skitter checkpoint restores health without a vend")
			check(not game.dispenser.active and game.dispenser.stocked and game.dispenser.dispenses == 0,
				"Automatic checkpoint does not consume or animate a spare")
			check(game.checkpoint_active and game.player == game.respawn_point,
				"Automatic checkpoint remains selected after fallback")
		game.queue_free()
		await process_frame
	print("Dispenser health timing: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
