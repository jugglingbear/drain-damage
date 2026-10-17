extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.release_guard=0
	for index in range(game.Level.CHECKPOINTS.size()):
		game.lives = 3
		game.player=Vector2(game.Level.CHECKPOINTS[index],394)
		game._physics_process(0)
		assert(game.checkpoint_index==index and not game.dialogue.active)
		game.dispenser.tick(game,0.5)
		game.health=1
		game.activate_checkpoint(index)
		assert(game.health==1, "Checkpoint cannot repeatedly heal")
		game.invulnerable=0
		game.hurt_player()
		for frame in range(180): game.step_death(1.0 / 60)
		game.update_death_popup_guard(0.4)
		game.resume_or_retry()
		assert(game.player.x==game.Level.CHECKPOINTS[index] and game.health==5)
		assert(game.invulnerable>=3)
		game.dispenser.tick(game,1.95)
		game._physics_process(0)
		game.dialogue.release_guard = 0
	game.player=Vector2(9451,394)
	game._physics_process(0)
	assert(not game.won, "Unspawned enemies count toward completion")
	game.reset_game()
	assert(game.checkpoint_index==-1 and game.mission.remaining()==30)
	game.queue_free()
	await process_frame
	print("PASS: one midpoint checkpoint, death recovery, no tutorial, queued completion guard and reset")
	quit()
