extends SceneTree
const Three = preload("res://scripts/three_screen_trial_game.gd")
const Section = preload("res://scripts/section_one_two_game.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func run_checks() -> void:
	for Type in [Three,Section]:
		var game = Type.new()
		root.add_child(game)
		game.hide()
		game.set_process(false)
		game.set_physics_process(false)
		game.dispenser.cancel()
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.dialogue.awaiting_release = false
		for hz in [30,60,120]:
			for phase in ["landing","scuttle","takeoff","recover","top_pause","approach"]:
				game.actors.clear()
				game.camera_x = 1800
				game.player = Vector2(2670,394)
				game.health = game.employee.max_health
				game.invulnerable = 1000
				game.grounded = true
				game.crossing_airborne = false
				game.crossing_until = 0
				game.create_actor({"id":"return-fixture","role":"aggressive_flyer","warning_seconds":0.8},Vector2(1680,190))
				var actor: Dictionary = game.actors.back()
				actor.merge({"feet":Vector2(1680,250),"active":true,"entry":{},"depth":"",
					"source":Vector2(1680,190),"bounds":Vector2(0,2880),"end":2880,
					"phase":"combat","age":2.0,"volley_left":0,"post_pit_pursuit":true,
					"attack_state":phase,"attack_clock":0.0,"attack_origin":Vector2(1800,190),
					"attack_direction":-1.0,"scuttle_direction":-1.0,"contact_live":true,
					"recovery_origin":Vector2(1680,250),"recovery_target":Vector2(1500,190)},true)
				var returned := false
				var attacked := false
				for tick in range(hz*18):
					var before: Vector2 = actor.feet
					game.trial_clock += 1.0/hz
					game.step_trial_actors(1.0/hz)
					check(game.actors.has(actor),"Live angel survives left viewport exit: "+phase)
					if not game.actors.has(actor): break
					check(actor.feet.distance_to(before) < 35,"Return moves continuously without teleport")
					for solid: Rect2 in game.actor_solids():
						check(not game.actor_rect(actor).grow(-0.01).intersects(solid),"Return never embeds in scenery")
					returned = returned or game.actor_rect(actor).position.x >= game.camera_x
					if returned and actor.attack_state == "swoop":
						attacked = true
						break
				check(returned and attacked,"Offscreen "+phase+" returns and attacks again at "+str(hz)+"Hz")
		game.free()
	print("Angel offscreen return: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
