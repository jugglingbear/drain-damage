extends SceneTree
const Section = preload("res://scripts/section_one_two_game.gd")
var failures: Array[String] = []
var checks_run := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func prepare(hero: int, mode: String) -> Node2D:
	var game := Section.new()
	game.employee = game.Crew.EMPLOYEES[hero]
	game.difficulty = mode
	game.seed_override = 197
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	return game

func terrain_route(game: Node2D, hz: int) -> void:
	game.reset_observation()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	for id in game.ledger: game.ledger[id] = "retired"
	game.grounded = true
	game.velocity = Vector2.ZERO
	var summit := false
	var guarded_landing := false
	Input.action_press("right")
	for tick in range(24*hz):
		if game.grounded:
			var needs_jump: bool = game.player.x+26 >= game.trial_level.pit.x-30 and game.player.x < game.trial_level.pit.x
			for solid: Rect2 in game.trial_level.plinths:
				var distance: float = solid.position.x-(game.player.x+26)
				if distance >= 0 and distance <= 30 and solid.position.y < game.player.y+46:
					needs_jump = true
			if needs_jump: game.jump_buffer = 0.14
		var crossing_airborne: bool = game.crossing_airborne
		game._physics_process(1.0/hz)
		if crossing_airborne and game.grounded and game.player.x+26 > game.trial_level.pit.y:
			guarded_landing = game.crossing_until-game.trial_clock >= 0.4
		if game.grounded and is_equal_approx(game.player.y+46,320): summit = true
		for solid: Rect2 in game.trial_level.plinths:
			check(not Rect2(game.player,game.PLAYER_SIZE).intersects(solid),"Traversal never embeds hero in machinery")
		if game.result_shown or game.life_state != "alive": break
	Input.action_release("right")
	check(game.result_shown and not game.pit_falling,"Both heroes finish the distinct route at "+str(hz)+" Hz")
	check(guarded_landing,"Actual pit landing retains the 0.45-second attack recovery guard")
	check(summit,"Route includes a supported machinery summit landing")
	check(game.camera_x > 1800 and game.camera_x <= 1920,"Camera follows the full section")
	game.set_paused(false)
	game.reset_game()

func jump_landing(game: Node2D, start: Vector2, hz: int, moving: bool, hold: float, direction := 1.0) -> Dictionary:
	var pos := start
	var motion := Vector2(direction*float(game.employee.move_speed) if moving else 0.0,-465)
	var released := false
	for tick in range(2*hz):
		if not released and float(tick)/hz >= hold:
			motion.y = maxf(motion.y,-170)
			released = true
		motion.x = move_toward(motion.x,direction*float(game.employee.move_speed),1900.0/hz)
		motion.y += 1250.0/hz
		var result: Dictionary = game.trial_level.move_body(pos,motion,game.PLAYER_SIZE,1.0/hz)
		pos = result.pos
		motion = result.velocity
		if result.grounded or result.falling: return result
	return {"grounded":false,"falling":false,"pos":pos}

