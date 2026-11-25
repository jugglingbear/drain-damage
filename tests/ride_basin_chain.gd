extends "res://tests/ride_wave_two_course.gd"
## The five-hop chain must preserve successive takeoffs and landings, including timing error.

func run_chain(hero: String, mode: String, seed_value: int, hz: int, anchor: float,
		offset: float, drift: float, missed_hop := -1) -> void:
	var host := SeededHost.new()
	host.employee.id = hero
	host.difficulty = mode
	host.run_seed = seed_value
	var model := Model.new()
	model.continuous = true
	model.begin(host)
	var shift := float(model.definition.wave_one_finish)-WAVE_ONE_FINISH
	model.encounter_scroll = 21900+shift-300
	model.clock = model.encounter_scroll/model.scroll_speed
	model.encounter_clock = model.clock
	model.position = Vector2(anchor,395)
	var plan := full_route_plan(model,mode)
	if missed_hop >= 0: plan.jumps.erase(23392.0+480*missed_hop+shift)
	var jumps := 0
	var landings := 0
	var landing_points := []
	var ordered_landings := true
	for frame in range(12*hz):
		var x: float = model.position.x+model.encounter_scroll
		var before_jump: int = model.events.get("jump",0)
		var before_land: int = model.events.get("landed",0)
		var controls := route_controls(model,plan,1.0/hz,offset,drift)
		model.tick(host,1.0/hz,controls.steering,controls.jump)
		if x > 23100+shift and x < 26000+shift:
			jumps += int(model.events.get("jump",0))-before_jump
			if int(model.events.get("landed",0)) > before_land:
				landings += 1
				var landing_x: float = model.encounter_scroll+model.position.x
				landing_points.append([landing_x,model.position.y])
				var center := 23800+480*(landings-1)+shift
				var bank := 380 if landings%2 == 1 else 280
				ordered_landings = ordered_landings and absf(landing_x-center) <= (195 if landings == 5 else 180) \
					and absf(model.position.y-bank) <= 50
		if host.health < 5 or model.encounter_scroll+model.position.x >= 27000+shift: break
	var failed := not ordered_landings or host.health != 5 or jumps != 5 or landings != 5 or model.encounter_scroll+model.position.x < 27000+shift
	if missed_hop >= 0: failed = host.health == 5
	if failed:
		var record := {"hero":hero,"mode":mode,"seed":seed_value,"hz":hz,"anchor":anchor,
			"offset":offset,"drift":drift,"missed_hop":missed_hop,"jumps":jumps,"landings":landings,"landing_points":landing_points,
			"event":model.last_event,"x":model.encounter_scroll+model.position.x}
		failures.append(record)
		print("CHAIN_FAILURE ",JSON.stringify(record))
	routes += 1
	host.free()

func checks() -> void:
	for hero in ["sean","tony"]:
		for hz in [30,60,120]:
			for anchor in [180.0,300.0,650.0]:
				for offset in [-0.05,0.0,0.05]:
					run_chain(hero,"normal",0,hz,anchor,offset,0)
	for hero in ["sean","tony"]:
		for hz in [30,60,120]:
			for missed in 5:
				run_chain(hero,"normal",0,hz,300,0,0,missed)
			for drift in [-0.1,0.1]:
				for offset in [-0.025,0.025]:
					run_chain(hero,"hard",9,hz,300,offset,drift)
	print(JSON.stringify({"routes":routes,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
