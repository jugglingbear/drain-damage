extends RefCounted
## Whole seeded cohorts preserve visible counts; safety relocation occurs before any warning is announced.
const Flow = preload("res://scripts/flush_flow.gd")
const PROP_NAMES := {"pooplog":"poop_log","carkeys":"car_keys","safetypin":"safety_pin"}
var layout: Dictionary = {}
var mode := "normal"
var items: Array[Dictionary] = []
var ledger: Array[Dictionary] = []
var bag: Array = []
var rng := RandomNumberGenerator.new()
var next_wave := 0
var safety_failures := 0
var spawned := 0

func configure(definition: Dictionary, difficulty: String, seed_value: int) -> void:
	layout = definition
	mode = difficulty
	rng.seed = seed_value+99002
	items.clear()
	ledger.clear()
	bag.clear()
	next_wave = 0
	safety_failures = 0
	spawned = 0

func shuffled(values: Array) -> Array:
	var result := values.duplicate()
	for index in range(result.size()-1,0,-1):
		var other := rng.randi_range(0,index)
		var old = result[index]
		result[index] = result[other]
		result[other] = old
	return result

func next_prop() -> String:
	if bag.is_empty(): bag = shuffled(layout.props)
	var id := str(bag.pop_back())
	return PROP_NAMES.get(id,id)

func advance(model: RefCounted, host: Node2D, delta: float) -> void:
	# Resolve impacts before the new cohort so boundary frames never exceed five airborne props.
	for index in range(items.size()-1,-1,-1):
		var item := items[index]
		if model.clock+0.000001 >= float(item.impact_at):
			if not item.impacted:
				item.impacted = true
				item.pos = item.impact_pos
				model.audio.play("debris_impact")
			else:
				item.pos = Flow.advect(item.pos,model.clock-delta,delta,layout.difficulty[mode].flow)
			if model.clock < 35 and model.clock < float(item.impact_at)+0.35 \
					and model.jump_height <= 24 and model.position.distance_to(item.pos) < 36:
				var before: int = host.health
				host.hurt_player()
				if host.health < before: model.damage_taken += 1
			if item.pos.length() < 12:
				items.remove_at(index)
	var waves: Array = layout.difficulty[mode].waves
	while next_wave < waves.size() and model.clock+0.000001 >= float(waves[next_wave].at) and model.clock < 35:
		spawn_wave(model,waves[next_wave],float(host.invulnerable),float(host.employee.move_speed))
		next_wave += 1

func spawn_wave(model: RefCounted, wave: Dictionary, immunity: float, hero_speed: float) -> void:
	var chosen: Array[Vector2] = []
	var route: Array[Vector2] = []
	var safe_point := Vector2.ZERO
	var witness: Dictionary = {}
	var offsets := shuffled([-22.5,-15.0,-7.5,0.0,7.5,15.0,22.5])
	offsets.append_array([30.0,-30.0,45.0,-45.0,60.0,-60.0,90.0,-90.0,135.0,-135.0,180.0])
	for offset in offsets:
		var angle: float = model.position.angle()+deg_to_rad(float(offset))
		var pocket := Vector2.from_angle(angle)*240.0
		var route_radius: float = maxf(162.2,model.position.length())
		var proposed: Array[Vector2] = []
		var slots := shuffled([2,3,4,5,6])
		for index in range(int(wave.count)):
			proposed.append(Vector2.from_angle(angle+float(slots[index])*TAU/8)*clampf(model.position.length(),190,285))
		var path: Array[Vector2] = [model.position]
		for segment in range(19):
			path.append(Vector2.from_angle(model.position.angle()+deg_to_rad(float(offset))*segment/18)*route_radius)
		path.append(pocket)
		var result := safe_route(path,proposed,float(wave.at),float(wave.duration),immunity,model.last_steering,hero_speed)
		if result.safe:
			witness = result
			chosen = proposed
			route = path
			safe_point = pocket
			break
	if chosen.is_empty():
		# Failure is explicit, never a silent cap drop or bag consumption. Validation must reject this run.
		safety_failures += 1
		push_error("Flush cohort has no verified escape route: "+str(wave.id))
		return
	var entry := {"id":wave.id,"at":wave.at,"duration":wave.duration,"count":wave.count,
		"safe_point":safe_point,"route":route,"witness":witness.commands,
		"inherited_contacts":witness.inherited_contacts,"props":[],"positions":[]}
	for point in chosen:
		var prop := next_prop()
		# The largest authored prop is at most 52px above its anchor; its top stays below the HUD.
		var screen_y: float = model.project(point).y
		var item := {"id":str(wave.id)+"-"+str(spawned),"prop":prop,"at":float(wave.at),
			"duration":float(wave.duration),"impact_at":float(wave.at)+float(wave.duration),
			"pos":point,"impact_pos":point,"height":minf(220,screen_y-124),"impacted":false}
		items.append(item)
		spawned += 1
		entry.props.append(prop)
		entry.positions.append(point)
	ledger.append(entry)

