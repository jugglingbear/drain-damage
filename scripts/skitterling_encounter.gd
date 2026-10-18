extends RefCounted
## Deterministic room-local encounter. Rendering, camera, audio and hero damage belong to the caller.
const FLOOR_Y := 440.0
const RAT_HP := 540
const PHASE_HP := 180
const MAX_HP := RAT_HP + PHASE_HP
const SWIM_SPEED := 340.0
const CHARGE_SPEED := 300.0
const ROCK_RADIUS := 14.0
const PORTS := [Vector2(250, 166), Vector2(710, 166), Vector2(48, 232), Vector2(912, 232)]
const DURATIONS := {
	"entry_skitter": 2.0, "rat_assembly": 2.5, "rat_ready": .6,
	"rat_bite_tell": .8, "rat_bite": .2, "rat_bite_recovery": 1.2,
	"rat_pipe_retreat": .7, "rat_inside_pipe": .5, "rat_pipe_warning": 2.0,
	"rat_pipe_launch": .6, "rat_pipe_abort": .6, "rat_landing_recovery": 1.4,
	"rat_collapse": 4.5, "reskitter": 4.5, "alligator_assembly": 2.5,
	"alligator_ready": .6,
	"alligator_jaw_recovery": 1.8, "alligator_water_dive": .6,
	"alligator_water_warning": .8, "alligator_charge_tell": .9, "alligator_charge_turn": .9, "alligator_surface_warning": 1.0,
	"alligator_surface": .6, "alligator_surface_return": .6, "alligator_surface_recovery": 2.0, "terminal_death": 1.2,
}
const NEXT := {
	"entry_skitter": "rat_assembly", "rat_assembly": "rat_ready",
	"rat_bite_tell": "rat_bite", "rat_bite": "rat_bite_recovery",
	"rat_bite_recovery": "rat_pipe_retreat", "rat_pipe_retreat": "rat_inside_pipe",
	"rat_inside_pipe": "rat_pipe_warning", "rat_pipe_warning": "rat_pipe_launch",
	"rat_pipe_launch": "rat_landing_recovery", "rat_pipe_abort": "rat_inside_pipe", "rat_collapse": "reskitter",
	"reskitter": "alligator_assembly", "alligator_assembly": "alligator_ready",
	"alligator_jaw_recovery": "alligator_water_dive", "alligator_water_dive": "alligator_swim",
	"alligator_water_warning": "alligator_debris",
	"alligator_charge_tell": "alligator_charge", "alligator_charge_turn": "alligator_charge", "alligator_surface_warning": "alligator_surface",
	"alligator_surface": "alligator_surface_recovery", "alligator_surface_return": "alligator_surface_swim", "terminal_death": "complete",
}
const EVENTS := {
	"entry_skitter": "swarm_entry", "rat_assembly": "rat_assembly",
	"rat_bite_tell": "rat_bite_warning", "rat_bite": "attack_start",
	"rat_pipe_retreat": "rat_pipe_hide", "rat_pipe_abort": "rat_pipe_hide", "rat_pipe_warning": "pipe_warning",
	"rat_pipe_launch": "pipe_launch", "rat_landing_recovery": "pipe_land",
	"rat_collapse": "rat_phase_defeat", "reskitter": "reskitter",
	"alligator_assembly": "alligator_assembly", "alligator_water_dive": "water_dive",
	"alligator_surface_return": "water_dive",
	"alligator_water_warning": "tail_warning", "alligator_surface": "water_emerge",
	"terminal_death": "terminal_death",
	"alligator_swim": "swim_start", "alligator_surface_swim": "swim_start",
	"alligator_charge_tell": "alligator_jaw_warning", "alligator_charge_turn": "alligator_jaw_warning",
	"alligator_charge": "attack_start",
}
const VULNERABLE := ["rat_ready", "rat_bite_tell", "rat_bite", "rat_bite_recovery",
	"rat_pipe_retreat", "rat_pipe_launch", "rat_landing_recovery", "alligator_ready",
	"alligator_jaw_recovery",
	"alligator_water_dive", "alligator_surface_recovery",
	"alligator_charge_tell", "alligator_charge_turn", "alligator_charge"]
