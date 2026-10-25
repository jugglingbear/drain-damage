extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Ride = preload("res://scripts/level_two_ride.gd")

func _initialize() -> void:
	call_deferred("checks")

func make_game(hero: int, mode: String) -> Node2D:
	var game = Game.new()
	game.employee = game.Crew.EMPLOYEES[hero]
	game.difficulty = mode
	game.seed_override = 42
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	game.flush.enter_landing(game)
	game.flush.enter_ride(game)
	game.flush.input_guard = false
	return game

func hazard(kind: String, x: float, y := 330.0) -> Dictionary:
	return {"id":"test","kind":kind,"world_x":x,"y":y,"width":24.0,"depth":200.0}

func checks() -> void:
	assert(Ride.overlap_interval(Vector2(0,0),Vector2(100,0),Rect2(40,-5,20,10)).is_equal_approx(Vector2(0.4,0.6)))
	assert(Ride.overlap_interval(Vector2(0,20),Vector2(100,20),Rect2(40,-5,20,10)).x < 0)
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game = make_game(hero,mode)
			var ride = game.flush.ride
			assert(ride.course.obstacles.size() == {"easy":8,"normal":12,"hard":16}[mode])
			var weapon: String = game.weapon.id
			game.health = 2
			ride.course.obstacles = []
			game.set_paused(true)
			game.flush.tick(game,1,Vector2.ONE,true,true)
			assert(ride.clock == 0 and ride.position == Vector2(300,330))
			game.set_paused(false)
			game.flush.tick(game,0.1,Vector2.ONE,true,true)
			assert(ride.jump_height > 0 and ride.position.x > 300 and ride.position.y > 330)
			assert(game.health == 2 and game.weapon.id == weapon and game.flush.shots_fired == 0)
			for frame in range(144): game.flush.tick(game,1.0/120,Vector2.ZERO,false,true)
			assert(ride.jump_age < 0 and ride.events.jump == 1 and ride.events.landed == 1)
			# An all-height support is not cleared by a jump; overlapping hazards debit once.
			ride.begin(game)
			ride.course.obstacles = [hazard("support",300),hazard("support",300)]
			ride.jump_age = 0.6
			game.invulnerable = 0
			game.flush.tick(game,1.0/120,Vector2.ZERO,false,false)
			assert(game.health == 1 and ride.events.hit == 1)
			# Low bars clear at the apex but hurt on the water.
			ride.begin(game)
			ride.course.obstacles = [hazard("low_barrier",300)]
			ride.jump_age = 0.6
			game.invulnerable = 0
			game.flush.tick(game,1.0/120,Vector2.ZERO,false,false)
			assert(game.health == 1)
			# Full footprint gap detection: center still outside, front over unsupported water.
			ride.begin(game)
			ride.course.obstacles = [hazard("gap",350)]
			game.invulnerable = 0
			game.health = 2
			var lives: int = game.lives
			game.flush.tick(game,1.0/120,Vector2.ZERO,false,false)
			assert(game.life_state == "alive" and game.health == 1 and game.lives == lives)
			assert(ride.events.recovered == 1 and not ride.events.has("fall"))
			for frame in range(240): game.flush.tick(game,1.0/120,Vector2.LEFT,false,false)
			assert(game.health == 1 and game.lives == lives)
			# A distinct unprotected contact at one HP still uses the normal death/checkpoint path.
			ride.begin(game)
			ride.course.obstacles = [hazard("gap",350)]
			game.invulnerable = 0
			game.flush.tick(game,1.0/120,Vector2.ZERO,false,false)
			assert(game.life_state == "dying" and game.lives == lives-1 and ride.events.fall == 1)
			game.flush.tick(game,1,Vector2.ZERO,false,false)
			assert(game.lives == lives-1)
			game.respawn_after_death()
			assert(game.flush.state == "ride" and game.flush.checkpoint_saved and ride.clock == 0)
			assert(game.health == game.employee.max_health and game.lives == lives-1 and game.weapon.id == weapon)
			assert(not game.flush.music.voice.playing and game.flush.radio.current.is_empty())
			game.lives = 0
			game.reset_game()
			assert(game.flush.state == "ride" and game.lives == 3 and ride.clock == 0)
			ride.course.obstacles = []
			ride.clock = ride.duration-0.01
			game.flush.tick(game,0.02,Vector2.ZERO,false,false)
			assert(game.won and ride.complete and ride.events.finished == 1)
			game.queue_free()
			await process_frame
	print("PASS: ride swept contacts, both heroes/all modes, movement/jump, no firing, pause, damage, nonlethal gap recovery, depleted-HP death, checkpoint/game-over retry and finish")
	quit()
