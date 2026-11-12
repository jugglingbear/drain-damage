extends RefCounted
## Per-run level budgets and simulation-driven starter-special geometry.
const Data = preload("res://scripts/combat_data.gd")
const DURATION := 7.5
const PIPE_GRAVITY := 1250.0
const PIPE_MANIFEST := "res://assets/specials/main-break-rain-v1/manifest.json"
var definition: Dictionary
var hero_id := "tony"
var level_key := "first-call"
var budgets: Dictionary = {}
var active := false
var elapsed := 0.0
var held := false
var activation_id := 0
var tick_clock := 0.0
var tick_serial := 0
var boss_used: Dictionary = {}
var rain_remainders: Dictionary = {}
var anchor := Vector2.ZERO
var pipe_fall_speed := 0.0
var pipe_contact := Vector2.ZERO
var locked_facing := 1.0
var costume := "normal"
var audio: RefCounted
var spent_pipes: Array[Dictionary] = []
var presentation_host: WeakRef

func _init() -> void:
	Data.load_data()
	definition = Data.bundle.starter_specials
	var pipe_art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PIPE_MANIFEST))
	var foot: Array = pipe_art.pipe.native_destination_relative_floor
	pipe_contact = Vector2(float(foot[0]),float(foot[0])+float(foot[2]))

func configure(hero: String, level: String) -> void:
	if hero != hero_id or level != level_key: cancel("configuration change")
	if level != level_key: spent_pipes.clear()
	hero_id = hero
	level_key = level
	var key := level+":"+hero
	if not budgets.has(key): budgets[key] = 2

func remaining(hero := "") -> int:
	return int(budgets.get(level_key+":"+(hero_id if hero.is_empty() else hero),2))

func refill_level(hero: String, level: String) -> void:
	configure(hero,level)
	budgets[level+":"+hero] = 2

func sample_input(host: Node2D, pressed: bool) -> bool:
	var fresh := pressed and not held
	held = pressed
	if not fresh or not host.specials_allowed(): return false
	var accepted := begin(host,true)
	if not accepted: host.special_audio.empty()
	return accepted

func begin(host: Node2D, present := false) -> bool:
	if active or not host.specials_allowed() or remaining() <= 0: return false
	var proposed: Vector2 = host.player+Vector2(13+44*host.facing,46)
	if hero_id == "sean" and (not host.grounded or not host.special_pipe_clear(proposed)): return false
	budgets[level_key+":"+hero_id] = remaining()-1
	active = true
	elapsed = 0
	tick_clock = 0
	tick_serial = 0
	activation_id += 1
	boss_used.clear()
	rain_remainders.clear()
	anchor = proposed
	pipe_fall_speed = 0
	locked_facing = host.facing
	costume = host.world_art.hero_aim_art.costume
	audio = host.special_audio
	if present and host.has_method("start_special_cinematic"):
		presentation_host = weakref(host)
		host.start_special_cinematic()
	else: host.special_audio.begin(hero_id)
	return true

func cancel(_reason := "") -> void:
	clear_transients()

func clear_transients() -> void:
	if presentation_host != null and is_instance_valid(presentation_host.get_ref()):
		presentation_host.get_ref().cancel_special_cinematic()
	presentation_host = null
	# Props belong to the current attempt; ending an attempt never refunds its level budget.
	spent_pipes.clear()
	if audio != null: audio.stop()
	active = false
	pipe_fall_speed = 0
	elapsed = 0
	tick_clock = 0
	boss_used.clear()
	rain_remainders.clear()

func pipe_state() -> Dictionary:
	return {"anchor":anchor,"angle":0.0,"elapsed":1.0,"costume":costume,"rain_pipe":true,"facing":locked_facing,
		"fall_speed":pipe_fall_speed}

func retire_pipe(host: Node2D) -> void:
	if active and hero_id == "sean":
		var state := pipe_state()
		state.spent_age = 0.0
		state.spent_variant = host.special_art.spent_variant(state,host.special_solids())
		spent_pipes.append(state)

func rooted() -> bool:
	return false

func movement_speed(direction: float, normal_speed: float, aim: Vector2) -> float:
	if rooted(): return 0
	if not active or hero_id != "tony": return direction*normal_speed
	var recoil := -aim.x*float(definition.initial_tuning.recoil_horizontal_pixels_per_second)
	if not is_zero_approx(direction) and direction*aim.x > 0:
		return direction*normal_speed*0.5
	return direction*normal_speed+recoil

func step(host: Node2D, delta: float) -> void:
	if host.life_state != "alive":
		if active or not spent_pipes.is_empty():
			cancel("death")
			host.special_audio.stop()
		return
	if presentation_host != null or not host.specials_allowed(true): return
	var advance := maxf(delta,0) if is_finite(delta) else 0.0
	var supports: Array[Rect2] = []
	if (active and hero_id == "sean") or not spent_pipes.is_empty():
		supports = host.special_solids().duplicate()
		if host.has_method("actor_solids"): supports.append_array(host.actor_solids())
	for state: Dictionary in spent_pipes:
		state.spent_age = float(state.get("spent_age",0))+advance
		fall_pipe(state,advance,supports)
	if not active: return
	var used := minf(advance,DURATION-elapsed)
	if hero_id == "sean":
		var moving_pipe := pipe_state()
		fall_pipe(moving_pipe,used,supports)
		anchor = moving_pipe.anchor
		pipe_fall_speed = moving_pipe.fall_speed
	var end_time := elapsed+used
	if end_time >= DURATION-0.000000001: end_time = DURATION
	host.special_audio.advance(used)
	var tuning: Dictionary = definition.initial_tuning.hero_overrides[hero_id]
	var interval: float = tuning.tick_interval_seconds
	# Sample each scheduled pose, including catch-up ticks, rather than the frame's final pose.
	while (tick_serial+1)*interval <= end_time+0.000001:
		tick_serial += 1
		elapsed = tick_serial*interval
		var applied: Dictionary
		if hero_id == "sean":
			applied = host.special_rain_damage(float(tuning.damage_per_tick),activation_id,tick_serial,rain_remainders)
		else:
			var segments := water_segments(host)
			if segments.is_empty(): continue
			var boss_tick_damage := {"skitterling":float(tuning.boss_damage_per_tick),
				"clogfather":float(tuning.boss_damage_per_tick)}
			applied = host.special_damage(segments,float(tuning.damage_per_tick),activation_id,boss_tick_damage)
		for key in applied: boss_used[key] = float(boss_used.get(key,0))+float(applied[key])
	elapsed = end_time
	tick_clock = maxf(0,elapsed-tick_serial*interval)
	if elapsed >= DURATION:
		retire_pipe(host)
		if hero_id == "sean" and not spent_pipes.is_empty():
			spent_pipes.back().spent_age = maxf(0,advance-used)
			fall_pipe(spent_pipes.back(),maxf(0,advance-used),supports)
		active = false
		rain_remainders.clear()
		host.special_audio.stop()

