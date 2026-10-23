extends RefCounted
## Room-local boss logic. Caller owns artwork, camera, audio and shared hero invulnerability.
const Data = preload("res://scripts/combat_data.gd")
const FLOOR_Y := 440.0
const SLUDGE_SPEED := 210.0
const SLUDGE_RADIUS := 12.0
const ACID_WIDTH := 64.0
const CORRIDOR_WIDTH := 180.0
const SAFE_SPEED := 235.0
const PRESSURE_WARNING := 1.2
const GAS_SECONDS := 2.0
const REINFORCEMENT_SECONDS := 3.0
const PRESSURE_CLEAR := 0.25
const GAS_SPEED := 30.0
const GAS_SIZE := Vector2(100,64)
const DURATIONS := {"volley_warning":0.9,"acid_warning":1.2,"acid_fall":0.6,
	"acid_puddle":0.8,"approach":0.8,"recovery":5.0,"collapse":1.2}
var max_hp := 0
var hp := 0
var phase := 1
var state := "idle"
var elapsed := 0.0
var active := false
var exit_open := false
var hazards: Array[Dictionary] = []
var warnings: Array[Rect2] = []
var safe_corridor := Rect2()
var shell := Rect2(700,120,255,320)
var weak_point := Rect2(626,377,48,42)
var high_weak_point := Rect2(692,304,48,42)
var recovery_index := 0
var pressure_kind := ""
var pressure_wave := 0
var reinforcement_requests: Array[Dictionary] = []
var _gas_start := Rect2()
var _gas_velocity := Vector2.ZERO
var nozzle := Vector2(675,255)
var floor_span := Rect2(0,FLOOR_Y,700,0)
var _hero := Rect2(96,394,26,46)
var _events: Array[String] = []
var _hurts: Array[Rect2] = []
var _hits: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _frozen := false
var _pattern := "sludge"
var _aim := Vector2.LEFT
var _shots := 0
var _closing_warned := false

func _init() -> void:
	reset()

func configure_geometry(body: Rect2, mouth: Rect2, outlet: Vector2, floor_area: Rect2) -> void:
	assert(not active and body.has_area() and mouth.has_area() and floor_area.size.x >= CORRIDOR_WIDTH)
	shell = body
	weak_point = mouth
	nozzle = outlet
	floor_span = floor_area

func reset(seed_value: int = 1) -> void:
	max_hp = int(Data.monster("clogfather").health.max_hp)
	hp = max_hp
	phase = 1
	recovery_index = 0
	pressure_kind = ""
	pressure_wave = 0
	reinforcement_requests.clear()
	_gas_start = Rect2()
	_gas_velocity = Vector2.ZERO
	state = "idle"
	elapsed = 0
	active = false
	exit_open = false
	hazards.clear()
	warnings.clear()
	_events.clear()
	_hurts.clear()
	_hits.clear()
	safe_corridor = Rect2()
	_rng.seed = seed_value
	_frozen = false
	_hero = Rect2(96,394,26,46)
	_aim = Vector2.LEFT
	_pattern = "sludge"
	_shots = 0
	_closing_warned = false

func start(hero_rect: Rect2) -> void:
	if active or exit_open: return
	_hero = hero_rect
	active = true
	_events.append("encounter_started")
	_begin_pattern()

func damageable() -> bool:
	return active and not _frozen and state == "recovery" and hp > 0

func body_rect() -> Rect2:
	return shell if active and hp > 0 else Rect2()

func weak_point_rect() -> Rect2:
	return (high_weak_point if recovery_index % 2 == 0 else weak_point) if damageable() else Rect2()

