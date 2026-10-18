extends SceneTree
## Exercise real geometry and scheduler timing at both supported diagnostic tick rates.

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for path in ["res://scripts/opening_trial_game.gd", "res://scripts/integrated_first_call.gd"]:
		var game = load(path).new()
		root.add_child(game)
		game.hide()
		game.set_process(false)
		game.set_physics_process(false)
		game.dispenser.cancel()
		for hz in [60, 120]:
			for home_x in [880.0, 1780.0, 2680.0]:
				for initial_facing in [-1.0, 1.0]:
					game.actors.clear()
					game.camera_x = home_x - 400
					game.player = Vector2(home_x + 300, 394)
					game.create_actor({"id":"fixture", "role":"floor_emerger", "warning_seconds":0.8},
						Vector2(home_x, 440))
					var actor: Dictionary = game.actors[0]
					actor.active = true
					actor.facing = initial_facing
					var min_x := INF
					var max_x := -INF
					var flips := 0
					for tick in range(hz * 8):
						var old_facing: float = actor.facing
						game.step_trial_actors(1.0 / hz)
						assert(is_equal_approx(actor.feet.y, 440), "Gratecrawler must not jump onto scenery")
						assert(absf(actor.feet.x - home_x) <= 70 + 90.0 / hz + 0.01)
						for solid: Rect2 in game.trial_level.plinths:
							assert(not game.actor_rect(actor).grow(-0.01).intersects(solid))
						if tick >= hz * 4:
							min_x = minf(min_x, actor.feet.x)
							max_x = maxf(max_x, actor.feet.x)
							if actor.facing != old_facing: flips += 1
					assert(max_x - min_x > 100, "Patrol must cross its accessible interval, not jitter")
					assert(flips >= 2 and flips <= 5, "Turn only at boundaries or blocking scenery")
			check_emergence(game, hz, false)
			check_emergence(game, hz, true)
		game.queue_free()
		await process_frame
	print("PASS: both paths60/120Hz, both headings,3grates, floor-only patrol, solid turns and1.45s safe activation")
	quit()

func check_emergence(game: Node, hz: int, occupied: bool) -> void:
	game.reset_observation()
	game.camera_x = 480
	game.player = Vector2(880 if occupied else 600, 394)
	game.health = 5
	game.invulnerable = 0
	game.trial_state.advance(11.0)
	var event: Dictionary
	for item: Dictionary in game.trial_state.results().events:
		if item.role == "floor_emerger": event = item
	assert(is_equal_approx(event.activation_delay, 1.45))
	assert(game.trial_state.reserve(event.id))
	game.create_actor(event, Vector2(880, 440))
	var actor: Dictionary = game.actors[0]
	for tick in range(int(1.45 * hz) - 1):
		game.trial_state.advance(1.0 / hz)
		game.step_trial_actors(1.0 / hz)
		assert(not actor.active and game.health == 5, "Warning/emergence/settle must remain harmless")
	for tick in range(2):
		game.trial_state.advance(1.0 / hz)
		game.step_trial_actors(1.0 / hz)
	assert(actor.active == not occupied, "Activation must recheck occupied grate")
	if occupied:
		game.player = Vector2(600, 394)
		game.trial_state.advance(1.0 / hz)
		game.step_trial_actors(1.0 / hz)
		assert(actor.active)
	game.player = actor.feet - Vector2(13, 46)
	game.step_trial_actors(1.0 / hz)
	assert(game.health == 4, "Fully active patrol retains contact damage1")
