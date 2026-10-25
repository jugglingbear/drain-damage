extends RefCounted
## Atomic seeded cohorts and persistent, size-aware water hazards share the same simulation as their escape witnesses.
const Flow = preload("res://scripts/flush_flow.gd")
const PROP_NAMES := {"pooplog":"poop_log","carkeys":"car_keys","safetypin":"safety_pin"}
const STEP := 1.0/120.0
const CUTOFF := 35.0
const NEAR_HAZARD_CLEARANCE := 110.0
const IMPACT_LOOKAHEAD := 0.25
var layout: Dictionary = {}
var mode := "normal"
var items: Array[Dictionary] = []
var ledger: Array[Dictionary] = []
var bag: Array = []
var rng := RandomNumberGenerator.new()
var next_wave := 0
var safety_failures := 0
var spawned := 0
var previous_hero := Vector2.ZERO
var have_previous_hero := false
var blocked := false
var render_frames: Dictionary = {}
var last_failure: Dictionary = {}
var proof_cache: Dictionary = {}
var reaction_commands: Array = []

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
	have_previous_hero = false
	blocked = false
	last_failure.clear()
	proof_cache.clear()
	reaction_commands.clear()

func shuffled(values: Array) -> Array:
	var result := values.duplicate()
	for index in range(result.size()-1,0,-1):
		var other := rng.randi_range(0,index)
		var old = result[index]
		result[index] = result[other]
		result[other] = old
	return result

func peek_props(count: int) -> Array:
	# Fill the queue without consuming it; failed placement retains these exact types.
	while bag.size() < count: bag.append_array(shuffled(layout.props))
	return bag.slice(0,count)

func radius_for(id: String) -> float:
	return float(layout.prop_profiles[id].collision_radius_world)

func upper_extent(frame: Dictionary) -> float:
	var extent := 0.0
	if frame.has("destination"): extent = maxf(0,-float(frame.destination[1]))
	for layer: Dictionary in frame.get("layers",[]): extent = maxf(extent,upper_extent(layer))
	return extent

func prop_extent(id: String) -> float:
	var art_id: String = PROP_NAMES.get(id,id)
	if render_frames.has(art_id): return upper_extent(render_frames[art_id])
	# Standalone simulations use a conservative extent until the authored manifest is attached.
	return 64.0 if id == "dead_hamster" else 52.0

func move_hazard(item: Dictionary, start: float, delta: float) -> Array[Dictionary]:
	## Return harmful swept segments, splitting impact, cutoff and physical swallow boundaries.
	var segments: Array[Dictionary] = []
	if not item.has("radius"):
		var source := str(item.get("source_prop",item.prop))
		for canonical in PROP_NAMES:
			if PROP_NAMES[canonical] == source: source = canonical
		item.radius = radius_for(source)
		item.warning_radius = float(item.radius)+14.0
	if not item.has("retired"): item.retired = false
	var end := start+delta
	var impact: float = item.impact_at
	if end+0.0000001 < impact: return segments
	if absf(end-impact) < 0.0000001: impact = end
	if not item.impacted:
		item.impacted = true
		item.pos = item.impact_pos
	var time := maxf(start,impact)
	var capture := 65.0-float(item.radius)
	if item.pos.length() <= capture:
		item.retired = true
		return segments
	while time < end-0.0000001:
		var dt := minf(STEP,end-time)
		if time < CUTOFF: dt = minf(dt,CUTOFF-time)
		var before: Vector2 = item.pos
		var after := Flow.advect(before,time,dt,layout.difficulty[mode].flow)
		if after.length() <= capture:
			var lower := 0.0
			var upper := dt
			for iteration in range(18):
				var middle := (lower+upper)*0.5
				if Flow.advect(before,time,middle,layout.difficulty[mode].flow).length() > capture:
					lower = middle
				else: upper = middle
			dt = upper
			after = Flow.advect(before,time,dt,layout.difficulty[mode].flow)
			item.retired = true
		if time < CUTOFF:
			segments.append({"from":before,"to":after,"start":time,"end":time+dt,
				"radius":float(item.radius)+14.0})
		item.pos = after
		time += dt
		if item.get("retired",false): break
	# Exact impact is a contact sample even when no elapsed floating time remains.
	if segments.is_empty() and impact < CUTOFF and is_equal_approx(end,impact):
		segments.append({"from":item.pos,"to":item.pos,"start":end,"end":end,
			"radius":float(item.radius)+14.0})
	return segments

