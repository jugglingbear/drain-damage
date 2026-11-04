extends SceneTree
## Surviving pre-pit Widows resume pursuit only after the landing protection ends.
const Trial = preload("res://scripts/three_screen_trial_game.gd")
var failures: Array[String] = []
var checks_run := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func prepare(hero: int) -> Node2D:
	var game := Trial.new()
	game.employee = game.Crew.EMPLOYEES[hero]
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.camera_x = 1920
	return game

func flyer(game: Node2D) -> Dictionary:
	game.actors.clear()
	game.create_actor({"id":"pressure-aggressive_flyer-4","role":"aggressive_flyer",
		"warning_seconds":0.8},Vector2(2100,190))
	var actor: Dictionary = game.actors.back()
	actor.merge({"depth":"","source":actor.home,"bounds":Vector2(1810,2160),"end":2880,
		"phase":"warning","volley_left":0})
	return actor

func checks() -> void:
	for hero in [0,1]:
		var game := prepare(hero)
		for hero_x in [2500.0,2563.0]:
			for hz in [30,120]:
				game.player = Vector2(hero_x,394)
				game.grounded = true
				game.health = game.employee.max_health
				game.invulnerable = 0
				game.life_state = "alive"
				game.crossing_airborne = false
				game.crossing_until = 0
				var actor := flyer(game)
				var saw_dive := false
				var initial_hp: int = game.health
				for tick in range(hz*12):
					game.trial_clock += 1.0/hz
					game.step_trial_actors(1.0/hz)
					saw_dive = saw_dive or actor.get("attack_state","") == "swoop"
					if game.health < initial_hp: break
				check(actor.get("post_pit_pursuit",false),"Safe landing unlocks survivor pursuit")
				check(saw_dive and game.health == initial_hp-1,
					"Pre-pit spider reaches and damages %s at x%s/%sHz" % [game.employee.id,hero_x,hz])
				check(game.actor_rect(actor).position.x > 2170,"Survivor traverses former containment boundary")
				# A reverse move into the protected corridor must not snap an unlocked actor back.
				var before: Vector2 = actor.feet
				game.player = Vector2(2300,300)
				game.grounded = false
				game.crossing_airborne = true
				var destination := before+Vector2(-1,0)
				game.move_flyer_clear(actor,destination)
				check(actor.get("post_pit_pursuit",false),"Unlock remains latched on hero reversal")
				check(actor.feet.distance_to(before) <= 1.001,"Reversal never teleports actor to old pocket")
				check(not game.begin_flyer_pattern(actor),"Reversal still blocks a fresh attack during crossing")
		check_landing_guard(game)
		check_backtrack_cancellation(game)
		check_ceiling_and_reset(game)
		root.remove_child(game)
		game.free()
	print("Trial flyer pursuit: %d checks, %d failures" % [checks_run,failures.size()])
	quit(0 if failures.is_empty() else 1)

func check_landing_guard(game: Node2D) -> void:
	for sample in [{"x":2430.0,"grounded":true,"airborne":false,"guard":0.0},
		{"x":2563.0,"grounded":false,"airborne":true,"guard":0.0},
		{"x":2563.0,"grounded":true,"airborne":false,"guard":0.45}]:
		var actor := flyer(game)
		game.player = Vector2(sample.x,394)
		game.grounded = sample.grounded
		game.crossing_airborne = sample.airborne
		game.trial_clock = 10
		game.crossing_until = game.trial_clock+sample.guard
		actor.feet.x = 2170-game.event_size(actor.role).end.x
		for tick in range(30):
			game.trial_clock += 0.01
			var completed: bool = game.move_flyer_clear(actor,actor.feet+Vector2(3,0))
			check(not completed,"Containment-clipped move reports incomplete")
			check(not actor.get("post_pit_pursuit",false),"No premature unlock before safe landing")
			check(game.actor_rect(actor).end.x <= 2170.001,"Full body remains behind crossing boundary")
		if sample.guard > 0:
			game.trial_clock = game.crossing_until+0.001
			check(game.move_flyer_clear(actor,actor.feet+Vector2(3,0)),"Pursuit starts after landing guard expires")
			check(actor.post_pit_pursuit,"Landing guard expiry latches unlock")

func check_ceiling_and_reset(game: Node2D) -> void:
	var actor := flyer(game)
	game.player = Vector2(2000,394)
	game.grounded = true
	game.crossing_airborne = false
	game.crossing_until = 0
	actor.feet = Vector2(2100,1-game.event_size(actor.role).position.y)
	var before: Vector2 = actor.feet
	check(not game.move_flyer_clear(actor,before-Vector2(0,3)),"Ceiling-blocked upward request reports false")
	check(actor.feet.is_equal_approx(before),"Ceiling collision keeps body in place")
	check(game.move_flyer_clear(actor,before+Vector2(0,3)),"Downward escape remains available at ceiling")
	actor.post_pit_pursuit = true
	game.reset_game()
	game.dialogue.finish()
	game.player = Vector2(2000,394)
	var fresh := flyer(game)
	check(not fresh.get("post_pit_pursuit",false),"Retry creates a fresh locked encounter")
	check(not game.crossing_airborne and game.crossing_until == 0,"Retry clears crossing lifecycle")

func check_backtrack_cancellation(game: Node2D) -> void:
	for phase in ["windup","swoop"]:
		var actor := flyer(game)
		game.player = Vector2(2300,300)
		game.grounded = false
		game.crossing_airborne = true
		game.health = game.employee.max_health
		game.invulnerable = 0
		actor.active = true
		actor.phase = "combat"
		actor.age = 2.0
		actor.feet = Vector2(2313,320)
		actor.post_pit_pursuit = true
		actor.contact_live = true
		actor.attack_state = phase
		actor.attack_clock = 0.3
		actor.attack_origin = Vector2(2400,190)
		actor.attack_target = game.player+game.PLAYER_SIZE*0.5
		actor.attack_direction = -1.0
		var hp: int = game.health
		check(game.actor_rect(actor).intersects(Rect2(game.player,game.PLAYER_SIZE)),"Backtrack fixture starts in contact range")
		game.step_trial_actors(1.0/120)
		check(actor.attack_state == "recover" and not actor.contact_live,"Reserved backtrack cancels active "+phase)
		for tick in range(90):
			game.trial_clock += 1.0/120
			game.step_trial_actors(1.0/120)
			check(game.health == hp,"Cancelled attack cannot damage hero during renewed crossing")
			check(not game.pattern_owners().has(actor.event_id),"Cancelled attack releases pattern ownership")
		check(actor.feet.y < 320,"Cancelled attack recovers upward")
		check(actor.post_pit_pursuit,"Cancelling attack does not revoke navigation unlock")
