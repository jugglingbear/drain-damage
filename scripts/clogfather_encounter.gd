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
var difficulty := "easy"
var gas_hp := 60
var _gas_plans: Array[Dictionary] = []
var _gas_hits: Dictionary = {}
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
var volley_round := 0
var _closing_warned := false

func _init() -> void:
	reset()

func configure_difficulty(mode: String, active_weapon_damage: int = 12) -> void:
	assert(not active and mode in ["easy","normal","hard"] and active_weapon_damage > 0)
	difficulty = mode
	gas_hp = active_weapon_damage*5

func gas_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if _frozen or not active or state != "pressure_active": return targets
	for hazard in hazards:
		if hazard.kind == "gas" and hazard.hp > 0: targets.append({"id":hazard.id,"rect":hazard.rect})
	return targets

func hit_gas(id: String, amount: int, attack_id: String) -> int:
	if _frozen or not active or state != "pressure_active" or amount <= 0 or attack_id.is_empty(): return 0
	var key := id+":"+attack_id
	if _gas_hits.has(key): return 0
	for index in range(hazards.size()):
		var hazard: Dictionary = hazards[index]
		if hazard.kind != "gas" or hazard.id != id: continue
		_gas_hits[key] = true
		var accepted := mini(amount,int(hazard.hp))
		hazard.hp -= accepted
		hazard.flash = 0.08
		if hazard.hp == 0:
			hazards.remove_at(index)
			_hurts.clear()
			for remaining in hazards: _hurts.append(remaining.rect)
			_events.append("gas_destroyed")
		else: _events.append("gas_damaged")
		return accepted
	return 0

func pressure_warning_seconds() -> float:
	if pressure_kind != "gas" or difficulty == "easy": return 1.2
	return 0.75 if difficulty == "normal" else 0.55

func pressure_active_seconds() -> float:
	if pressure_kind == "gas": return 2.0 if difficulty == "easy" else 4.0 if difficulty == "normal" else 4.5
	return 3.0 if difficulty == "easy" else 4.0 if difficulty == "normal" else 5.0

func acid_warning_seconds() -> float:
	return 1.2 if difficulty == "easy" else 0.9 if difficulty == "normal" else 0.7

func configure_geometry(body: Rect2, mouth: Rect2, outlet: Vector2, floor_area: Rect2) -> void:
	assert(not active and body.has_area() and mouth.has_area() and floor_area.size.x >= CORRIDOR_WIDTH)
	shell = body
	weak_point = mouth
	nozzle = outlet
	floor_span = floor_area

func reset(seed_value: int = 1) -> void:
	_gas_plans.clear()
	_gas_hits.clear()
	max_hp = int(Data.monster("clogfather").health.max_hp)
	hp = max_hp
	phase = 1
	recovery_index = 0
	pressure_kind = ""
	pressure_wave = 0
	reinforcement_requests.clear()
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
	volley_round = 0
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
		"pressure_kind":pressure_kind,"pressure_wave":pressure_wave,"difficulty":difficulty,"gas_hp":gas_hp,
		"volley_round":volley_round,
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
		volley_round = 1
		_begin_volley_round()
	elif _plan_acid():
		_enter("acid_warning")
		_events.append("acid_warning")
	else:
		_enter("approach")

