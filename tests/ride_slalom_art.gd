extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func planes(frame: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if bool(frame.get("collision_plane",false)): result.append(frame)
	for layer: Dictionary in frame.get("layers",[]): result.append_array(planes(layer))
	return result

func checks() -> void:
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	game.flush.enter_ride(game,0)
	var ride = game.flush.ride
	var ids: Dictionary = {}
	var banks: Dictionary = {}
	var samples := 0
	for obstacle: Dictionary in ride.course.obstacles:
		var id: String = ride.obstacle_frame_id(obstacle)
		ids[id] = true
		var frame: Dictionary = ride.obstacle_art.manifest.frames[id]
		var surfaces := planes(frame)
		assert(surfaces.size() == 1,"Each slalom collider needs one authored water-plane surface")
		var plane: Dictionary = surfaces[0]
		var d: Array = plane.destination
		var rect := Rect2(d[0],d[1],d[2],d[3])
		assert(rect.is_equal_approx(Rect2(-obstacle.width*0.5,-obstacle.depth*0.5,obstacle.width,obstacle.depth)),
			"Visible water-plane registration must equal collider, not an upright pedestal face")
		var texture: Texture2D = ride.obstacle_art.textures[plane.path]
		var pixels := texture.get_image()
		if pixels.is_compressed(): assert(pixels.decompress() == OK)
		var region: Array = plane.source_rect
		# Sample the interior and bank seams; transparent padding cannot stand in for a solid barrier.
		var opaque := 0
		var total := 0
		for row in range(1,20):
			for column in range(1,20):
				var pixel := Vector2i(int(region[0]+region[2]*column/20.0),int(region[1]+region[3]*row/20.0))
				if pixels.get_pixelv(pixel).a > 0.9: opaque += 1
				total += 1
		assert(float(opaque)/total >= 0.95,"Collision plane must be visibly occupied")
		samples += total
		var world := rect
		world.position += Vector2(obstacle.x,obstacle.y)
		if is_equal_approx(world.position.y,230): banks.far = true
		elif is_equal_approx(world.end.y,430): banks.near = true
		else:
			assert(world.position.y > 230 and world.end.y < 430)
			banks.center = true
		if is_equal_approx(world.position.y,230) or is_equal_approx(world.end.y,430):
			var edge := 0.005 if is_equal_approx(world.position.y,230) else 0.995
			for column in range(1,20):
				var pixel := Vector2i(int(region[0]+region[2]*column/20.0),int(region[1]+region[3]*edge))
				assert(pixels.get_pixelv(pixel).a > 0.9,"Wall seam cannot be transparent")
	assert(ids.size() == 3 and banks.size() == 3,"Distinct far, near and center structures are required")
	game.queue_free()
	await process_frame
	print("PASS: three distinct slalom surfaces match colliders/bank seams; ",samples," imported-texture opacity samples")
	quit()
