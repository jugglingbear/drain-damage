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
	assert(art.roach_body.meshes.size() == 4, "Body uses four bounded batched draws")
	assert(art.roach_body.insect_textures.size() == 4)
	for insect: Image in art.roach_body.insect_images:
		assert(insect.get_width() > 200, "Use full-resolution insect source, never magnify reduced runtime crops")
	var fitted := 0
	for shape: Dictionary in art.roach_body.targets["rat-source-v2:1"].shapes:
		assert(shape.mobility <= 1.5)
		if shape.size.y < 14: fitted += 1
	assert(fitted > 20, "Thin anatomy must use smaller fitted insects")
	for key: String in art.roach_body.targets:
		assert(art.roach_body.targets[key].points.size() == Art.RoachBody.COUNT)
		for point: Vector2 in art.roach_body.targets[key].points:
			assert(art.frames[key].image.get_pixelv(Vector2i(point)).a > .5)
	var moved := 0
	for index in range(Art.RoachBody.COUNT):
		var point: Vector2 = art.roach_body.insect_position("rat-source-v2:1", "rat-source-v2:1", 0, index, 1.0)
		var next: Vector2 = art.roach_body.insect_position("rat-source-v2:1", "rat-source-v2:1", 0, index, 1.0 + 1.0 / 60)
		assert(point.distance_to(next) < .5, "Roaches must move continuously between rendered frames")
		if point.distance_to(next) > .001: moved += 1
	assert(moved > 125, "Nearly every insect must move independently")
	# Source-body textures are retained for provenance only; no baked surface variants remain.
	for key: String in art.frames:
		assert(art.frames[key].textures.size() == 1)
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
	assert(left.size == right.size and left.end.y <= 465)
	snapshot.rat_contact_active = true
	var started := Time.get_ticks_usec()
	var contacts: Array[Rect2] = art.visible_contact_regions(snapshot, Vector2.ZERO, 2.0)
	assert(not contacts.is_empty(), "Formed rat must have visible insect contact")
	for repeat in range(30):
		assert(contacts == art.visible_contact_regions(snapshot, Vector2.ZERO, 2.0))
	print("Rat contact query average ms: ", (Time.get_ticks_usec() - started) / 31000.0)
	var shifted: Array[Rect2] = art.visible_contact_regions(snapshot, Vector2(100, 80), 2.0)
	assert(shifted.size() == contacts.size())
	for i in range(contacts.size()):
		assert(contacts[i].position.is_equal_approx(shifted[i].position - Vector2(100, 80)))
		assert(contacts[i].size == Vector2(2, 2), "Contact samples individual insect cores")
	for crouch_state in ["rat_rush_tell", "rat_rush", "rat_rush_recovery"]:
		snapshot.state = crouch_state
		var scale: float = art.rush_scale(snapshot)
		var selected: Dictionary = art._selection(snapshot)
		assert(selected.key == "rat-attacks-source-v1:3")
		var bounds := Rect2()
		for index in range(Art.RoachBody.COUNT):
			var p: Vector2 = (art.roach_body.insect_position(selected.key, selected.key, 0, index, 2.0) - Art.ANCHOR) * scale
			var shape: Dictionary = art.roach_body.insect_shape(selected.key, selected.key, 0, index, 2.0)
			var radius: float = Vector2(shape.size).length() * .5 * scale
			assert(p.y - radius >= -50.001, "All rotated sprite pixels must fit below jump clearance")
			var insect := Rect2(p - Vector2.ONE * radius, Vector2.ONE * radius * 2)
			bounds = insect if index == 0 else bounds.merge(insect)
		print(crouch_state, " scale=", scale, " conservative bounds=", bounds)
		assert(bounds.size.x <= 260)
		assert(not art.visible_contact_regions(snapshot, Vector2.ZERO, 2.0).is_empty())
	snapshot.rat_contact_active = false
	assert(art.visible_contact_regions(snapshot).is_empty())
	snapshot.state = "rat_collapse"
	snapshot.elapsed = .5
	assert(art.state_is_still(snapshot))
	assert(Encounter.DURATIONS.rat_collapse > Art.COLLAPSE_SECONDS)
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
	snapshot.volley_targets = [150.0, 300.0, 450.0, 600.0, 750.0]
	var marks: Array[Rect2] = art.warning_bounds(snapshot)
	assert(marks.size() == 5 and marks[4].get_center().x == 750)
	snapshot.volley_targets.append(825.0)
	marks = art.warning_bounds(snapshot)
	assert(marks.size() == 6 and marks[5].get_center().x == 825, "Aimed marker appears only after release")
	snapshot.volley_targets = []
	# Pipe draws and target queries share deterministic snapshot-driven motion.
	snapshot.state = "rat_pipe_retreat"
	snapshot.position = Vector2(480, 400)
	snapshot.elapsed = .1
	var regions: Array[Rect2] = art.visible_target_regions(snapshot)
	assert(not regions.is_empty(), "Visible retreat insects remain targetable")
	assert(regions == art.visible_target_regions(snapshot), "Query must not depend on draw history")
	var translated: Array[Rect2] = art.visible_target_regions(snapshot, Vector2(100, 80))
	assert(regions.size() == translated.size())
	for index in range(regions.size()):
		assert(regions[index].position.is_equal_approx(translated[index].position - Vector2(100, 80)))
	snapshot.elapsed = .7
	assert(art.visible_target_regions(snapshot).is_empty(), "Consumed swarm cannot be shot behind pipe")
	snapshot.state = "rat_pipe_launch"
	snapshot.elapsed = .15
	snapshot.port = 0
	snapshot.port_position = Vector2(250, 166)
	var pipe: Dictionary = art.pipe_parameters(snapshot)
	assert(pipe.mouth.y == 181, "Art mouth uses actual authored aperture, not logical launch coordinate")
	for index in range(Art.RoachBody.COUNT):
		var point := Vector2(index, 300)
		var sample: Dictionary = Art.RoachBody.pipe_sample(index, point, pipe)
		assert(sample.visible and sample.position == point and sample.scale == 1.0)
	var rim: Image = art.ceiling_rim.get_image()
	assert(rim.get_pixel(187, 396).a == 0, "Warning insects must show through the pipe aperture")
	assert(rim.get_pixel(187, 450).a > .5, "Authored bottom lip must cover the warning cloud")
	for attack: Dictionary in [
		{"key":"rat-attacks-source-v1:2", "area":Rect2(64,176,72,48)},
		{"key":"rat-attacks-source-v1:3", "area":Rect2(64,180,64,44)},
		{"key":"tail-sweep-source-v1:2", "area":Rect2(216,184,120,40)}]:
		var populated := 0
		for index in range(Art.RoachBody.COUNT):
			var point: Vector2 = art.roach_body.insect_position(attack.key, attack.key, 0, index, 0)
			if attack.area.has_point(point): populated += 1
		assert(populated >= 3, "Active attack area must contain authored insect anatomy: " + str(attack.key))
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
	print("PASS: Skitterling authored preparation, 140 larger constituent insects, continuous motion, mirrored bounds, false death and draw states")
	quit()