func _begin_volley_round() -> void:
	_aim = (_hero.get_center()-nozzle).normalized()
	if _aim.x >= -0.05: _aim = Vector2(-1,0.2).normalized()
	_shots = 0
	_enter("volley_warning")
	_events.append("volley_warning")

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
	_gas_plans.clear()
	_gas_hits.clear()
	reinforcement_requests.clear()
	safe_corridor = Rect2()
	var left := maxf(80.0,floor_span.position.x)
	var right := floor_span.end.x
	if pressure_kind == "reinforcements":
		# Fixed central escape leaves two columns on each flank, each with two rows.
		var middle := (left+right)*0.5
		safe_corridor = Rect2(middle-90,0,180,FLOOR_Y)
		var count := 2 if difficulty == "easy" else 4 if difficulty == "normal" else 8
		for index in range(count):
			var side := index % 2
			var column := (index/2) % 2 if count == 8 else 0
			var row := index/4 if count == 8 else index/2
			var flank_left := left if side == 0 else safe_corridor.end.x+16
			var flank_right := safe_corridor.position.x-16 if side == 0 else right
			var bounds := Rect2(flank_left,160,flank_right-flank_left,280)
			var x := lerpf(flank_left+48,flank_right-48,float(column)) if count == 8 else bounds.get_center().x
			var spawn := Vector2(x,224+row*120)
			reinforcement_requests.append({"id":"clog-pressure-%d-%d" % [pressure_wave,index],
				"center":spawn,"bounds":bounds,"hp":24})
			warnings.append(Rect2(spawn-Vector2(48,48),Vector2(96,96)))
	else:
		var width := 180.0 if difficulty == "easy" else 140.0 if difficulty == "normal" else 120.0
		var offset := 100.0 if difficulty == "easy" else 70.0 if difficulty == "normal" else 45.0
		var center := clampf(_hero.get_center().x,left,right)
		for x in [center+offset,center-offset-width,clampf(center-width*0.5,left,right-width)]:
			if x < left or x+width > right: continue
			var destination := clampf(_hero.position.x,x,x+width-_hero.size.x)
			if absf(destination-_hero.position.x) > SAFE_SPEED*(pressure_warning_seconds()-0.15): continue
			safe_corridor = Rect2(x,0,width,FLOOR_Y)
			break
		assert(safe_corridor.has_area(),"Gas requires a reachable escape lane")
		var flanks: Array[Rect2] = [Rect2(left,0,safe_corridor.position.x-left,440),
			Rect2(safe_corridor.end.x,0,right-safe_corridor.end.x,440)]
		if difficulty == "easy":
			if center > safe_corridor.get_center().x: flanks.reverse()
			for flank in flanks:
				if flank.size.x < 200: continue
				var rightward := flank.position.x < safe_corridor.position.x
				var x := flank.position.x+20 if rightward else flank.end.x-120
				_add_gas(Rect2(x,356,100,64),Vector2(30 if rightward else -30,0),flank)
				break
		else:
			var lanes: Array[Rect2] = []
			if flanks[0].size.x >= 160 and flanks[1].size.x >= 160:
				lanes = flanks
			else:
				var larger: Rect2 = flanks[0] if flanks[0].size.x > flanks[1].size.x else flanks[1]
				lanes = [Rect2(larger.position,Vector2(larger.size.x/2,440)),
					Rect2(larger.position+Vector2(larger.size.x/2,0),Vector2(larger.size.x/2,440))]
			for row in range(2 if difficulty == "normal" else 3):
				for lane in lanes:
					_add_gas(Rect2(lane.get_center().x-50,356-row*102,100,64),
						Vector2(65 if difficulty == "normal" else 90,0),lane)
	assert(not warnings.is_empty(),"Pressure wave cannot silently drop its formation")
	_enter("pressure_warning")
	_events.append("gas_warning" if pressure_kind == "gas" else "reinforcements_warning")

func _add_gas(rect: Rect2, velocity: Vector2, bounds: Rect2) -> void:
	_gas_plans.append({"id":"clog-gas-%d-%d" % [pressure_wave,_gas_plans.size()],"kind":"gas",
		"rect":rect,"origin":rect.position,"bounds":bounds,"age":0.0,"velocity":velocity,
		"hp":gas_hp,"max_hp":gas_hp,"flash":0.0})
	warnings.append(rect)

