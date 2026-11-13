extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func prepare(game: Node2D, hero: int) -> void:
	game.devil_spiders.clear(game,"test")
	game.actors.clear()
	game.employee = game.Crew.EMPLOYEES[hero]
	game.reset_game()
	game.dialogue.finish()
	game.dialogue.awaiting_release = false
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.dispenser.just_finished = false
	game.intro_input_release = false
	game.restart_guard_device = -1
	game.cinematic_resume_frame = -1
	game.life_state = "alive"
	game.paused = false
	game.player = Vector2(500,394)
	game.velocity = Vector2.ZERO
	game.grounded = true
	game.invulnerable = 30
	game.specials.budgets["first-call:"+game.employee.id] = 2
func capture(game: Node2D, hp := 10000.0) -> Dictionary:
	game.create_actor({"id":"web-rain","role":"aggressive_flyer","warning_seconds":0,
		"variant":"devil","devil_limits":Vector2(480,550)},Vector2(513,110))
	var actor: Dictionary = game.actors.back()
	actor.merge({"volley_left":0,"depth":{}},true)
	actor.active = true
	actor.entry = {"complete":true}
	actor.feet = actor.home
	actor.hp = hp
	actor.devil.start(actor.feet,actor.devil_limits,1)
	actor.devil.tuning.crawl_seconds = 1000.0
	actor.devil.drain_events()
	actor.devil.projectiles[1] = true
	actor.devil.projectile_hit_player(1,game.player+game.PLAYER_SIZE*.5)
	game.devil_spiders.consume_events(game,actor)
	return actor
func projectile(game: Node2D) -> void:
	game.hostile_shots.append({"id":"capture-hit","owner":"test","pos":game.player+game.PLAYER_SIZE*.5,
		"dir":Vector2.RIGHT,"age":0.0,"distance":0.0,"range":INF,"radius":4.0})
	game.step_hostile_projectiles(1.0/60)
func run() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	var game := Game.new()
	root.add_child(game)
	while not game.startup_complete: await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	for hz in [30,60,120]:
		prepare(game,1)
		check(game.specials.begin(game,true),"Sean starts cinematic")
		game._process(3.4)
		game.cinematic_resume_frame = -1
		check(game.specials.elapsed == 0 and not game.cinematic.active,"Fresh rain clock after cinematic")
		for frame in range(hz*2): game.step_player(1.0/hz)
		capture(game)
		check(game.devil_spiders.locked(),"Real web capture accepted")
		check(game.specials.active,"Started rain survives web capture")
		if not game.specials.active:
			game.free()
			quit(1)
			return
		check(not game.specials_allowed() and game.specials_allowed(true),"Capture blocks activation, not existing rain")
		var before: float = game.specials.elapsed
		game.set_paused(true)
		game.specials.step(game,10)
		check(game.specials.elapsed == before,"Paused capture cannot consume rain")
		game.set_paused(false)
		game.dialogue.tick(.25,false)
		for frame in range(hz*11/2): game.step_player(1.0/hz)
		print("RAIN CAPTURE hz=",hz," elapsed=",game.specials.elapsed," ticks=",game.specials.tick_serial," active=",game.specials.active," life=",game.life_state)
		check(not game.specials.active and is_equal_approx(game.specials.elapsed,7.5),"Full seven-and-half gameplay seconds")
		check(game.specials.tick_serial == 7,"Exactly seven rain pulses despite capture")
		# Ordinary shots hit while hauling; only normal post-hit grace prevents immediate repeats.
		prepare(game,1)
		capture(game)
		game.invulnerable = 0
		game.step_player(1.0/hz)
		var health: int = game.health
		projectile(game)
		check(game.health == health-1,"Incoming projectile damages hauled hero")
		projectile(game)
		check(game.health == health-1,"Normal post-hit grace prevents repeat damage")
		for frame in range(hz*2): game.step_player(1.0/hz)
		check(game.invulnerable == 0,"Ordinary grace expires while hauling")
		health = game.health
		projectile(game)
		check(game.health == health-1,"Capture does not grant blanket immunity")
		health = game.health
		for frame in range(hz*6): game.step_player(1.0/hz)
		check(game.health < health and not game.devil_spiders.locked(),"Spider bite damages and releases captive")
	prepare(game,1)
	check(game.specials.begin(game,false),"Rain owner-death scenario starts")
	var actor := capture(game,135)
	for frame in range(60*4): game.step_player(1.0/60)
	check(actor.hp <= 0 and not game.devil_spiders.locked(),"Rain kills capture owner and releases Sean")
	check(game.specials.active and game.specials.tick_serial == 4,"Owner death does not cancel rain")
	prepare(game,0)
	check(game.specials.begin(game,false),"Tony special starts")
	capture(game)
	check(not game.specials.active,"Held Tony jet retains capture cancellation")
	game.free()
	await process_frame
	print("Webbed Main Break: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
