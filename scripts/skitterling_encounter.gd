extends RefCounted
## Deterministic room-local encounter. Rendering, camera, audio and hero damage belong to the caller.
const FLOOR_Y := 440.0
const RAT_HP := 900
const PHASE_HP := 540
const MAX_HP := RAT_HP + PHASE_HP
const SWIM_SPEED := 340.0
const CHARGE_SPEED := 300.0
const ROCK_RADIUS := 14.0
const VOLLEY_SPACING := .22
const VOLLEY_COUNT := 6
const ARC_FLIGHT_SECONDS := 1.6
const RAT_GROUND_SPEED := 300.0
const RAT_RUSH_SPEED := 360.0
const RAT_RUSH_ACCELERATION := 900.0
const PORTS := [Vector2(250, 166), Vector2(710, 166), Vector2(48, 232), Vector2(912, 232)]
const DURATIONS := {
	"entry_skitter": 1.0, "rat_assembly": 1.4, "rat_ready": .6,
	"rat_wall_climb": .7, "rat_pounce_tell": 1.0, "rat_pounce": .9,
	"rat_pounce_recovery": 1.2, "rat_rush_tell": .8, "rat_rush_recovery": 1.2,
	"rat_pipe_retreat": .7, "rat_inside_pipe": .5, "rat_pipe_warning": 2.0,
	"rat_pipe_launch": 1.1, "rat_pipe_abort": .6, "rat_landing_recovery": 1.4,
	"rat_collapse": 1.6, "reskitter": 1.2, "alligator_assembly": 1.4,
	"alligator_ready": .6, "alligator_tail_tell": 1.0,
	"alligator_tail_sweep": .35, "alligator_tail_recovery": 1.2,
	"alligator_jaw_recovery": 1.8, "alligator_water_dive": .6,
	"alligator_water_warning": .8, "alligator_charge_tell": .9, "alligator_charge_turn": .9, "alligator_surface_warning": 1.0,
	"alligator_surface": .6, "alligator_surface_return": .6, "alligator_surface_recovery": .1, "terminal_death": 1.2,
}
const NEXT := {
	"entry_skitter": "rat_assembly", "rat_assembly": "rat_ready",
	"rat_wall_climb": "rat_pounce_tell", "rat_pounce_tell": "rat_pounce",
	"rat_pounce": "rat_pounce_recovery", "rat_rush_tell": "rat_rush",
	"rat_pipe_retreat": "rat_inside_pipe",
	"rat_inside_pipe": "rat_pipe_warning", "rat_pipe_warning": "rat_pipe_launch",
	"rat_pipe_launch": "rat_landing_recovery", "rat_pipe_abort": "rat_inside_pipe", "rat_collapse": "reskitter",
	"reskitter": "alligator_assembly", "alligator_assembly": "alligator_ready",
	"alligator_tail_tell": "alligator_tail_sweep",
	"alligator_tail_sweep": "alligator_tail_recovery", "alligator_tail_recovery": "alligator_water_dive", "alligator_water_dive": "alligator_swim",
	"alligator_water_warning": "alligator_debris",
	"alligator_charge_tell": "alligator_charge", "alligator_charge_turn": "alligator_charge", "alligator_surface_warning": "alligator_surface",
	"alligator_surface": "alligator_surface_recovery", "alligator_surface_return": "alligator_surface_swim", "terminal_death": "complete",
}
const EVENTS := {
	"entry_skitter": "swarm_entry", "rat_assembly": "rat_assembly",
	"rat_wall_climb": "rat_climb", "rat_pounce_tell": "rat_pounce_warning",
	"rat_pounce": "rat_pounce", "rat_pounce_recovery": "rat_pounce_land",
	"rat_rush_tell": "rat_rush_warning", "rat_rush": "rat_rush",
	"rat_pipe_retreat": "rat_pipe_hide", "rat_pipe_abort": "rat_pipe_hide", "rat_pipe_warning": "pipe_warning",
	"rat_pipe_launch": "pipe_launch", "rat_landing_recovery": "pipe_land",
	"rat_collapse": "rat_phase_defeat", "reskitter": "reskitter",
	"alligator_assembly": "alligator_assembly", "alligator_water_dive": "water_dive",
	"alligator_surface_return": "water_dive",
	"alligator_water_warning": "tail_warning", "alligator_surface": "water_emerge",
	"terminal_death": "terminal_death",
	"alligator_swim": "swim_start", "alligator_surface_swim": "swim_start",
	"alligator_charge_tell": "alligator_jaw_warning", "alligator_charge_turn": "alligator_jaw_warning",
	"alligator_charge": "attack_start", "alligator_tail_tell": "alligator_tail_warning",
	"alligator_tail_sweep": "alligator_tail_sweep",
}
const VULNERABLE := ["rat_ready", "rat_wall_approach", "rat_wall_climb", "rat_pounce_tell",
	"rat_pounce", "rat_pounce_recovery", "rat_rush_setup", "rat_rush_tell", "rat_rush", "rat_rush_recovery",
	"rat_pipe_retreat", "rat_pipe_launch", "rat_landing_recovery", "alligator_ready",
	"alligator_jaw_recovery",
	"alligator_water_dive", "alligator_surface_recovery",
	"alligator_charge_tell", "alligator_charge_turn", "alligator_charge",
	"alligator_tail_tell", "alligator_tail_sweep", "alligator_tail_recovery"]
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
var volley_targets: Array[float] = []
var swim_target := 480.0
var charge_end := 480.0
var _charge_leg := 0
var _rat_move_index := 0
var _rush_speed := 0.0
var rat_ground_distance := 0.0
var alligator_ground_distance := 0.0
var alligator_snap_elapsed := 0.0
var attack_target := Vector2.ZERO
var wall_anchor := Vector2.ZERO
var _tail_cycle := 0

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
	volley_targets.clear()
	swim_target = 480
	charge_end = 480
	_charge_leg = 0
	_rat_move_index = 0
	_rush_speed = 0
	rat_ground_distance = 0
	alligator_ground_distance = 0
	alligator_snap_elapsed = 0
	_tail_cycle = 0
	attack_target = Vector2.ZERO
	wall_anchor = Vector2.ZERO
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

