extends SceneTree
const Art = preload("res://scripts/skitterling_art.gd")
const Encounter = preload("res://scripts/skitterling_encounter.gd")

class ArtCanvas extends Node2D:
	var art: RefCounted
	var snapshot: Dictionary
	func _draw() -> void:
		draw_set_transform(Vector2(-6570, 0))
		art.draw_room(self, Vector2(6570, 0), snapshot.exit_open)
		art.draw_portals_back(self, Vector2(6570, 0), true, snapshot.exit_open)
		art.draw_boss(self, snapshot, Vector2(6570, 0), 3.4)
		art.draw_front(self, snapshot, Vector2(6570, 0), 3.4)
		art.draw_portals_front(self, Vector2(6570, 0), true, snapshot.exit_open)

func _initialize() -> void:
	var art := Art.new()
	assert(art.prepare(), art.last_error)
	assert(art.frames.size() > 70)
	var cached = art.frames["rat-source-v2:1"].textures[0]
	assert(art.prepare() and art.frames["rat-source-v2:1"].textures[0] == cached)
	var second := Art.new()
	assert(second.prepare() and second.frames["rat-source-v2:1"].textures[0] == cached)
	var masks: Array[Rect2] = art.portal_occlusion_rects(Vector2(6570, 0), true, false)
	assert(masks[0].encloses(Rect2(6550, 394, 26, 46)))
	assert(masks[1].encloses(Rect2(7510, 394, 26, 46)))
	# Check every logical hero-band pixel against the prepared authored shell, not its bounding box.
	for layer: String in ["front_open", "front_closed"]:
		var spec: Dictionary = art.room.portals.layers[layer]
		var source: Rect2 = art._rect(spec.source_rect)
		var destination: Rect2 = art._rect(spec.destination)
		var pixels: Image = art.images[art.room.portals.path]
		for x in range(40, 200):
			for y in range(394, 440):
				var uv := source.position + (Vector2(x, y) - destination.position) / destination.size * source.size
				assert(pixels.get_pixelv(Vector2i(uv)).a == 1.0, "Portal must fully cover walking hero")
	var changed := false
	for key: String in art.frames:
		var frame: Dictionary = art.frames[key]
		var base: PackedByteArray = frame.image.get_data()
		for texture: Texture2D in frame.textures:
			var variant := texture.get_image().get_data()
			for index in range(3, variant.size(), 4):
				assert(variant[index] == base[index], "Churn must preserve exact body alpha: " + key)
			if variant != base: changed = true
	assert(changed, "Authored roach layers must visibly change body pixels")
	var encounter := Encounter.new()
	encounter.configure(21)
	encounter.start(Rect2(90, 394, 26, 46))
	var snapshot := encounter.snapshot()
	snapshot.state = "rat_ready"
	snapshot.visible = true
	snapshot.position = Vector2(480, 440)
	snapshot.elapsed = .2
	snapshot.facing = -1
	var left: Rect2 = art.visible_bounds(snapshot)
	snapshot.facing = 1
	var right: Rect2 = art.visible_bounds(snapshot)
	assert(is_equal_approx(left.position.x - 480, 480 - right.end.x))
	assert(left.size == right.size and left.end.y <= 441)
	snapshot.state = "rat_collapse"
	snapshot.elapsed = .5
	assert(art.state_is_still(snapshot))
	assert(is_equal_approx(Encounter.DURATIONS.rat_collapse - Art.COLLAPSE_SECONDS, 4.0))
	var dead: Dictionary = art._selection(snapshot)
	snapshot.elapsed = 4.0
	assert(dead == art._selection(snapshot), "False death must remain motionless after collapse")
	snapshot.state = "alligator_surface_warning"
	snapshot.position = Vector2(200, 570)
	snapshot.landing = Vector2(700, 440)
	assert(art.warning_bounds(snapshot)[0].get_center().x == 700)
	snapshot.state = "alligator_water_warning"
	snapshot.column_x = 400.0
	var warning: Rect2 = art.warning_bounds(snapshot)[0]
	assert(warning.get_center().x == 400 and warning.end.y == 440 and warning.position.y < 440)
	snapshot.state = "alligator_debris"
	assert(art.warning_bounds(snapshot)[0] == warning, "Committed debris lane remains marked")
	var canvas := ArtCanvas.new()
	canvas.art = art
	root.add_child(canvas)
	var states: Array = Encounter.DURATIONS.keys()
	states.append_array(["alligator_swim", "alligator_surface_swim", "alligator_charge", "alligator_debris"])
	for state: String in states:
		snapshot.state = state
		snapshot.elapsed = .2
		snapshot.port_position = Vector2(250, 166)
		snapshot.landing = Vector2(480, 440)
		snapshot.hazards = [{"id":1, "position":Vector2(500, 250)}]
		canvas.snapshot = snapshot.duplicate(true)
		canvas.queue_redraw()
		await process_frame
		await process_frame
	canvas.queue_free()
	print("PASS: Skitterling authored preparation, cached alpha-clipped churn, mirrored bounds, false death and draw states")
	quit()