func touches(a: Vector2, b: Vector2, start: float, end: float, segments: Array[Dictionary]) -> bool:
	for segment in segments:
		var fraction0 := clampf((float(segment.start)-start)/maxf(end-start,0.0000001),0,1)
		var fraction1 := clampf((float(segment.end)-start)/maxf(end-start,0.0000001),0,1)
		var from: Vector2 = a.lerp(b,fraction0)-segment.from
		var to: Vector2 = a.lerp(b,fraction1)-segment.to
		if Geometry2D.get_closest_point_to_segment(Vector2.ZERO,from,to).length() <= float(segment.radius):
			return true
	return false

func advance(model: RefCounted, host: Node2D, delta: float) -> void:
	if not have_previous_hero:
		previous_hero = model.position
		have_previous_hero = true
	var end: float = model.clock
	var start := end-delta
	var contact := false
	for index in range(items.size()-1,-1,-1):
		var item := items[index]
		var was_impacted: bool = item.impacted
		var segments := move_hazard(item,start,delta)
		if not was_impacted and item.impacted: model.audio.play("debris_impact")
		contact = touches(previous_hero,model.position,start,end,segments) or contact
		if item.get("retired",false): items.remove_at(index)
	# One request for all simultaneous contacts; host owns the shared immunity and life debit.
	if contact and host.health > 0:
		var before: int = host.health
		host.hurt_player()
		if host.health < before: model.damage_taken += 1
	previous_hero = model.position
	if blocked or host.health <= 0: return
	var waves: Array = layout.difficulty[mode].waves
	while next_wave < waves.size() and end+0.000001 >= float(waves[next_wave].at) and end < CUTOFF:
		if end-float(waves[next_wave].at) > STEP+0.00001:
			fail_wave(waves[next_wave],"caller skipped cohort boundary; substep the runtime")
			return
		if not spawn_wave(model,waves[next_wave],float(host.invulnerable),float(host.employee.move_speed)):
			return
		next_wave += 1

func fail_wave(wave: Dictionary, reason: String) -> void:
	blocked = true
	safety_failures += 1
	push_error("Flush cohort "+str(wave.id)+": "+reason)

func old_contact_in_reaction(origin: Vector2, start: float, prior_input: Vector2, speed: float) -> bool:
	var old: Array[Dictionary] = []
	for item in items: old.append(item.duplicate(true))
	var point := origin
	for index in range(18):
		var time := start+index*STEP
		var input: Vector2 = reaction_commands[index] if index < reaction_commands.size() else prior_input
		var next := Flow.swim(point,input,speed,time+STEP,STEP,layout.difficulty[mode].flow)
		for hazard in old:
			if hazard.get("retired",false): continue
			if touches(point,next,time,time+STEP,move_hazard(hazard,time,STEP)): return true
		point = next
	return false

func prior_reaction(origin: Vector2, time: float, hero_speed: float) -> Array:
	if ledger.is_empty(): return []
	var prior: Dictionary = ledger[-1]
	if prior.mode != mode or not is_equal_approx(float(prior.hero_speed),hero_speed): return []
	var phase := (time-float(prior.witness_start))/STEP
	var index := roundi(phase)
	if absf(phase-index) > 0.00001 or index < 0: return []
	if index+18 > prior.witness.size() or index >= prior.witness_positions.size(): return []
	if origin.distance_to(prior.witness_positions[index]) > 0.01: return []
	return prior.witness.slice(index,index+18)

