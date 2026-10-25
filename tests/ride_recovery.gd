extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const STEP := 1.0/120.0

func _initialize() -> void:
	call_deferred("checks")

func obstacle(id: String, kind: String, x: float) -> Dictionary:
	return {"id":id,"kind":kind,"world_x":x,"y":330.0,"width":60.0,"depth":200.0}

func checks() -> void:
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
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
			var ride = game.flush.ride
			assert(ride.scroll_speed == 225.0 and ride.duration == 36.0)
			var lives: int = game.lives
			for kind in ["gap","support","low_barrier"]:
				ride.begin(game)
				ride.position = Vector2(650,330)
				ride.course.obstacles = [obstacle("slow",kind,700)]
				game.health = 3
				game.invulnerable = 0
				# Left steering slows relative travel enough to keep this overlap beyond immunity.
				for frame in range(240): ride.tick(game,STEP,Vector2.LEFT,false)
				assert(game.health == 2 and game.lives == lives and game.life_state == "alive")
				assert(ride.events.hit == 1 and ride.course.obstacles.size() == 1)
				assert(absf(ride.clock-2.0) < 0.00001 and absf(ride.position.x-maxf(180.0,650.0-2.0*ride.x_speed)) < 0.01)
				if kind == "gap": assert(ride.events.recovered == 1)
				# A distinct obstacle can still hurt after immunity; recovery is not global protection.
				var world_x: float = ride.position.x+ride.clock*ride.scroll_speed
				ride.course.obstacles.append(obstacle("next","support",world_x))
				ride.tick(game,STEP,Vector2.ZERO,false)
				assert(game.health == 1 and ride.events.hit == 2)
			# Immune entry latches without a delayed debit; simultaneous contacts debit at most once.
			for immune in [0.0,0.01]:
				ride.begin(game)
				game.health = 3
				game.invulnerable = immune
				ride.course.obstacles = [obstacle("a","gap",300),obstacle("b","support",300)]
				for frame in range(30): ride.tick(game,STEP,Vector2.ZERO,false)
				assert(game.health == (2 if immune == 0 else 3))
				assert(game.lives == lives and ride.events.recovered == 1)
			# Only depleted HP kills; the landing checkpoint and reset clear traversal latches.
			ride.begin(game)
			game.health = 1
			game.invulnerable = 0
			ride.course.obstacles = [obstacle("lethal","gap",300)]
			ride.tick(game,STEP,Vector2.ZERO,false)
			assert(game.life_state == "dying" and game.lives == lives-1)
			ride.tick(game,STEP,Vector2.ZERO,false)
			assert(game.lives == lives-1)
			game.respawn_after_death()
			assert(game.flush.state == "ride" and game.flush.checkpoint_saved and ride.clock == 0)
			assert(game.health == game.employee.max_health)
			game.invulnerable = 0
			ride.course.obstacles = [obstacle("lethal","gap",300)]
			ride.tick(game,STEP,Vector2.ZERO,false)
			assert(game.health == game.employee.max_health-1 and game.life_state == "alive")
			ride.course.obstacles = []
			ride.clock = ride.duration-STEP
			ride.tick(game,STEP*2,Vector2.ZERO,false)
			assert(ride.complete and game.won and ride.clock == ride.duration)
			game.queue_free()
			await process_frame
	print("PASS: ride103 all obstacle traversal latches, bounded in-place gap recovery, shared immunity, later hazards and HP-only checkpoint death for both heroes/all modes")
	quit()
