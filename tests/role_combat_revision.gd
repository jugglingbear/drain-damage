extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("run_checks")

func prepare(game: Node, role: String, home: Vector2) -> Dictionary:
	game.reset_observation()
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.trial_level.plinths.clear()
	game.trial_level.decks.clear()
	game.player = Vector2(200,394)
	game.camera_x = 0
	game.invulnerable = 1000
	game.trial_state.advance(2)
	var event: Dictionary = {}
	for item in game.trial_state.results().events:
		if item.role == role: event = item; break
	assert(not event.is_empty() and game.trial_state.reserve(event.id))
	game.trial_state.advance(2)
	assert(game.trial_state.activate(event.id))
	game.create_actor(event,home)
	var actor: Dictionary = game.actors[0]
	actor.active = true
	return actor

func run_checks() -> void:
	create_timer(45).timeout.connect(func() -> void: quit(1))
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	for hz in [60,120]:
		var dt: float = 1.0/hz
		var shooter := prepare(game,"perched_shooter",Vector2(600,300))
		var times: Array[float] = []
		for tick in range(hz*9):
			shooter.age += dt
			shooter.visible_age += dt
			game.trial_state.advance(dt)
			game.step_shooter(shooter,dt,true)
			if not game.hostile_shots.is_empty():
				times.append(shooter.age)
				for shot in game.hostile_shots: game.trial_state.remove_bullet(shot.id)
				game.hostile_shots.clear()
		assert(times.size() == 4)
		assert(times[0] >= 0.8-dt and times[0] <= 0.8+dt)
		for index in range(1,times.size()): assert(absf(times[index]-times[index-1]-2.5) <= dt+0.0001)
		game.step_shooter(shooter,1,false)
		assert(game.hostile_shots.is_empty() and shooter.visible_age == 0)
		var crawler := prepare(game,"floor_emerger",Vector2(600,440))
		assert(game.event_size("floor_emerger") == Rect2(-34,-80,68,80))
		assert(crawler.hp == 24 and crawler.max_hp == 24 and game.role_scale("floor_emerger") == 2)
		for tick in range(hz*2):
			crawler.age += dt
			game.trial_state.advance(dt)
			game.step_muck_thrower(crawler,dt,true)
			if not game.hostile_shots.is_empty(): break
		assert(game.hostile_shots.size() == 1)
		var ball: Dictionary = game.hostile_shots[0]
		assert(ball.kind == "muck" and ball.radius == 12)
		var origin: Vector2 = ball.pos
		var velocity: Vector2 = ball.velocity
		var target: Vector2 = ball.target
		assert(velocity.y < 0)
		game.player = Vector2(900,100)
		game.step_hostile_projectiles(0.5)
		assert(ball.pos.distance_to(origin+velocity*0.5+Vector2(0,87.5)) < 0.02)
		var frozen: Dictionary = ball.duplicate(true)
		game.paused = true
		game.step_hostile_projectiles(2)
		game.step_trial_actors(2)
		assert(ball == frozen)
		game.paused = false
		game.step_hostile_projectiles(0.5)
		assert(ball.pos.distance_to(target) < 0.03,"Ball must reach locked aim in one second")
		game.step_hostile_projectiles(0.5)
		assert(game.hostile_shots.is_empty() and game.trial_state.results().bullets == 0)
		game.player = Vector2(200,394)
		var releases: Array[float] = [crawler.fire_age]
		for tick in range(hz*6):
			crawler.age += dt
			game.trial_state.advance(dt)
			game.step_muck_thrower(crawler,dt,true)
			if not game.hostile_shots.is_empty():
				releases.append(crawler.fire_age)
				for shot in game.hostile_shots: game.trial_state.remove_bullet(shot.id)
				game.hostile_shots.clear()
		assert(releases.size() == 3)
		for index in range(1,releases.size()): assert(absf(releases[index]-releases[index-1]-2.5) <= dt+0.0001)
		game.reset_observation()
		assert(game.hostile_shots.is_empty())
	# Active Widow pursues back toward hero even when offscreen or initially facing away.
	for side in [-1,1]:
		var flyer := prepare(game,"aggressive_flyer",Vector2(800,200))
		game.player = Vector2(800+side*700,394)
		game.camera_x = game.player.x-320
		flyer.facing = -side
		var old_distance: float = absf(flyer.feet.x-game.player.x)
		for tick in range(120): game.step_flyer(flyer,1.0/120)
		assert(absf(flyer.feet.x-game.player.x) < old_distance-200 and flyer.hp == 135)
	# A blocked vertical return can slide out from under an overhang, without tunneling.
	var flyer := prepare(game,"aggressive_flyer",Vector2(600,350))
	var ceiling := Rect2(520,270,180,30)
	game.trial_level.plinths.append(ceiling)
	flyer.attack_state = "recover"
	flyer.attack_clock = 0.0
	flyer.attack_origin = Vector2(600,200)
	flyer.recovery_origin = flyer.feet
	flyer.recovery_target = Vector2(650,200)
	flyer.facing = -1
	for tick in range(120*4):
		game.step_flyer(flyer,1.0/120)
		assert(not game.actor_rect(flyer).intersects(ceiling))
		if flyer.attack_state != "recover": break
	assert(flyer.attack_state != "recover","Blocked recovery must not strand a living Widow")
	game.queue_free()
	await process_frame
	print("PASS: shooter0.8/2.5 cadence,2x24HPcrawler, ballistic locked aim/pause/floor cleanup, bidirectional offscreen pursuit and blocked recovery")
	quit()
