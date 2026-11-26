extends SceneTree
const Compiler = preload("res://scripts/ride_wave_three.gd")
const Model = preload("res://scripts/ride_showcase_model.gd")
class Host extends Node2D:
	var employee := {"id":"sean"}
	var difficulty := "normal"
	var health := 5
	var lives := 3
	var invulnerable := 0.0
	var paused := false
	var life_state := "alive"
	var won := false
	func hurt_player(_fatal_fall := false) -> void:
		if invulnerable > 0 or life_state != "alive": return
		health -= 1
		invulnerable = 1.5
		if health <= 0:
			lives -= 1
			life_state = "dead"

static func bank_input(model: RefCounted, target: float, dt: float) -> float:
	var speed := float(model.steering_velocity.y)
	var stopping: float = speed*absf(speed)*float(model.steering_config.steering.coast_seconds)/(2*model.bank_speed)
	return clampf((target-float(model.position.y)-stopping)/(model.bank_speed*maxf(dt,0.06)),-1,1)

static func predicted_world_x(model: RefCounted, steering: Vector2, dt: float) -> float:
	var input := steering.limit_length()
	var horizontal := Model.steer_axis(model.steering_velocity.x,input.x,model.x_speed,dt)
	return model.encounter_scroll+model.scroll_speed*dt+clampf(model.position.x+horizontal.x,180,650)

var failures: Array = []
var cases := 0

func _initialize() -> void: call_deferred("checks")

static func route_plan(model: RefCounted) -> Dictionary:
	var origin := float(model.definition.retry_world_x[0])-300
	var points := [[300,395],[1200,265],[2350,330],[3150,265],[4650,330],[5150,395],
		[6100,265],[6680,330],[7800,395],[8900,330],[10000,280],[15100,395],
		[15950,265],[16500,330],[17400,270],[18800,330],[19700,330],
		[20500,395],[20930,265],[21900,330],[23150,395],[24000,330],[25050,395],[26000,330],[26500,265],[27000,395],
		[27850,330],[28300,265],[29050,330],[29500,380],[33450,395],
		[34150,330],[34600,265],[35100,395],[35950,330],[36400,265],[36900,330]]
	var jumps := [7350,22850,24750,37550]
	var flanges := []
	for obstacle: Dictionary in model.course.obstacles:
		if obstacle.kind == "low_barrier": flanges.append(float(obstacle.x)-origin)
	flanges.sort()
	var previous := -INF
	for x: float in flanges:
		if x-previous > 100:
			jumps.append(x-123)
			previous = x
	var chain := []
	var extension_chain := []
	for obstacle: Dictionary in model.course.obstacles:
		if obstacle.kind == "deck" and str(obstacle.id).begins_with("w3-chain-"): chain.append(obstacle)
		if obstacle.kind == "deck" and str(obstacle.id).begins_with("w3-extension-chain-"): extension_chain.append(obstacle)
	chain.sort_custom(func(a,b):return a.x < b.x)
	extension_chain.sort_custom(func(a,b):return a.x < b.x)
	for i in range(chain.size()-1):
		var trigger := float(chain[i].x)-origin+72
		jumps.append(trigger)
		points.append([trigger,float(chain[i+1].y)])
	for i in range(extension_chain.size()-1):
		var trigger := float(extension_chain[i].x)-origin+72
		jumps.append(trigger)
		points.append([trigger,float(extension_chain[i+1].y)])
	for point in points: point[0] += origin
	for i in jumps.size(): jumps[i] += origin
	points.sort_custom(func(a,b):return a[0] < b[0])
	jumps.sort()
	var next_jump := 0
	while next_jump < jumps.size() and jumps[next_jump] < model.encounter_scroll+model.position.x:
		next_jump += 1
	return {"origin":origin,"points":points,"jumps":jumps,"next_jump":next_jump,"chain":chain,"extension_chain":extension_chain}