func rat_contact_active() -> bool:
	## The room intersects the rendered insects, not the empty corners of the logical body.
	return phase == "rat" and damageable()

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
		"visible": visible(), "damageable": damageable(), "rat_contact_active": rat_contact_active(), "body_rect": body_rect(),
		"port": port, "port_position": PORTS[port] if port >= 0 else Vector2.ZERO,
		"landing": landing, "column_x": column_x, "hazards": hazards.duplicate(true),
		"exit_open": exit_open, "frozen": _frozen, "throw_origins": throw_origins.duplicate(),
		"swim_target": swim_target, "charge_end": charge_end, "throw_count": _released,
		"volley_targets": volley_targets.duplicate(), "attack_target": attack_target, "wall_anchor": wall_anchor, "rush_speed": _rush_speed,
		"rat_ground_distance": rat_ground_distance, "alligator_ground_distance": alligator_ground_distance,
		"alligator_snap_elapsed": alligator_snap_elapsed,
		"rat_move_index": _rat_move_index, "tail_bounds": _tail_rect()}

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
	if state == "rat_collapse":
		position.y = minf(FLOOR_Y, _origin.y+450.0*elapsed+500.0*elapsed*elapsed)
	if state in ["alligator_swim", "alligator_surface_swim"]:
		if state == "alligator_swim":
			swim_target = _next_throw_origin()
			facing = 1 if swim_target > position.x else -1
		position.x = move_toward(position.x, swim_target, SWIM_SPEED*dt)
		if is_equal_approx(position.x, swim_target):
			_enter("alligator_water_warning" if state == "alligator_swim" else "alligator_surface_warning")
		return
	if state in ["rat_wall_approach", "rat_rush_setup"]:
		position.x = move_toward(position.x, wall_anchor.x, RAT_GROUND_SPEED*dt)
		rat_ground_distance += absf(position.x-before.get_center().x)
		if is_equal_approx(position.x, wall_anchor.x):
			_enter("rat_wall_climb" if state == "rat_wall_approach" else "rat_rush_tell")
		return
	if state == "rat_rush":
		_rush_speed = minf(RAT_RUSH_SPEED, _rush_speed+RAT_RUSH_ACCELERATION*dt)
		position.x = move_toward(position.x, _destination.x, _rush_speed*dt)
		rat_ground_distance += absf(position.x-before.get_center().x)
		# The crouched rush damages through the room's visible insect contact regions.
		if is_equal_approx(position.x, _destination.x): _enter("rat_rush_recovery")
		return
	if state == "alligator_charge":
		alligator_snap_elapsed = elapsed
		position.x = move_toward(position.x, charge_end, CHARGE_SPEED*dt)
		alligator_ground_distance += absf(position.x-before.get_center().x)
		_add_hurt(_jaw(before).merge(_jaw(body_rect())))
		if is_equal_approx(position.x, charge_end):
			_charge_leg += 1
			_enter("alligator_charge_turn" if _charge_leg < 2 else "alligator_jaw_recovery")
		return
	if state in ["rat_wall_climb", "rat_pounce", "rat_pipe_retreat",
		"rat_pipe_launch", "rat_pipe_abort", "alligator_water_dive", "alligator_surface",
		"alligator_surface_return"]:
		var progress := clampf(elapsed/float(DURATIONS[state]), 0, 1)
		position = _origin.lerp(_destination, progress)
		if state == "rat_pounce": position.y -= 80.0*sin(PI*progress)
	if state == "rat_pounce":
		_add_hurt(_rat_strike(before, 72, 48).merge(_rat_strike(body_rect(), 72, 48)))
	elif state == "alligator_tail_sweep":
		_add_hurt(_tail_rect())
	elif state == "rat_pipe_launch" and _fully_emerged():
		_add_hurt(before.merge(body_rect()))
	if state == "alligator_debris":
		_step_debris(dt)
		while _released < VOLLEY_COUNT and elapsed >= _released*VOLLEY_SPACING:
			_release_debris()
		if _released == VOLLEY_COUNT and hazards.is_empty(): _enter("alligator_surface_swim")
	elif DURATIONS.has(state) and elapsed >= float(DURATIONS[state])-.000001:
		# Assembly is harmless and nonblocking; occupancy must not stall combat forever.
		if state == "rat_pipe_warning" and _occupied(landing):
			_enter("rat_pipe_warning")
		elif state == "alligator_surface_warning" and _occupied(landing):
			_enter("alligator_surface_swim")
		elif state == "alligator_ready":
			_enter("alligator_water_dive")
		elif state == "alligator_surface_recovery":
			_enter("alligator_charge_tell")
		elif state in ["rat_ready", "rat_pounce_recovery", "rat_rush_recovery", "rat_landing_recovery"]:
			_prepare_attack()
		elif state == "alligator_jaw_recovery":
			_tail_cycle += 1
			var behind := (_hero.get_center().x-position.x)*facing < 0
			_enter("alligator_tail_tell" if behind or _tail_cycle % 2 == 0 else "alligator_water_dive")
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

