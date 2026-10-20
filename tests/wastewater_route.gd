extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	create_timer(45).timeout.connect(func() -> void: quit(1))
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	var pipe = game.wastewater_art
	assert(pipe.profile.world_end == game.WORLD_WIDTH)
	assert(pipe.profile.terminal_x == game.ClogfatherRoom.START)
	for checkpoint in [4650.0,13800.0]:
		var before: Dictionary = pipe.profile.sample(checkpoint)
		game.respawn_origin = checkpoint
		game.reset_observation()
		assert(pipe.profile.sample(checkpoint) == before,"Retry must retain local pipe progression")
		assert(not pipe.commands(checkpoint,0).is_empty(),"Retry camera must retain bottom pipe")
	var prior: Dictionary = pipe.profile.sample(0)
	for location in [1440,4650,6570,7530,9600,12000,13800,14150]:
		var local: Dictionary = pipe.profile.sample(location)
		assert(local.water <= prior.water and local.coverage >= prior.coverage)
		if location < 14150: assert(local.water > 0 and local.coverage < 1)
		prior = local
	assert(pipe.profile.sample(14150).coverage == 1)
	game.ending.begin(game)
	assert(not pipe.commands(14150,10).is_empty(),"Portal dialogue must retain terminal pipe")
	game.reset_game()
	assert(pipe.profile.sample(0).water == 0.75,"Restart must restore wet entrance")
	game.queue_free()
	await process_frame
	print("PASS: extended pipe route, miniboss continuation, both checkpoint retries, portal and restart")
	quit()
