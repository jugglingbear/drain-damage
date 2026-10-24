extends RefCounted
## Registered authored layers share arena coordinates and retain stable attachment points.
const MANIFEST := "res://assets/bestiary/the-clogfather/runtime-manifest-v3.json"
const GAS_MANIFEST := "res://assets/bestiary/the-clogfather/gas-manifest-v1.json"
var definition: Dictionary = {}
var textures: Dictionary = {}
var opening := 0.0
var high_opening := 0.0
var damage_flash := 0.0
var deflect_flash := 0.0
var deflect_position := Vector2(700,300)

func prepare() -> bool:
	definition = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var gas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GAS_MANIFEST))
	definition.frames.merge(gas.frames)
	for frame: Dictionary in definition.frames.values():
		if not textures.has(frame.path): textures[frame.path] = load("res://"+frame.path)
	return not textures.values().has(null)

func reset() -> void:
	opening = 0
	high_opening = 0
	damage_flash = 0
	deflect_flash = 0

func step(snapshot: Dictionary, delta: float) -> void:
	var high: bool = snapshot.get("weak_point_level","low") == "high"
	opening = move_toward(opening,1.0 if snapshot.damageable and not high else 0.0,delta/0.25)
	high_opening = move_toward(high_opening,1.0 if snapshot.damageable and high else 0.0,delta/0.25)
	damage_flash = maxf(0,damage_flash-delta)
	deflect_flash = maxf(0,deflect_flash-delta)

func events(values: Array) -> void:
	if values.has("damage_accepted"): damage_flash = 0.15
	if values.has("closed_shell_hit"): deflect_flash = 0.12

func rect(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])

func frame(canvas: Node2D, id: String, origin: Vector2, offset := Vector2.ZERO,
		scale_value := Vector2.ONE, rotation := 0.0, alpha := 1.0) -> void:
	if alpha <= 0 or not definition.frames.has(id): return
	var part: Dictionary = definition.frames[id]
	var anchor := Vector2(part.anchor[0],part.anchor[1])
	var target := rect(part.destination)
	target.position -= anchor
	canvas.draw_set_transform(origin+anchor+offset,rotation,scale_value)
	canvas.draw_texture_rect_region(textures[part.path],target,rect(part.source_rect),Color(1,1,1,alpha))
	canvas.draw_set_transform(origin)

func draw(canvas: Node2D, snapshot: Dictionary, origin: Vector2, clock: float) -> void:
	if snapshot.hp <= 0 and definition.frames.has("collapse_0"):
		var progress := clampf(snapshot.elapsed/1.2,0,1)*5 if snapshot.state == "collapse" else 5.0
		var current := mini(5,int(progress))
		var blend := progress-current
		var remains_alpha: float = snapshot.get("remains_alpha",1.0)
		frame(canvas,"collapse_%d" % current,origin,Vector2.ZERO,Vector2.ONE,0,(1-blend)*remains_alpha)
		if current < 5:
			frame(canvas,"collapse_%d" % (current+1),origin,Vector2.ZERO,Vector2.ONE,0,blend*remains_alpha)
		return
	var breathing := 0.0 if snapshot.hp <= 0 else sin(clock*2.2)*0.006
	var fraction: float = float(snapshot.hp)/maxf(1,snapshot.max_hp)
	var stage := "healthy" if fraction > .75 else "mild" if fraction > .5 else "moderate" \
		if fraction > .25 else "severe" if fraction > .1 else "near_death"
	var body := "damage_body_"+stage
	if not definition.frames.has(body): body = "body"
	frame(canvas,body,origin,Vector2.ZERO,Vector2(1+breathing,1-breathing))
	var recoil := 0.0
	if snapshot.state == "volley": recoil = maxf(0,sin(snapshot.elapsed*PI*5))*2.0
	var swelling := smoothstep(0,0.9,snapshot.elapsed) if snapshot.state == "volley_warning" else 0.0
	# The nozzle is stationary at emission; only the authored warning swells its relaxed skin.
	frame(canvas,"sludge_relaxed",origin,Vector2(recoil,0),Vector2.ONE,0,1-swelling)
	frame(canvas,"sludge_swell",origin,Vector2.ZERO,Vector2.ONE,0,swelling)
	frame(canvas,"weak_closed",origin,Vector2.ZERO,Vector2.ONE,0,1-opening)
	frame(canvas,"weak_open",origin,Vector2.ZERO,Vector2.ONE,0,opening)
	frame(canvas,"weak_high_closed",origin,Vector2.ZERO,Vector2.ONE,0,1-high_opening)
	frame(canvas,"weak_high_open",origin,Vector2.ZERO,Vector2.ONE,0,high_opening)
	frame(canvas,"drool",origin,Vector2(0,sin(clock*2)*1.5),Vector2.ONE,0,opening)
	if damage_flash > 0:
		var weak: Rect2 = snapshot.weak_point_rect
		if weak.has_area(): place(canvas,"weak_hit",origin,weak.get_center())
	if deflect_flash > 0: place(canvas,"deflect",origin,deflect_position)
	for warning: Rect2 in snapshot.warnings:
		if snapshot.state == "pressure_warning":
			if snapshot.pressure_kind == "gas":
				place(canvas,"gas_warning_a" if int(clock*8)%2 == 0 else "gas_warning_b",
					origin,warning.get_center())
			continue
		place(canvas,"acid_warning",origin,Vector2(warning.get_center().x,440))
		if snapshot.state == "acid_warning":
			place(canvas,"acid_ceiling_warning",origin,Vector2(warning.get_center().x,110))
	for hazard: Dictionary in snapshot.hazards:
		if hazard.kind == "sludge":
			var id := "sludge_projectile_a" if int(hazard.age*10)%2 == 0 else "sludge_projectile_b"
			place(canvas,id,origin,hazard.pos,hazard.velocity.angle()+PI)
		elif hazard.kind == "gas":
			place(canvas,"gas_cloud_"+str(["a","b","c","d"][int(hazard.age*8)%4]),
				origin,hazard.rect.get_center(),0,Color(2,2,2) if hazard.get("flash",0.0) > 0 else Color.WHITE)
			if hazard.age < 0.3: place(canvas,"gas_emit",origin,snapshot.nozzle)
		else:
			place(canvas,"acid_puddle" if snapshot.state == "acid_puddle" else "acid_drop",origin,hazard.pos)

func place(canvas: Node2D, id: String, origin: Vector2, position: Vector2, rotation := 0.0, tint := Color.WHITE) -> void:
	if not definition.frames.has(id): return
	var part: Dictionary = definition.frames[id]
	if str(part.get("coordinate_space","")).begins_with("destination relative"):
		canvas.draw_set_transform(origin+position,rotation)
		canvas.draw_texture_rect_region(textures[part.path],rect(part.destination),rect(part.source_rect),tint)
		canvas.draw_set_transform(origin)
		return
	var anchor: Array = part.anchor
	frame(canvas,id,origin,position-Vector2(anchor[0],anchor[1]),Vector2.ONE,rotation)