func check_geometry(game: Node2D) -> void:
	var pit: Vector2 = game.trial_level.pit
	check(is_equal_approx(game.trial_level.fatal_fraction,0.9),"Only section1.2 adopts Sean's ninety-percent rule")
	check(game.trial_level.plinths[1].size == Vector2(220,120),"Summit preserves approved pump dimensions")
	check(pit.x < 1500,"Second section has an early pit, not the baseline late pit")
	for hz in [30,120]:
		for fraction in [0.89,0.9,0.91]:
			for x in [pit.x-26+26*fraction,pit.y-26*fraction]:
				var pos := Vector2(x,394)
				var result: Dictionary = game.trial_level.move_body(pos,Vector2(0,10),game.PLAYER_SIZE,1.0/hz)
				check(result.falling == (fraction >= 0.9),"Both ledges use the section-specific ninety-percent threshold")
				result = game.trial_level.move_body(pos-Vector2(0,4),Vector2(0,600),game.PLAYER_SIZE,1.0/hz)
				check(result.falling == (fraction >= 0.9),"Landing uses the same ninety-percent footprint rule")
		var reported: Dictionary = game.trial_level.move_body(Vector2(891,394),Vector2(0,10),game.PLAYER_SIZE,1.0/hz)
		check(reported.grounded and not reported.falling,"Reported x891 approach retains visible ledge support")
		for direction in [-1.0,1.0]:
			var start := Vector2(pit.x-60 if direction > 0 else pit.y+40,394)
			var swept: Dictionary = game.trial_level.move_body(start,Vector2(direction*270,30),game.PLAYER_SIZE,1)
			check(swept.falling,"Grounded sweep cannot tunnel over the opening in either direction")
		for moving in [false,true]:
			var landing := jump_landing(game,Vector2(pit.x-26,394),hz,moving,1.0)
			check(landing.grounded and not landing.falling and landing.pos.x+26 > pit.y,
				"Standing and moving starts clear the early pit with a held jump")
			var reverse := jump_landing(game,Vector2(pit.y,394),hz,moving,1.0,-1)
			check(reverse.grounded and not reverse.falling and reverse.pos.x < pit.x,
				"Standing and moving reverse jumps clear the same visible opening")
			for index in [0,1]:
				var solid: Rect2 = game.trial_level.plinths[index]
				for hold in [0.15,1.0]:
					landing = jump_landing(game,Vector2(solid.position.x-26,solid.position.y+60-46),hz,moving,hold)
					check(landing.grounded and not landing.falling and is_equal_approx(landing.pos.y+46,solid.position.y),
						"Short and held jumps reach each sixty-pixel rise")
		terrain_route(game,hz)
	for index in range(game.trial_level.plinths.size()):
		check(game.region(game.art_part("machinery-%d" % index).destination) == game.trial_level.plinths[index],
			"Machinery artwork and collision use identical rectangles")
	check(game.region(game.art_part("pit-depth").destination) == Rect2(pit.x,440,pit.y-pit.x,100),
		"Visible pit follows actual opening")
	check(game.region(game.art_part("pit-left-rim").destination).end.x == pit.x,
		"Visible left lip ends at actual collision ledge")
	check(game.region(game.art_part("pit-right-rim").destination).position.x == pit.y,
		"Visible right lip begins at actual collision ledge")
	var support: Dictionary = game.art_part("catwalk-support")
	var support_rect: Rect2 = game.region(support.destination)
	var support_source: Rect2 = game.region(support.source_rect)
	check(is_equal_approx(support_rect.size.x/support_source.size.x,support_rect.size.y/support_source.size.y),
		"Catwalk braces retain uniform artwork proportions")
	check(is_equal_approx(support_rect.end.y,440) and is_equal_approx(support_rect.get_center().x,580),
		"Catwalk support is centered and reaches the floor")
	for pair in [["access-deck",0],["catwalk-deck",1]]:
		check(game.region(game.art_part(pair[0]).destination) == game.trial_level.decks[pair[1]],
			"Optional deck top matches collision")

func check_encounters(game: Node2D) -> void:
	game.reset_observation()
	var ids := {}
	var specs: Array = game.event_specs()
	check(specs.size() > 0 and specs.size() < 32,"New section has a smaller finite authored roster")
	for spec: Dictionary in specs:
		check(not ids.has(spec.id),"Encounter IDs are unique")
		ids[spec.id] = true
		check(spec.trigger < spec.end and spec.end <= game.actor_world_limit(),"Admission window stays inside section")
		if spec.entry.mode == "ceiling":
			check(spec.role == "perched_shooter" and is_equal_approx(spec.feet.y,180),
				"Ceiling shooter uses Art's registered hanging mount")
		elif spec.role in ["runner","perched_shooter"]:
			var shape: Rect2 = game.event_size(spec.role)
			var supported := false
			if spec.feet.x < game.trial_level.pit.x:
				check(spec.feet.x+shape.end.x <= float(game.contract.geometry.pit.takeoff_clear_x[0]),
					"Pre-pit ground spawn stays entirely outside takeoff lane")
				check(spec.bounds.y+shape.end.x <= float(game.contract.geometry.pit.takeoff_clear_x[0]),
					"Runner containment preserves the full takeoff lane")
			for solid: Rect2 in game.actor_solids():
				check(not Rect2(spec.feet+shape.position,shape.size).intersects(solid),"Actor spawn does not embed in terrain")
				if is_equal_approx(spec.feet.y,solid.position.y) and spec.feet.x >= solid.position.x and spec.feet.x <= solid.end.x:
					supported = true
			check(supported,"Ground creature has a supported spawn")
	# Exercise actual admission over the section, retaining all live actors to stress role caps.
	for x in range(100,2770,40):
		game.player = Vector2(x,394)
		game.camera_x = clampf(x-320,0,1920)
		for repeat in range(4):
			game.trial_clock += 1
			game.issue_event()
		var shooters := 0
		var flyers := 0
		var active_ids := {}
		for actor in game.actors:
			check(not active_ids.has(actor.event_id),"A finite actor is never issued twice")
			active_ids[actor.event_id] = true
			if actor.role == "perched_shooter": shooters += 1
			if actor.role == "aggressive_flyer": flyers += 1
		check(shooters <= game.tuning.shooter_cap and flyers <= game.tuning.flyer_cap,"Live role limits survive section scheduling")
		check(game.live_population() <= game.tuning.total_actors_max,"Total population remains bounded")
	if game.difficulty == "normal":
		check(game.tuning.shooter_cap == 2 and game.tuning.flyer_cap == 2 and is_equal_approx(game.tuning.recovery_seconds,2.2),
			"Normal retains approved shooter/flyer limits and recovery")
	game.reset_observation()
	for state in game.ledger.values(): check(state == "pending","Retry restores the complete finite roster")
	check(game.run_seed == 197,"Retry preserves selected seed")
	check(game.actors.is_empty() and game.hostile_shots.is_empty() and game.swarms.actors.is_empty(),"Retry clears live encounters")

