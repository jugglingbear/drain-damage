extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	for setup in [[0,"easy"],[0,"normal"],[0,"hard"],[1,"easy"],[1,"normal"],[1,"hard"]]:
		var game = Game.new()
		game.employee = game.Crew.EMPLOYEES[setup[0]]
		game.difficulty = setup[1]
		root.add_child(game)
		game.hide()
		game.set_process(false)
		game.set_physics_process(false)
		for time in [0.0,20.0,34.99]:
			game.begin_level_two()
			var flush = game.flush
			flush.prelude_remaining = 0
			flush.clock = time
			var center: Vector2 = flush.project(Vector2.ZERO)
			for angle in [0.0,PI/2,PI,PI*1.5]:
				var radii := Vector2(65,25.28)
				assert(not flush.drain_contact(flush.unproject(center+Vector2.from_angle(angle)*radii*1.01)))
				assert(flush.drain_contact(flush.unproject(center+Vector2.from_angle(angle)*radii*0.99)))
			flush.position = Vector2.ZERO
			game.invulnerable = 10
			var lives: int = game.lives
			flush.tick(game,0.1,Vector2.ZERO,false,false)
			assert(game.life_state == "dying" and game.lives == lives-1 and game.health == 0)
			assert(flush.state == "drain_death" and not flush.checkpoint_saved)
			flush.tick(game,50,Vector2.ONE,false,false)
			assert(game.lives == lives-1 and flush.state == "drain_death")
			game.set_paused(true)
			game.step_death(0.5)
			assert(flush.sink_depth == 0)
			game.set_paused(false)
			game.step_death(0.5)
			assert(flush.sink_depth > 0)
			game.respawn_after_death()
			assert(game.life_state == "alive" and flush.state == "bowl" and flush.sink_depth == 0)
			assert(not flush.drain_contact(flush.position))
			game.lives = 3
		# A straddling frame must resolve inward drift before scripted capture takes over.
		game.begin_level_two()
		var boundary_flush = game.flush
		boundary_flush.prelude_remaining = 0
		boundary_flush.clock = 34.99
		var edge_center: Vector2 = boundary_flush.project(Vector2.ZERO)
		boundary_flush.position = boundary_flush.unproject(edge_center+Vector2(65.1,0))
		boundary_flush.tick(game,0.1,Vector2.LEFT,false,false)
		assert(game.life_state == "dying" and boundary_flush.state == "drain_death")
		game.lives = 3
		# Crossing the phase boundary cannot skip an already-lethal position.
		game.begin_level_two()
		var flush = game.flush
		flush.prelude_remaining = 0
		flush.clock = 35
		flush.position = Vector2.ZERO
		flush.tick(game,10,Vector2.ZERO,false,false)
		assert(game.life_state == "alive" and game.lives == 3)
		assert(flush.state == "landing" and flush.checkpoint_saved)
		flush.tick(game,7,Vector2.ZERO,false,false)
		assert(flush.state == "ride" and game.lives == 3)
		game.queue_free()
		await process_frame
	print("PASS: both heroes, actual opening edges, fatal immunity bypass, single life, retry, paused descent and scripted capture")
	quit()
