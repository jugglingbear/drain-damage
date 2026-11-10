extends RefCounted
## Persistent, harmless corpse snapshots, with opaque-pixel support rather than sprite margins.
const PATH := "res://assets/bestiary/regular-remains-v1/manifest.json"
const STEP := 1.0/120.0
var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
var frames: Dictionary = {}
var textures: Dictionary = {}
var entries: Array[Dictionary] = []
var remainder := 0.0

func prepare(host: Node, yield_frame := Callable()) -> void:
	frames.angel = definition.angel.frames.duplicate(true)
	frames.swarm = definition.sewer_swarm.frames.duplicate(true)
	var spec: Dictionary = host.trial_data.role_art.roles.gratecrawler
	frames.grate = []
	for index in range(spec.states.death.frames.size()):
		var frame: Dictionary = spec.frames[spec.states.death.frames[index]].duplicate(true)
		frame.destination[0] -= spec.anchor[0]
		frame.destination[1] -= spec.anchor[1]
		frame.duration_seconds = spec.states.death.durations[index]
		frames.grate.append(frame)
	var final: Dictionary = definition.gratecrawler.reuse_frame.duplicate(true)
	final.destination[0] -= final.anchor[0]
	final.destination[1] -= final.anchor[1]
	final.duration_seconds = 0.0
	frames.grate.append(final)
	for sequence: Array in frames.values():
		for frame: Dictionary in sequence:
			if not textures.has(frame.path):
				if yield_frame.is_valid(): await yield_frame.call()
				var texture: Texture2D = load("res://"+frame.path)
				var pixels := texture.get_image()
				pixels.convert(Image.FORMAT_RGBA8)
				var bytes := pixels.get_data()
				for index in range(3,bytes.size(),4):
					if bytes[index] < 240: bytes[index] = 0
				pixels.set_data(pixels.get_width(),pixels.get_height(),false,Image.FORMAT_RGBA8,bytes)
				textures[frame.path] = ImageTexture.create_from_image(pixels)
			var source := rect(frame.source_rect)
			var image: Image = textures[frame.path].get_image().get_region(Rect2i(source))
			var used := Rect2(image.get_used_rect())
			var destination := rect(frame.destination)
			frame.opaque = Rect2(destination.position+used.position*destination.size/source.size,
				used.size*destination.size/source.size)

func rect(value: Array) -> Rect2: return Rect2(value[0],value[1],value[2],value[3])

func reset() -> void:
	entries.clear()
	remainder = 0

func begin(host: Node, actor: Dictionary) -> void:
	if actor.get("regular_remains_recorded",false): return
	actor.regular_remains_recorded = true
	var kind := "angel" if actor.role == "aggressive_flyer" else "grate"
	var origin: Vector2 = host.actor_rect(actor).get_center() if kind == "angel" else actor.feet
	add(kind,origin,host.role_scale(actor.role),float(actor.facing),0)
	# Ground deaths inherit real foot support; atlas padding is not a collision baseline.
	var footprint := bounds(entries.back())
	footprint.position.y = actor.feet.y
	footprint.size.y = 0
	var support := support_at(host,footprint,actor.feet.y)
	if is_finite(support): settle(entries.back(),support)

func begin_swarm(_host: Node, actor: Dictionary) -> void:
	if actor.get("regular_remains_recorded",false): return
	actor.regular_remains_recorded = true
	var seed_value: int = actor.rng.seed if actor.has("rng") else str(actor.get("event_id","")).hash()
	add("swarm",actor.pos,1.0,1.0,posmod(seed_value,3))

func add(kind: String, origin: Vector2, scale: float, facing: float, variant: int) -> void:
	entries.append({"kind":kind,"origin":origin,"scale":scale,"facing":facing,"frame":variant,
		"age":0.0,"falling":true,"landed_once":false,"velocity":0.0,"lost":false})

func bounds(entry: Dictionary) -> Rect2:
	var frame: Dictionary = frames[entry.kind][entry.frame]
	var local: Rect2 = frame.opaque
	if entry.facing > 0: local.position.x = -local.end.x
	return Rect2(entry.origin+local.position*entry.scale,local.size*entry.scale)

func support_at(host: Node, box: Rect2, previous_bottom: float) -> float:
	var support := INF
	for solid: Rect2 in host.actor_solids():
		if box.end.x <= solid.position.x or box.position.x >= solid.end.x: continue
		if previous_bottom <= solid.position.y+0.01 and box.end.y >= solid.position.y-0.01:
			support = minf(support,solid.position.y)
	return support

func settle(entry: Dictionary, support: float) -> void:
	entry.falling = false
	entry.velocity = 0
	entry.landed_once = true
	if entry.kind == "angel":
		entry.frame = 1
		entry.age = 0
	entry.origin.y += support-bounds(entry).end.y

func step(host: Node, delta: float) -> void:
	if host.paused or delta <= 0: return
	remainder += delta
	while remainder+0.0000001 >= STEP:
		remainder -= STEP
		for entry in entries:
			if entry.lost: continue
			var old := bounds(entry)
			entry.age += STEP
			if entry.kind == "grate":
				var age: float = entry.age
				entry.frame = frames.grate.size()-1
				for index in range(frames.grate.size()-1):
					if age < frames.grate[index].duration_seconds:
						entry.frame = index
						break
					age -= frames.grate[index].duration_seconds
			elif entry.kind == "angel" and not entry.falling and entry.age >= 0.12:
				entry.frame = 2
			if not entry.falling:
				var support := support_at(host,old,old.end.y)
				entry.origin.y += old.end.y-bounds(entry).end.y
				if is_finite(support): continue
				entry.falling = true
			entry.velocity += 600.0*STEP
			entry.origin.y += entry.velocity*STEP
			var box := bounds(entry)
			var support := support_at(host,box,old.end.y)
			if is_finite(support): settle(entry,support)
			elif box.position.y > float(host.FLOOR_Y)+700: entry.lost = true

func draw(host: Node2D) -> void:
	for entry in entries:
		if entry.lost: continue
		var frame: Dictionary = frames[entry.kind][entry.frame]
		host.draw_set_transform(entry.origin-Vector2(floorf(host.camera_x),0),0,
			Vector2(-1 if entry.facing > 0 else 1,1)*entry.scale)
		host.draw_texture_rect_region(textures[frame.path],rect(frame.destination),rect(frame.source_rect))
	host.draw_set_transform(Vector2(-floorf(host.camera_x),0))
