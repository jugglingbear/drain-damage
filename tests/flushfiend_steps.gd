extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	for hero in [game.Crew.TONY,game.Crew.SEAN]:
		game.employee = hero
		for role in ["runner","rear_runner"]:
			for direction in [-1.0,1.0]:
				var actor := {"event_id":"normal-route-01","role":role,
					"feet":Vector2(3890 if direction < 0 else 3610,380),"vy":0.0,"facing":direction}
				var highest := 440.0
				for i in range(480):
					game.move_ground_actor(actor,direction*100,1.0/120)
					highest = minf(highest,actor.feet.y)
				assert(highest <= 320,"Flushfiend must hop from lower platform onto next60px step")
				assert(actor.feet.x < 3750 if direction < 0 else actor.feet.x > 3750)
	# Retain the original staircase as a navigation fixture; the boss approach replaces its final deck.
	game.trial_level.plinths.assign(game.Level.PROPS)
	# Ascend three successive60px steps using each actor route, from either end of the authored staircase.
	for event_id in ["opening-runner","normal-route-01"]:
		for direction in [-1.0,1.0]:
			var actor := {"event_id":event_id,"role":"runner",
				"feet":Vector2(5800 if direction < 0 else 4800,440),"vy":0.0,"facing":direction}
			var landings: Dictionary = {}
			for i in range(1200):
				game.move_ground_actor(actor,direction*100,1.0/120)
				if actor.vy == 0: landings[int(round(actor.feet.y))] = true
			for height in [380,320,260]:
				assert(landings.has(height),"Each successive platform landing must rearm the next jump")
			assert(actor.feet.x < 5190 if direction < 0 else actor.feet.x > 5390)
	# Campaign enemy path used by Easy/Hard must retain the same repeated-step behavior.
	for direction in [-1.0,1.0]:
		game.enemies.clear()
		game.shots.clear()
		var enemy: Dictionary = game.Data.spawn("toilet",Vector2(3871 if direction < 0 else 3591,344))
		enemy.aggro = true
		enemy.direction = direction
		game.enemies.append(enemy)
		game.player = Vector2(3300 if direction < 0 else 4200,394)
		game.invulnerable = 100
		var highest := 440.0
		for i in range(720):
			game.step_combat(1.0/120)
			highest = minf(highest,enemy.pos.y+36)
		assert(highest <= 320,"Campaign Flushfiends must climb from platform support")
	# Unreachable wall and low ceiling choose retreat, without embedding or midair jump refresh.
	var geometry: Array[Rect2] = game.trial_level.plinths.duplicate()
	game.trial_level.decks.clear()
	for ceiling in [false,true]:
		game.trial_level.plinths.assign([Rect2(500,380 if ceiling else 300,180,60 if ceiling else 140)])
		if ceiling: game.trial_level.plinths.append(Rect2(400,380,90,10))
		var actor := {"event_id":"normal-route-01","role":"runner",
			"feet":Vector2(481,440),"vy":0.0,"facing":1.0}
		for i in range(60): game.move_ground_actor(actor,100,1.0/120)
		assert(actor.feet.x < 470 and actor.vy == 0,"Blocked ascent must retreat instead of stall/head-bump")
	game.trial_level.plinths.assign(geometry)
	var airborne := {"event_id":"normal-route-01","role":"runner",
		"feet":Vector2(3641,370),"vy":0.0,"facing":1.0}
	game.move_ground_actor(airborne,100,1.0/120)
	assert(airborne.vy > 0,"Apex without support cannot grant a midair jump")
	game.queue_free()
	await process_frame
	print("PASS: Flushfiend platform-relative steps both directions,roles/heroes,successive steps,campaign,ceilings,walls and no midair jump")
	quit()