func spawn_wave(model: RefCounted, wave: Dictionary, immunity: float, hero_speed: float) -> bool:
	proof_cache.clear()
	reaction_commands = prior_reaction(model.position,model.clock,hero_speed)
	var types := peek_props(int(wave.count))
	var impact := float(wave.at)+float(wave.duration)
	var bounds := Flow.annulus(impact)
	var candidates: Array[Dictionary] = []
	var offsets := shuffled([0.0,15.0,-15.0,30.0,-30.0,45.0,-45.0,60.0,-60.0,90.0,-90.0,135.0,-135.0,180.0])
	for offset in offsets:
		var angle: float = model.position.angle()+deg_to_rad(float(offset))
		for assignment in range(8):
			var slots := shuffled([3,4,5,6,7,8,9])
			var incoming: Array[Dictionary] = []
			var separated := true
			for index in range(types.size()):
				var id := str(types[index])
				var radius := radius_for(id)
				var distance := clampf(model.position.length(),bounds.x+radius,bounds.y-radius)
				var point := Vector2.from_angle(angle+float(slots[index])*TAU/12)*distance
				for other in incoming:
					if point.distance_to(other.pos) < radius+float(other.radius): separated = false
				incoming.append({"id":str(wave.id)+"-"+str(spawned+index),"prop":PROP_NAMES.get(id,id),
					"source_prop":id,"radius":radius,"warning_radius":radius+14,"at":float(wave.at),
					"duration":float(wave.duration),"impact_at":impact,"pos":point,"impact_pos":point,
					"height":maxf(0,minf(220,model.project(point).y-72-prop_extent(id))),
					"impacted":false,"retired":false})
			if not separated: continue
			candidates.append({"angle":angle,"items":incoming})
			break
	# A matching prior route already accounts for all current old floats; recheck actual state, not just provenance.
	if not reaction_commands.is_empty():
		var prior: Dictionary = ledger[-1]
		var phase := roundi((model.clock-float(prior.witness_start))/STEP)
		var fixed: Array = prior.witness.slice(phase)
		var witness := safe_route(model.position,[],model.clock,model.position.angle(),model.last_steering,
			hero_speed,false,immunity,fixed)
		if witness.safe:
			for placement in candidates:
				if not incoming_clear(witness,model.clock,placement.items): continue
				witness.reused_previous_route = true
				commit_wave(model,wave,placement.items,model.position.angle(),witness,"strict",immunity,0)
				return true
	# First verify a route through old debris. Incoming waves cannot alter its movement or hits.
	for route_candidate in candidates:
		var witness := safe_route(model.position,[],model.clock,route_candidate.angle,model.last_steering,hero_speed)
		if not witness.safe:
			last_failure = witness
			if witness.get("reaction_locked",false): break
			continue
		for placement in candidates:
			if incoming_clear(witness,model.clock,placement.items):
				commit_wave(model,wave,placement.items,route_candidate.angle,witness,"strict",immunity,0)
				return true
	# Only baseline-confirmed old contact permits recovery. New props must cause zero contact, even while immune.
	if old_contact_in_reaction(model.position,model.clock,model.last_steering,hero_speed):
		var baselines: Array[Dictionary] = []
		var baseline_hits := 2147483647
		for route_candidate in candidates:
			var baseline := safe_route(model.position,[],model.clock,route_candidate.angle,model.last_steering,
				hero_speed,true,immunity)
			if not baseline.safe: continue
			baseline_hits = mini(baseline_hits,int(baseline.hits))
			baselines.append({"angle":route_candidate.angle,"witness":baseline})
			if baseline_hits == 0: break
		for baseline in baselines:
			if int(baseline.witness.hits) != baseline_hits: continue
			for placement in candidates:
				if not incoming_clear(baseline.witness,model.clock,placement.items): continue
				baseline.witness.paired_baseline_hits = baseline_hits
				commit_wave(model,wave,placement.items,baseline.angle,baseline.witness,"recovery",immunity,baseline_hits)
				return true
	fail_wave(wave,"no full-count placement avoids a verified old-debris route; no props consumed")
	return false