const HIDDEN := ["idle", "rat_inside_pipe", "rat_pipe_warning", "alligator_water_warning",
	"alligator_debris", "alligator_surface_warning", "complete"]

var state := "idle"
var phase := "rat"
var hp := MAX_HP
var position := Vector2(480, FLOOR_Y)
var facing := -1
var elapsed := 0.0
var active := false
var exit_open := false
var hazards: Array[Dictionary] = []
var port := -1
var landing := Vector2.ZERO
var column_x := 480.0
var _seed := 1
var _rng := RandomNumberGenerator.new()
var _events: Array[String] = []
var _hurts: Array[Rect2] = []
var _origin := Vector2.ZERO
var _destination := Vector2.ZERO
var _hero := Rect2(96, 394, 28, 46)
var _frozen := false
var _released := 0
var throw_origins: Array[float] = []
var swim_target := 480.0
var charge_end := 480.0
var _charge_leg := 0

func configure(run_seed: int) -> void:
	_seed = run_seed
	reset()

func reset() -> void:
	_rng.seed = _seed
	state = "idle"
	phase = "rat"
	hp = MAX_HP
	position = Vector2(480, FLOOR_Y)
	facing = -1
	elapsed = 0
	active = false
	exit_open = false
	port = -1
	landing = Vector2.ZERO
	column_x = 480
	_frozen = false
	_released = 0
	throw_origins.clear()
	swim_target = 480
	charge_end = 480
	_charge_leg = 0
	_origin = Vector2.ZERO
	_destination = Vector2.ZERO
	hazards.clear()
	_hurts.clear()
	_events.clear()

func start(hero_rect: Rect2) -> void:
	if state != "idle": return
	_hero = hero_rect
	active = true
	position = _safe_anchor()
	_enter("entry_skitter")

func damageable() -> bool:
	return active and not _frozen and state in VULNERABLE and (
		state != "rat_pipe_launch" or _fully_emerged())

func _fully_emerged() -> bool:
	var bounds := body_rect()
	return elapsed >= .15 and bounds.position.x >= 32 and bounds.end.x <= 928 and bounds.position.y >= 82

func visible() -> bool:
	return state not in HIDDEN

func body_rect() -> Rect2:
	var size := Vector2(256, 150) if phase == "rat" else Vector2(288, 112)
	return Rect2(position-Vector2(size.x*.5, size.y), size)

func damage(amount: int) -> int:
	if amount <= 0 or not damageable(): return 0
	var floor_hp := PHASE_HP if phase == "rat" else 0
	var accepted := mini(amount, hp-floor_hp)
	if accepted <= 0: return 0
	hp -= accepted
	if hp == floor_hp:
		hazards.clear()
		_hurts.clear()
		_enter("rat_collapse" if phase == "rat" else "terminal_death")
	else:
		_events.append("hit")
	return accepted

func drain_events() -> Array[String]:
	var result := _events.duplicate()
	_events.clear()
	return result

func hurt_regions() -> Array[Rect2]:
	return _hurts.duplicate() if not _frozen else []

func snapshot() -> Dictionary:
	return {"state": state, "phase": phase, "hp": hp, "max_hp": MAX_HP,
		"position": position, "facing": facing, "elapsed": elapsed, "active": active,
		"visible": visible(), "damageable": damageable(), "body_rect": body_rect(),
		"port": port, "port_position": PORTS[port] if port >= 0 else Vector2.ZERO,
		"landing": landing, "column_x": column_x, "hazards": hazards.duplicate(true),
		"exit_open": exit_open, "frozen": _frozen, "throw_origins": throw_origins.duplicate(),
		"swim_target": swim_target, "charge_end": charge_end, "throw_count": _released}

func step(delta: float, hero_rect: Rect2, frozen := false) -> void:
	_frozen = frozen
	_hurts.clear()
	if frozen or not active or delta <= 0: return
	_hero = hero_rect
	# Substeps bound motion sweeps, preserve all timers and prevent large-frame tunneling.
	var remaining := delta
	while remaining > .000001 and active:
		var dt := minf(remaining, 1.0/120.0)
		if DURATIONS.has(state) and elapsed < float(DURATIONS[state]):
			dt = minf(dt, maxf(.000001, float(DURATIONS[state])-elapsed))
		_tick(dt)
		remaining -= dt