func fall_pipe(state: Dictionary, delta: float, solids: Array[Rect2]) -> void:
	if delta <= 0: return
	var start: Vector2 = state.anchor
	var speed: float = state.get("fall_speed",0.0)
	var end_y := start.y+speed*delta+0.5*PIPE_GRAVITY*delta*delta
	var landing := INF
	var left := start.x+pipe_contact.x
	var right := start.x+pipe_contact.y
	for solid: Rect2 in solids:
		var top := solid.position.y
		if top < start.y-0.001 or top > end_y+0.001 or top >= landing: continue
		if supported_interval(left,right,top,solids): landing = top
	if is_finite(landing):
		state.anchor = Vector2(start.x,landing)
		state.fall_speed = 0.0
	else:
		state.anchor = Vector2(start.x,end_y)
		state.fall_speed = speed+PIPE_GRAVITY*delta

func supported_interval(left: float, right: float, top: float, solids: Array[Rect2]) -> bool:
	# Use the registered base, not decorative compact-collapse bolt overhang. Adjacent material can share support.
	var intervals: Array[Vector2] = []
	for solid: Rect2 in solids:
		if absf(solid.position.y-top) <= 0.001 and solid.end.x > left and solid.position.x < right:
			intervals.append(Vector2(solid.position.x,solid.end.x))
	intervals.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.x < b.x)
	var covered := left
	for interval in intervals:
		if interval.x > covered+0.001: return false
		covered = maxf(covered,interval.y)
		if covered >= right-0.001: return true
	return false

func water_width() -> float:
	if not active or hero_id == "sean": return 0
	var strength := minf(clampf(elapsed/0.35,0,1),clampf((DURATION-elapsed)/0.7,0,1))
	return float(definition.initial_tuning.tony_jet_thickness_pixels)*strength

func pipe_angle() -> float:
	return 0.0

func outlet(host: Node2D) -> Dictionary:
	if hero_id == "tony":
		return {"origin":host.world_art.hero_aim_art.muzzle(host),"direction":host.current_aim.normalized()}
	var direction := Vector2.UP.rotated(pipe_angle())
	return {"origin":anchor+Vector2(0,-32)+direction*16,"direction":direction}

func water_segments(host: Node2D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var width := water_width()
	if width <= 0.01: return result
	var pose := outlet(host)
	var origin: Vector2 = pose.origin
	var direction: Vector2 = pose.direction
	if direction.is_zero_approx(): return result
	var viewport := Rect2(host.camera_x,0,960,540)
	var length := 10000.0
	for axis in range(2):
		if absf(direction[axis]) < 0.000001: continue
		var boundary: float = viewport.end[axis] if direction[axis] > 0 else viewport.position[axis]
		length = minf(length,(boundary-origin[axis])/direction[axis])
	if length <= 0: return result
	var end := origin+direction*length
	# Conservative full-width obstruction keeps both art and damage out of hidden terrain.
	for solid: Rect2 in host.special_solids():
		var hit: float = host.segment_hit(origin,end,solid.grow(width*0.5))
		if hit >= 0: length = minf(length,origin.distance_to(end)*hit)
	if length <= 0.01: return result
	result.append({"origin":origin,"end":origin+direction*length,"width":width,"clip":viewport})
	return result

static func overlaps(segments: Array[Dictionary], rect: Rect2) -> bool:
	var target := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,
		Vector2(rect.position.x,rect.end.y)])
	for segment in segments:
		var start: Vector2 = segment.origin
		var finish: Vector2 = segment.end
		var normal := (finish-start).normalized().orthogonal()*float(segment.width)*0.5
		var water := PackedVector2Array([start+normal,finish+normal,finish-normal,start-normal])
		var shapes: Array[PackedVector2Array] = [water]
		if segment.has("clip"):
			var clip: Rect2 = segment.clip
			shapes = Geometry2D.intersect_polygons(water,PackedVector2Array([clip.position,
				Vector2(clip.end.x,clip.position.y),clip.end,Vector2(clip.position.x,clip.end.y)]))
		for shape in shapes:
			if not Geometry2D.intersect_polygons(shape,target).is_empty(): return true
	return false

func resume_from_cinematic(host: Node2D) -> void:
	if not active or presentation_host == null: return
	presentation_host = null
	elapsed = 0.0
	# Presentation never consumes rain time or creates damage debt.
	tick_serial = 0
	tick_clock = 0
	host.special_audio.begin_from_cinematic(hero_id,host.cinematic_audio)
