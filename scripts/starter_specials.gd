extends RefCounted
## Per-run level budgets and simulation-driven starter-special geometry.
const Data = preload("res://scripts/combat_data.gd")
const DURATION := 7.5
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
var anchor := Vector2.ZERO
var locked_facing := 1.0
var costume := "normal"
var audio: RefCounted
var spent_pipes: Array[Dictionary] = []

func _init() -> void:
	Data.load_data()
	definition = Data.bundle.starter_specials

func configure(hero: String, level: String) -> void:
	if hero != hero_id or level != level_key: cancel("configuration change")
	if level != level_key: spent_pipes.clear()
	hero_id = hero
	level_key = level
	var key := level+":"+hero
	if not budgets.has(key): budgets[key] = 2

func remaining(hero := "") -> int:
	return int(budgets.get(level_key+":"+(hero_id if hero.is_empty() else hero),2))

func sample_input(host: Node2D, pressed: bool) -> bool:
	var fresh := pressed and not held
	held = pressed
	if not fresh or not host.specials_allowed(): return false
	var accepted := begin(host)
	if not accepted: host.special_audio.empty()
	return accepted

func begin(host: Node2D) -> bool:
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
	anchor = proposed
	locked_facing = host.facing
	costume = host.world_art.hero_aim_art.costume
	audio = host.special_audio
	host.special_audio.begin(hero_id)
	return true

func cancel(_reason := "") -> void:
	retire_pipe()
	if audio != null: audio.stop()
	active = false
	elapsed = 0
	tick_clock = 0

func pipe_state() -> Dictionary:
	return {"anchor":anchor,"angle":pipe_angle(),"elapsed":elapsed,"costume":costume}

func retire_pipe() -> void:
	if active and hero_id == "sean" and elapsed > 0.26: spent_pipes.append(pipe_state())

func rooted() -> bool:
	return active and hero_id == "sean" and elapsed < 1.0

func movement_speed(direction: float, normal_speed: float, aim: Vector2) -> float:
	if rooted(): return 0
	if not active or hero_id != "tony": return direction*normal_speed
	var recoil := -aim.x*float(definition.initial_tuning.recoil_horizontal_pixels_per_second)
	if not is_zero_approx(direction) and direction*aim.x > 0:
		return direction*normal_speed*0.5
	return direction*normal_speed+recoil

func step(host: Node2D, delta: float) -> void:
	if not active: return
	if host.life_state != "alive":
		cancel("death")
		host.special_audio.stop()
		return
	if not host.specials_allowed(true): return
	var used := minf(maxf(delta,0),DURATION-elapsed)
	elapsed += used
	host.special_audio.advance(used)
	tick_clock += used
	var tuning: Dictionary = definition.initial_tuning.hero_overrides[hero_id]
	var interval: float = tuning.tick_interval_seconds
	while tick_clock+0.000001 >= interval:
		tick_clock -= interval
		tick_serial += 1
		var segments := water_segments(host)
		if segments.is_empty(): continue
		var budget := {}
		for key in ["skitterling","clogfather"]:
			budget[key] = maxf(0,float(definition.initial_tuning.maximum_damage_per_boss_per_activation)-float(boss_used.get(key,0)))
		var applied: Dictionary = host.special_damage(segments,float(tuning.damage_per_tick),activation_id,budget)
		for key in applied: boss_used[key] = float(boss_used.get(key,0))+float(applied[key])
	if elapsed >= DURATION:
		retire_pipe()
		active = false
		host.special_audio.stop()

func water_width() -> float:
	if not active: return 0
	var strength := 1.0
	if hero_id == "tony":
		strength = minf(clampf(elapsed/0.35,0,1),clampf((DURATION-elapsed)/0.7,0,1))
	else:
		if elapsed < 1: return 0
		strength = clampf((DURATION-elapsed)/1.5,0,1)
	return float(definition.initial_tuning.tony_jet_thickness_pixels)*strength

func pipe_angle() -> float:
	return locked_facing*PI*0.5*smoothstep(3.25,6.0,elapsed)

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