func incoming_clear(witness: Dictionary, start: float, incoming: Array[Dictionary]) -> bool:
	if witness.positions.size() != witness.commands.size()+1: return false
	if witness.commands.size()*STEP < CUTOFF-start-0.000001: return false
	var simulated: Array[Dictionary] = []
	for item in incoming: simulated.append(item.duplicate(true))
	var first_impact := CUTOFF
	for hazard in simulated: first_impact = minf(first_impact,float(hazard.impact_at))
	var first_step := maxi(0,floori((first_impact-start)/STEP))
	var time := start+first_step*STEP
	var initial_bounds := Flow.annulus(start)
	var origin: Vector2 = witness.positions[0]
	var flow: Dictionary = layout.difficulty[mode].flow
	var allow_cutoff := origin.length() >= initial_bounds.x and origin.length() <= initial_bounds.y
	allow_cutoff = allow_cutoff and minf(flow.inward_speed_start,flow.inward_speed_end) >= 8
	for index in range(first_step,witness.commands.size()):
		var dt := minf(STEP,CUTOFF-time)
		if dt <= 0: break
		var a: Vector2 = witness.positions[index]
		var b: Vector2 = witness.positions[index+1]
		var remaining := false
		for hazard in simulated:
			if hazard.retired or hazard.get("proof_retired",false): continue
			# Include the entire first impact interval and exact boundary sample, without immunity exemptions.
			if touches(a,b,time,time+dt,move_hazard(hazard,time,dt)): return false
			if allow_cutoff and hazard.impacted and hazard.pos.length()+float(hazard.radius)+14+0.25 < Flow.annulus(time+dt).x:
				hazard.proof_retired = true
			remaining = remaining or (not hazard.retired and not hazard.get("proof_retired",false))
		if not remaining: return true
		time += dt
	return true

func commit_wave(model: RefCounted, wave: Dictionary, incoming: Array[Dictionary], angle: float,
		witness: Dictionary, admission: String, immunity: float, baseline_hits: int) -> void:
	var bounds := Flow.annulus(float(wave.at)+float(wave.duration))
	var entry := {"id":wave.id,"at":wave.at,"duration":wave.duration,"count":wave.count,
		"safe_point":Vector2.from_angle(angle)*(bounds.x+bounds.y)*0.5,"witness":witness.commands,
		"witness_start":model.clock,"witness_end":CUTOFF,"witness_positions":witness.positions,
		"used_continuation":not reaction_commands.is_empty(),"mode":mode,"hero_speed":witness.hero_speed,
		"reaction_source":ledger[-1].id if not reaction_commands.is_empty() else "constant-input",
		"incoming_contacts":0,"proof_strategy":"old-route-then-incoming",
		"reused_previous_route":witness.get("reused_previous_route",false),"inherited_contacts":[],"props":[],"positions":[],
		"admission":admission,"starting_immunity":immunity,"baseline_hits":baseline_hits,
		"projected_hits":witness.hits,"paired_baseline_hits":witness.get("paired_baseline_hits",0)}
	for item in incoming:
		items.append(item)
		bag.pop_front()
		spawned += 1
		entry.props.append(item.prop)
		entry.positions.append(item.impact_pos)
	ledger.append(entry)
	proof_cache.clear()

func packed_touches(a: Vector2, b: Vector2, start: float, end: float, segments: PackedFloat64Array) -> bool:
	for index in range(0,segments.size(),7):
		var fraction0 := clampf((segments[index+4]-start)/maxf(end-start,0.0000001),0,1)
		var fraction1 := clampf((segments[index+5]-start)/maxf(end-start,0.0000001),0,1)
		var from := a.lerp(b,fraction0)-Vector2(segments[index],segments[index+1])
		var to := a.lerp(b,fraction1)-Vector2(segments[index+2],segments[index+3])
		if Geometry2D.get_closest_point_to_segment(Vector2.ZERO,from,to).length() <= segments[index+6]: return true
	return false

func proof_frame(cache: Dictionary, index: int, time: float, dt: float) -> Dictionary:
	if index < cache.frames.size(): return cache.frames[index]
	var segments := PackedFloat64Array()
	var positions := PackedVector2Array()
	var retired := PackedByteArray()
	var all_retired := true
	for hazard in cache.simulated:
		if not hazard.retired and not hazard.get("proof_retired",false):
			for segment in move_hazard(hazard,time,dt):
				segments.append_array(PackedFloat64Array([segment.from.x,segment.from.y,segment.to.x,segment.to.y,
					segment.start,segment.end,segment.radius]))
		# Preserve this frame's crossing segments; only future proof steps omit unreachable disks.
		if cache.allow_cutoff and dt <= STEP+0.0000001 and hazard.impacted:
			if hazard.pos.length()+float(hazard.radius)+14+0.25 < Flow.annulus(time+dt).x:
				hazard.proof_retired = true
		var excluded: bool = hazard.retired or hazard.get("proof_retired",false)
		positions.append(hazard.pos)
		retired.append(1 if excluded else 0)
		all_retired = all_retired and excluded
	var frame := {"segments":segments,"positions":positions,"retired":retired,"all_retired":all_retired}
	cache.frames.append(frame)
	return frame

