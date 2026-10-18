extends RefCounted
## Authored art only. All coordinates respect the caller's existing world/camera transform.
const Encounter = preload("res://scripts/skitterling_encounter.gd")
const BODY_PATH := "res://assets/bestiary/cockroach-swarm/runtime-manifest-v1.json"
const ROOM_PATH := "res://assets/world/skitterling-room/manifest-v1.json"
const ANCHOR := Vector2(192, 224)
const CANVAS := Vector2i(384, 256)
const CUTOFF := 240
const COLLAPSE_SECONDS := .5
const STATE_ART := {
	"entry_skitter":"floor_skitter", "rat_assembly":"rat_assembly", "rat_ready":"rat_idle",
	"rat_bite_tell":"rat_warning", "rat_bite":"rat_bite", "rat_bite_recovery":"rat_recovery",
	"rat_pipe_retreat":"rat_retreat", "rat_pipe_launch":"rat_airborne", "rat_pipe_abort":"rat_airborne",
	"rat_landing_recovery":"rat_landing", "rat_collapse":"rat_collapse", "reskitter":"floor_skitter",
	"alligator_assembly":"alligator_assembly", "alligator_ready":"alligator_idle",
	"alligator_jaw_tell":"alligator_warning", "alligator_jaw_lunge":"alligator_bite",
	"alligator_jaw_recovery":"alligator_recovery", "alligator_water_dive":"alligator_dive",
	"alligator_surface":"alligator_surface", "alligator_surface_return":"alligator_dive",
	"alligator_surface_recovery":"alligator_recovery",
	"terminal_death":"terminal_death",
	"alligator_swim":"alligator_move", "alligator_surface_swim":"alligator_move",
	"alligator_charge_tell":"alligator_warning", "alligator_charge_turn":"alligator_warning",
	"alligator_charge":"alligator_charge",
}
static var shared_cache: Dictionary = {}
var ready := false
var body: Dictionary = {}
var room: Dictionary = {}
var textures: Dictionary = {}
var images: Dictionary = {}
var frames: Dictionary = {}
var last_error := ""

func prepare() -> bool:
	if ready: return true
	if not shared_cache.is_empty():
		body = shared_cache.body
		room = shared_cache.room
		textures = shared_cache.textures
		images = shared_cache.images
		frames = shared_cache.frames
		ready = true
		return true
	body = _json(BODY_PATH)
	room = _json(ROOM_PATH)
	if body.is_empty() or room.is_empty(): return _fail("Missing Skitterling manifests")
	for sheet: Dictionary in body.sheets:
		if not _load_texture(sheet.path, true): return false
	for entry: Dictionary in [room.background, room.pipes, room.effects, room.portals]:
		if not _load_texture(entry.path, entry != room.background): return false
	for sheet: Dictionary in body.sheets:
		for frame: Dictionary in sheet.frames:
			if not frame.enabled: continue
			var source := _recti(frame.source_rect)
			var pixels: Image = images[sheet.path]
			if not Rect2i(Vector2i.ZERO, pixels.get_size()).encloses(source):
				return _fail("Source crop outside " + str(sheet.path))
			var destination := _recti(frame.destination)
			var crop := pixels.get_region(source)
			crop.resize(maxi(1, destination.size.x), maxi(1, destination.size.y), Image.INTERPOLATE_NEAREST)
			var canvas := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
			canvas.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), destination.position)
			var key := str(sheet.id) + ":" + str(int(frame.id))
			frames[key] = {"image":canvas, "textures":[ImageTexture.create_from_image(canvas)],
				"bounds":Rect2(canvas.get_used_rect())}
	# Bake independent crawling layers once; no image allocation or pixel work during gameplay.
	for key: String in frames.keys():
		if not _formed_sheet(key): continue
		var base: Image = frames[key].image
		var bounds: Rect2 = frames[key].bounds
		var variants: Array = []
		for phase in range(4):
			var composite := base.duplicate() as Image
			for patch in range(8):
				var bug: Image = frames["roach-layers-v1:" + str(8 + posmod(phase + patch, 4))].image
				var tile := bug.get_region(bug.get_used_rect())
				tile.resize(22, 14, Image.INTERPOLATE_NEAREST)
				var at := Vector2i(bounds.position + bounds.size * Vector2(
					.15 + float(patch % 4) * .2, .35 + float(patch / 4) * .3))
				at.x = clampi(at.x, 0, CANVAS.x - 22)
				at.y = clampi(at.y, 0, CANVAS.y - 14)
				var mask := base.get_region(Rect2i(at, tile.get_size()))
				composite.blend_rect_mask(tile, mask, Rect2i(Vector2i.ZERO, tile.get_size()), at)
			variants.append(ImageTexture.create_from_image(composite))
		frames[key].textures = variants
	shared_cache = {"body":body, "room":room, "textures":textures, "images":images, "frames":frames}
	ready = true
	return true

