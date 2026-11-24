extends SceneTree
## Composed input witnesses validate real physics; arbitrary steering is not promised safe.
const Model = preload("res://scripts/ride_showcase_model.gd")
const Host = preload("res://tests/ride_showcase_course.gd").Host
class SeededHost extends Host:
	var run_seed := 42

var failures: Array[Dictionary] = []
var routes := 0

func _initialize() -> void: call_deferred("checks")

static func bank_input(model: RefCounted, target: float, dt: float) -> float:
	var error := target-float(model.position.y)
	var speed := float(model.steering_velocity.y)
	var stopping: float = speed*absf(speed)*float(model.steering_config.steering.coast_seconds)/(2*model.bank_speed)
	# Release before arrival instead of assuming velocity disappears on the target frame.
	return clampf((error-stopping)/(model.bank_speed*maxf(dt,0.06)),-1,1)

static func predicted_world_x(model: RefCounted, steering: Vector2, dt: float) -> float:
	var input := steering.limit_length()
	var horizontal := Model.steer_axis(model.steering_velocity.x,input.x,model.x_speed,dt)
	return model.encounter_scroll+model.scroll_speed*dt+clampf(model.position.x+horizontal.x,180,650)

static func route_plan(model: RefCounted, mode: String, cap_drift := 0.0, strainer_jump := false) -> Dictionary:
	var spacing: float = JSON.parse_string(FileAccess.get_file_as_string(
		"res://levels/level-two-ride-continuous.json")).spacing[mode]
	var shift := 7*(spacing-410)
	var jumps := [1450+1.5*spacing-123,1450+4.5*spacing-159,5077.0+shift,7390.0+shift-cap_drift*200,7800.0+shift+maxf(0,cap_drift)*200,9407+shift,11342+shift]

	var points := [[750,395]]
	var banks := [395,265,265,395,265,395,395,265]
	var turn_offsets := [0,30,100,46,30,30,100,46]
	for i in range(1,banks.size()):
		points.append([1450+(i-1)*spacing+turn_offsets[i],banks[i]])
	points.append_array([[1450+7*spacing+120,330],[6900+shift,265],[7390+shift,395],[7800+shift,265]])
	var last_gap_end := 0.0
	for gap: Dictionary in model.course.obstacles:
		if not gap.get("station",false): continue
		last_gap_end = maxf(last_gap_end,float(gap.x)+float(gap.width)*0.5)
		if float(gap.depth) >= 200:
			jumps.append(float(gap.x)-150)
			continue
		var bank := 395 if gap.y <= 330 else 265
		var turn := float(gap.x)-float(gap.width)*0.5-330
		if gap.id == "drop-1-1":
			bank = 330
			turn = float(gap.x)-330
		elif gap.id == "drop-1-2":
			# Leave the previous short opening diagonally; do not turn into its occupied bank early.
			turn = 12555+shift
		if strainer_jump and gap.id == "drop-0-0":
			bank = int(gap.y)
			jumps.append(float(gap.x)-168)
		points.append([turn,bank])
	points.append([last_gap_end+20,265])
	jumps.sort()
	var next_jump := 0
	while next_jump < jumps.size() and jumps[next_jump] < model.position.x+model.encounter_scroll:
		next_jump += 1
	return {"shift":shift,"jumps":jumps,"points":points,"next_jump":next_jump}

static func route_controls(model: RefCounted, plan: Dictionary, dt: float, offset := 0.0,
		horizontal := 0.0) -> Dictionary:
	var target := 330.0
	var next_x: float = model.encounter_scroll+model.scroll_speed*dt+model.position.x+model.steering_velocity.x*dt
	for point in plan.points:
		if next_x >= float(point[0])+offset*model.scroll_speed: target = point[1]
	var steering := Vector2(horizontal,bank_input(model,target,dt))
	next_x = predicted_world_x(model,steering,dt)
	var jump: bool = plan.next_jump < plan.jumps.size() and next_x >= plan.jumps[plan.next_jump]+offset*model.scroll_speed
	if jump: plan.next_jump += 1
	return {"steering":steering,"jump":jump}

