extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/opening_trial_game.gd").new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	assert(game.role_scale("aggressive_flyer") == 2)
	assert(game.event_size("aggressive_flyer") == Rect2(-30,-24,60,48))
	for person in game.Crew.EMPLOYEES:
		game.employee = person
		game.reset_game()
		game.player = Vector2(850,394)
		game.camera_x = 600
		var event := {"id":"opening-09","role":"aggressive_flyer","warning_seconds":0.8}
		game.trial_state.advance(15)
		assert(game.trial_state.reserve(event.id))
		game.trial_state.advance(1.1)
		assert(game.trial_state.activate(event.id))
		game.create_actor(event,Vector2(940,250))
		var actor: Dictionary = game.actors[0]
		actor.active = true
		assert(actor.hp == 180 and actor.max_hp == 180)
		assert(game.choose_home({"id":"opening-10","role":"aggressive_flyer"}) == Vector2.INF)
		game.step_flyer(actor,1.0/120)
		assert(actor.attack_state == "windup")
		var origin: Vector2 = actor.feet
		var target: Vector2 = actor.attack_target
		game.player.x = 750
		for tick in range(70):
			game.step_flyer(actor,1.0/120)
			assert(actor.feet == origin, "Warning must finish before the dive")
		for tick in range(12): game.step_flyer(actor,1.0/120)
		assert(actor.attack_state == "swoop")
		assert(actor.attack_target == target, "Committed dive must not follow a dodging hero")
		for tick in range(100): game.step_flyer(actor,1.0/120)
		assert(actor.attack_state == "recover")
		assert(actor.feet.y > origin.y+100, "Dive must reach the hero's lane")
		for tick in range(120): game.step_flyer(actor,1.0/120)
		assert(actor.attack_state == "cooldown")
		assert(actor.feet.is_equal_approx(origin))
		actor.feet = Vector2(1400,250)
		assert(not game.move_flyer_clear(actor,Vector2(1400,410)))
		assert(game.actor_rect(actor).end.y <= 320, "Expanded body must not dive through a deck")
		actor.feet = Vector2(1400,250)
		actor.active = true
		var required := 15 if person.id == "tony" else 10
		for hit in range(required):
			game.shots.append({"pos":Vector2(1350,250),"dir":Vector2.RIGHT,
				"damage":game.weapon.damage,"speed":760,"range":320,"distance":0.0,"trial_id":"fixture"})
			game.step_trial_shots(0.1)
			assert(actor.hp == maxf(0,180-(hit+1)*game.weapon.damage))
			if hit < required-1: assert(actor.hp > 0)
		assert(actor.hp == 0)
	game.actors.clear()
	game.queue_free()
	await process_frame
	print("PASS: doubled flyer bounds,180HP,15/10 hits,single Widow,proximity warning/committed swoop/recovery and deck collision")
	quit()
