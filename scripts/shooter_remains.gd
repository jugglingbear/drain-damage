extends RefCounted
## Harmless world-space shooter wrecks; source actors may retire independently.
const PATH := "res://assets/bestiary/opening-trial/sputtervalve-death-v1.json"
const STEP := 1.0/120.0
const GRAVITY := 600.0
var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
var entries: Array[Dictionary] = []
var seen: Dictionary = {}
var remainder := 0.0

func prepare(host: Node, yield_frame := Callable()) -> void:
	for frame: Dictionary in definition.frames: frame.alpha_cutoff = 240
	await host.load_trial_textures(definition,yield_frame)
	host.ceiling_shooter_art.prepare()

func reset() -> void:
	entries.clear()
	seen.clear()
	remainder = 0

func begin(host: Node, actor: Dictionary) -> void:
	if seen.has(actor.event_id): return
	seen[actor.event_id] = true
	var ceiling: bool = actor.get("mount","") == "ceiling"
	var entry := {"id":actor.event_id,"origin":Vector2(actor.feet),"mount":Vector2(actor.feet),
		"facing":float(actor.facing),"scale":host.role_scale("perched_shooter"),"age":0.0,
		"ceiling":ceiling,"falling":ceiling,"lost":false,"velocity":0.0,"drop":0.0,"spin":0.0,
		"frame":0,"body":Rect2(),"barrel":Rect2(),"pivot":Vector2.ZERO,"aim":0.0}
	if ceiling:
		var art = host.ceiling_shooter_art
		entry.body = art.body_rect(actor.feet)
		entry.pivot = art.pivot(actor.feet)
		entry.aim = art.angle(host.ceiling_direction(actor))
		var spec: Dictionary = art.definition
		entry.barrel = Rect2(-art.vector(spec.barrel_pivot_in_frame)*float(spec.barrel_scale),
			Vector2(spec.barrel_source_rect[2],spec.barrel_source_rect[3])*float(spec.barrel_scale))
	else:
		entry.falling = not supported(host,entry.origin)
	entries.append(entry)

func supported(host: Node, point: Vector2) -> bool:
	for solid: Rect2 in host.actor_solids():
		if absf(solid.position.y-point.y) < 0.1 and point.x >= solid.position.x and point.x <= solid.end.x: return true
	return false

func rotated_bounds(rect: Rect2, transform: Transform2D) -> Rect2:
	var bounds := Rect2(transform*rect.position,Vector2.ZERO)
	for point in [Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
		bounds = bounds.expand(transform*point)
	return bounds

func falling_bounds(entry: Dictionary) -> Rect2:
	if not entry.ceiling:
		return Rect2(entry.origin+Vector2(-19,-50)*entry.scale+Vector2(0,entry.drop),Vector2(38,50)*entry.scale)
	var body: Rect2 = entry.body
	body.position.y += 10
	body.size.y -= 10
	var center := body.get_center()
	var bounds := rotated_bounds(Rect2(-body.size/2,body.size),Transform2D(entry.spin,center+Vector2(0,entry.drop)))
	return bounds.merge(rotated_bounds(entry.barrel,
		Transform2D(entry.aim-entry.spin,entry.pivot+Vector2(0,entry.drop))))

func select_frame(age: float) -> int:
	for index in range(5):
		var duration: float = definition.frames[index].duration_seconds
		if age < duration-0.000001: return index
		age -= duration
	return 5

func step(host: Node, delta: float) -> void:
	if host.paused or delta <= 0: return
	remainder += delta
	while remainder+0.0000001 >= STEP:
		remainder -= STEP
		for entry in entries:
			if entry.lost: continue
			if not entry.falling:
				entry.age += STEP
				entry.frame = select_frame(entry.age)
				continue
			var old := falling_bounds(entry)
			entry.velocity += GRAVITY*STEP
			entry.drop += entry.velocity*STEP
			entry.spin += STEP*0.8*entry.facing
			var bounds := falling_bounds(entry)
			var support := INF
			for solid: Rect2 in host.actor_solids():
				if bounds.end.x <= solid.position.x or bounds.position.x >= solid.end.x: continue
				if old.end.y <= solid.position.y+0.001 and bounds.end.y >= solid.position.y:
					support = minf(support,solid.position.y)
			if is_finite(support):
				entry.origin = Vector2(entry.origin.x,support)
				entry.falling = false
				entry.age = 0.28
				entry.frame = 3
			elif bounds.position.y > float(host.FLOOR_Y)+700:
				entry.lost = true

func draw(host: Node2D) -> void:
	var camera := Vector2(floorf(host.camera_x),0)
	for entry in entries:
		if entry.ceiling:
			var art = host.ceiling_shooter_art
			var plate: Rect2 = entry.body
			plate.size.y = 10
			host.draw_set_transform(-camera)
			host.draw_texture_rect_region(art.bodies[0],plate,Rect2(0,0,475,100))
		if entry.lost: continue
		if entry.falling and entry.ceiling:
			var art = host.ceiling_shooter_art
			var body: Rect2 = entry.body
			body.position.y += 10
			body.size.y -= 10
			host.draw_set_transform(body.get_center()+Vector2(0,entry.drop)-camera,entry.spin)
			host.draw_texture_rect_region(art.bodies[0],Rect2(-body.size/2,body.size),Rect2(0,100,475,398))
			host.draw_set_transform(entry.pivot+Vector2(0,entry.drop)-camera,entry.aim-entry.spin)
			host.draw_texture_rect(art.barrel,entry.barrel,false)
			continue
		var frame: Dictionary = definition.frames[entry.frame].duplicate(true)
		var destination: Rect2 = host.region(frame.destination)
		# Crop at the actual supporting plane; small painted fragments cannot extend underground.
		if not entry.falling and destination.end.y > 0:
			frame.source_rect[3] *= -destination.position.y/destination.size.y
			destination.size.y = -destination.position.y
		host.draw_set_transform(entry.origin+Vector2(0,entry.drop if entry.falling else 0)-camera,0,
			Vector2(-1 if entry.facing > 0 else 1,1)*entry.scale)
		host.draw_asset(frame,destination)
	host.draw_set_transform(-camera)
