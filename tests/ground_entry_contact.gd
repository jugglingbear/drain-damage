extends SceneTree
const Opening = preload("res://scripts/opening_trial_game.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func run_checks() -> void:
	var game := Opening.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dispenser.cancel()
	game.life_state = "alive"
	for role in ["runner","perched_shooter","floor_emerger"]:
		game.actors.clear()
		game.create_actor({"id":"entry-contact","role":role,"warning_seconds":0},Vector2(500,440))
		var actor: Dictionary = game.actors.back()
		game.start_actor_entry(actor,"floor",Vector2.ZERO,1.2)
		game.player = Vector2(487,394)
		game.health = game.employee.max_health
		game.invulnerable = 0
		check(not game.exposed_entry_rect(actor).has_area(),"Closed gate has no contact: "+role)
		game.step_actor_entry(actor,0.01)
		check(game.health == game.employee.max_health,"Fully concealed body does not damage: "+role)
		var exposed := false
		for tick in range(144):
			game.step_actor_entry(actor,1.0/120)
			var body := game.exposed_entry_rect(actor)
			if body.has_area():
				exposed = true
				check(body.end.y <= 440.001,"Entry contact stays above clipping plane: "+role)
				if game.health < game.employee.max_health: break
		check(exposed and game.health == game.employee.max_health-1,"Exposed body damages during entry: "+role)
		check(not actor.entry.complete,"Contact starts before entry completes: "+role)
		game.player = Vector2(487,394)
		game.step_actor_entry(actor,0.01)
		check(game.health == game.employee.max_health-1,"Normal invulnerability blocks repeated entry hits: "+role)
		game.invulnerable = 0
		game.player = Vector2(487,441)
		game.step_actor_entry(actor,0.01)
		check(game.health == game.employee.max_health-1,"Hidden portion below floor cannot damage: "+role)
		game.player = Vector2(700,394)
		game.step_actor_entry(actor,2)
		game.player = Vector2(487,394)
		game.step_actor_entry(actor,0.01)
		check(game.health == game.employee.max_health-2,"Settled entrant has no admission contact gap: "+role)
		actor.hp = 0
		game.invulnerable = 0
		game.player = Vector2(487,394)
		game.step_actor_entry(actor,0.01)
		check(game.health == game.employee.max_health-2,"Dead entrant cannot damage: "+role)
		actor.hp = 24
		game.start_actor_entry(actor,"foreground",Vector2.ZERO,1.2) if role != "perched_shooter" else game.start_actor_entry(actor,"ceiling",Vector2.ZERO,1.2)
		check(not game.exposed_entry_rect(actor).has_area(),"Other entry modes retain admission protection: "+role)
	game.free()
	await create_timer(.2).timeout
	print("Ground entry contact: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