func _tick(dt: float) -> void:
	# A moving hero can invalidate a previously safe destination. Return harmlessly, never retarget in flight.
	if state == "rat_pipe_launch" and _occupied(landing):
		_enter("rat_pipe_abort")
	elif state == "alligator_surface" and _occupied(landing):
		_enter("alligator_surface_return")
	var before := body_rect()
	elapsed += dt
	if state in ["alligator_swim", "alligator_surface_swim"]:
		if state == "alligator_swim":
			swim_target = _next_throw_origin()
			facing = 1 if swim_target > position.x else -1
		position.x = move_toward(position.x, swim_target, SWIM_SPEED*dt)
		if is_equal_approx(position.x, swim_target):
			_enter("alligator_water_warning" if state == "alligator_swim" else "alligator_surface_warning")
		return
	if state == "alligator_charge":
		position.x = move_toward(position.x, charge_end, CHARGE_SPEED*dt)
		_add_hurt(_jaw(before).merge(_jaw(body_rect())))
		if is_equal_approx(position.x, charge_end):
			_charge_leg += 1
			_enter("alligator_charge_turn" if _charge_leg < 2 else "alligator_jaw_recovery")
		return
	if state in ["rat_bite", "rat_pipe_retreat",
		"rat_pipe_launch", "rat_pipe_abort", "alligator_water_dive", "alligator_surface",
		"alligator_surface_return"]:
		var progress := clampf(elapsed/float(DURATIONS[state]), 0, 1)
		position = _origin.lerp(_destination, progress)
	if state == "rat_bite":
		# Only the visible leading jaw quarter hurts; the body never physically blocks escape.
		_add_hurt(_jaw(before).merge(_jaw(body_rect())))
	elif state == "rat_pipe_launch" and _fully_emerged():
		_add_hurt(before.merge(body_rect()))
	if state == "alligator_debris":
		_step_debris(dt)
		if hazards.is_empty():
			if _released < 3: _enter("alligator_swim")
			else: _enter("alligator_surface_swim")
	elif DURATIONS.has(state) and elapsed >= float(DURATIONS[state])-.000001:
		if state in ["rat_assembly", "alligator_assembly"] and _occupied(position):
			# Keep the announced formation in place, harmless, rather than pushing or teleporting the hero.
			elapsed = float(DURATIONS[state])
		elif state == "rat_pipe_warning" and _occupied(landing):
			_enter("rat_pipe_warning")
		elif state == "alligator_surface_warning" and _occupied(landing):
			_enter("alligator_surface_swim")
		elif state == "alligator_ready":
			_enter("alligator_water_dive")
		elif state == "alligator_surface_recovery":
			_enter("alligator_charge_tell")
		elif state in ["rat_ready", "rat_landing_recovery"]:
			_prepare_attack()
		else:
			_enter(str(NEXT[state]))

func _jaw(rect: Rect2) -> Rect2:
	var width := rect.size.x*.25
	if phase == "alligator":
		# The low visible snapping jaws can be cleared by the existing 86px hero jump.
		return Rect2(Vector2(rect.end.x-width if facing > 0 else rect.position.x, FLOOR_Y-44),
			Vector2(width, 44))
	return Rect2(Vector2(rect.end.x-width if facing > 0 else rect.position.x, rect.position.y+rect.size.y*.4),
		Vector2(width, rect.size.y*.6))

func _add_hurt(rect: Rect2) -> void:
	# Preserve separate sweeps: merging a diagonal path would damage empty space beside it.
	_hurts.append(rect)

func _occupied(feet: Vector2) -> bool:
	var size := Vector2(256, 150) if phase == "rat" else Vector2(288, 112)
	return Rect2(feet-Vector2(size.x*.5, size.y), size).grow(8).intersects(_hero)

func _safe_anchor() -> Vector2:
	var best := Vector2(480, FLOOR_Y)
	var distance := -1.0
	for x in [180.0, 480.0, 780.0]:
		var gap := absf(x-_hero.get_center().x)
		if gap > distance:
			distance = gap
			best = Vector2(x, FLOOR_Y)
	return best