func hit(amount: int, attack_id: String, airborne_attack := false) -> int:
	if not active or _frozen or hp <= 0 or amount <= 0 or attack_id.is_empty() or _hits.has(attack_id): return 0
	_hits[attack_id] = true
	if not damageable() or (recovery_index % 2 == 0 and not airborne_attack):
		_events.append("closed_shell_hit")
		return 0
	var accepted := mini(amount,hp)
	hp -= accepted
	if hp == 0:
		_clear_pressure()
		hazards.clear()
		warnings.clear()
		_hurts.clear()
		_enter("collapse")
		_events.append("death_started")
	else: _events.append("damage_accepted")
	return accepted

func drain_events() -> Array[String]:
	var result := _events.duplicate()
	_events.clear()
	return result

func hurt_rects() -> Array[Rect2]:
	if _frozen or not active or hp <= 0: return []
	var result := _hurts.duplicate()
	if state not in ["approach","recovery"]: result.append(shell)
	return result

func snapshot() -> Dictionary:
	return {"state":state,"elapsed":elapsed,"phase":phase,"hp":hp,"max_hp":max_hp,
		"active":active,"exit_open":exit_open,"damageable":damageable(),"body_rect":body_rect(),
		"weak_point_rect":weak_point_rect(),"hazards":hazards.duplicate(true),
		"warnings":warnings.duplicate(),"safe_corridor":safe_corridor,"nozzle":nozzle,
		"weak_point_level":"high" if recovery_index > 0 and recovery_index % 2 == 0 else "low",
		"recovery_index":recovery_index,"aim":_aim,"closing":state == "recovery" and elapsed >= 4.25,
		"pressure_kind":pressure_kind,"pressure_wave":pressure_wave,
		"reinforcement_requests":reinforcement_requests.duplicate(true)}

func step(delta: float, hero_rect: Rect2, frozen := false) -> void:
	_frozen = frozen
	_hurts.clear()
	if frozen or not active or delta <= 0: return
	_hero = hero_rect
	var remaining := delta
	while remaining > 0.000001 and active:
		var dt := minf(remaining,1.0/120)
		remaining -= dt
		_tick(dt)

func _enter(next_state: String) -> void:
	state = next_state
	elapsed = 0
	if state in ["approach","recovery","collapse","complete"]:
		_hurts.clear()
		warnings.clear()
		safe_corridor = Rect2()
	if state == "recovery":
		recovery_index += 1
		_closing_warned = false
		_events.append("weak_point_open")

func _begin_pattern() -> void:
	warnings.clear()
	safe_corridor = Rect2()
	if _pattern == "sludge":
		_aim = (_hero.get_center()-nozzle).normalized()
		if _aim.x >= -0.05: _aim = Vector2(-1,0.2).normalized()
		_shots = 0
		_enter("volley_warning")
		_events.append("volley_warning")
	elif _plan_acid():
		_enter("acid_warning")
		_events.append("acid_warning")
	else:
		_enter("approach")

func _clear_pressure() -> void:
	if not pressure_kind.is_empty(): _events.append("pressure_cleared")
	pressure_kind = ""
	reinforcement_requests.clear()
	hazards.clear()
	warnings.clear()
	_hurts.clear()
	safe_corridor = Rect2()