func safe_route(origin: Vector2, incoming: Array[Dictionary], start: float, angle: float,
		prior_input: Vector2, hero_speed: float, recovery := false, initial_immunity := 0.0,
		fixed_commands: Array = []) -> Dictionary:
	var result := search_route(origin,incoming,start,angle,prior_input,hero_speed,recovery,initial_immunity,fixed_commands,true)
	if result.safe or result.get("reaction_locked",false): return result
	# Inner-disk pruning changes steering scores; retain the proven full-lifetime search as fallback.
	return search_route(origin,incoming,start,angle,prior_input,hero_speed,recovery,initial_immunity,fixed_commands,false)

func search_route(origin: Vector2, incoming: Array[Dictionary], start: float, angle: float,
		prior_input: Vector2, hero_speed: float, recovery: bool, initial_immunity: float,
		fixed_commands: Array, use_cutoff: bool) -> Dictionary:
	# No immunity or inherited-contact exemptions: a witness must avoid every persistent hazard until35.
	var simulated: Array[Dictionary] = []
	for item in items: simulated.append(item.duplicate(true))
	for item in incoming: simulated.append(item.duplicate(true))
	# Cache exact hero-independent trajectories only within this wave planning transaction.
	var initial_bounds := Flow.annulus(start)
	var flow: Dictionary = layout.difficulty[mode].flow
	var allow_cutoff := use_cutoff and origin.length() >= initial_bounds.x and origin.length() <= initial_bounds.y
	allow_cutoff = allow_cutoff and minf(flow.inward_speed_start,flow.inward_speed_end) >= 8
	var key := var_to_str([start,mode,flow,simulated,allow_cutoff])
	if not proof_cache.has(key):
		proof_cache[key] = {"simulated":simulated.duplicate(true),"frames":[],"allow_cutoff":allow_cutoff}
	var cached: Dictionary = proof_cache[key]
	var frame_index := 0
	var all_retired: bool = simulated.all(func(hazard: Dictionary) -> bool: return hazard.retired)
	var point := origin
	var commands: Array[Vector2] = []
	var positions: Array[Vector2] = [origin]
	var directions: Array[Vector2] = [Vector2.ZERO]
	for index in range(8): directions.append(Vector2.from_angle(index*TAU/8))
	var time := start
	var immunity := initial_immunity
	var hits := 0
	while time < CUTOFF-0.0000001:
		var dt := minf(STEP,CUTOFF-time)
		# Unimpacted incoming props remain unretired, so this cannot skip a future landing.
		if all_retired:
			immunity = maxf(0,immunity-(CUTOFF-time))
			while time < CUTOFF-0.0000001:
				var tail_dt := minf(STEP,CUTOFF-time)
				# A verified route still guides active steering after old debris becomes unreachable.
				# Zero-input padding here would make every later wave protect passive current drift.
				var tail_bounds := Flow.annulus(time+tail_dt)
				var tail_velocity := Flow.velocity(point,time+tail_dt,flow)
				var tail_target := Vector2.from_angle(angle)*(tail_bounds.x+tail_bounds.y)*0.5
				var desired := tail_target-point-tail_velocity*tail_dt
				var tail_command := Vector2.ZERO
				if desired.length() > hero_speed*tail_dt*0.5:
					tail_command = directions[1+posmod(roundi(desired.angle()/(TAU/8)),8)]
				if not fixed_commands.is_empty(): tail_command = fixed_commands[commands.size()]
				elif commands.size() < reaction_commands.size(): tail_command = reaction_commands[commands.size()]
				elif commands.size() < 18: tail_command = prior_input
				point += (tail_command.limit_length()*hero_speed+tail_velocity)*tail_dt
				if point == Vector2.ZERO: point = Vector2.RIGHT*tail_bounds.x
				point = point.normalized()*clampf(point.length(),tail_bounds.x,tail_bounds.y)
				commands.append(tail_command)
				positions.append(point)
				time += tail_dt
			break
		var frame := proof_frame(cached,frame_index,time,dt)
		frame_index += 1
		all_retired = frame.all_retired
		var segments: PackedFloat64Array = frame.segments
		var bounds := Flow.annulus(time+dt)
		var target := Vector2.from_angle(angle)*(bounds.x+bounds.y)*0.5
		var velocity := Flow.velocity(point,time+dt,layout.difficulty[mode].flow)
		var best := INF
		var command := prior_input
		var next := point
		var best_contact := false
		immunity = maxf(0,immunity-dt)
		var reaction: Vector2 = reaction_commands[commands.size()] if commands.size() < reaction_commands.size() else prior_input
		var options: Array = [reaction] if time-start < 0.15-0.000001 else directions
		if time-start >= 0.15-0.000001 and fixed_commands.is_empty():
			var near_hazard := false
			for hazard_index in range(simulated.size()):
				var hazard: Dictionary = simulated[hazard_index]
				if frame.retired[hazard_index] or float(hazard.impact_at) > time+IMPACT_LOOKAHEAD: continue
				if point.distance_to(frame.positions[hazard_index]) < float(hazard.radius)+14+NEAR_HAZARD_CLEARANCE:
					near_hazard = true
					break
			# Far from present or imminent hazards, one analytic input still gets the full swept check.
			if not near_hazard:
				var desired := target-point-velocity*dt
				var primary := Vector2.ZERO
				if desired.length() > hero_speed*dt*0.5:
					primary = directions[1+posmod(roundi(desired.angle()/(TAU/8)),8)]
				options = [primary]
		if not fixed_commands.is_empty(): options = [fixed_commands[commands.size()]]
		for option in options:
			# Same Flow.swim arithmetic; force and bounds are shared by all nine inputs.
			var input: Vector2 = option
			var candidate := point+(input.limit_length()*hero_speed+velocity)*dt
			if candidate == Vector2.ZERO: candidate = Vector2.RIGHT*bounds.x
			candidate = candidate.normalized()*clampf(candidate.length(),bounds.x,bounds.y)
			var score := candidate.distance_squared_to(target)
			# Every remaining score term is nonnegative; these candidates cannot win.
			if score >= best: continue
			var contact := packed_touches(point,candidate,time,time+dt,segments)
			if contact and not recovery: continue
			if contact and immunity <= 0: score += 1000000000.0
			# Prefer clearance before the next movement step rather than walking into a local dead end.
			for hazard_index in range(simulated.size() if options.size() > 1 else 0):
				var hazard: Dictionary = simulated[hazard_index]
				if frame.retired[hazard_index] or time+dt < float(hazard.impact_at): continue
				var clearance := candidate.distance_to(frame.positions[hazard_index])-float(hazard.radius)-14
				score += 20000.0/maxf(1,clearance)
				if score >= best: break
			if score < best:
				best = score
				command = option
				next = candidate
				best_contact = contact
		if best == INF: return {"safe":false,"failed_at":time,"reaction_locked":time-start < 0.15-0.000001,
			"point":point,"prior_input":prior_input}
		if best_contact and immunity <= 0:
			hits += 1
			immunity = 1.5
		commands.append(command)
		point = next
		positions.append(point)
		time += dt
	return {"safe":true,"commands":commands,"positions":positions,"hero_speed":hero_speed,"hits":hits,"ending_immunity":immunity}

func predicted_float(point: Vector2, start: float, end: float) -> Vector2:
	while start < end:
		var delta := minf(STEP,end-start)
		point = Flow.advect(point,start,delta,layout.difficulty[mode].flow)
		start += delta
	return point

func fall_height(item: Dictionary, time: float) -> float:
	var progress := clampf((time-float(item.at))/float(item.duration),0,1)
	return float(item.height)*(1-progress*progress)

func falling_count(time: float) -> int:
	var count := 0
	for item in items:
		if time < float(item.impact_at)-0.000001: count += 1
	return count
