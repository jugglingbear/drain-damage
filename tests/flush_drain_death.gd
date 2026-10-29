extends SceneTree
const Flow = preload("res://scripts/flush_flow.gd")
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func sampled_overlap(point: Vector2) -> float:
	var inside := 0
	var total := 0
	for x in range(160):
		for y in range(160):
			var offset := Vector2((x+.5)/160*28-14,(y+.5)/160*28-14)
			if offset.length_squared() > 196: continue
			total += 1
			if Flow.drain_coordinates(point+offset,Vector2(65,25.28),140.0/360,60).length_squared() <= 1: inside += 1
	return float(inside)/total

func footprint_checks() -> void:
	var max_call := 0
	var max_bisection := 0
	var max_cold_call := 0
	for angle in [0.0,PI/2,PI,PI*1.5]:
		var direction := Vector2.from_angle(angle)
		var low := 0.0
		var high := 220.0
		for iteration in range(16):
			var middle := (low+high)*.5
			var call_start := Time.get_ticks_usec()
			if Flow.drain_contact(direction*middle,Vector2(65,25.28),140.0/360,60,14): low = middle
			else: high = middle
			max_cold_call = maxi(max_cold_call,Time.get_ticks_usec()-call_start)
		var lethal := direction*low
		var reference := sampled_overlap(lethal)
		assert(reference >= .499 and reference < .515,"Certified crossing must be at least half within oracle grid tolerance")
		assert(not Flow.drain_contact(direction*(high+1),Vector2(65,25.28),140.0/360,60,14))
		assert(Flow.drain_contact(direction*(low-1),Vector2(65,25.28),140.0/360,60,14))
		var began := Time.get_ticks_usec()
		for repeat in range(12): Flow.drain_contact(lethal,Vector2(65,25.28),140.0/360,60,14)
		max_call = maxi(max_call,(Time.get_ticks_usec()-began)/12)
		began = Time.get_ticks_usec()
		var start := high+1
		var end := low-1
		for iteration in range(4):
			var middle := (start+end)*.5
			if Flow.drain_contact(direction*middle,Vector2(65,25.28),140.0/360,60,14): end = middle
			else: start = middle
		max_bisection = maxi(max_bisection,Time.get_ticks_usec()-began)
		print("HALF AREA angle=",angle," sampled_fraction=",reference," radius=",low)
	print("DRAIN BENCHMARK worst_call_us=",max_call," worst_4_step_bisection_us=",max_bisection," worst_search_call_us=",max_cold_call)

func checks() -> void:
	footprint_checks()
	var worst_death_tick := 0
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
				assert(not flush.drain_contact(flush.unproject(center+Vector2.from_angle(angle)*radii*1.2)))
				assert(flush.drain_contact(flush.unproject(center+Vector2.from_angle(angle)*radii*0.8)))
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
		boundary_flush.position = boundary_flush.unproject(edge_center+Vector2(64.0,0))
		var death_tick_start := Time.get_ticks_usec()
		boundary_flush.tick(game,0.1,Vector2.LEFT,false,false)
		worst_death_tick = maxi(worst_death_tick,Time.get_ticks_usec()-death_tick_start)
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
	print("DRAIN BENCHMARK worst_straddling_death_tick_us=",worst_death_tick)
	print("PASS: both heroes, actual opening edges, fatal immunity bypass, single life, retry, paused descent and scripted capture")
	quit()