static func controls(model: RefCounted, plan: Dictionary, dt: float, offset := 0.0, horizontal := 0.0) -> Dictionary:
	var x := predicted_world_x(model,Vector2(horizontal,0),dt)
	var target := 330.0
	for point in plan.points:
		if x >= float(point[0])+offset*model.scroll_speed: target = point[1]
	if model.ramp_active: target = 330
	if model.boosted: target = 270
	var input := Vector2(horizontal,bank_input(model,target,dt))
	x = predicted_world_x(model,input,dt)
	var jump: bool = plan.next_jump < plan.jumps.size() and x >= plan.jumps[plan.next_jump]+offset*model.scroll_speed
	if jump: plan.next_jump += 1
	return {"steering":input,"jump":jump}

static func create_model(host: Node2D, origin := 0.0) -> RefCounted:
	var model := Model.new()
	model.definition = Compiler.build(JSON.parse_string(FileAccess.get_file_as_string(Model.SOURCE)),origin,true,host.difficulty)
	# Exercise the compiler's exact geometry without asking begin() to rebuild the prior course.
	model.definition.erase("continuous")
	model.begin(host)
	model.continuous = true
	model.encounter_scroll = origin
	model.clock = origin/model.scroll_speed
	model.encounter_clock = model.clock
	return model

func run_route(hero: String, mode: String, hz: int, anchor: float, offset := 0.0) -> void:
	var host := Host.new()
	host.employee.id = hero
	host.difficulty = mode
	var model := create_model(host)
	model.position.x = anchor
	var plan := route_plan(model)
	var chain_jumps := 0
	var chain_landings := 0
	var ordered_landings := true
	var extension_jumps := 0
	var extension_landings := 0
	for frame in hz*75:
		var x: float = model.encounter_scroll+model.position.x
		var before_jump: int = model.events.get("jump",0)
		var before_land: int = model.events.get("landed",0)
		var action := controls(model,plan,1.0/hz,offset)
		model.tick(host,1.0/hz,action.steering,action.jump)
		if x > 10400 and x < 15000:
			chain_jumps += int(model.events.get("jump",0))-before_jump
			if int(model.events.get("landed",0)) > before_land:
				chain_landings += 1
				if chain_landings >= plan.chain.size():
					ordered_landings = false
				else:
					var deck: Dictionary = plan.chain[chain_landings]
					ordered_landings = ordered_landings and absf(model.encounter_scroll+model.position.x-float(deck.x)) <= float(deck.width)*0.5 \
						and absf(model.position.y-float(deck.y)) <= float(deck.depth)*0.5
		if x > 30200 and x < 33400:
			extension_jumps += int(model.events.get("jump",0))-before_jump
			if int(model.events.get("landed",0)) > before_land:
				extension_landings += 1
				if extension_landings >= plan.extension_chain.size():
					ordered_landings = false
				else:
					var deck: Dictionary = plan.extension_chain[extension_landings]
					ordered_landings = ordered_landings and absf(model.encounter_scroll+model.position.x-float(deck.x)) <= float(deck.width)*0.5 \
						and absf(model.position.y-float(deck.y)) <= float(deck.depth)*0.5
		if model.complete or host.health < 5: break
	if not model.complete or model.jump_age >= 0 or model.ramp_active or model.encounter_scroll+model.position.x-55 <= 37770 or host.health != 5 or chain_jumps != 9 or chain_landings != 9 or extension_jumps != 6 or extension_landings != 6 or not ordered_landings:
		var record := {"hero":hero,"mode":mode,"hz":hz,"anchor":anchor,"offset":offset,
			"x":model.encounter_scroll+model.position.x,"airborne":model.jump_age >= 0,"event":model.last_event,
			"jumps":chain_jumps,"landings":chain_landings,"extension_jumps":extension_jumps,
			"extension_landings":extension_landings,"ordered":ordered_landings}
		failures.append(record)
		print("WAVE3_FAILURE ",JSON.stringify(record))
	cases += 1
	host.free()