func _begin_pressure() -> void:
	pressure_wave += 1
	pressure_kind = "gas" if pressure_wave % 2 == 1 else "reinforcements"
	warnings.clear()
	hazards.clear()
	reinforcement_requests.clear()
	safe_corridor = Rect2()
	# The entry shutter closes at local x80; space behind it is never an escape route.
	var left := maxf(80.0,floor_span.position.x)
	var right := floor_span.end.x
	var center := clampf(_hero.get_center().x,left,right)
	for x in [center+100,center-100-CORRIDOR_WIDTH,clampf(center-90,left,right-CORRIDOR_WIDTH)]:
		if x < left or x+CORRIDOR_WIDTH > right: continue
		var destination := clampf(_hero.position.x,x,x+CORRIDOR_WIDTH-_hero.size.x)
		if absf(destination-_hero.position.x) > SAFE_SPEED*(PRESSURE_WARNING-0.15): continue
		safe_corridor = Rect2(x,0,CORRIDOR_WIDTH,FLOOR_Y)
		break
	if not safe_corridor.has_area():
		_clear_pressure()
		_enter("pressure_clear")
		return
	var flanks: Array[Rect2] = [Rect2(left,160,safe_corridor.position.x-left,280),
		Rect2(safe_corridor.end.x,160,right-safe_corridor.end.x,280)]
	# Prefer the hero's side, while leaving the whole promised corridor untouched.
	if center > safe_corridor.get_center().x: flanks.reverse()
	if pressure_kind == "gas":
		for flank in flanks:
			# Twenty extra pixels contain the140px artwork around the100px damage core.
			if flank.size.x < GAS_SIZE.x+GAS_SPEED*GAS_SECONDS+40: continue
			var toward_right := flank.position.x < safe_corridor.position.x
			var x := flank.position.x+20 if toward_right else flank.end.x-20-GAS_SIZE.x
			_gas_start = Rect2(Vector2(x,356),GAS_SIZE)
			_gas_velocity = Vector2(GAS_SPEED if toward_right else -GAS_SPEED,0)
			warnings.append(_gas_start)
			break
	else:
		var cap := 1 if phase == 1 else 2
		for flank in flanks:
			# Bounds contain the48px core;16px inset also contains its64px render radius.
			var bounds := Rect2(flank.position+Vector2(16,0),flank.size-Vector2(32,0))
			if bounds.size.x < 116: continue
			var spawn := Vector2(bounds.get_center().x,280)
			reinforcement_requests.append({"id":"clog-pressure-%d-%d" % [pressure_wave,reinforcement_requests.size()],
				"center":spawn,"bounds":bounds,"hp":24})
			warnings.append(Rect2(spawn-Vector2(48,48),Vector2(96,96)))
			if reinforcement_requests.size() == cap: break
	if warnings.is_empty():
		_clear_pressure()
		_enter("pressure_clear")
		return
	_enter("pressure_warning")
	_events.append("gas_warning" if pressure_kind == "gas" else "reinforcements_warning")

func _plan_acid() -> bool:
	var center := clampf(_hero.get_center().x,floor_span.position.x,floor_span.end.x)
	var candidates := [center+100,center-100-CORRIDOR_WIDTH]
	for start_x in candidates:
		if start_x < floor_span.position.x or start_x+CORRIDOR_WIDTH > floor_span.end.x: continue
		var destination := clampf(_hero.position.x,start_x,start_x+CORRIDOR_WIDTH-_hero.size.x)
		if absf(destination-_hero.position.x) > SAFE_SPEED*(1.2-0.15): continue
		safe_corridor = Rect2(start_x,0,CORRIDOR_WIDTH,FLOOR_Y)
		break
	if not safe_corridor.has_area(): return false
	var positions: Array[float] = [clampf(center,floor_span.position.x+32,floor_span.end.x-32)]
	var offset := _rng.randf_range(0,20)
	for x in range(int(floor_span.position.x+32),int(floor_span.end.x-32),80): positions.append(x+offset)
	var count := 3 if phase == 3 else 2
	for x in positions:
		var mark := Rect2(x-ACID_WIDTH/2,0,ACID_WIDTH,FLOOR_Y)
		if mark.end.x > floor_span.end.x or mark.intersects(safe_corridor): continue
		var overlaps := false
		for existing in warnings:
			if existing.grow(12).intersects(mark): overlaps = true
		if overlaps: continue
		if (warnings.size()+1)*ACID_WIDTH > floor_span.size.x*0.35: break
		warnings.append(mark)
		if warnings.size() == count: break
	return not warnings.is_empty()

