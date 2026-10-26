extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	for index in range(9):
		game.health = game.employee.max_health
		game.invulnerable = 0
		game.flush.enter_ride(game,index)
		var ride = game.flush.ride
		var cue := "metal_impact"
		if index in [2,3,5]: cue = "soft_contact"
		elif index == 7: cue = "porcelain_contact"
		ride.course.obstacles = [{"id":"contact","kind":"support","x":300,"y":330,"width":2000,"depth":200}]
		var before: int = ride.audio.starts.get(cue,0)
		ride.tick(game,0.01,Vector2.ZERO,false)
		assert(ride.audio.starts.get(cue,0) == before+1)
		ride.tick(game,0.5,Vector2.ZERO,false)
		assert(ride.audio.starts.get(cue,0) == before+1,"No repeated contact layer")
		game.flush.enter_ride(game,index)
		game.invulnerable = 1
		ride.course.obstacles = [{"id":"immune","kind":"support","x":300,"y":330,"width":100,"depth":200}]
		ride.tick(game,0.01,Vector2.ZERO,false)
		assert(ride.audio.starts.get(cue,0) == before+1,"Immune contacts stay silent")
	game.flush.enter_ride(game,5)
	var ride = game.flush.ride
	ride.position.y = 400
	ride.course.obstacles[0].x = 500
	ride.tick(game,.01,Vector2.ZERO,false)
	assert(ride.audio.starts.hinge_move == 1)
	for frame in range(10): ride.tick(game,.01,Vector2.ZERO,false)
	assert(ride.audio.starts.hinge_move == 1,"Mechanism must not restart each frame")
	ride.phase = "rest"
	ride.rest_remaining = 3
	ride.course.obstacles = []
	ride.tick(game,.01,Vector2.ZERO,false)
	assert(not ride.audio.voices.mechanism.playing)
	game.flush.enter_ride(game,9)
	game.health = game.employee.max_health
	game.invulnerable = 0
	for frame in range(900):
		if ride.phase == "rest": break
		ride.tick(game,1.0/120,Vector2.ZERO,false)
	assert(game.life_state == "alive" and ride.audio.starts.water_launch == 1)
	game.flush.enter_ride(game,9)
	ride.course.obstacles = [{"id":"fatal","kind":"long_pit","x":300,"y":330,"width":100,"depth":200}]
	ride.tick(game,.01,Vector2.ZERO,false)
	assert(game.life_state == "dying")
	for voice in ride.audio.voices.values(): assert(not voice.playing,"Death stops ride layers")
	game.queue_free()
	await process_frame
	print("PASS: material event routing, silent immune contacts, bounded visible mechanism, rest cleanup, ramp launch and death priority")
	quit()
