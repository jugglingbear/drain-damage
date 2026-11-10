extends RefCounted
## One spider's simulation. Caller owns swept projectile collision and cross-spider capture exclusion.
const ART_SIZE := Vector2(128,128)
const CEILING_ANCHOR := Vector2(64,12)
const DEFAULTS := {
	"crawl_speed":35.0,"crawl_seconds":0.5,"windup_seconds":0.7,"web_speed":240.0,
	"recover_seconds":1.5,"haul_speed":60.0,"minimum_haul_seconds":2.0,
	"cocoon_presses":6,"snare_presses":3,"trap_seconds":6.0,"trap_cap":2,
	"release_immunity_seconds":1.0,"mouth_offset":Vector2(0,70),
}
var tuning: Dictionary
var state := "inactive"
var alive: bool:
	get: return state not in ["inactive","dead"]
var position := Vector2.ZERO
var limits := Vector2.ZERO
var direction := 1.0
var state_time := 0.0
var captive_position := Vector2.ZERO
var capture_kind := ""
var presses := 0
var capture_trap := -1
var release_immunity := 0.0
var traps: Array[Dictionary] = []
var projectiles: Dictionary = {}
var _events: Array[Dictionary] = []
var _serial := 0
var _paused := false

func _init(overrides: Dictionary = {}) -> void:
	tuning = DEFAULTS.duplicate(true)
	for key in overrides:
		assert(tuning.has(key),"Unknown spider tuning: "+str(key))
		tuning[key] = overrides[key]
	for key in DEFAULTS:
		if key != "mouth_offset": assert(float(tuning[key]) > 0,"Spider tuning must be positive")
	assert(int(tuning.trap_cap) >= 1 and int(tuning.cocoon_presses) >= 1 and int(tuning.snare_presses) >= 1)

func start(anchor: Vector2, crawl_limits: Vector2, facing := 1.0) -> void:
	clear("restart")
	limits = Vector2(minf(crawl_limits.x,crawl_limits.y),maxf(crawl_limits.x,crawl_limits.y))
	position = Vector2(clampf(anchor.x,limits.x,limits.y),anchor.y)
	direction = -1.0 if facing < 0 else 1.0
	state = "crawl"
	_paused = false

func drain_events() -> Array[Dictionary]:
	var result := _events
	_events = []
	return result

func movement_locked() -> bool:
	return not capture_kind.is_empty()

func tear_progress() -> float:
	if capture_kind.is_empty(): return 0
	return clampf(float(presses)/float(tuning.cocoon_presses if capture_kind == "cocoon"
		else tuning.snare_presses),0,1)

func mouth_position() -> Vector2:
	return position+Vector2(tuning.mouth_offset)

func _remove_trap(id: int, reason: String) -> void:
	for index in range(traps.size()):
		if int(traps[index].id) != id: continue
		traps.remove_at(index)
		_events.append({"event":"trap_removed","id":id,"reason":reason})
		if capture_kind == "snare" and capture_trap == id: _release(reason)
		return

func _release(reason: String) -> void:
	if capture_kind.is_empty(): return
	var old_kind := capture_kind
	capture_kind = ""
	capture_trap = -1
	presses = 0
	release_immunity = float(tuning.release_immunity_seconds)
	_events.append({"event":"released","kind":old_kind,"reason":reason,
		"position":captive_position,"immunity":release_immunity})
	if state == "haul":
		state = "recover"
		state_time = 0

func clear(reason := "teardown") -> void:
	_release(reason)
	for trap in traps:
		_events.append({"event":"trap_removed","id":trap.id,"reason":reason})
	traps.clear()
	projectiles.clear()
	# Drop pending attacks so a same-frame death cannot dispatch an earlier queued web or hit.
	_events = _events.filter(func(event: Dictionary) -> bool:
		return event.event in ["released","trap_removed"])
	_events.append({"event":"clear_projectiles","reason":reason})
	state = "inactive"
	state_time = 0