func _formed_sheet(key: String) -> bool:
	return not key.begins_with("roach-layers")

func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _fail(message: String) -> bool:
	last_error = message
	push_error(message)
	return false

func _load_texture(path: String, clean: bool) -> bool:
	if textures.has(path): return true
	var source = load("res://" + path)
	if not source is Texture2D: return _fail("Missing authored texture: " + path)
	var pixels: Image = source.get_image()
	pixels.convert(Image.FORMAT_RGBA8)
	if clean:
		var bytes := pixels.get_data()
		for index in range(3, bytes.size(), 4): bytes[index] = 255 if bytes[index] >= CUTOFF else 0
		pixels = Image.create_from_data(pixels.get_width(), pixels.get_height(), false, Image.FORMAT_RGBA8, bytes)
	images[path] = pixels
	textures[path] = ImageTexture.create_from_image(pixels)
	return true

func _rect(values: Array) -> Rect2:
	return Rect2(values[0], values[1], values[2], values[3])

func _recti(values: Array) -> Rect2i:
	return Rect2i(roundi(values[0]), roundi(values[1]), roundi(values[2]), roundi(values[3]))

func _prop(host: CanvasItem, id: String, destination: Rect2, flip := false) -> void:
	if flip: destination.size.x = -destination.size.x
	host.draw_texture_rect_region(textures[room.pipes.path], destination,
		_rect(room.pipes.props[id].source_rect))

func draw_room(host: CanvasItem, world_origin: Vector2, exit_open: bool) -> void:
	if not ready: return
	for strip: Dictionary in room.background.strips:
		var destination := _rect(strip.destination)
		destination.position += world_origin
		host.draw_texture_rect_region(textures[room.background.path], destination, _rect(strip.source_rect))
	for instance: Dictionary in room.instances:
		if instance.id in ["entry", "exit"]: continue
		var destination := _rect(instance.destination)
		destination.position += world_origin
		var prop: String = instance.prop
		if instance.id == "exit" and exit_open: prop = "open"
		_prop(host, prop, destination, instance.get("mirror_x", false))

func _selection(snapshot: Dictionary) -> Dictionary:
	var state: String = snapshot.get("state", "idle")
	if not STATE_ART.has(state): return {}
	var animation: String = STATE_ART[state]
	var elapsed: float = snapshot.get("elapsed", 0.0)
	var duration: float = Encounter.DURATIONS.get(state, 1.0)
	if state == "rat_collapse":
		if elapsed >= COLLAPSE_SECONDS: animation = "rat_false_death"
		else: duration = COLLAPSE_SECONDS
	var spec: Dictionary = body.animations[animation]
	var ids: Array = spec.frames
	var index := posmod(int(elapsed / float(spec.frame_seconds)), ids.size()) if spec.loop else mini(
		ids.size() - 1, int(clampf(elapsed / duration, 0, 1) * ids.size()))
	return {"key":str(spec.sheet) + ":" + str(int(ids[index])), "state":state}