func _rat_strike(rect: Rect2, width: float, height: float) -> Rect2:
	return Rect2(Vector2(rect.end.x-width if facing > 0 else rect.position.x, rect.end.y-height),
		Vector2(width, height))

func _tail_rect() -> Rect2:
	var body := body_rect()
	return Rect2(Vector2(body.position.x if facing > 0 else body.end.x-120, FLOOR_Y-40), Vector2(120, 40))

func _prepare_attack() -> void:
	var move: String = ["pounce", "rush", "pounce", "pipe"][_rat_move_index % 4]
	_rat_move_index += 1
	if move == "pipe":
		_enter("rat_pipe_retreat")
		return
	wall_anchor = Vector2(780 if _hero.get_center().x < 480 else 180, FLOOR_Y)
	facing = 1 if wall_anchor.x > position.x else -1
	_enter("rat_wall_approach" if move == "pounce" else "rat_rush_setup")

func _enter(next_state: String) -> void:
	state = next_state
	elapsed = 0
	if EVENTS.has(state): _events.append(str(EVENTS[state]))
	if state in ["rat_pounce", "rat_rush", "alligator_tail_sweep"]:
		_events.insert(_events.size()-1, "attack_start")
	if state == "alligator_charge": _events.append("jaw_snap")
	match state:
		"rat_collapse":
			_origin = position
		"rat_wall_climb":
			_origin = position
			_destination = Vector2(position.x, 250)
		"rat_pounce_tell", "rat_rush_tell":
			facing = 1 if _hero.get_center().x > position.x else -1
			attack_target = Vector2(_hero.get_center().x, FLOOR_Y)
			var offset := 92.0 if state == "rat_pounce_tell" else 48.0
			_origin = position
			_destination = Vector2(clampf(attack_target.x-facing*offset, 160, 800), FLOOR_Y)
		"rat_rush":
			_rush_speed = 0
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
			volley_targets.clear()
			_origin = position
			_destination = Vector2(position.x, 570)
		"alligator_swim":
			swim_target = _next_throw_origin()
			facing = 1 if swim_target > position.x else -1
		"alligator_water_warning":
			column_x = position.x
			volley_targets.clear()
			for shot in range(VOLLEY_COUNT-1):
				volley_targets.append(_rng.randf_range(133, 827))
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
	var shot := _released
	_released += 1
	throw_origins.append(column_x)
	# The final shot samples the hero now; its trajectory never tracks after release.
	if shot == VOLLEY_COUNT-1:
		volley_targets.append(clampf(_hero.get_center().x, 133, 827))
	var target := volley_targets[shot]
	var horizontal := (target-column_x)/ARC_FLIGHT_SECONDS
	# All shots start below the walkway. Ballistic arcs land exactly at the committed floor target.
	var vertical := (FLOOR_Y-500-.5*1000*ARC_FLIGHT_SECONDS*ARC_FLIGHT_SECONDS)/ARC_FLIGHT_SECONDS
	hazards.append({"position": Vector2(column_x, 500), "vy": vertical, "vx": horizontal,
		"descending": false, "radius": ROCK_RADIUS, "id": _released,
		"kind": "aimed_arc" if shot == VOLLEY_COUNT-1 else "random_arc", "target_x": target, "age": 0.0})
	_events.append("debris_release")

func _step_debris(dt: float) -> void:
	for index in range(hazards.size()-1, -1, -1):
		var rock := hazards[index]
		var old: Vector2 = rock.position
		var velocity: float = rock.vy
		var travel_dt := minf(dt, maxf(0, ARC_FLIGHT_SECONDS-float(rock.age)))
		rock.position.x += float(rock.vx)*travel_dt
		rock.position.y += velocity*travel_dt+500.0*travel_dt*travel_dt
		rock.age += travel_dt
		rock.vy = velocity+1000.0*travel_dt
		rock.descending = float(rock.vy) >= 0
		var now: Vector2 = rock.position
		var radius := Vector2.ONE*ROCK_RADIUS
		_add_hurt(Rect2(old-radius, radius*2).merge(Rect2(now-radius, radius*2)))
		if float(rock.age) >= ARC_FLIGHT_SECONDS-.000001:
			hazards.remove_at(index)
			_events.append("debris_impact")

func _next_throw_origin() -> float:
	# Track while swimming, then hold the launch origin throughout the volley.
	var hero_x := _hero.get_center().x
	return clampf(hero_x+(80 if hero_x < 480 else -80), 133, 827)