func _prepare_attack() -> void:
	facing = 1 if _hero.get_center().x > position.x else -1
	var travel := 60.0
	var half_width := body_rect().size.x*.5
	var endpoint := clampf(position.x+facing*travel, 32+half_width, 928-half_width)
	var safe_gap := (928-_hero.end.x) if facing > 0 else (_hero.position.x-32)
	var starts_clear := (_hero.position.x >= body_rect().end.x) if facing > 0 else (
		_hero.end.x <= body_rect().position.x)
	if safe_gap < 180 or not starts_clear:
		_enter("rat_pipe_retreat")
		return
	_origin = position
	_destination = Vector2(endpoint, FLOOR_Y)
	_enter("rat_bite_tell")

func _enter(next_state: String) -> void:
	state = next_state
	elapsed = 0
	if EVENTS.has(state): _events.append(str(EVENTS[state]))
	if state == "alligator_charge": _events.append("jaw_snap")
	match state:
		"rat_assembly", "alligator_assembly":
			if state == "alligator_assembly": phase = "alligator"
			position = _safe_anchor()
		"rat_pipe_retreat":
			_origin = position
			_destination = Vector2(480, 360)
		"rat_pipe_warning":
			port = _rng.randi_range(0, PORTS.size()-1)
			landing = _safe_anchor()
			_origin = PORTS[port]+Vector2(0, 150)
			_destination = landing
			facing = 1 if landing.x > _origin.x else -1
		"rat_pipe_launch":
			position = _origin
		"rat_pipe_abort":
			_origin = position
			_destination = PORTS[port]+Vector2(0, 150)
			_hurts.clear()
		"rat_landing_recovery":
			position = landing
		"alligator_water_dive":
			_released = 0
			throw_origins.clear()
			_origin = position
			_destination = Vector2(position.x, 570)
		"alligator_swim":
			swim_target = _next_throw_origin()
			facing = 1 if swim_target > position.x else -1
		"alligator_water_warning":
			column_x = position.x
		"alligator_debris":
			_release_debris()
		"alligator_surface_swim":
			landing = _safe_anchor()
			swim_target = landing.x
			facing = 1 if swim_target > position.x else -1
		"alligator_charge_tell", "alligator_charge_turn":
			if state == "alligator_charge_tell": _charge_leg = 0
			charge_end = 784.0 if position.x < 480 else 176.0
			facing = 1 if charge_end > position.x else -1
		"alligator_surface":
			_origin = Vector2(landing.x, 570)
			_destination = landing
			position = _origin
		"alligator_surface_return":
			_origin = position
			_destination = Vector2(position.x, 570)
			_hurts.clear()
		"complete":
			active = false
			exit_open = true
			_events.append("exit_open")

func _release_debris() -> void:
	_released += 1
	throw_origins.append(column_x)
	# Commit before release: both upward and downward travel hurt, with no horizontal tracking.
	hazards.append({"position": Vector2(column_x, 500), "vy": -sqrt(700000.0),
		"descending": false, "radius": ROCK_RADIUS, "id": _released})
	_events.append("debris_release")

func _step_debris(dt: float) -> void:
	for index in range(hazards.size()-1, -1, -1):
		var rock := hazards[index]
		var old: Vector2 = rock.position
		var velocity: float = rock.vy
		rock.position.y += velocity*dt+500.0*dt*dt
		rock.vy = velocity+1000.0*dt
		rock.descending = float(rock.vy) >= 0
		var now: Vector2 = rock.position
		var radius := Vector2.ONE*ROCK_RADIUS
		_add_hurt(Rect2(old-radius, radius*2).merge(Rect2(now-radius, radius*2)))
		if rock.descending and now.y >= FLOOR_Y:
			hazards.remove_at(index)
			_events.append("debris_impact")

func _next_throw_origin() -> float:
	# A stationary hero occupies a footprint, not a single point. Distinct nearby origins all intersect it.
	var preferred: float = [-10.0, 0.0, 10.0][_released]
	for offset in [preferred, -10.0, 0.0, 10.0, -6.0, 6.0, -14.0, 14.0]:
		var candidate := clampf(_hero.get_center().x+float(offset), 32, 928)
		var distinct := true
		for previous in throw_origins:
			if absf(candidate-previous) < 2.0: distinct = false
		if distinct: return candidate
	return clampf(_hero.get_center().x, 32, 928)
