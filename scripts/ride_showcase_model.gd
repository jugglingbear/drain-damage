extends RefCounted
## Deterministic showcase physics. Rendering/audio remain in the ride wrapper.
const SOURCE := "res://levels/level-two-ride-showcase.json"
const STEP := 1.0/120.0
const HALF := Vector2(45,14)
const EPS := 0.000001
var definition: Dictionary = {}
var course: Dictionary = {"obstacles":[]}
var encounter: Dictionary = {}
var encounter_index := 0
var checkpoint_index := 0
var phase := "encounter"
var rest_remaining := 0.0
var encounter_clock := 0.0
var encounter_scroll := 0.0
var clock := 0.0
var scroll_speed := 560.0
var x_speed := 400.0
var bank_speed := 350.0
var position := Vector2(300,330)
var jump_age := -1.0
var jump_height := 0.0
var active_jump_duration := 0.6
var active_jump_apex := 54.0
var jump_duration: float:
	get: return active_jump_duration
var jump_apex: float:
	get: return active_jump_apex
var cooldown := 0.0
var boosted := false
var ballistic := false
var ramp_active := false
var active_ramp: Dictionary = {}
var render_height := 0.0
var render_pitch := 0.0
var launch_height := 0.0
var launch_velocity := 0.0
var launch_gravity := 0.0
var launch_pitch := 0.0
var complete := false
var recovery_clock := 0.0
var events: Dictionary = {}
var contact_latches: Dictionary = {}
var hit_ids: Dictionary = {}
var used_ramps: Dictionary = {}
var last_event: Dictionary = {}

func emit_event(name: String, id := "") -> void:
	events[name] = int(events.get(name,0))+1
	last_event = {"event":name,"obstacle_id":id,"clock":clock,"encounter":encounter_index}

func begin(host: Node2D, index := 0) -> void:
	if definition.is_empty():
		definition = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	clock = 0
	position = Vector2(300,330)
	jump_age = -1
	jump_height = 0
	cooldown = 0
	recovery_clock = 0
	boosted = false
	ballistic = false
	ramp_active = false
	active_ramp.clear()
	render_height = 0
	render_pitch = 0
	complete = false
	events.clear()
	host.won = false
	_start_encounter(clampi(index,0,definition.encounters.size()-1))
	sync_hero(host)

func _start_encounter(index: int) -> void:
	encounter_index = index
	checkpoint_index = index
	encounter = definition.encounters[index].duplicate(true)
	course = {"obstacles":encounter.obstacles}
	for i in range(course.obstacles.size()):
		var obstacle: Dictionary = course.obstacles[i]
		if not obstacle.has("id"): obstacle.id = str(encounter.get("id",index))+"-"+str(i)
	phase = "encounter"
	rest_remaining = 0
	encounter_clock = 0
	encounter_scroll = 0
	contact_latches.clear()
	hit_ids.clear()
	used_ramps.clear()
	emit_event("encounter_started")

func sync_hero(_host: Node2D) -> void:
	pass

func height(age: float) -> float:
	if age < 0 or age >= active_jump_duration: return 0
	if ballistic: return maxf(0,launch_height+launch_velocity*age-launch_gravity*age*age)
	var u := age/active_jump_duration
	return 4*active_jump_apex*u*(1-u)

func hero_head_height(host: Node2D) -> float:
	return 84.0 if str(host.employee.id) == "tony" else 72.0

func motion_offset(obstacle: Dictionary, time: float) -> Vector2:
	var motion: Dictionary = obstacle.get("motion",{})
	if motion.is_empty(): return Vector2.ZERO
	var value := float(motion.get("amplitude",0))*sin(TAU*time/maxf(0.01,float(motion.get("period",2)))+float(motion.get("phase",0)))
	return Vector2(value,0) if motion.get("axis","y") == "x" else Vector2(0,value)

func obstacle_position(obstacle: Dictionary) -> Vector2:
	return Vector2(float(obstacle.x)-encounter_scroll,float(obstacle.y))+motion_offset(obstacle,encounter_clock)

func obstacle_rect(obstacle: Dictionary) -> Rect2:
	return Rect2(Vector2(float(obstacle.x),float(obstacle.y))-Vector2(float(obstacle.width),float(obstacle.depth))*0.5,
		Vector2(float(obstacle.width),float(obstacle.depth)))

static func overlap_interval(start: Vector2, finish: Vector2, rect: Rect2) -> Vector2:
	var enter := 0.0
	var leave := 1.0
	var delta := finish-start
	for axis in [0,1]:
		if absf(delta[axis]) < EPS:
			if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]: return Vector2(-1,-1)
		else:
			var a: float = (rect.position[axis]-start[axis])/delta[axis]
			var b: float = (rect.end[axis]-start[axis])/delta[axis]
			enter = maxf(enter,minf(a,b))
			leave = minf(leave,maxf(a,b))
			if enter > leave: return Vector2(-1,-1)
	return Vector2(enter,leave)