func run_chain_case(hero: String, mode: String, hz: int, missed := -1, fixed_bank := -1.0,
		drift := 0.0, offset := 0.0, extension := false) -> void:
	var host := Host.new()
	host.employee.id = hero
	host.difficulty = mode
	var model := create_model(host)
	model.encounter_scroll = 29400 if extension else 9500
	model.clock = model.encounter_scroll/model.scroll_speed
	model.encounter_clock = model.clock
	model.position.y = fixed_bank if fixed_bank >= 0 else 265
	var plan := route_plan(model)
	var decks: Array = plan.extension_chain if extension else plan.chain
	var entry := 30200.0 if extension else 10400.0
	var exit_x := 33400.0 if extension else 15000.0
	var required := decks.size()-1
	if missed >= 0: plan.jumps.erase(float(decks[missed].x)+72)
	var jumps := 0
	var landings := 0
	var ordered := true
	for frame in hz*12:
		var before_jump: int = model.events.get("jump",0)
		var before_land: int = model.events.get("landed",0)
		var action := controls(model,plan,1.0/hz,offset,drift)
		if fixed_bank >= 0: action.steering.y = 0
		model.tick(host,1.0/hz,action.steering,action.jump)
		if model.encounter_scroll+model.position.x > entry:
			jumps += int(model.events.get("jump",0))-before_jump
		if model.events.get("landed",0) > before_land and model.encounter_scroll+model.position.x > entry and model.encounter_scroll+model.position.x < exit_x:
			landings += 1
			if landings >= decks.size():
				ordered = false
			else:
				var deck: Dictionary = decks[landings]
				ordered = ordered and absf(model.encounter_scroll+model.position.x-float(deck.x)) <= float(deck.width)*0.5 \
					and absf(model.position.y-float(deck.y)) <= float(deck.depth)*0.5
		if host.health < 5 or model.encounter_scroll+model.position.x >= exit_x+200: break
	var negative := missed >= 0 or fixed_bank >= 0
	var failed := host.health == 5 if negative else host.health != 5 or jumps != required or landings != required or not ordered
	if failed:
		var record := {"reason":"extension chain" if extension else "chain", "hero":hero,"mode":mode,"hz":hz,"missed":missed,
			"fixed_bank":fixed_bank,"drift":drift,"offset":offset,"jumps":jumps,"landings":landings,
			"ordered":ordered,"event":model.last_event}
		failures.append(record)
		print("WAVE3_CHAIN_FAILURE ",JSON.stringify(record))
	cases += 1
	host.free()

func run_entry(hz: int, bank: float, offset: float) -> void:
	var host := Host.new()
	var model := create_model(host)
	model.position = Vector2(650,bank)
	var plan := route_plan(model)
	for frame in hz*4:
		var action := controls(model,plan,1.0/hz,offset)
		if model.clock < 0.15: action.steering = Vector2.ZERO
		model.tick(host,1.0/hz,action.steering,action.jump)
		if host.health < 5 or model.encounter_scroll+model.position.x > 1800: break
	if host.health < 5: failures.append({"reason":"entry reaction","hz":hz,"bank":bank,"offset":offset,"event":model.last_event})
	cases += 1
	host.free()

