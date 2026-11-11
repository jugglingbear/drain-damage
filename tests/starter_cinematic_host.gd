extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func run() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	var game := Game.new()
	root.add_child(game)
	while not game.startup_complete: await process_frame
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		game.specials.configure(hero.id,"cinematic-test")
		game.dialogue.finish()
		game.dialogue.awaiting_release = false
		game.dialogue.release_guard = 0
		game.dispenser.cancel()
		game.dispenser.just_finished = false
		game.intro_input_release = false
		game.restart_guard_device = -1
		game.life_state = "alive"
		game.player = Vector2(500,394)
		game.grounded = true
		game.velocity = Vector2(55,-22)
		game.invulnerable = .75
		game.fire_timer = .3
		game.camera_x = 180
		game.specials.budgets["cinematic-test:"+hero.id] = 2
		check(game.specials.begin(game,true),"Accepted cinematic "+hero.id)
		check(game.specials.remaining() == 1,"Spend exactly once")
		var position: Vector2 = game.player
		var velocity: Vector2 = game.velocity
		var clock: float = game.elapsed
		var camera: float = game.camera_x
		game._process(.5)
		game._physics_process(.5)
		check(game.player == position and game.velocity == velocity,"Freeze position and velocity")
		check(game.elapsed == clock and game.camera_x == camera,"Freeze world clock and camera baseline")
		check(game.invulnerable == .75 and game.fire_timer == .3,"Freeze invulnerability and cooldown")
		check(game.specials.tick_serial == 0 and game.specials.elapsed == 0,"No cinematic damage ticks")
		game.set_paused(true)
		game._process(10)
		check(is_equal_approx(game.cinematic.elapsed,.5),"Pause preserves cinematic offset")
		game.set_paused(false)
		game._process(20)
		check(not game.cinematic.active and game.transform == Transform2D.IDENTITY,"Handoff restores camera exactly")
		check(game.specials.remaining() == 1,"Handoff never spends again")
		check(game.specials.elapsed == (1.0 if hero.id == "sean" else 0.0),"Exact effect handoff clock")
		check(game.specials.tick_serial == (9 if hero.id == "sean" else 0),"First water tick remains due")
		game.specials.step(game,.001)
		check(game.specials.tick_serial == (10 if hero.id == "sean" else 0),"Sean first tick emitted once")
		game.specials.step(game,.001)
		check(game.specials.tick_serial == (10 if hero.id == "sean" else 0),"No duplicate first tick")
		game.specials.cancel("test")
		check(game.specials.begin(game,true),"Second activation")
		game._process(.7)
		game.specials.cancel("retry")
		game._process(.1)
		check(not game.cinematic.active and not game.specials.active,"Cancel has no delayed activation")
		check(game.specials.remaining() == 0 and game.transform == Transform2D.IDENTITY,"Cancel restores camera without refund")
	game.free()
	await create_timer(.3).timeout
	print("Cinematic host: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