func _relative_interval(obstacle: Dictionary, a: Vector2, b: Vector2, time: float, dt: float, supported := false) -> Vector2:
	var rect := obstacle_rect(obstacle)
	# Bound sinusoid curvature for both hazard expansion and full-board deck containment.
	var motion: Dictionary = obstacle.get("motion",{})
	var pad := 0.0
	if not motion.is_empty():
		pad = absf(float(motion.get("amplitude",0)))*pow(TAU/maxf(.01,float(motion.get("period",2))),2)*dt*dt/8
	var extent := HALF+Vector2.ONE*pad
	if supported:
		if rect.size.x < extent.x*2 or rect.size.y < extent.y*2: return Vector2(-1,-1)
		rect = rect.grow_individual(-extent.x,-extent.y,-extent.x,-extent.y)
	else:
		rect = rect.grow_individual(extent.x,extent.y,extent.x,extent.y)
	return overlap_interval(a-motion_offset(obstacle,time),b-motion_offset(obstacle,time+dt),rect)

func _vertical_spans(kind: String, obstacle: Dictionary, age: float, dt: float, overlap: Vector2, head: float) -> Array:
	if kind == "support": return [overlap]
	var threshold := 0.0
	var above := kind == "overhead"
	if kind == "low_barrier": threshold = float(obstacle.get("clearance",28))
	if above: threshold = float(obstacle.get("bottom_z",110))-head
	if ramp_active:
		return [overlap] if (above and render_height >= threshold) or (not above and render_height <= threshold) else []
	if age < 0:
		return [overlap] if (above and threshold <= 0) or not above else []
	if threshold > active_jump_apex: return [] if above else [overlap]
	if threshold < 0: return [overlap] if above else []
	var ascent: float
	var descent: float
	if ballistic:
		var discriminant := launch_velocity*launch_velocity+4*launch_gravity*(launch_height-threshold)
		var root := sqrt(maxf(0,discriminant))
		ascent = ((launch_velocity-root)/(2*launch_gravity)-age)/dt
		descent = ((launch_velocity+root)/(2*launch_gravity)-age)/dt
	else:
		var root := sqrt(maxf(0,1-threshold/active_jump_apex))
		ascent = (active_jump_duration*0.5*(1-root)-age)/dt
		descent = (active_jump_duration*0.5*(1+root)-age)/dt
	var spans: Array = [Vector2(ascent,descent)] if above else [Vector2(-INF,ascent),Vector2(descent,INF)]
	var result: Array = []
	for span in spans:
		var lo := maxf(overlap.x,span.x)
		var hi := minf(overlap.y,span.y)
		if hi > lo or (hi == lo and kind in ["gap","long_pit","overhead"]): result.append(Vector2(lo,hi))
	return result

func _subtract_support(spans: Array, support: Vector2) -> Array:
	if support.x < 0: return spans
	var result: Array = []
	for span in spans:
		if support.y < span.x or support.x > span.y:
			result.append(span)
			continue
		if span.x < support.x: result.append(Vector2(span.x,support.x-EPS))
		if span.y > support.y: result.append(Vector2(support.y+EPS,span.y))
	return result

func _surface(x: float) -> float:
	var left := float(active_ramp.x)-float(active_ramp.width)*0.5
	var u := (x-left)/float(active_ramp.width)
	var rise := float(active_ramp.get("rise",40))
	if u <= 0: return 0
	if u > 1: return rise*(2*u-1)
	return rise*u*u

func _ramp_geometry(x: float) -> Array[float]:
	# Solve the chord's projected width so the rotated rigid110px board touches at both ends.
	var low := 0.0
	var high := 55.0
	for iteration in range(32):
		var half_x := (low+high)*0.5
		var rise := _surface(x+half_x)-_surface(x-half_x)
		if 4*half_x*half_x+rise*rise > 110*110:
			high = half_x
		else:
			low = half_x
	var half_x := (low+high)*0.5
	var rear := _surface(x-half_x)
	var front := _surface(x+half_x)
	return [(rear+front)*0.5,-atan2(front-rear,2*half_x),half_x]

func _ramp_pose(x: float) -> void:
	var pose := _ramp_geometry(x)
	render_height = pose[0]
	render_pitch = pose[1]
	jump_height = render_height

