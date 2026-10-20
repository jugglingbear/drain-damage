extends RefCounted
## Authored art only. All coordinates respect the caller's existing world/camera transform.
const Water = preload("res://scripts/skitterling_water.gd")
const RoachBody = preload("res://scripts/skitterling_roach_body.gd")
const Encounter = preload("res://scripts/skitterling_encounter.gd")
const BODY_PATH := "res://assets/bestiary/cockroach-swarm/runtime-manifest-v1.json"
const ROOM_PATH := "res://assets/world/skitterling-room/manifest-v1.json"
const ANCHOR := Vector2(192, 224)
const CANVAS := Vector2i(384, 256)
const CUTOFF := 240
const COLLAPSE_SECONDS := .5
const ALLIGATOR_GROUNDED := ["alligator_ready", "alligator_surface_recovery", "alligator_charge_tell",
	"alligator_charge_turn", "alligator_charge", "alligator_jaw_recovery"]
const STATE_ART := {
	"rat_wall_approach":"rat_ground_scuttle", "rat_wall_climb":"rat_climb",
	"rat_pounce_tell":"rat_claw_tell", "rat_pounce":"rat_claw_pounce",
	"rat_pounce_recovery":"rat_land_recovery", "rat_rush_setup":"rat_ground_scuttle",
	"rat_rush_tell":"rat_ground_rush", "rat_rush":"rat_ground_rush", "rat_rush_recovery":"rat_ground_rush",
	"alligator_tail_tell":"alligator_tail_tell", "alligator_tail_sweep":"alligator_tail_sweep",
	"alligator_tail_recovery":"alligator_tail_recovery",
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
var roach_body := RoachBody.new()
var roach_front := RoachBody.new()
var roach_pipe := RoachBody.new()
var ceiling_rim: Texture2D
var water := Water.new()

func prepare() -> bool:
	if ready: return true
	if not shared_cache.is_empty():
		body = shared_cache.body
		room = shared_cache.room
		textures = shared_cache.textures
		images = shared_cache.images
		frames = shared_cache.frames
		roach_body.prepare(frames, images["assets/bestiary/cockroach-swarm/roach-layers-v1.png"])
		roach_front.prepare(frames, images["assets/bestiary/cockroach-swarm/roach-layers-v1.png"])
		roach_pipe.prepare(frames, images["assets/bestiary/cockroach-swarm/roach-layers-v1.png"])
		_prepare_water()
		_prepare_ceiling_rim()
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
			if frame.has("anatomy"): frames[key].anatomy = frame.anatomy
	roach_body.prepare(frames, images["assets/bestiary/cockroach-swarm/roach-layers-v1.png"])
	roach_front.prepare(frames, images["assets/bestiary/cockroach-swarm/roach-layers-v1.png"])
	roach_pipe.prepare(frames, images["assets/bestiary/cockroach-swarm/roach-layers-v1.png"])
	_prepare_water()
	_prepare_ceiling_rim()
	shared_cache = {"body":body, "room":room, "textures":textures, "images":images, "frames":frames}
	ready = true
	return true

func _prepare_water() -> void:
	var frame: Dictionary = room.effects.frames[0]
	var crop := _rect(frame.source_rect)
	var opaque := _rect_from_edges(frame.opaque_bounds)
	crop.position += opaque.position
	crop.size = opaque.size
	water.prepare(images[room.effects.path], Rect2i(crop))

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

func _selection(snapshot: Dictionary, hold_idle := true) -> Dictionary:
	var state: String = snapshot.get("state", "idle")
	if not STATE_ART.has(state): return {}
	if state in ["rat_wall_approach", "rat_rush_setup", "rat_rush_tell", "rat_rush", "rat_rush_recovery"]:
		return _ground_gait(snapshot)
	# Combat bounds deliberately retain the prior authored selection and timing.
	if hold_idle and state in ALLIGATOR_GROUNDED: return _alligator_ground_pose(snapshot)
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
	# Resting poses hold their structure; insects supply the continuous movement.
	if hold_idle and animation in ["rat_idle", "alligator_idle", "alligator_move"]: index = 0
	var next_index := (index + 1) % ids.size() if spec.loop else mini(index + 1, ids.size() - 1)
	var blend := fposmod(elapsed / float(spec.frame_seconds), 1.0) if spec.loop else fposmod(
		clampf(elapsed / duration, 0, 1) * ids.size(), 1.0)
	if hold_idle and animation in ["rat_idle", "alligator_idle", "alligator_move"]:
		next_index = index
		blend = 0.0
	if next_index == index: blend = 0.0
	return {"key":str(spec.sheet) + ":" + str(int(ids[index])), "state":state,
		"next_key":str(spec.sheet) + ":" + str(int(ids[next_index])), "blend":blend}

func collision_bounds(snapshot: Dictionary, world_origin := Vector2.ZERO) -> Rect2:
	## Preserve Prototype71 combat geometry independently of the new insect-only visuals.
	if not ready or not snapshot.get("visible", false): return Rect2()
	var selection := _selection(snapshot, false)
	if selection.is_empty(): return Rect2()
	var bounds: Rect2 = frames[selection.key].bounds
	if int(snapshot.get("facing", -1)) > 0:
		bounds.position.x = CANVAS.x - bounds.end.x
	var scale := rush_scale(snapshot)
	bounds = Rect2((bounds.position - ANCHOR) * scale, bounds.size * scale)
	bounds.position += world_origin + Vector2(snapshot.position)
	return bounds

func visible_bounds(snapshot: Dictionary, world_origin := Vector2.ZERO) -> Rect2:
	if not ready or not snapshot.get("visible", false): return Rect2()
	var selection := _selection(snapshot)
	if selection.is_empty(): return Rect2()
	var bounds: Rect2 = frames[selection.key].bounds.merge(frames[selection.next_key].bounds).grow(RoachBody.EXTENT)
	for pose: Dictionary in selection.get("overrides", {}).values():
		bounds = bounds.merge(frames[pose.key].bounds.grow(RoachBody.EXTENT))
		bounds = bounds.merge(frames[pose.next_key].bounds.grow(RoachBody.EXTENT))
	if int(snapshot.get("facing", -1)) > 0:
		bounds.position.x = CANVAS.x - bounds.end.x
	var scale := rush_scale(snapshot)
	bounds = Rect2((bounds.position - ANCHOR) * scale, bounds.size * scale)
	bounds.position += world_origin + Vector2(snapshot.position)
	return bounds

func state_is_still(snapshot: Dictionary) -> bool:
	return snapshot.get("state") == "rat_collapse" and float(snapshot.get("elapsed", 0)) >= COLLAPSE_SECONDS

func draw_boss(host: CanvasItem, snapshot: Dictionary, world_origin: Vector2, clock: float) -> void:
	if not ready: return
	var selection := _selection(snapshot)
	if not selection.is_empty() and snapshot.get("visible", false) and snapshot.get("state") not in ["alligator_swim", "alligator_surface_swim"]:
		roach_body.draw(host, selection.key, selection.next_key, selection.blend,
			world_origin + Vector2(snapshot.position), int(snapshot.get("facing", -1)),
			0.0 if state_is_still(snapshot) else clock, false, world_origin.y + 456, pipe_parameters(snapshot, world_origin),
			str(snapshot.get("state", "")).begins_with("rat_") or snapshot.get("state") in ALLIGATOR_GROUNDED,
			rush_scale(snapshot), selection.get("overrides", {}))

	var state: String = snapshot.get("state", "idle")
	if state == "rat_pipe_warning":
		roach_pipe.draw(host, "rat-source-v2:1", "rat-source-v2:1", 0.0, world_origin, -1, clock,
			false, world_origin.y + 456, pipe_parameters(snapshot, world_origin))
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

func draw_front(host: CanvasItem, snapshot: Dictionary, world_origin: Vector2, clock: float,
		include_room_water := true) -> void:
	if not ready: return
	var state: String = snapshot.get("state", "idle")
	if state in ["entry_skitter", "rat_pipe_retreat"]:
		_prop(host, "front_rim", Rect2(world_origin + Vector2(320, 108), Vector2(320, 300)))
	if state in ["rat_pipe_warning", "rat_pipe_launch", "rat_pipe_abort"]:
		var port: int = int(snapshot.get("port", 0))
		if port < 2:
			var x := 166.0 if port == 0 else 626.0
			host.draw_texture_rect(ceiling_rim, Rect2(world_origin + Vector2(x, 82), Vector2(168, 116)), false)
		else:
			var x := -22.0 if port == 2 else 842.0
			_prop(host, "front_rim", Rect2(world_origin + Vector2(x, 170), Vector2(140, 124)))
	# Animated water is confined below continuous hero support; it never changes collision.
	if include_room_water: water.draw(host, world_origin, clock)
	if state in ["alligator_swim", "alligator_surface_swim"]:
		_draw_swimmer(host, snapshot, world_origin, clock)
	if state in ["alligator_water_warning", "alligator_debris"]:
		var elapsed: float = snapshot.get("elapsed", 0.0)
		var id := (4 if elapsed < .4 else 5) if state == "alligator_water_warning" else (6 if elapsed < .2 else 7)
		var key := "water-actions-v2:" + str(id)
		roach_front.draw(host, key, key, 0.0, world_origin + Vector2(snapshot.column_x, 530),
			int(snapshot.get("facing", -1)), clock)

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
	roach_front.draw(host, selection.key, selection.next_key, selection.blend,
		world_origin + Vector2(snapshot.position), int(snapshot.get("facing", -1)), clock, true, world_origin.y + 456)

func warning_bounds(snapshot: Dictionary) -> Array[Rect2]:
	## Authored splashes reach the walkway at the committed hazard/return location.
	var state: String = snapshot.get("state", "idle")
	if state in ["alligator_water_warning", "alligator_debris"]:
		var columns: Array = snapshot.get("volley_targets", [])
		if columns.is_empty(): columns = [float(snapshot.column_x)]
		var marks: Array[Rect2] = []
		for column in columns: marks.append(Rect2(float(column) - 36, 384, 72, 56))
		return marks
	if state == "alligator_surface_warning":
		return [Rect2(Vector2(snapshot.landing).x - 75, 340, 150, 100)]
	return []

func _prepare_ceiling_rim() -> void:
	# Reuse the authored pipe. Clear only its dark aperture so insects sit behind the metal lip.
	var pixels: Image = images[room.pipes.path].get_region(_recti(room.pipes.props.ceiling_pipe.source_rect))
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			if ((Vector2(x, y) - Vector2(187, 396)) / Vector2(145, 32)).length_squared() < 1:
				pixels.set_pixel(x, y, Color.TRANSPARENT)
	ceiling_rim = ImageTexture.create_from_image(pixels)

func pipe_parameters(snapshot: Dictionary, world_origin := Vector2.ZERO) -> Dictionary:
	var state: String = snapshot.get("state", "")
	var elapsed := float(snapshot.get("elapsed", 0.0))
	if state in ["rat_pipe_retreat", "entry_skitter"]:
		return {"mode":"retreat" if state == "rat_pipe_retreat" else "launch",
			"progress":clampf(elapsed / float(Encounter.DURATIONS[state]), 0, 1),
			"mouth":world_origin + Vector2(480, 258), "radius":Vector2(115, 105),
			"outer":Rect2(world_origin + Vector2(320, 108), Vector2(320, 300))}
	if state not in ["rat_pipe_warning", "rat_pipe_launch", "rat_pipe_abort"]: return {}
	var port := int(snapshot.get("port", 0))
	var mouth: Vector2 = Vector2(snapshot.port_position) + world_origin
	var radius := Vector2(50, 44)
	var outer := Rect2(mouth - Vector2(70, 62), Vector2(140, 124))
	if port < 2:
		mouth.y = world_origin.y + 181
		radius = Vector2(64, 9)
		outer = Rect2(Vector2(mouth.x - 84, world_origin.y + 82), Vector2(168, 116))
	var mode := "warning" if state == "rat_pipe_warning" else "launch" if state == "rat_pipe_launch" else "retreat"
	return {"mode":mode, "elapsed":elapsed, "progress":clampf(elapsed / (.15 if mode == "launch" else float(Encounter.DURATIONS.get(state, 1.0))), 0, 1),
		"mouth":mouth, "radius":radius, "outer":outer}

func visible_target_regions(snapshot: Dictionary, world_origin := Vector2.ZERO) -> Array[Rect2]:
	## Pure shot-target coverage: sample visible insect cells, excluding the authored rim and consumed insects.
	var result: Array[Rect2] = []
	if snapshot.get("state", "") != "rat_pipe_retreat": return result
	var selection := _selection(snapshot)
	var pipe := pipe_parameters(snapshot, world_origin)
	for index in range(RoachBody.COUNT):
		var point := roach_body.insect_position(selection.key, selection.next_key, selection.blend, index, 0.0) - ANCHOR
		if int(snapshot.get("facing", -1)) > 0: point.x = -point.x
		point += Vector2(snapshot.position) + world_origin
		var sample := RoachBody.pipe_sample(index, point, pipe)
		if not sample.visible: continue
		# Small cells keep partially occluded insects from leaving a broad target across the metal rim.
		var center: Vector2 = sample.position
		var cells: Array = RoachBody.prepared_cells[Vector2i(index, int(snapshot.get("facing", -1)))]
		for local: Rect2 in cells:
			var cell := Rect2(center + local.position * float(sample.scale), local.size * float(sample.scale))
			var covered := false
			for corner: Vector2 in [cell.position, cell.end, Vector2(cell.end.x, cell.position.y), Vector2(cell.position.x, cell.end.y)]:
				if pipe.outer.has_point(corner) and ((corner - pipe.mouth) / pipe.radius).length_squared() > 1:
					covered = true
			if not covered: result.append(cell)
	return result

func visible_contact_regions(snapshot: Dictionary, world_origin := Vector2.ZERO, clock := 0.0) -> Array[Rect2]:
	## Conservative opaque insect cores, sharing the rat draw's analytic pose and pipe concealment.
	var result: Array[Rect2] = []
	if not ready or not snapshot.get("visible", false) or not snapshot.get("rat_contact_active", false): return result
	if snapshot.get("state", "") == "rat_pipe_retreat": return visible_target_regions(snapshot, world_origin)
	var selection := _selection(snapshot)
	if selection.is_empty(): return result
	var body_scale := rush_scale(snapshot)
	var pipe := pipe_parameters(snapshot, world_origin)
	var pose_clock := clock if pipe.is_empty() else 0.0
	for index in range(RoachBody.COUNT):
		var point := roach_body.insect_position(selection.key, selection.next_key, selection.blend, index, pose_clock) - ANCHOR
		var shape := roach_body.insect_shape(selection.key, selection.next_key, selection.blend, index, pose_clock)
		var size: Vector2 = shape.size if pipe.is_empty() else RoachBody.insect_size(index)
		var angle: float = shape.angle if pipe.is_empty() else RoachBody.insect_angle(index, 0.0)
		if int(snapshot.get("facing", -1)) > 0:
			point.x = -point.x
			angle = PI - angle
		point *= body_scale
		size *= body_scale
		point += Vector2(snapshot.position) + world_origin
		var sample := RoachBody.pipe_sample(index, point, pipe)
		if not sample.visible: continue
		point = sample.position
		size *= float(sample.scale)
		for offset in [-.18, 0.0, .18]:
			var center: Vector2 = point + Vector2.from_angle(angle) * size.x * offset
			var cell := Rect2(center - Vector2.ONE, Vector2(2, 2))
			if not roach_body.opaque_cell(cell, point, size, angle): continue
			var covered := false
			if not pipe.is_empty():
				for corner: Vector2 in [cell.position, cell.end, Vector2(cell.end.x, cell.position.y), Vector2(cell.position.x, cell.end.y)]:
					if pipe.outer.has_point(corner) and ((corner - pipe.mouth) / pipe.radius).length_squared() > 1: covered = true
			if not covered: result.append(cell)
	return result

func rush_scale(_snapshot: Dictionary) -> float:
	## Authored crouching changes posture, never whole-animal scale.
	return 1.0

func _alligator_ground_pose(snapshot: Dictionary) -> Dictionary:
	var state: String = snapshot.state
	var stride := float(body.get("alligator_ground_motion", {}).get("stride_distance_pixels", 120.0))
	var phase := fposmod(float(snapshot.get("alligator_ground_distance", 0.0)) / stride, 1.0) * 6.0
	var index := int(phase)
	var jaw := _alligator_jaw_pose(snapshot)
	return {"key":"alligator-run-source-v1:" + str(index),
		"next_key":"alligator-run-source-v1:" + str((index + 1) % 6),
		"blend":fposmod(phase, 1.0), "state":state,
		"overrides":{"upper_jaw":jaw, "lower_jaw":jaw,
			"torso_tail":{"key":"alligator-run-source-v1:0", "next_key":"alligator-run-source-v1:0", "blend":0.0}}}

func _alligator_jaw_cycle(elapsed: float) -> Dictionary:
	# Preserve the earlier .52-second snap rhythm, but separate opening, closure and recovery.
	var time := fposmod(elapsed, .52)
	var times := [0.0, .07, .11, .24, .32, .43, .52]
	var ids := [3, 4, 5, 0, 1, 2, 3]
	var index := 0
	while index < times.size() - 2 and time >= times[index + 1]: index += 1
	return {"key":"alligator-jaw-source-v1:" + str(ids[index]),
		"next_key":"alligator-jaw-source-v1:" + str(ids[index + 1]),
		"blend":inverse_lerp(times[index], times[index + 1], time)}

func _alligator_jaw_pose(snapshot: Dictionary) -> Dictionary:
	var state: String = snapshot.state
	var elapsed := float(snapshot.get("elapsed", 0.0))
	if state == "alligator_charge": return _alligator_jaw_cycle(elapsed)
	if state in ["alligator_charge_turn", "alligator_jaw_recovery"]:
		var last := _alligator_jaw_cycle(float(snapshot.get("alligator_snap_elapsed", 0.0)))
		if elapsed < .1:
			last.blend *= 1.0 - smoothstep(0, .1, elapsed)
			return last
		return {"key":last.key, "next_key":"alligator-jaw-source-v1:" + (
			"3" if state == "alligator_charge_turn" else "0"), "blend":clampf((elapsed - .1) / .3, 0, 1)}
	if state == "alligator_charge_tell":
		var amount := clampf(elapsed / .65, 0, 1) * 3
		var index := mini(2, int(amount))
		return {"key":"alligator-jaw-source-v1:" + str(index),
			"next_key":"alligator-jaw-source-v1:" + str(index + 1), "blend":amount - index}
	return {"key":"alligator-jaw-source-v1:0", "next_key":"alligator-jaw-source-v1:0", "blend":0.0}

func _ground_gait(snapshot: Dictionary) -> Dictionary:
	var state: String = snapshot.state
	var phase := fposmod(float(snapshot.get("rat_ground_distance", 0.0)) / 120.0, 1.0) * 6.0
	var index := int(phase)
	var sheet := "rat-crouch-source-v1" if state in ["rat_rush_tell", "rat_rush", "rat_rush_recovery"] else "rat-run-source-v1"
	var key := sheet + ":" + str(index)
	var next_key := sheet + ":" + str((index + 1) % 6)
	var blend := fposmod(phase, 1.0)
	var elapsed := float(snapshot.get("elapsed", 0.0))
	var fraction := blend
	if state == "rat_rush_tell":
		key = "rat-run-source-v1:" + str(index)
		if elapsed < .1:
			next_key = "rat-run-source-v1:" + str((index + 1) % 6)
			blend = fraction * (1.0 - smoothstep(0, .1, elapsed))
		else:
			next_key = "rat-crouch-source-v1:" + str(index)
			blend = clampf((elapsed - .1) / .2, 0, 1)
		if elapsed >= .7:
			key = "rat-crouch-source-v1:" + str(index)
			next_key = "rat-crouch-source-v1:" + str((index + 1) % 6)
			blend = fraction * smoothstep(.7, .8, elapsed)
	elif state == "rat_rush_recovery":
		key = "rat-crouch-source-v1:" + str(index)
		if elapsed < .1:
			next_key = "rat-crouch-source-v1:" + str((index + 1) % 6)
			blend = fraction * (1.0 - smoothstep(0, .1, elapsed))
		elif elapsed < 1.1:
			next_key = "rat-run-source-v1:" + str(index)
			blend = clampf((elapsed - .8) / .3, 0, 1)
		else:
			key = "rat-run-source-v1:" + str(index)
			next_key = "rat-run-source-v1:" + str((index + 1) % 6)
			blend = fraction * smoothstep(1.1, 1.2, elapsed)
	return {"key":key, "next_key":next_key, "blend":blend, "state":state}