func _tick(dt: float) -> void:
	elapsed += dt
	if state == "pressure_warning":
		if elapsed+0.000001 >= PRESSURE_WARNING:
			_enter("pressure_active")
			warnings.clear()
			if pressure_kind == "gas":
				hazards.append({"kind":"gas","rect":_gas_start,"age":0.0,"velocity":_gas_velocity})
				_events.append("gas_started")
			else: _events.append("reinforcements_spawn")
		return
	if state == "pressure_active":
		for hazard in hazards:
			var previous: Rect2 = hazard.rect
			hazard.age = minf(GAS_SECONDS,float(hazard.age)+dt)
			hazard.rect = Rect2(_gas_start.position+_gas_velocity*hazard.age,GAS_SIZE)
			_hurts.append(previous.merge(hazard.rect))
		if elapsed+0.000001 >= (GAS_SECONDS if pressure_kind == "gas" else REINFORCEMENT_SECONDS):
			_clear_pressure()
			_enter("pressure_clear")
		return
	if state == "pressure_clear":
		if elapsed+0.000001 >= PRESSURE_CLEAR: _begin_pattern()
		return
	if state == "volley_warning" and elapsed+0.000001 >= DURATIONS.volley_warning:
		_enter("volley")
	if state == "volley":
		var count := 3 if phase == 1 else 4
		while _shots < count and elapsed+0.000001 >= _shots*0.45:
			hazards.append({"kind":"sludge","pos":nozzle,"velocity":_aim*SLUDGE_SPEED,"age":0.0})
			_shots += 1
			_events.append("projectile_spawn")
		for index in range(hazards.size()-1,-1,-1):
			var hazard: Dictionary = hazards[index]
			var old: Vector2 = hazard.pos
			hazard.age += dt
			hazard.pos += hazard.velocity*dt
			var next: Vector2 = hazard.pos
			_hurts.append(Rect2(old,Vector2.ZERO).expand(next).grow(SLUDGE_RADIUS))
			if next.x < -SLUDGE_RADIUS or next.y >= FLOOR_Y-SLUDGE_RADIUS or hazard.age >= 4.0:
				hazards.remove_at(index)
				_events.append("projectile_hit")
		if _shots == count and hazards.is_empty(): _enter("approach")
	elif state == "acid_warning" and elapsed+0.000001 >= DURATIONS.acid_warning:
		_enter("acid_fall")
		for mark in warnings: hazards.append({"kind":"acid","pos":Vector2(mark.get_center().x,110)})
	elif state == "acid_fall":
		for hazard in hazards:
			var old_y: float = hazard.pos.y
			hazard.pos.y = lerpf(110,FLOOR_Y,minf(1,elapsed/DURATIONS.acid_fall))
			_hurts.append(Rect2(hazard.pos.x-32,old_y,64,maxf(1,hazard.pos.y-old_y)))
		if elapsed+0.000001 >= DURATIONS.acid_fall:
			_enter("acid_puddle")
			_events.append("acid_impact")
	elif state == "acid_puddle":
		for hazard in hazards: _hurts.append(Rect2(hazard.pos.x-32,FLOOR_Y-12,64,12))
		if elapsed+0.000001 >= DURATIONS.acid_puddle:
			hazards.clear()
			warnings.clear()
			_enter("approach")
	elif state == "approach" and elapsed+0.000001 >= DURATIONS.approach:
		_enter("recovery")
	elif state == "recovery":
		if elapsed >= 4.25 and not _closing_warned:
			_closing_warned = true
			_events.append("weak_point_closing")
		if elapsed+0.000001 >= DURATIONS.recovery:
			var next_phase := 3 if hp*3 <= max_hp else 2 if hp*3 <= max_hp*2 else 1
			_pattern = "acid" if _pattern == "sludge" else "sludge"
			if next_phase != phase:
				phase = next_phase
				_events.append("phase_changed")
			_begin_pressure()
	elif state == "collapse" and elapsed+0.000001 >= DURATIONS.collapse:
		active = false
		exit_open = true
		_enter("complete")
		_events.append("boss_defeated")