func run_route(hero: String, mode: String, anchor: float, hz: int, offset: float, mixed: bool,
		retry := 0, strainer_jump := false, cap_drift := 0.0, seed_value := 42, station_drift := 0.0) -> void:
	var host := SeededHost.new()
	host.run_seed = seed_value
	host.employee.id = hero
	host.difficulty = mode
	var model := Model.new()
	model.continuous = true
	model.begin(host,retry)
	model.position.x = anchor
	var plan := route_plan(model,mode,cap_drift,strainer_jump)
	var shift: float = plan.shift
	var start_clock: float = model.clock
	var initial_scroll: float = model.encounter_scroll
	var previous_scroll: float = model.encounter_scroll
	var horizontal_frames := 0
	for frame in range(32*hz):
		var dt := 1.0/hz
		var x: float = model.position.x+model.encounter_scroll
		# Reposition through the approach and connectors; settle before precision cap landings.
		var horizontal := 0.0
		if mixed and (x < 1200 or (x > 5600+shift and x < 6800+shift) or x > 13600+shift):
			horizontal = 1.0 if int(model.clock/0.7)%2 == 0 else -1.0
			horizontal_frames += 1
		if x > 7000+shift and x < 8500+shift: horizontal = cap_drift
		if x > 9600+shift and x < 13600+shift: horizontal = station_drift
		var controls := route_controls(model,plan,dt,offset,horizontal)
		model.tick(host,dt,controls.steering,controls.jump)
		if model.encounter_scroll < previous_scroll:
			failures.append({"reason":"scroll reset","mode":mode})
		previous_scroll = model.encounter_scroll
		if model.complete or host.health < 5: break
	var record := {"hero":hero,"mode":mode,"anchor":anchor,"hz":hz,"offset":offset,"mixed":mixed,
		"retry":retry,"station_drift":station_drift,"seed":seed_value,"cap_drift":cap_drift,"strainer_jump":strainer_jump,"x":model.position.x+model.encounter_scroll,
		"event":model.last_event}
	if not model.complete or host.health != 5 or host.lives != 3 or host.life_state != "alive":
		failures.append(record)
		print("ROUTE_FAILURE ",JSON.stringify(record))
	elif mixed and horizontal_frames == 0:
		record.reason = "mixed route did not exercise horizontal input"
		failures.append(record)
	else:
		var expected: float = (float(model.definition.world_finish)-300-initial_scroll)/560
		if absf(model.clock-start_clock-expected) > 1.0/hz+0.0001:
			record.reason = "unexpected finish timing"
			failures.append(record)
	routes += 1
	if routes%100 == 0: print("ROUTE_PROGRESS ",routes," failures ",failures.size())
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
	for seed_value in 24:
		run_route("sean","normal",300,60,0,false,2,seed_value%2 == 0,0,seed_value)
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
	check_station_drift()
	print(JSON.stringify({"routes":routes,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func check_station_drift() -> void:
	var variants := {}
	for seed_value in 64:
		var host := SeededHost.new()
		host.run_seed = seed_value
		var model := Model.new()
		model.continuous = true
		model.begin(host)
		for gap: Dictionary in model.course.obstacles:
			if gap.id == "drop-0-0" and not variants.has(gap.y): variants[gap.y] = seed_value
		host.free()
		if variants.size() == 2: break
	for seed_value: int in variants.values():
		for hero in ["tony","sean"]:
			for mode in ["easy","normal","hard"]:
				for anchor in [180.0,300.0,650.0]:
					for hz in [30,60,120]:
						for drift in [-0.1,0.1]:
							for offset in [-0.025,0.0,0.025]:
								run_route(hero,mode,anchor,hz,offset,false,2,false,0,seed_value,drift)