func safe_route(path: Array[Vector2], incoming: Array[Vector2], start: float, duration: float,
		immunity: float, prior_input: Vector2, hero_speed: float) -> Dictionary:
	var point := path[0]
	var segment := 1
	var step := 1.0/120.0
	var commands: Array[Vector2] = []
	var inherited: Dictionary = {}
	var directions: Array[Vector2] = [Vector2.ZERO]
	for index in range(8): directions.append(Vector2.from_angle(index*TAU/8))
	var flow: Dictionary = layout.difficulty[mode].flow
	var old_positions: Array[Vector2] = []
	for old: Dictionary in items: old_positions.append(old.pos)
	var new_positions := incoming.duplicate()
	for index in range(ceili((duration+0.35)/step)):
		var elapsed := (index+1)*step
		var time := start+elapsed
		while segment < path.size()-1 and point.distance_to(path[segment]) < 5: segment += 1
		var command := prior_input
		if elapsed > 0.15:
			var best := INF
			for option in directions:
				var candidate := Flow.swim(point,option,hero_speed,time,step,flow)
				var distance := candidate.distance_squared_to(path[segment])
				if distance < best:
					best = distance
					command = option
		var next := Flow.swim(point,command,hero_speed,time,step,flow)
		commands.append(command)
		for old_index in range(items.size()):
			var old: Dictionary = items[old_index]
			var before: Vector2 = old_positions[old_index]
			var after := before
			if time >= float(old.impact_at):
				after = Flow.advect(before,time-step,step,flow)
			old_positions[old_index] = after
			if time < float(old.impact_at) or time >= float(old.impact_at)+0.35: continue
			var contact := Geometry2D.get_closest_point_to_segment(Vector2.ZERO,point-before,next-after).length() < 36.1
			# A prior warning's hit already in progress, or during unchanged reaction input, is inherited—not caused by this wave.
			if contact and elapsed <= 0.15: inherited[old.id] = true
			if contact and elapsed >= immunity and not inherited.has(old.id):
				return {"safe":false}
		if elapsed >= duration:
			for new_index in range(incoming.size()):
				var before: Vector2 = new_positions[new_index]
				var after := before if elapsed-duration <= step*0.5 else Flow.advect(before,time-step,step,flow)
				new_positions[new_index] = after
				if Geometry2D.get_closest_point_to_segment(Vector2.ZERO,point-before,next-after).length() < 36.1:
					return {"safe":false}
				if path[-1].distance_to(after) < 84: return {"safe":false}
		point = next
	if point.distance_to(path[-1]) > 48: return {"safe":false}
	return {"safe":true,"commands":commands,"inherited_contacts":inherited.keys()}

func predicted_float(point: Vector2, start: float, end: float) -> Vector2:
	var time := start
	while time < end:
		var delta := minf(0.025,end-time)
		point = Flow.advect(point,time,delta,layout.difficulty[mode].flow)
		time += delta
	return point

func fall_height(item: Dictionary, time: float) -> float:
	var progress := clampf((time-float(item.at))/float(item.duration),0,1)
	return float(item.height)*(1-progress*progress)

func falling_count(time: float) -> int:
	var count := 0
	for item: Dictionary in items:
		if time < float(item.impact_at)-0.000001: count += 1
	return count
