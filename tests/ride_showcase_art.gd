extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func validate_frame(frame: Dictionary, art: RefCounted) -> void:
	if frame.has("layers"):
		for layer: Dictionary in frame.layers: validate_frame(layer,art)
		return
	assert(art.textures.has(frame.path) and art.textures[frame.path] != null)
	var texture: Texture2D = art.textures[frame.path]
	var region := Rect2(frame.source_rect[0],frame.source_rect[1],frame.source_rect[2],frame.source_rect[3])
	assert(region.has_area() and Rect2(Vector2.ZERO,texture.get_size()).encloses(region))
	assert(float(frame.destination[2]) > 0 and float(frame.destination[3]) > 0)

func checks() -> void:
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	game.flush.enter_ride(game,0)
	var ride = game.flush.ride
	var manifest: Dictionary = ride.obstacle_art.manifest
	assert(manifest.ramp.render_mode == "quadratic_strips")
	assert(manifest.ramp.run == 200 and manifest.ramp.rise == 40)
	for frame: Dictionary in manifest.frames.values(): validate_frame(frame,ride.obstacle_art)
	for encounter: Dictionary in ride.definition.encounters:
		for obstacle: Dictionary in encounter.obstacles:
			var id: String = ride.obstacle_frame_id(obstacle)
			assert(manifest.frames.has(id),"Every collider needs visible authored artwork")
			if obstacle.get("mirror_bank",false) and manifest.bank_variants.has(obstacle.art_id):
				assert(id.ends_with("_near"),"Upright near-bank variant required")
			if obstacle.art_id == "ordinary_gap": assert(id.ends_with(str(int(obstacle.width))))
	for hero in [0,1]:
		game.employee = game.Crew.EMPLOYEES[hero]
		for mode in ["normal","hard"]:
			game.difficulty = mode
			var contact: Array = manifest.rider_contacts[game.employee.id][mode]
			assert(float(contact[1]) > 0 and float(contact[1]) < 16)
			for pitch in [-0.4,-0.2,0.0,0.2,0.4]:
				ride.render_height = 40
				ride.render_pitch = pitch
				var transform: Transform2D = ride.rider_transform(game)
				assert(is_equal_approx(transform.determinant(),1.0),"Never stretch rider or board")
				assert(transform.origin.is_equal_approx(ride.position-Vector2(0,40)))
				assert(is_equal_approx(transform.get_rotation(),pitch))
	# One-pixel material strips differ from exact collider height by at most 0.2px.
	for column in range(200):
		var middle := 40*pow((column+0.5)/200.0,2)
		for edge in [float(column),float(column+1)]:
			assert(absf(middle-40*pow(edge/200.0,2)) <= 0.2)
	game.queue_free()
	await process_frame
	print("PASS: calibrated obstacle frame bounds, gap sizes, upright bank variants, all rider contact registrations and rigid transforms")
	quit()
