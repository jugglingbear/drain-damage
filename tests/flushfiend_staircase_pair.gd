extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/integrated_first_call.gd").new()
	game.seed_override = 42
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	# Preserve the Prototype68 screenshot geometry as a navigation regression fixture.
	game.trial_level.plinths.assign(game.Level.PROPS)
	for rect in [Rect2(4850,380,160,60),Rect2(5010,320,180,120),Rect2(5190,260,200,180),
		Rect2(5390,320,180,120),Rect2(5570,380,160,60)]:
		assert(rect in game.trial_level.plinths)
	for hero in game.Crew.EMPLOYEES:
		for direction in [-1.0,1.0]:
			game.employee = hero
			game.player = Vector2(5277,214)
			game.camera_x = 4900 if direction < 0 else 4550
			game.invulnerable = 100
			game.actors.clear()
			var runners: Array[Dictionary] = []
			var landings := [{},{}]
			for index in range(2):
				var feet := Vector2(5800+index*65 if direction < 0 else 4800-index*65,440)
				game.create_actor({"id":"pair-"+str(index),"role":"runner","warning_seconds":0.8},feet)
				var actor: Dictionary = game.actors.back()
				actor.active = true
				actor.facing = direction
				actor.runner.direction = direction
				runners.append(actor)
			for tick in range(1800):
				game.step_trial_actors(1.0/120)
				for index in range(2):
					var actor: Dictionary = runners[index]
					if actor.vy == 0: landings[index][int(round(actor.feet.y))] = true
			for index in range(2):
				for height in [380,320,260]:
					assert(landings[index].has(height),"Both pursuing Flushfiends must land on every step")
				assert(runners[index].feet.x >= 5190 and runners[index].feet.x <= 5390)
			print("PAIR ",hero.id," direction=",direction," feet=",runners[0].feet,",",runners[1].feet)
	game.queue_free()
	await process_frame
	print("PASS: two simultaneous pursuing Flushfiends climb actual4850..5730 staircase to both heroes, both directions")
	quit()
