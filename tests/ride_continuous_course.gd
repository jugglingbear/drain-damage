extends SceneTree
## Composed input witnesses validate real physics; arbitrary steering is not promised safe.
const Model = preload("res://scripts/ride_showcase_model.gd")
const Host = preload("res://tests/ride_showcase_course.gd").Host
var failures: Array[Dictionary] = []
var routes := 0

func _initialize() -> void: call_deferred("checks")

func run_route(hero: String, mode: String, anchor: float, hz: int, offset: float, mixed: bool,
		retry := 0, strainer_jump := false, cap_drift := 0.0) -> void:
	var host := Host.new()
	host.employee.id = hero
	host.difficulty = mode
	var model := Model.new()
	model.continuous = true
	model.begin(host,retry)
	model.position.x = anchor
	var spacing: float = JSON.parse_string(FileAccess.get_file_as_string(
		"res://levels/level-two-ride-continuous.json")).spacing[mode]
	var shift := 2*(spacing-650)
	var jumps := [5077.0+shift,7422.0+shift,7872.0+shift]
	if strainer_jump: jumps.append(10432.0+shift)
	var points := [[2200.0,380.0],[2740.0,280.0],[2740.0+spacing,400.0],
		[4300.0+shift,330.0],[9900.0+shift,330.0 if strainer_jump else 270.0],[11000.0+shift,270.0]]
	var next_jump := 0
	while next_jump < jumps.size() and jumps[next_jump] < model.position.x+model.encounter_scroll:
		next_jump += 1
	var start_clock: float = model.clock
	var initial_scroll: float = model.encounter_scroll
	var previous_scroll: float = model.encounter_scroll
	var horizontal_frames := 0
	for frame in range(32*hz):
		var dt := 1.0/hz
		var x: float = model.position.x+model.encounter_scroll
		# Reposition through the approach and connectors; settle before precision cap landings.
		var horizontal := 0.0
		if mixed and (x < 4700+shift or (x > 5600+shift and x < 6800+shift) or x > 11000+shift):
			horizontal = 1.0 if int(model.clock/0.7)%2 == 0 else -1.0
			horizontal_frames += 1
		if x > 7000+shift and x < 8500+shift: horizontal = cap_drift
		var target := 330.0
		var next_x: float = model.encounter_scroll+560*dt+clampf(model.position.x+horizontal*400*dt,180,650)
		for point in points:
			if next_x >= float(point[0])+offset*560: target = point[1]
		var jump: bool = next_jump < jumps.size() and next_x >= jumps[next_jump]+offset*560
		if jump: next_jump += 1
		model.tick(host,dt,Vector2(horizontal,clampf((target-model.position.y)/(350*dt),-1,1)),jump)
		if model.encounter_scroll < previous_scroll:
			failures.append({"reason":"scroll reset","mode":mode})
		previous_scroll = model.encounter_scroll
		if model.complete or host.health < 5: break
	var record := {"hero":hero,"mode":mode,"anchor":anchor,"hz":hz,"offset":offset,"mixed":mixed,
		"retry":retry,"cap_drift":cap_drift,"strainer_jump":strainer_jump,"x":model.position.x+model.encounter_scroll,
		"event":model.last_event}
	if not model.complete or host.health != 5 or host.lives != 3 or host.life_state != "alive":
		failures.append(record)
	elif mixed and horizontal_frames == 0:
		record.reason = "mixed route did not exercise horizontal input"
		failures.append(record)
	else:
		var expected: float = (float(model.definition.world_finish)-300-initial_scroll)/560
		if absf(model.clock-start_clock-expected) > 1.0/hz+0.0001:
			record.reason = "unexpected finish timing"
			failures.append(record)
	routes += 1
	host.free()

func check_demands() -> void:
	for mode in ["easy","normal","hard"]:
		for anchor in [180.0,300.0,650.0]:
			for bank in [270.0,330.0,390.0]:
				for hopping in [false,true]:
					var host := Host.new()
					host.difficulty = mode
					var model := Model.new()
					model.continuous = true
					model.begin(host)
					model.position = Vector2(anchor,bank)
					for frame in range(12*60):
						model.tick(host,1.0/60,Vector2.ZERO,hopping and model.jump_age < 0 and model.cooldown <= 0)
						if host.health < 5 or model.complete: break
					if host.health == 5:
						failures.append({"reason":"straight/repeated-jump bypass","mode":mode,
							"anchor":anchor,"bank":bank,"hopping":hopping})
					host.free()

func check_warning_budget() -> void:
	for mode in ["easy","normal","hard"]:
		var host := Host.new()
		host.difficulty = mode
		var model := Model.new()
		model.continuous = true
		model.begin(host)
		for obstacle: Dictionary in model.course.obstacles:
			if obstacle.instance_id != "slice-strainer": continue
			# Front anchor is the earliest possible arrival even with sustained forward input.
			var first_contact := (float(obstacle.x)-float(obstacle.width)*0.5-45-650)/560
			var lead := first_contact-float(obstacle.warning_at)
			if lead < 1.5 or float(obstacle.activates_at) > first_contact:
				failures.append({"reason":"strainer warning/activation budget","mode":mode,"lead":lead})
			print("WARNING_BUDGET ",mode," ",lead)
		host.free()

func checks() -> void:
	check_demands()
	check_warning_budget()
	for hero in ["tony","sean"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					for offset in [-0.05,0.0,0.05]:
						run_route(hero,mode,anchor,hz,offset,false)
					for offset in [-0.025,0.0,0.025]:
						run_route(hero,mode,anchor,hz,offset,true)
			for retry in [1,2]:
				run_route(hero,mode,300,60,0,false,retry)
			for hz in [30,60,120]:
				run_route(hero,mode,650,hz,0,false,0,true)
				for drift in [-0.1,0.1]: run_route(hero,mode,300,hz,0,false,1,false,drift)
	print(JSON.stringify({"routes":routes,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