func checks() -> void:
	if "--extension-middle" in OS.get_cmdline_user_args():
		check_extension_middle()
		return
	if "--extension" in OS.get_cmdline_user_args():
		check_extension()
		return
	if "--pacing" in OS.get_cmdline_user_args():
		check_pacing()
		return
	if "--middle-timing" in OS.get_cmdline_user_args():
		check_middle_timing()
		return
	if "--middle-windows" in OS.get_cmdline_user_args():
		check_middle_windows()
		return
	if "--gates" in OS.get_cmdline_user_args():
		check_gates()
		return
	if "--focused" in OS.get_cmdline_user_args():
		check_chain_and_entry()
		return
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					for offset in [-0.05,0.0,0.05]: run_route(hero,mode,hz,anchor,offset)
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func check_chain_and_entry() -> void:
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for hz in [30,60,120]:
				for missed in 9: run_chain_case(hero,mode,hz,missed)
				for bank in [265.0,330.0,395.0]: run_chain_case(hero,mode,hz,-1,bank)
				for drift in [-0.1,0.1]:
					for offset in [-0.025,0.0,0.025]: run_chain_case(hero,mode,hz,-1,-1,drift,offset)
	for hz in [30,60,120]:
		for bank in [260.0,330.0,400.0]:
			for offset in [-0.05,0.0,0.05]: run_entry(hz,bank,offset)
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func run_gate_case(mode: String, hz: int, center: float, bank: float, steer: bool, jump: bool) -> void:
	var host := Host.new()
	host.difficulty = mode
	var model := create_model(host)
	# Local counterfactuals isolate each gate; full routes prove approach-state composition.
	model.course.obstacles = model.course.obstacles.filter(func(obstacle):
		return str(obstacle.id).begins_with("w3-middle-%d-" % center))
	model.encounter_scroll = center-650
	model.clock = model.encounter_scroll/model.scroll_speed
	model.encounter_clock = model.clock
	model.position.y = bank
	var plan := route_plan(model)
	for frame in hz*2:
		var action := controls(model,plan,1.0/hz)
		if not steer: action.steering.y = 0
		if not jump: action.jump = false
		model.tick(host,1.0/hz,action.steering,action.jump)
		if host.health < 5 or model.encounter_scroll+model.position.x > center+100: break
	var expected_success := steer and jump
	var hit_gate := str(model.last_event.get("obstacle_id","")).begins_with("w3-middle-%d-" % center)
	if (host.health == 5) != expected_success or (not expected_success and not hit_gate):
		failures.append({"reason":"gate", "mode":mode,"hz":hz,"center":center,"bank":bank,
			"steer":steer,"jump":jump,"event":model.last_event})
	cases += 1
	host.free()

func check_gates() -> void:
	for mode in ["easy","normal","hard"]:
		for hz in [30,60,120]:
			for center in [2750.0,5050.0,7000.0,9250.0,19500.0,22500.0,24400.0]:
				for bank in [265.0,395.0]:
					run_gate_case(mode,hz,center,bank,true,true)
					run_gate_case(mode,hz,center,bank,false,true)
				run_gate_case(mode,hz,center,330,false,false)
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func run_middle_case(mode: String, hz: int, index: int, displacement: float, timing := 0.0, extension := false) -> bool:
	var host := Host.new()
	host.difficulty = mode
	var model := create_model(host)
	model.encounter_scroll = 29400 if extension else 9500
	model.clock = model.encounter_scroll/model.scroll_speed
	model.encounter_clock = model.clock
	model.position.y = 265
	var plan := route_plan(model)
	var decks: Array = plan.extension_chain if extension else plan.chain
	var trigger := float(decks[index-1].x)+72
	for point in plan.points:
		if point[0] == trigger:
			point[1] += displacement
			point[0] += timing*model.scroll_speed
	for i in plan.jumps.size():
		if plan.jumps[i] == trigger: plan.jumps[i] += timing*model.scroll_speed
	var target: Dictionary = decks[index]
	var landed := false
	for frame in hz*12:
		var before: int = model.events.get("landed",0)
		var action := controls(model,plan,1.0/hz)
		model.tick(host,1.0/hz,action.steering,action.jump)
		var x: float = model.encounter_scroll+model.position.x
		if model.events.get("landed",0) > before and x > trigger:
			landed = absf(x-float(target.x)) < float(target.width)*0.5
		if host.health < 5 or x > float(target.x)+65: break
	var safe := host.health == 5 and landed
	if (absf(displacement) <= 15 and absf(timing) <= 0.05 and not safe) or (absf(displacement) >= 45 and safe):
		failures.append({"reason":"middle alignment", "mode":mode,"hz":hz,"index":index,
			"displacement":displacement,"timing":timing,"safe":safe,"event":model.last_event})
	cases += 1
	host.free()
	return safe