func visible_bounds(snapshot: Dictionary, world_origin := Vector2.ZERO) -> Rect2:
	if not ready or not snapshot.get("visible", false): return Rect2()
	var selection := _selection(snapshot)
	if selection.is_empty(): return Rect2()
	var bounds: Rect2 = frames[selection.key].bounds
	if int(snapshot.get("facing", -1)) > 0:
		bounds.position.x = CANVAS.x - bounds.end.x
	bounds.position += world_origin + Vector2(snapshot.position) - ANCHOR
	return bounds

func state_is_still(snapshot: Dictionary) -> bool:
	return snapshot.get("state") == "rat_collapse" and float(snapshot.get("elapsed", 0)) >= COLLAPSE_SECONDS

func draw_boss(host: CanvasItem, snapshot: Dictionary, world_origin: Vector2, clock: float) -> void:
	if not ready: return
	var selection := _selection(snapshot)
	if not selection.is_empty() and snapshot.get("visible", false) and snapshot.get("state") not in ["alligator_swim", "alligator_surface_swim"]:
		var frame: Dictionary = frames[selection.key]
		var variants: Array = frame.textures
		var phase := 0 if state_is_still(snapshot) else posmod(int(clock * 10), variants.size())
		var destination := Rect2(world_origin + Vector2(snapshot.position) - ANCHOR, Vector2(CANVAS))
		if int(snapshot.get("facing", -1)) > 0: destination.size.x = -destination.size.x
		host.draw_texture_rect(variants[phase], destination, false)
	var state: String = snapshot.get("state", "idle")
	if state == "entry_skitter":
		# Authored insect tiles travel from the visible rear mouth to the foreground swarm.
		for index in range(16):
			var progress := fposmod(clock * .65 + index * .061, 1.0)
			var target := Vector2(350 + index * 17, 440)
			_effect(host, 12 + posmod(index + int(clock * 10), 4),
				world_origin + Vector2(480, 300).lerp(target, progress), Vector2(24, 16))
	if state == "rat_pipe_warning":
		_effect(host, 12 + posmod(int(clock * 10), 4), world_origin + Vector2(snapshot.port_position), Vector2(96, 64))
		_effect(host, 12 + posmod(int(clock * 10 + 2), 4), world_origin + Vector2(snapshot.landing), Vector2(112, 32))

func _effect(host: CanvasItem, id: int, at: Vector2, size: Vector2) -> void:
	var frame: Dictionary = room.effects.frames[id]
	var source := _rect(frame.source_rect)
	var opaque := _rect_from_edges(frame.opaque_bounds)
	source.position += opaque.position
	source.size = opaque.size
	host.draw_texture_rect_region(textures[room.effects.path], Rect2(at - Vector2(size.x * .5, size.y), size), source)

func _rect_from_edges(values: Array) -> Rect2:
	return Rect2(values[0], values[1], values[2] - values[0], values[3] - values[1])

func draw_front(host: CanvasItem, snapshot: Dictionary, world_origin: Vector2, clock: float) -> void:
	if not ready: return
	var state: String = snapshot.get("state", "idle")
	if state in ["entry_skitter", "rat_pipe_retreat"]:
		_prop(host, "front_rim", Rect2(world_origin + Vector2(320, 108), Vector2(320, 300)))
	# Animated water is confined below continuous hero support; it never changes collision.
	for column in range(3):
		_effect(host, posmod(int(clock * 8) + column, 4), world_origin + Vector2(160 + column * 320, 540), Vector2(320, 84))
	if state in ["alligator_swim", "alligator_surface_swim"]:
		_draw_swimmer(host, snapshot, world_origin, clock)
	if state in ["alligator_water_warning", "alligator_debris"]:
		var elapsed: float = snapshot.get("elapsed", 0.0)
		var id := (4 if elapsed < .4 else 5) if state == "alligator_water_warning" else (6 if elapsed < .2 else 7)
		var key := "water-actions-v2:" + str(id)
		var destination := Rect2(world_origin + Vector2(snapshot.column_x, 530) - ANCHOR, Vector2(CANVAS))
		host.draw_texture_rect(frames[key].textures[posmod(int(clock * 10), 4)], destination, false)
	if state in ["alligator_water_dive", "alligator_surface"]:
		_effect(host, 4 + posmod(int(clock * 10), 4), world_origin + Vector2(snapshot.position.x, 500), Vector2(150, 100))
	for warning: Rect2 in warning_bounds(snapshot):
		_effect(host, 4 + posmod(int(clock * 10), 4),
			world_origin + Vector2(warning.get_center().x, warning.end.y), warning.size)
	for hazard: Dictionary in snapshot.get("hazards", []):
		_effect(host, 8 + posmod(int(hazard.id), 4), world_origin + Vector2(hazard.position) + Vector2(0, 14), Vector2(28, 28))