func _launch(ramp := false) -> void:
	active_jump_duration = 1.25 if ramp else 0.6
	active_jump_apex = 54
	jump_age = 0
	boosted = ramp
	ballistic = ramp
	if ramp:
		var x := position.x+encounter_scroll
		_ramp_pose(x)
		launch_height = render_height
		launch_pitch = render_pitch
		# Differentiate the solved center path, including its changing projected contact width.
		launch_velocity = scroll_speed*(_ramp_geometry(x+0.01)[0]-_ramp_geometry(x-0.01)[0])/0.02
		launch_gravity = (launch_height+launch_velocity*active_jump_duration)/pow(active_jump_duration,2)
		active_jump_apex = launch_height+launch_velocity*launch_velocity/(4*launch_gravity)
	else:
		render_height = 0
		render_pitch = 0
	jump_height = render_height
	ramp_active = false
	emit_event("ramp" if ramp else "jump")

func tick(host: Node2D, delta: float, steering: Vector2, jumping: bool) -> void:
	if complete or host.paused or host.life_state != "alive" or delta <= 0: return
	var remaining := delta
	var pressed := jumping
	while remaining > EPS and not complete and host.life_state == "alive":
		var dt := minf(STEP,remaining)
		if phase == "rest": dt = minf(dt,rest_remaining)
		if phase == "rest":
			clock += dt
			rest_remaining = maxf(0,rest_remaining-dt)
			host.invulnerable = maxf(0,host.invulnerable-dt)
			# Safe rest has no collision/warning actors; movement remains responsive.
			position += steering.limit_length()*Vector2(x_speed,bank_speed)*dt
			position = position.clamp(Vector2(180,260),Vector2(650,400))
			if pressed and jump_age < 0 and cooldown <= 0:
				_launch()
			_advance_air_motion(dt)
			if rest_remaining <= EPS:
				if encounter_index+1 >= definition.encounters.size():
					complete = true
					phase = "complete"
					host.won = true
					emit_event("finished")
				else: _start_encounter(encounter_index+1)
		else:
			_step(host,dt,steering,pressed)
		remaining -= dt
		pressed = false
	sync_hero(host)