func check_middle_windows() -> void:
	for mode in ["easy","normal","hard"]:
		for index in [1,3,6,8]:
			var accepted := []
			for displacement in range(-60,61,5):
				if run_middle_case(mode,60,index,displacement): accepted.append(displacement)
			print("MIDDLE_WINDOW ",JSON.stringify({"mode":mode,"deck":index+1,"accepted_offsets":accepted}))
			for hz in [30,120]:
				for displacement in [-50.0,-15.0,0.0,15.0,50.0]: run_middle_case(mode,hz,index,displacement)
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func check_middle_timing() -> void:
	for index in [1,3,6,8]:
		var accepted := []
		for milliseconds in range(-150,151,10):
			if run_middle_case("normal",60,index,0,milliseconds/1000.0): accepted.append(milliseconds)
		print("MIDDLE_TIMING ",JSON.stringify({"deck":index+1,"accepted_ms":accepted}))
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func check_pacing() -> void:
	for mode in ["easy","normal","hard"]:
		var host := Host.new()
		host.difficulty = mode
		var model := create_model(host)
		var plan := route_plan(model)
		var still := 0
		var spans := []
		for frame in 4500:
			var action := controls(model,plan,1.0/60)
			var active: bool = absf(action.steering.y) > 0.08 or model.jump_age >= 0 or action.jump or model.ramp_active
			if active or model.complete:
				if still > 48:
					var span := {"x":roundi(model.position.x+model.encounter_scroll-still*model.scroll_speed/60),
						"seconds":snappedf(still/60.0,0.01)}
					spans.append(span)
					if still > 54: failures.append({"reason":"idle interval","mode":mode,"span":span})
				still = 0
			else: still += 1
			if model.complete or host.health < 5: break
			model.tick(host,1.0/60,action.steering,action.jump)
		if not model.complete or host.health != 5: failures.append({"reason":"pacing route","mode":mode})
		print("PACING ",JSON.stringify({"mode":mode,"intervals_over_0_8_seconds":spans}))
		cases += 1
		host.free()
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func check_extension() -> void:
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for hz in [30,60,120]:
				for missed in 6: run_chain_case(hero,mode,hz,missed,-1,0,0,true)
				for bank in [265.0,305.0,330.0,355.0,395.0]: run_chain_case(hero,mode,hz,-1,bank,0,0,true)
				for drift in [-0.1,0.1]:
					for offset in [-0.025,0.0,0.025]: run_chain_case(hero,mode,hz,-1,-1,drift,offset,true)
	for mode in ["easy","normal","hard"]:
		for hz in [30,60,120]:
			for center in [26400.0,28200.0,29400.0,34500.0,36300.0,37300.0]:
				for bank in [265.0,395.0]:
					run_gate_case(mode,hz,center,bank,true,true)
					run_gate_case(mode,hz,center,bank,false,true)
				run_gate_case(mode,hz,center,330,false,false)
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func check_extension_middle() -> void:
	for mode in ["easy","normal","hard"]:
		for index in [1,4]:
			var accepted := []
			for displacement in range(-60,61,5):
				if run_middle_case(mode,60,index,displacement,0,true): accepted.append(displacement)
			print("EXTENSION_MIDDLE_WINDOW ",JSON.stringify({"mode":mode,"deck":index+1,"accepted_offsets":accepted}))
			for hz in [30,120]:
				for displacement in [-50.0,-15.0,0.0,15.0,50.0]: run_middle_case(mode,hz,index,displacement,0,true)
	for index in [1,4]:
		var accepted := []
		for milliseconds in range(-150,151,10):
			if run_middle_case("normal",60,index,0,milliseconds/1000.0,true): accepted.append(milliseconds)
		print("EXTENSION_MIDDLE_TIMING ",JSON.stringify({"deck":index+1,"accepted_ms":accepted}))
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
