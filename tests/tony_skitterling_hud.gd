extends SceneTree
const Integrated = preload("res://scripts/integrated_first_call.gd")
var failures: Array[String] = []
var count := 0
func check(value: bool, message: String) -> void:
	count += 1
	if not value:
		failures.append(message)
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = Integrated.new()
	for hero in game.Crew.EMPLOYEES:
		if hero.id == "tony": game.employee = hero
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.awaiting_release = false
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.restart_guard_device = -1
	game.intro_input_release = false
	game.boss_intro.seen = {"cockroach-swarm":true,"clogfather":true}
	game.paused = false
	game.life_state = "alive"
	game.grounded = true
	game.facing = 1
	game.current_aim = Vector2.RIGHT
	game.skitterling.entered = true
	var boss = game.skitterling.encounter
	boss.active = true
	boss.state = "rat_ready"
	boss.phase = "rat"
	boss.position = Vector2(600,440)
	game.player = game.skitterling.ORIGIN+Vector2(300,394)
	game.camera_x = game.skitterling.ORIGIN.x
	var hud = game.boss_hud
	hud.begin_encounter("cockroach-swarm")
	check(game.specials.begin(game),"Real Tony special activates")
	var initial: int = boss.hp
	for frame in range(120):
		var before: int = boss.hp
		game.specials.step(game,1.0/60)
		hud.tick(1.0/60)
		check(hud.hp == boss.hp,"HUD HP matches encounter every frame")
		if (frame+1)%6 == 0:
			check(boss.hp == before-12,"Real contact applies damage every 0.10 seconds")
		if frame == 35:
			check(hud.trail < 1 and game.specials.active,"Visible trail drops while special remains active")
	check(initial-boss.hp == 240,"Two seconds of contact applies 240 boss damage")
	var held: int = boss.hp
	game.paused = true
	for frame in range(60): game.specials.step(game,1.0/60)
	check(boss.hp == held,"Pause does not accumulate damage")
	game.paused = false
	game.specials.cancel("test")
	hud.tick(1)
	check(is_equal_approx(hud.trail,hud.hp/hud.maximum),"Trail catches up after burst")
	var prior: float = hud.trail
	game.skitterling.damage(game,12)
	hud.tick(.05)
	check(is_equal_approx(hud.trail,prior),"Fresh burst gets its brief hold")
	hud.tick(.5)
	check(hud.trail < prior,"Fresh burst also catches up promptly")
	root.remove_child(game)
	game.free()
	print("Tony Skitterling HUD: %d checks, %d failures" % [count,failures.size()])
	quit(0 if failures.is_empty() else 1)