func _step(host: Node2D, dt: float, steering: Vector2, pressed: bool, check_ramps := true) -> void:
	var old_age := jump_age
	var start_position := position
	var a := position+Vector2(encounter_scroll,0)
	var input := steering.limit_length()
	var movement := Vector2(0 if boosted or ramp_active else input.x*x_speed,input.y*bank_speed)*dt
	var next_position := (position+movement).clamp(Vector2(180,260),Vector2(650,400))
	var b := next_position+Vector2(encounter_scroll+scroll_speed*dt,0)
	# Losing full bank support cannot retain or reacquire the automatic ramp launch.
	if ramp_active:
		var bank_min := float(active_ramp.y)-float(active_ramp.depth)*0.5+HALF.y
		var bank_max := float(active_ramp.y)+float(active_ramp.depth)*0.5-HALF.y
		if next_position.y < bank_min or next_position.y > bank_max:
			# Leaving the side drops naturally to the water; it never grants the long-pit boost.
			ramp_active = false
			boosted = false
			launch_height = render_height
			launch_velocity = 0
			launch_gravity = 181.128
			launch_pitch = render_pitch
			active_jump_duration = sqrt(launch_height/launch_gravity)
			active_jump_apex = launch_height
			ballistic = active_jump_duration > EPS
			jump_age = 0 if ballistic else -1
			old_age = jump_age
	# Split entry and lip events exactly, so the entire attached composite follows one surface pose.
	if ramp_active:
		var lip := float(active_ramp.get("launch_x",float(active_ramp.x)+float(active_ramp.width)*0.5))
		if check_ramps and a.x < lip and b.x >= lip:
			var fraction := (lip-a.x)/(b.x-a.x)
			_step(host,dt*fraction,steering,false,false)
			_launch(true)
			_step(host,dt*(1-fraction),steering,false,false)
			return
		if a.x >= lip and check_ramps:
			_launch(true)
			_step(host,dt,steering,false,false)
			return
	elif check_ramps:
		var ramp: Dictionary = {}
		var ramp_at := 2.0
		for obstacle: Dictionary in course.obstacles:
			if obstacle.kind != "ramp" or used_ramps.has(obstacle.id): continue
			var rect := obstacle_rect(obstacle)
			var entry_x := rect.position.x-55
			if a.x > entry_x or b.x < entry_x or b.x <= a.x: continue
			var at := (entry_x-a.x)/(b.x-a.x)
			var bank := lerpf(a.y,b.y,at)
			used_ramps[obstacle.id] = true
			if jump_age >= 0 or rect.size.y < HALF.y*2: continue
			if bank-HALF.y < rect.position.y or bank+HALF.y > rect.end.y: continue
			if at < ramp_at:
				ramp = obstacle
				ramp_at = at
		if not ramp.is_empty():
			if ramp_at > EPS: _step(host,dt*ramp_at,steering,false,false)
			if host.life_state != "alive": return
			used_ramps[ramp.id] = true
			active_ramp = ramp
			ramp_active = true
			_ramp_pose(position.x+encounter_scroll)
			_step(host,dt*(1-ramp_at),steering,false,false)
			return
	if dt <= EPS: return
	if pressed and jump_age < 0 and not ramp_active and cooldown <= 0:
		_launch()
		old_age = 0
	position = next_position
	clock += dt
	encounter_scroll += scroll_speed*dt
	var contacts: Array[Dictionary] = []
	for obstacle: Dictionary in course.obstacles:
		var kind := str(obstacle.kind)
		if kind in ["deck","ramp"]: continue
		var motion: Dictionary = obstacle.get("motion",{})
		var max_x := absf(float(motion.get("amplitude",0))) if motion.get("axis","") == "x" else 0.0
		if contact_latches.has(obstacle.id):
			if b.x-HALF.x > float(obstacle.x)+float(obstacle.width)*0.5+max_x: contact_latches.erase(obstacle.id)
			continue
		var interval := _relative_interval(obstacle,a,b,encounter_clock,dt)
		if interval.x < 0: continue
		var spans := _vertical_spans(kind,obstacle,old_age,dt,interval,hero_head_height(host))
		if kind in ["gap","long_pit"]:
			for deck: Dictionary in course.obstacles:
				if deck.kind == "deck": spans = _subtract_support(spans,_relative_interval(deck,a,b,encounter_clock,dt,true))
		if not spans.is_empty(): contacts.append({"obstacle":obstacle,"at":spans[0].x})
	contacts.sort_custom(func(left: Dictionary,right: Dictionary) -> bool: return left.at < right.at)
	var processed := 0.0
	for contact in contacts:
		var event_time := float(contact.at)*dt
		host.invulnerable = maxf(0,host.invulnerable-(event_time-processed))
		processed = event_time
		var obstacle: Dictionary = contact.obstacle
		if obstacle.kind in ["gap","long_pit"]:
			if host.life_state == "alive":
				# Freeze at the actual unsupported contact, not the end of this simulation substep.
				position = start_position.lerp(next_position,float(contact.at))
				clock -= dt-event_time
				encounter_scroll -= scroll_speed*(dt-event_time)
				encounter_clock += event_time
				jump_height = 0
				render_height = 0
				host.health = 1
				host.invulnerable = 0
				host.hurt_player()
				emit_event("fall",str(obstacle.id))
			return
		contact_latches[obstacle.id] = true
		if host.invulnerable <= 0:
			host.hurt_player()
			hit_ids[obstacle.id] = true
			emit_event("hit",str(obstacle.id))
			if host.life_state != "alive": return
	host.invulnerable = maxf(0,host.invulnerable-(dt-processed))
	encounter_clock += dt
	_advance_air_motion(dt)
	if _encounter_clear():
		phase = "rest"
		rest_remaining = 3.0
		course = {"obstacles":[]}
		emit_event("rest_started")

func _advance_air_motion(dt: float) -> void:
	recovery_clock = maxf(0,recovery_clock-dt)
	cooldown = maxf(0,cooldown-dt)
	if jump_age >= 0:
		jump_age += dt
		if jump_age+EPS >= active_jump_duration:
			jump_age = -1
			boosted = false
			ballistic = false
			cooldown = 0.10
			emit_event("landed")
	jump_height = height(jump_age)
	render_height = jump_height
	if ramp_active:
		_ramp_pose(position.x+encounter_scroll)
	elif ballistic:
		var tangent := -atan2(launch_velocity-2*launch_gravity*jump_age,scroll_speed)
		render_pitch = lerpf(launch_pitch,tangent,clampf(jump_age/0.12,0,1))
		# Level the rigid composite before contact instead of snapping its angle on the landing frame.
		var settling := clampf((active_jump_duration-jump_age)/0.18,0,1)
		render_pitch *= settling*settling*(3-2*settling)
	else:
		render_pitch = 0

func _encounter_clear() -> bool:
	if ramp_active or jump_age >= 0 or recovery_clock > EPS or not contact_latches.is_empty(): return false
	for obstacle: Dictionary in course.obstacles:
		var motion: Dictionary = obstacle.get("motion",{})
		var max_x := absf(float(motion.get("amplitude",0))) if motion.get("axis","") == "x" else 0.0
		if float(obstacle.x)+float(obstacle.width)*0.5+max_x-encounter_scroll >= 180-HALF.x: return false
	return true
