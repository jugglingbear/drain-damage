extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func advance(game: Node2D, seconds: float) -> void:
	for step in range(ceili(seconds*120)):
		game._process(1.0/120)
		game._physics_process(1.0/120)

func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	for selected in range(2):
		title.selected = selected
		title.start_game()
		var game = title.game
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		var dispenser = game.dispenser
		for viewport_size in [Vector2(960,540),Vector2(480,270),Vector2(1920,1080),Vector2(160,120)]:
			for sample in range(100):
				dispenser.hero = game.employee.id
				dispenser.cosmetic_rng.seed = sample
				dispenser.sample_impact(viewport_size)
				var visible := Rect2(dispenser.impact_point+dispenser.impact_bounds.position,
					dispenser.impact_bounds.size)
				assert(Rect2(Vector2.ZERO,viewport_size).encloses(visible))
		assert(game.Level.CHECKPOINTS == [4650.0,13800.0])
		var checkpoint := Vector2(game.Level.CHECKPOINTS[0],394)
		assert(checkpoint.x > 4500 and checkpoint.x < 4900)
		assert(dispenser.stocked and dispenser.sleeping_frames(game.employee.id,0).size() == 1)
		dispenser.full_sequence_seen = false
		game.activate_checkpoint(0)
		advance(game,0.42)
		assert(dispenser.mode == "full_health" and dispenser.stocked and dispenser.dispenses == 0)
		assert(game.lives == 3 and dispenser.events == ["stamp","release"])
		game.health = 1
		game.activate_checkpoint(0)
		assert(not dispenser.active and game.health == 1,"Revisit must not heal or reset stock")
		game.lives = 2
		game.respawn_after_death()
		assert(dispenser.mode == "respawn" and not dispenser.stocked and dispenser.dispenses == 1)
		assert(dispenser.sleeping_frames(game.employee.id,0).is_empty())
		advance(game,1.95)
		assert(game.player == checkpoint and game.lives == 2 and not dispenser.active)
		game.lives = 1
		game.respawn_after_death()
		assert(dispenser.mode == "empty_arrival" and not dispenser.hides_hero())
		advance(game,0.45)
		assert(game.player == checkpoint and game.lives == 1 and dispenser.dispenses == 1)
		assert(not dispenser.events.has("vend") and not dispenser.events.has("emerge"))
		# Injured first arrival retains the existing gag and consumes at its vend event.
		game.reset_game()
		game.health = 1
		game.activate_checkpoint(0)
		assert(dispenser.mode == "injured" and dispenser.stocked and not dispenser.can_skip)
		assert(dispenser.arrival_health == 1 and dispenser.arrival_max_health == game.employee.max_health)
		advance(game,1)
		assert(dispenser.stocked and game.health == game.employee.max_health)
		var clock_value: float = dispenser.elapsed
		game.set_paused(true)
		advance(game,2)
		assert(dispenser.elapsed == clock_value and dispenser.stocked)
		game.set_paused(false)
		advance(game,2.9)
		assert(not dispenser.stocked and dispenser.dispenses == 1 and dispenser.overlay_visible())
		advance(game,3.0)
		assert(not dispenser.active and dispenser.finalizations == 1 and game.lives == 3)
		assert(dispenser.events.count("impact") == 1 and dispenser.events.count("vend") == 1)
		game.respawn_after_death()
		assert(dispenser.mode == "empty_arrival")
		advance(game,0.5)
		assert(dispenser.dispenses == 1 and not dispenser.overlay_visible())
		game.reset_game()
		Input.action_press("dialogue_skip")
		game.health = 1
		game.activate_checkpoint(0)
		dispenser.tick(game,0.1)
		assert(dispenser.active and not dispenser.skip_armed and dispenser.stocked)
		Input.action_release("dialogue_skip")
		await process_frame
		dispenser.tick(game,0.01)
		Input.action_press("dialogue_skip")
		dispenser.tick(game,0.01)
		assert(not dispenser.active and dispenser.dispenses == 1 and dispenser.actions_locked)
		Input.action_release("dialogue_skip")
		await process_frame
		# Skips and watchdog finalize one replacement, never restock or replay a second clone.
		for time in [0.2,1.0,1.95,2.5,3.8,4.7,5.2,6.5]:
			game.reset_game()
			game.health = 1
			game.activate_checkpoint(0)
			dispenser.tick(game,time)
			dispenser.finish(game,true)
			dispenser.finish(game,true)
			assert(not dispenser.stocked and dispenser.dispenses == 1 and dispenser.finalizations == 1)
			assert(not dispenser.overlay_visible() and game.lives == 3)
			game.respawn_after_death()
			assert(dispenser.mode == "empty_arrival")
			dispenser.tick(game,1)
			assert(dispenser.dispenses == 1)
		game.reset_game()
		assert(dispenser.stocked and dispenser.dispenses == 0)
		game.health = 1
		game.activate_checkpoint(0)
		dispenser.timeline = []
		dispenser.tick(game,100)
		assert(not dispenser.active and dispenser.dispenses == 1 and dispenser.finalizations == 1)
		# Cancellation never replenishes spent stock.
		dispenser.cancel()
		assert(not dispenser.stocked)
		title.return_to_title()
		await process_frame
	title.queue_free()
	await process_frame
	print("PASS: both heroes, independent route checkpoints, full/injured/skip/death, single clone, empty arrivals and reset")
	quit()