func owner_killed() -> void:
	clear("owner_killed")
	state = "dead"

func _can_capture(available: bool) -> bool:
	return available and not _paused and state not in ["inactive","dead"] \
		and capture_kind.is_empty() and release_immunity <= 0

func projectile_hit_player(id: int, hero_position: Vector2, capture_available := true) -> bool:
	if _paused or not projectiles.has(id): return false
	projectiles.erase(id)
	if not _can_capture(capture_available): return false
	capture_kind = "cocoon"
	captive_position = hero_position
	presses = 0
	state = "haul"
	state_time = 0
	_events.append({"event":"captured","kind":"cocoon","position":hero_position})
	return true

func projectile_hit_solid(id: int, point: Vector2, is_floor := true) -> int:
	if _paused or not projectiles.has(id): return -1
	projectiles.erase(id)
	if not is_floor or state in ["inactive","dead"]: return -1
	while traps.size() >= int(tuning.trap_cap): _remove_trap(int(traps[0].id),"capacity")
	_serial += 1
	traps.append({"id":_serial,"position":point,"remaining":float(tuning.trap_seconds)})
	_events.append({"event":"trap_spawned","id":_serial,"position":point})
	return _serial

func trigger_floor_trap(id: int, hero_position: Vector2, capture_available := true) -> bool:
	if not _can_capture(capture_available): return false
	for trap in traps:
		if int(trap.id) != id: continue
		capture_kind = "snare"
		capture_trap = id
		captive_position = hero_position
		presses = 0
		_events.append({"event":"captured","kind":"snare","position":hero_position})
		return true
	return false

func escape_press() -> bool:
	if _paused or capture_kind.is_empty(): return false
	presses += 1
	_events.append({"event":"tear","progress":tear_progress()})
	var required := int(tuning.cocoon_presses if capture_kind == "cocoon" else tuning.snare_presses)
	if presses >= required:
		if capture_kind == "snare": _remove_trap(capture_trap,"escaped")
		else: _release("escaped")
	return true

func step(delta: float, hero_position: Vector2, paused := false) -> void:
	_paused = paused
	if paused or delta <= 0 or state in ["inactive","dead"]: return
	var remaining := delta
	while remaining > 0.0000001:
		var dt := minf(remaining,1.0/120.0)
		remaining -= dt
		release_immunity = maxf(0,release_immunity-dt)
		for index in range(traps.size()-1,-1,-1):
			traps[index].remaining -= dt
			if float(traps[index].remaining) <= 0.0000001: _remove_trap(int(traps[index].id),"expired")
		state_time += dt
		if state == "haul":
			captive_position = captive_position.move_toward(mouth_position(),float(tuning.haul_speed)*dt)
			if state_time+0.0000001 >= float(tuning.minimum_haul_seconds) \
					and captive_position.distance_to(mouth_position()) < 0.001:
				_events.append({"event":"ordinary_hit","amount":1})
				_release("mouth")
		elif state == "crawl":
			position.x += direction*float(tuning.crawl_speed)*dt
			if position.x < limits.x or position.x > limits.y:
				position.x = clampf(position.x,limits.x,limits.y)
				direction *= -1
			if state_time+0.0000001 >= float(tuning.crawl_seconds):
				state = "windup"
				state_time = 0
		elif state == "windup" and state_time+0.0000001 >= float(tuning.windup_seconds):
			var aim := mouth_position().direction_to(hero_position)
			if aim.is_zero_approx(): aim = Vector2.DOWN
			_serial += 1
			projectiles[_serial] = true
			_events.append({"event":"web_fired","id":_serial,"origin":mouth_position(),
				"direction":aim,"velocity":aim*float(tuning.web_speed)})
			state = "recover"
			state_time = 0
		elif state == "recover" and state_time+0.0000001 >= float(tuning.recover_seconds):
			state = "crawl"
			state_time = 0