func _plan_acid() -> bool:
	var left := floor_span.position.x if difficulty == "easy" else maxf(80,floor_span.position.x)
	var width := 180.0 if difficulty == "easy" else 140.0 if difficulty == "normal" else 120.0
	var offset := 100.0 if difficulty == "easy" else 70.0 if difficulty == "normal" else 45.0
	var center := clampf(_hero.get_center().x,left,floor_span.end.x)
	var candidates := [center+offset,center-offset-width]
	for start_x in candidates:
		if start_x < left or start_x+width > floor_span.end.x: continue
		var destination := clampf(_hero.position.x,start_x,start_x+width-_hero.size.x)
		if absf(destination-_hero.position.x) > SAFE_SPEED*(acid_warning_seconds()-0.15): continue
		safe_corridor = Rect2(start_x,0,width,FLOOR_Y)
		break
	if not safe_corridor.has_area(): return false
	var positions: Array[float] = [clampf(center,floor_span.position.x+32,floor_span.end.x-32)]
	var jitter := _rng.randf_range(0,20)
	for x in range(int(left+32),int(floor_span.end.x-32),80 if difficulty == "easy" else 8): positions.append(x+jitter)
	var count := (3 if phase == 3 else 2) if difficulty == "easy" else (5 if phase == 3 else 4) if difficulty == "normal" else (6 if phase == 3 else 5)
	for x in positions:
		var mark := Rect2(x-ACID_WIDTH/2,0,ACID_WIDTH,FLOOR_Y)
		if mark.position.x < left or mark.end.x > floor_span.end.x or mark.intersects(safe_corridor): continue
		var overlaps := false
		for existing in warnings:
			if existing.grow(12 if difficulty == "easy" else 4).intersects(mark): overlaps = true
		if overlaps: continue
		if (warnings.size()+1)*ACID_WIDTH > floor_span.size.x*(0.35 if difficulty == "easy" else 0.5 if difficulty == "normal" else 0.6): break
		warnings.append(mark)
		if warnings.size() == count: break
	return not warnings.is_empty()

func _tick(dt: float) -> void:
	elapsed += dt
	if state == "pressure_warning":
		if elapsed+0.000001 >= pressure_warning_seconds():
			_enter("pressure_active")
			warnings.clear()
			if pressure_kind == "gas":
				hazards.assign(_gas_plans.duplicate(true))
				_events.append("gas_started")
			else: _events.append("reinforcements_spawn")
		return
	if state == "pressure_active":
		for hazard in hazards:
			var previous: Rect2 = hazard.rect
			hazard.age = float(hazard.age)+dt
			hazard.flash = maxf(0,float(hazard.flash)-dt)
			var next: Rect2 = hazard.rect
			next.position += hazard.velocity*dt
			var minimum: float = hazard.bounds.position.x+20
			var maximum: float = hazard.bounds.end.x-120
			if next.position.x < minimum or next.position.x > maximum:
				hazard.velocity.x *= -1
				next.position.x = clampf(next.position.x,minimum,maximum)
			hazard.rect = next
			_hurts.append(previous.merge(hazard.rect))
		if elapsed+0.000001 >= pressure_active_seconds():
			_clear_pressure()
			_enter("pressure_clear")
		return
	if state == "pressure_clear":
		if elapsed+0.000001 >= PRESSURE_CLEAR: _begin_pattern()
		return
	if state == "volley_warning" and elapsed+0.000001 >= (0.9 if difficulty == "easy" else 0.7 if difficulty == "normal" else 0.55):
		_enter("volley")
	if state == "volley":
		var count := 3 if phase == 1 else 4
		while _shots < count and elapsed+0.000001 >= _shots*(0.45 if difficulty == "easy" else 0.35 if difficulty == "normal" else 0.25):
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
		if _shots == count and hazards.is_empty():
			if difficulty != "easy" and volley_round == 1:
				volley_round = 2
				_begin_volley_round()
			else: _enter("approach")
	elif state == "acid_warning" and elapsed+0.000001 >= acid_warning_seconds():
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
