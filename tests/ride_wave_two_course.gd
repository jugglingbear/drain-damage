extends "res://tests/ride_continuous_course.gd"
## Wave 2 and seam witnesses use actual state; synthetic starts are not game checkpoints.

static func full_route_plan(model: RefCounted, mode: String) -> Dictionary:
	var plan := route_plan(model,mode)
	var shift: float = plan.shift
	var points := [
		[14320,395],[15180,265],[16650,395],[17700,265],
		[18200,395],[18760,265],[19860,330],[20600,265],[21600,395],
		[22700,280],[23392,380],[23872,280],[24352,380],[24832,280],[25312,380],
		[28450,265],[29600,395],[30200,270],[32100,395],[32700,265],[33750,395],
		[34900,330],[36780,395],[37700,265],[41400,265]]
	if mode != "easy":
		for point in points:
			if point[0] == 18760: point[0] = 18670
			if point[0] == 19860: point[1] = 265
		for x in [15627,26087,28557,36917,41527]: plan.jumps.append(float(x)+shift)
	if mode == "hard": plan.jumps.append(32027.0+shift)
	for point in points: plan.points.append([float(point[0])+shift,point[1]])
	for x in [14957,16391,17477,20327,21377,22377,23392,23872,24352,24832,25312,
		27627,29241,33577,34477,37477,39227,41127]:
		plan.jumps.append(float(x)+shift)
	for gap: Dictionary in model.course.obstacles:
		if not str(gap.id).begins_with("w2-drop-"): continue
		if float(gap.depth) >= 200:
			plan.jumps.append(float(gap.x)-150)
			continue
		var bank := 395 if float(gap.y) <= 330 else 265
		var turn := float(gap.x)-float(gap.width)*0.5-330
		if gap.id == "w2-drop-3": turn = 38200+shift
		if gap.id == "w2-drop-4":
			bank = 330
			turn = float(gap.x)-330
		plan.points.append([turn,bank])
	plan.points.sort_custom(func(a,b): return a[0] < b[0])
	plan.jumps.sort()
	plan.next_jump = 0
	while plan.next_jump < plan.jumps.size() and plan.jumps[plan.next_jump] < model.position.x+model.encounter_scroll:
		plan.next_jump += 1
	return plan

func run_extension(hero: String, mode: String, seed_value: int, hz := 60, anchor := 300.0,
		offset := 0.0, start := 0.0, drift := 0.0) -> void:
	var host := SeededHost.new()
	host.employee.id = hero
	host.difficulty = mode
	host.run_seed = seed_value
	var model := Model.new()
	model.continuous = true
	model.begin(host)
	var shift := float(model.definition.wave_one_finish)-WAVE_ONE_FINISH
	if start > 0:
		model.encounter_scroll = start+shift-300
		model.clock = model.encounter_scroll/model.scroll_speed
		model.encounter_clock = model.clock
	model.position.x = anchor
	var plan := full_route_plan(model,mode)
	var prior_scroll: float = model.encounter_scroll
	var seams := []
	var next_seam := 14300.0+shift
	while next_seam <= prior_scroll+300: next_seam += 4000
	for frame in range(85*hz):
		var x: float = model.encounter_scroll+model.position.x
		# Deliberate diagonal travel outside precision basin and launch/catch envelopes.
		var horizontal := drift if x > 14400+shift and not (x > 22700+shift and x < 26000+shift
			or x > 34900+shift and x < 36800+shift) else 0.0
		var controls := route_controls(model,plan,1.0/hz,offset,horizontal)
		model.tick(host,1.0/hz,controls.steering,controls.jump)
		if model.encounter_scroll < prior_scroll:
			failures.append({"reason":"scroll reset","seed":seed_value})
		prior_scroll = model.encounter_scroll
		if prior_scroll+300 >= next_seam:
			seams.append({"x":next_seam,"bank":model.position.y,"velocity":str(model.steering_velocity),
				"jump_age":model.jump_age,"cooldown":model.cooldown})
			next_seam += 4000
		if model.complete or host.health < 5: break
	var record := {"hero":hero,"mode":mode,"seed":seed_value,"hz":hz,"anchor":anchor,
		"offset":offset,"start":start,"drift":drift,"x":model.encounter_scroll+model.position.x,
		"event":model.last_event,"seams":seams}
	if not model.complete or host.health != 5 or host.lives != 3 or host.life_state != "alive":
		failures.append(record)
		print("WAVE_TWO_FAILURE ",JSON.stringify(record))
	routes += 1
	host.free()

func check_replay_and_demands(seed_value: int) -> void:
	var host := SeededHost.new()
	host.run_seed = seed_value
	var model := Model.new()
	model.continuous = true
	model.begin(host)
	var original := JSON.stringify(model.course)
	model.tick(host,0.5,Vector2(1,1),true)
	host.paused = true
	var frozen := [model.clock,model.encounter_scroll,model.position,model.jump_age,model.steering_velocity]
	model.tick(host,1.0,Vector2(-1,-1),true)
	if frozen != [model.clock,model.encounter_scroll,model.position,model.jump_age,model.steering_velocity]:
		failures.append({"reason":"pause advanced route","seed":seed_value})
	host.paused = false
	model.begin(host)
	if JSON.stringify(model.course) != original or model.position != Vector2(300,330) \
		or model.encounter_scroll != 0 or model.steering_velocity != Vector2.ZERO:
		failures.append({"reason":"retry changed layout or start","seed":seed_value})
	host.free()
	for start in [14300.0,18300.0,22300.0,26300.0,30300.0,34300.0,38300.0]:
		for bank in [265.0,330.0,395.0]:
			host = SeededHost.new()
			host.run_seed = seed_value
			model = Model.new()
			model.continuous = true
			model.begin(host)
			model.encounter_scroll = start-300
			model.clock = model.encounter_scroll/model.scroll_speed
			model.encounter_clock = model.clock
			model.position.y = bank
			var plan := full_route_plan(model,"normal")
			for frame in 480:
				var controls := route_controls(model,plan,1.0/60)
				# Even correctly timed jumps must not replace the authored bank changes.
				model.tick(host,1.0/60,Vector2.ZERO,controls.jump)
				if host.health < 5 or model.encounter_scroll+300 >= start+4000: break
			if host.health == 5:
				failures.append({"reason":"fixed-bank bypass","start":start,"bank":bank,"seed":seed_value})
			host.free()

func checks() -> void:
	# Cover both mirrors and each follow-up count without multiplying the legacy matrix.
	for seed_value in [0,7,1,9,8,2]:
		check_replay_and_demands(seed_value)
		for hero in ["sean","tony"]:
			for mode in ["easy","normal","hard"]:
				run_extension(hero,mode,seed_value)
			for hz in [30,60,120]:
				for anchor in [180.0,300.0,650.0]:
					for offset in [-0.05,0.05]:
						run_extension(hero,"normal",seed_value,hz,anchor,offset,14000)
				for drift in [-0.1,0.1]:
					run_extension(hero,"hard",seed_value,hz,300,0,14000,drift)
	print(JSON.stringify({"routes":routes,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