func check_climb_pursuit(game: Node2D) -> void:
	for id in ["b-run4","c-run2"]:
		game.reset_observation()
		for key in game.ledger: game.ledger[key] = "retired"
		game.ledger[id] = "pending"
		game.player = Vector2(1660 if id == "b-run4" else 2027,274)
		game.camera_x = 1340 if id == "b-run4" else 1707
		game.grounded = true
		game.issue_event()
		check(game.actors.size() == 1,"Late climb runner admits from each side")
		if game.actors.is_empty(): continue
		var actor: Dictionary = game.actors[0]
		game.player = Vector2(2027,274)
		var landed := false
		for tick in range(1800):
			game.step_trial_actors(1.0/120)
			if actor.get("grounded",false) and is_equal_approx(actor.feet.y,320):
				landed = true
				break
		check(landed,"Runner reaches relocated summit from "+id)

func check_pacing(game: Node2D) -> void:
	game.reset_observation()
	for id in game.ledger: game.ledger[id] = "retired"
	game.ledger["a-shot1"] = "pending"
	game.player = Vector2(500,394)
	game.camera_x = 180
	game.issue_event()
	check(game.actors.size() == 1,"Pacing fixture admits the authored pre-pit shooter")
	if game.actors.is_empty(): return
	check(is_equal_approx(game.next_warning-game.trial_clock,0.45),"Admissions retain authored spacing")
	var actor: Dictionary = game.actors[0]
	game.MonsterEntry.advance(actor.entry,actor.entry.duration)
	actor.feet = actor.entry.home
	actor.active = true
	game.player.x = 750
	game.ledger["a-run4"] = "pending"
	game.trial_clock = 2
	game.issue_event()
	check(game.ledger["a-run4"] == "pending","Approach dip defers new arrivals")
	game.step_three_shooter(actor,0.6)
	check(not actor.winding and game.hostile_shots.is_empty(),"Approach dip prevents a fresh shooter charge")
	game.player.x = 690
	game.step_three_shooter(actor,0.01)
	check(actor.winding,"Shooter can charge outside the dip")
	game.player.x = 750
	game.step_three_shooter(actor,0.6)
	check(not game.hostile_shots.is_empty(),"Already telegraphed attack completes during dip")
	var bolts: int = game.hostile_shots.size()
	game.player.x = 1250
	game.issue_event()
	check(game.in_pressure_dip() and game.hostile_shots.size() == bolts,"Landing dip preserves existing bolts")

func check_crossing(game: Node2D) -> void:
	var pit: Vector2 = game.trial_level.pit
	game.player = Vector2(pit.x-50,394)
	game.grounded = true
	check(game.crossing_reserved(),"Early crossing reserves attacks")
	check(not game.admitted_trajectory(Vector2(pit.x-200,415),Vector2.RIGHT),"No bolt born into committed crossing")
	game.player.x = pit.y+200
	check(not game.crossing_reserved(),"Crossing reservation releases after safe landing")
	check(game.admitted_trajectory(Vector2(pit.y+400,415),Vector2.LEFT),"Forward combat resumes after early pit")
	var actor := {"home":Vector2(pit.x-250,190),"feet":Vector2(pit.x-250,190)}
	game.move_flyer_clear(actor,Vector2(pit.x-249,190))
	check(actor.get("post_pit_pursuit",false),"Surviving flyer unlocks pursuit after early pit")
	game.player.x = pit.x-40
	check(game.crossing_reserved() and actor.post_pit_pursuit,"Backtracking preserves pursuit latch and restores crossing protection")

func checks() -> void:
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game := prepare(hero,mode)
			check(game.employee.id == game.Crew.EMPLOYEES[hero].id and game.difficulty == mode and game.run_seed == 197,
				"Launcher-selected hero, difficulty and seed reach new subclass")
			check_geometry(game)
			check_encounters(game)
			if mode == "normal": check_climb_pursuit(game)
			check_pacing(game)
			check_crossing(game)
			root.remove_child(game)
			game.free()
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://levels/first-call/three-screen-trial.json"))
	check(is_equal_approx(float(baseline.movement.pit_overlap_fatal_fraction),0.65),
		"Baseline keeps its sixty-five-percent threshold")
	check(int(baseline.world.finish_x) == 2770 and int(baseline.geometry.pit.opening_x[0]) == 2240
		and int(baseline.geometry.pit.opening_x[1]) == 2360,
		"Original trial retains its authored late pit and finish")
	print("Section 1.2: %d checks, %d failures" % [checks_run,failures.size()])
	quit(0 if failures.is_empty() else 1)