func draw_entry(host: CanvasItem, world_x: float) -> void:
	## Compatibility entry point; new callers use paired portal APIs around hero drawing.
	if not ready: return
	_portal(host, "front_open", world_x - 120, Vector2.ZERO, false)

func _portal(host: CanvasItem, layer: String, local_x: float, origin: Vector2, flip: bool) -> void:
	var data: Dictionary = room.portals.layers[layer]
	var destination := _rect(data.destination)
	destination.position += origin + Vector2(local_x, 0)
	if flip: destination.size.x = -destination.size.x
	host.draw_texture_rect_region(textures[room.portals.path], destination, _rect(data.source_rect))

func draw_portals_back(host: CanvasItem, world_origin: Vector2, _entry_closed: bool, _exit_open: bool) -> void:
	if not ready: return
	for portal: Dictionary in room.portals.instances:
		_portal(host, "rear", portal.local_x, world_origin, false)

func draw_portals_front(host: CanvasItem, world_origin: Vector2, entry_closed: bool, exit_open: bool) -> void:
	if not ready: return
	_portal(host, "front_closed" if entry_closed else "front_open", -120, world_origin, false)
	_portal(host, "front_open" if exit_open else "front_closed", 840, world_origin, not exit_open)

func portal_occlusion_rects(world_origin: Vector2, _entry_closed := false, _exit_open := false) -> Array[Rect2]:
	if not ready: return []
	var result: Array[Rect2] = []
	for portal: Dictionary in room.portals.instances:
		var area := _rect(room.portals.opaque_hero_band)
		area.position += world_origin + Vector2(portal.local_x, 0)
		result.append(area)
	return result

func _draw_swimmer(host: CanvasItem, snapshot: Dictionary, world_origin: Vector2, clock: float) -> void:
	var selection := _selection(snapshot)
	if selection.is_empty(): return
	var variants: Array = frames[selection.key].textures
	var destination := Rect2(world_origin + Vector2(snapshot.position) - ANCHOR, Vector2(CANVAS))
	var clipped := destination.intersection(Rect2(world_origin + Vector2(0, 456), Vector2(960, 84)))
	if not clipped.has_area(): return
	var source := Rect2(clipped.position - destination.position, clipped.size)
	if int(snapshot.get("facing", -1)) > 0:
		source.position.x = CANVAS.x - source.end.x
		clipped.size.x = -clipped.size.x
	host.draw_texture_rect_region(variants[posmod(int(clock * 10), variants.size())], clipped, source,
		Color(.65, .85, .85, .85))

func warning_bounds(snapshot: Dictionary) -> Array[Rect2]:
	## Authored splashes reach the walkway at the committed hazard/return location.
	var state: String = snapshot.get("state", "idle")
	if state in ["alligator_water_warning", "alligator_debris"]:
		return [Rect2(float(snapshot.column_x) - 36, 384, 72, 56)]
	if state == "alligator_surface_warning":
		return [Rect2(Vector2(snapshot.landing).x - 75, 340, 150, 100)]
	return []
