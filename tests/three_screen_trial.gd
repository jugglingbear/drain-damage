extends SceneTree
const Trial = preload("res://scripts/three_screen_trial_game.gd")
const Launch = preload("res://scripts/playtest_launch.gd")
var failures: Array[String] = []
var checks_run := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func prepare(hero: int, mode: String) -> Node2D:
	var game := Trial.new()
	game.employee = game.Crew.EMPLOYEES[hero]
	game.difficulty = mode
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	return game

func dispose(game: Node2D) -> void:
	Input.action_release("right")
	Input.action_release("shoot")
	root.remove_child(game)
	game.free()

func checks() -> void:
	check_aggressive_integration()
	check_arrival_charge()
	check(Launch.parse(["--level=1-trial"]).target.initializer == "three-screen-trial","Separate target")
	check(Launch.parse(["--level=1"]).target.initializer == "level-one","Production target unchanged")
	for hero in [0,1]:
		var game := prepare(hero,"normal")
		for start in [Vector2(1702,394),Vector2(1502,334),Vector2(1654,334),Vector2(1702,360)]:
			game.player = start
			game.invulnerable = 0
			game.health = game.employee.max_health
			game.hurt_player()
			for solid in game.trial_level.plinths:
				check(not Rect2(game.player,game.PLAYER_SIZE).intersects(solid),"Knockback cannot enter solid")
			for tick in range(90):
				game.step_player(1.0/120)
				for solid in game.trial_level.plinths:
					check(not Rect2(game.player,game.PLAYER_SIZE).intersects(solid),"Post-hit movement stays outside solid")
		dispose(game)
	for start in [Vector2(1740,440),Vector2(1590,380),Vector2(1040,440)]:
		var game := prepare(0,"normal")
		game.player = Vector2(1373,274)
		game.camera_x = 1053
		game.grounded = true
		game.issue_event()
		var actor: Dictionary = game.actors[0]
		game.step_actor_entry(actor,actor.entry.duration)
		actor.active = true
		actor.feet = start
		var landed_summit := false
		var jumped := false
		var frames := {}
		for tick in range(1800):
			game.step_trial_actors(1.0/120)
			jumped = jumped or actor.vy < -100
			if actor.grounded and is_equal_approx(actor.feet.y,320): landed_summit = true
			var enemy: Dictionary = actor.runner
			enemy.phase = actor.age*4.5
			enemy.pos = actor.feet-Vector2(19,36)
			enemy.grounded = actor.grounded
			if actor.grounded: frames[game.world_art.damage_art.frame_for(enemy)] = true
			check(game.actor_rect(actor).position.x >= 1000 and game.actor_rect(actor).end.x <= 2010,
				"Pursuit full body remains inside envelope")
			if landed_summit and frames.size() >= 2: break
		check(jumped and landed_summit,"Runner reaches hero summit from "+str(start))
		check(frames.size() >= 2,"Grounded runner cycles walking frames on supported surfaces")
		for feet_y in [440,380,320]:
			var enemy: Dictionary = actor.runner.duplicate(true)
			enemy.pos.y = feet_y-36
			enemy.grounded = true
			enemy.phase = 0
			var first: int = game.world_art.damage_art.frame_for(enemy)
			enemy.phase = 0.13*4.5
			check(game.world_art.damage_art.frame_for(enemy) != first,"Walking cycles at height "+str(feet_y))
			enemy.grounded = false
			check(game.world_art.damage_art.frame_for(enemy) == 2,"Air pose follows support state")
		for edge in [actor.bounds.x,actor.bounds.y]:
			actor.feet = Vector2(edge,440)
			actor.vy = 0
			actor.navigation_retreat = 0.8
			actor.navigation_away = -1 if edge < 1500 else 1
			game.player.x = 900 if edge < 1500 else 2200
			for tick in range(144):
				game.step_trial_actors(1.0/120)
				if absf(actor.feet.x-edge) < 10:
					check(is_zero_approx(actor.vy),"No jump at invisible patrol edge")
				check(game.actor_rect(actor).position.x >= 1000 and game.actor_rect(actor).end.x <= 2010,
					"Retreat stays inside protected envelope")
			check(absf(actor.feet.x-edge) > 10,"Patrol recovers after outward retreat expires")
		dispose(game)
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game := prepare(hero,mode)
			game.player = Vector2(1722,394)
			game.camera_x = 1402
			game.grounded = true
			# Reproduce Sean's cleared climb section while he waits for the foreground entrant.
			for id in game.ledger:
				if id != "foreground-entry": game.ledger[id] = "retired"
			game.issue_event()
			check(game.actors.size() == 1,"Stationary foreground entry admitted")
			var entrant: Dictionary = game.actors[0]
			for frame in range(360):
				game.trial_clock += 1.0/120
				game.step_trial_actors(1.0/120)
			check(entrant.active,"Arrival becomes vulnerable without advancing past x1722")
			check(entrant.feet.distance_to(entrant.home) > 10,"Completed entrant walks its patrol")
			var initial_hp: float = entrant.hp
			Input.action_press("shoot")
			for frame in range(240): game._physics_process(1.0/120)
			print("stationary fire ",game.employee.id," muzzle=",game.world_art.hero_aim_art.muzzle(game),
				" target=",game.actor_projectile_rect(entrant)," hp=",entrant.hp)
			check(entrant.hp < initial_hp,"Grounded horizontal fire damages entrant: "+game.employee.id)
			check(game.corpses.size() == 1,"Defeat retains one animated wreck")
			dispose(game)
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game := prepare(hero,mode)
			check(game.health == game.employee.max_health and game.lives == 3,"Fresh hero")
			# Full scene route: real shooting/damage, no healing or invulnerability override.
			Input.action_press("right")
			Input.action_press("shoot")
			var max_actors := 0
			var max_patterns := 0
			var max_bullets := 0
			var max_sources := 0
			for frame in range(7200):
				if game.grounded and ((game.player.x >= 1030 and game.player.x < 1080)
					or (game.player.x >= 1230 and game.player.x < 1280)
					or (game.player.x >= 2190 and game.player.x < 2240)):
					game.jump_buffer = 0.14
				game._physics_process(1.0/120)
				max_actors = maxi(max_actors,game.live_population())
				max_patterns = maxi(max_patterns,game.pattern_owners().size())
				max_bullets = maxi(max_bullets,game.hostile_shots.size())
				var sources := {}
				for bullet in game.hostile_shots:
					sources[bullet.owner] = true
					if game.player.x < 2440:
						check(not Rect2(2180,300,260,140).grow(4).has_point(bullet.pos),"Crossing trajectory remains clear")
				max_sources = maxi(max_sources,sources.size())
				for actor in game.actors:
					if actor.active and actor.hp > 0:
						var body: Rect2 = game.actor_rect(actor)
						if not actor.get("post_pit_pursuit",false):
							check(body.end.x < 2180 or body.position.x > 2440,"Reserved crossing contact corridor")
				if game.result_shown or game.life_state != "alive": break
			print("route ",game.employee.id," ",mode," x=",game.player.x," hp=",game.health,
				" peaks=",[max_actors,max_patterns,max_bullets]," fired=",game.shot_log.size()," sources=",max_sources," shooter=",game.shooter_stats)
			# This deliberately naive route is a pressure witness, not a required winning strategy.
			check(game.result_shown or game.life_state == "dying","Moving route reaches a valid outcome")
			check(not game.pit_falling,"Terrain-aware route does not fail the pit geometry")
			check(max_actors <= game.tuning.total_actors_max,"Actor budget")
			check(max_patterns <= game.tuning.active_patterns_max,"Pattern budget")
			check(max_bullets <= game.tuning.hostile_projectiles_max,"Projectile budget")
			if mode == "normal":
				# Arrivals now finish before charging; a naive moving run need not overlap two shooters.
				check(max_bullets >= 3 and game.shot_log.size() >= 3,"Normal moving route retains an actual burst threat")
			dispose(game)
	for mode in ["easy","normal","hard"]:
		var game := prepare(0,mode)
		game.player = Vector2(2700,394)
		game.grounded = true
		game.camera_x = 1920
		game.issue_event()
		check(game.actors.size() == 1,"Final shooter admitted")
		# Actor fixture deliberately stands in range; only scheduling advances to inspect volleys.
		for frame in range(1200):
			game.trial_clock += 1.0/120
			game.step_trial_actors(1.0/120)
			game.step_hostile_projectiles(1.0/120)
		var volleys := {}
		for shot in game.shot_log:
			volleys[shot.volley] = int(volleys.get(shot.volley,0))+1
		check(volleys.get(1,0) == 1,"First cycle single: "+mode)
		check(volleys.get(2,0) == int(game.tuning.burst_count),"Second cycle burst: "+mode)
		check(game.shot_log.size() > 0,"Final exchange actually fires: "+mode)
		print("final exchange ",mode," volleys=",volleys)
		game.reset_game()
		check(game.shot_log.is_empty() and game.hostile_shots.is_empty() and game.actors.is_empty(),"Reset cleanup")
		check(game.run_seed == 42 and game.player == Vector2(72,394),"Deterministic reset")
		var before: float = game.trial_clock
		game.set_paused(true)
		game._physics_process(1)
		check(game.trial_clock == before,"Pause freezes scheduler")
		dispose(game)
	for mode in ["easy","normal","hard"]:
		var game := prepare(0,mode)
		# Deliberate foreground approach completes the full warning and depth travel.
		game.player = Vector2(1810,394)
		game.camera_x = 1490
		game.grounded = true
		game.issue_event()
		check(game.actors.size() == 1 and game.actors[0].depth == "foreground","Foreground reserved")
		check(game.arrival_audio.starts == 1,"One spatial cue per admitted entry")
		var entrant: Dictionary = game.actors[0]
		var fixed_home: Vector2 = entrant.home
		for frame in range(300):
			game.trial_clock += 1.0/120
			game.step_trial_actors(1.0/120)
			if not entrant.active: check(not entrant.contact_live,"Harmless warning/travel")
		check(entrant.active and entrant.home == fixed_home,"Committed foreground arrival completes")
		check(entrant.activation_time >= float(game.tuning.arrival_warning_seconds)+0.8,"Full arrival duration")
		game.reset_game()
		game.player = Vector2(1810,394)
		game.camera_x = 1490
		game.grounded = true
		game.issue_event()
		game.player.x = 2040
		game.step_trial_actors(1.0/120)
		check(game.actors.size() == 1,"Pit approach does not erase visible arrival")
		game.reset_game()
		game.player = Vector2(1200,334)
		game.camera_x = 880
		game.grounded = true
		game.issue_event()
		check(game.actors.size() == 1 and game.actors[0].depth == "background","Background reserved")
		for frame in range(300):
			game.trial_clock += 1.0/120
			game.step_trial_actors(1.0/120)
		check(game.actors[0].active,"Background arrival completes")
		for phase_age in [0.1,float(game.tuning.arrival_warning_seconds)+0.1,
			float(game.tuning.arrival_warning_seconds)+0.79]:
			game.reset_game()
			game.player = Vector2(1810,394)
			game.camera_x = 1490
			game.grounded = true
			game.issue_event()
			game.actors[0].age = phase_age
			game.player = Vector2(1910,394)
			game.step_trial_actors(1.0/120)
			check(game.actors.size() == 1,"Occupancy preserves visible warning/travel/settle")
			var arrival: Dictionary = game.actors[0]
			game.player = Vector2(1910,394)
			var health_before: int = game.health
			for tick in range(300): game.step_trial_actors(1.0/120)
			check(arrival.active and game.actors.has(arrival),"Occupied arrival finishes visibly")
			check(game.health == health_before,"Occupied landing does not cause unavoidable damage")
			game.player.x = 1810
			game.step_trial_actors(1.0/120)
			check(not arrival.arrival_guard and arrival.rearm_until > arrival.age,
				"Separation starts fresh warning before contact can rearm")
			check(not arrival.contact_live,"Fresh warning remains harmless")
			var hp_before: float = arrival.hp
			game.damage_trial_actor(arrival,1)
			check(arrival.hp < hp_before,"Arrival remains vulnerable while rearming")
		for vx in [-270.0,270.0]:
			game.reset_game()
			game.player = Vector2(1200,334)
			game.camera_x = 880
			game.grounded = true
			game.issue_event()
			var body: Dictionary = game.actors[0]
			game.player = Vector2(1590-vx*0.2-13,280)
			game.velocity = Vector2(vx,150)
			game.grounded = false
			check(not game.arrival_safe(body),"Predicted airborne landing rejected from both directions")
		game.reset_game()
		game.dialogue.tick(0.3,false)
		game.player = Vector2(2245,394)
		game.grounded = true
		game._physics_process(1.0/60)
		check(game.life_state == "dying" and game.lives == 2,"Pit costs exactly one life")
		for frame in range(90): game._physics_process(1.0/60)
		check(game.life_state == "death_popup" and game.lives == 2 and game.player.y > 440,"Visible fall then popup")
		game.respawn_after_death()
		check(not game.pit_falling and game.player == Vector2(72,394),"Pit retry resets route")
		dispose(game)
	print("PASS" if failures.is_empty() else "FAIL",": three-screen scene ",checks_run," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func check_aggressive_integration() -> void:
	var game := prepare(0,"normal")
	var roles := {}
	for spec in game.event_specs(): roles[spec.role] = int(roles.get(spec.role,0))+1
	check(game.event_specs().size() == 32,"Finite expanded roster contains 32 unique events")
	check(roles == {"runner":15,"perched_shooter":8,"aggressive_flyer":6,"swarm":3},"Mixed ground/ranged/air roster")
	game.player = Vector2(100,394)
	game.camera_x = 0
	game.hostile_shots.append({"id":"persistent","owner":"test","pos":Vector2(500,200),
		"previous":Vector2(500,200),"dir":Vector2.RIGHT,"age":100.0,"distance":900.0,"range":120.0})
	game.step_hostile_projectiles(0.1)
	check(game.hostile_shots.size() == 1 and game.hostile_shots[0].pos.x > 500,
		"Visible purple bolt ignores obsolete age/range fields")
	game.hostile_shots[0].pos = Vector2(1100,200)
	game.step_hostile_projectiles(0.01)
	check(game.hostile_shots.is_empty(),"Fully offscreen bolt retires")
	check(not game.admitted_trajectory(Vector2(2100,410),Vector2.RIGHT),"Crossing-blocking shot denied before birth")
	game.player.x = 2470
	check(game.admitted_trajectory(Vector2(2700,410),Vector2.LEFT),"Final shooter retains infinite-range attack after crossing")
	game.player = Vector2(100,394)
	game.create_actor({"id":"target","role":"runner","warning_seconds":0.0},Vector2(500,440))
	var actor: Dictionary = game.actors.back()
	game.step_actor_entry(actor,actor.entry.duration)
	actor.active = true
	var hp: float = actor.hp
	var swarm: Dictionary = game.swarms.spawn(Vector2(300,420),Rect2(0,0,960,540),0)
	swarm.event_id = "nearest"
	game.swarms.actors.append(swarm)
	game.shots.append({"pos":Vector2(100,420),"dir":Vector2.RIGHT,"speed":1000.0,
		"range":900.0,"distance":0.0,"damage":1.0})
	game.step_trial_shots(0.6)
	check(swarm.hp == game.swarms.definition.health.spawn_hp-1,
		"Nearest swarm receives friendly impact")
	check(actor.hp == hp and game.shots.is_empty(),"One shot cannot penetrate swarm into runner")
	game.reset_game()
	check(game.swarms.actors.is_empty() and game.hostile_shots.is_empty(),"Trial retry clears all air and projectile state")
	check(game.ledger.size() == 32 and game.pressure_log.is_empty(),"Trial retry restores finite ledger and telemetry")
	dispose(game)

func check_arrival_charge() -> void:
	var game := prepare(0,"normal")
	for id in game.ledger:
		if id != "pressure-perched_shooter-0": game.ledger[id] = "retired"
	game.player = Vector2(100,394)
	game.camera_x = 0
	game.issue_event()
	check(game.actors.size() == 1,"Pressure shooter admitted for charge timing")
	if game.actors.is_empty():
		dispose(game)
		return
	var actor: Dictionary = game.actors[0]
	for tick in range(300):
		game.trial_clock += 1.0/120
		game.step_trial_actors(1.0/120)
		if not game.shot_log.is_empty(): break
		check(game.hostile_shots.is_empty(),"No unlogged early projectile")
		if game.MonsterEntry.active(actor): check(not actor.winding,"Charge cannot begin during depth transit")
	check(not game.shot_log.is_empty(),"Arrival charge completes while hero stays in range")
	if not game.shot_log.is_empty():
		check(game.shot_log[0].time >= float(actor.entry.duration)+0.55,"Full arrival then full charge before first bolt")
		check(actor.age-actor.windup_started+0.00001 >= 0.55,"Full visible charge duration before first bolt")
		check(actor.windup_duration == 0.55,"Pressure deformation uses actual charge duration")
	dispose(game)
