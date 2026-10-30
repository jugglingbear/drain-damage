extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Batches = preload("res://scripts/ride_static_batches.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960,540)
	root.position = Vector2i(80,80)
	call_deferred("checks")

func mesh_count(node: Node) -> int:
	var count := 1 if node is MeshInstance3D or node is MultiMeshInstance3D else 0
	for child in node.get_children(): count += mesh_count(child)
	return count

var record_details: Dictionary = {}
var normal_records: Dictionary = {}

func record(mesh: Mesh, pose: Transform3D, state: Variant, shadow: int, layers: int) -> int:
	var detail := [hash(mesh.surface_get_arrays(0)),stable_pose(pose),hash(state),shadow,layers]
	var key := hash(detail)
	record_details[key] = detail
	return key

func stable_pose(pose: Transform3D) -> Array:
	# MultiMesh stores transforms as32-bit instance buffers; allow only subpixel storage rounding.
	return [pose.origin.snapped(Vector3.ONE*.0001),pose.basis.x.snapped(Vector3.ONE*.0001),
		pose.basis.y.snapped(Vector3.ONE*.0001),pose.basis.z.snapped(Vector3.ONE*.0001)]

func geometry_records(node: Node3D, transform := Transform3D.IDENTITY) -> Array:
	var records: Array = []
	var at := transform*node.transform
	if node is MeshInstance3D:
		var material = node.material_override
		var state = Batches.material_state(material) if material != null else null
		if node.mesh is ArrayMesh:
			var arrays: Array = node.mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if indices.is_empty():
				for index in vertices.size(): indices.append(index)
			for triangle in range(0,indices.size(),3):
				var corners := []
				var normals: Array[Vector3] = []
				for corner in range(3):
					var vertex := indices[triangle+corner]
					var normal: Vector3 = arrays[Mesh.ARRAY_NORMAL][vertex]
					var uv: Vector2 = arrays[Mesh.ARRAY_TEX_UV][vertex]
					corners.append([vertices[vertex],uv])
					normals.append(normal)
				var detail := [corners,stable_pose(at),hash(state),node.cast_shadow,node.layers]
				var key := hash(detail)
				record_details[key] = detail
				normal_records[key] = normals
				records.append(key)
		else:
			records.append(record(node.mesh,at,state,node.cast_shadow,node.layers))
	elif node is MultiMeshInstance3D:
		var state = Batches.material_state(node.material_override)
		for index in node.multimesh.instance_count:
			var pose: Transform3D = node.get_meta("source_transforms")[index] if DisplayServer.get_name() == "headless" else node.multimesh.get_instance_transform(index)
			records.append(record(node.multimesh.mesh,at*pose,state,node.cast_shadow,node.layers))
	for child in node.get_children():
		if child is Node3D: records.append_array(geometry_records(child,at))
	return records

func checks() -> void:
	var game := Game.new()
	var initializing := Time.get_ticks_usec()
	root.add_child(game)
	print("GAME_INITIALIZE_US ",Time.get_ticks_usec()-initializing)
	game.set_process(false)
	game.set_physics_process(false)
	Launch.initialize(game,Launch.parse(["--level=2-landing"]).target)
	var view = game.flush.world_view
	view.set_process(false)
	var start := Time.get_ticks_usec()
	view._process(0)
	print("CONFIGURE_US ",Time.get_ticks_usec()-start," POOL_PREPARE_US ",view.preparation_usec,
		" POOL_BUILDS ",view.actor_build_count," MESH_SAVINGS ",view.pooled_mesh_savings)
	var prepared: int = view.actor_build_count
	# Batch equivalence includes original vertices/normals/UVs, per-instance transforms and material state.
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride-showcase.json"))
	for index in [1,3,5,6,9,10,11]:
		var obstacle: Dictionary = source.encounters[index].obstacles[0]
		var raw := Node3D.new()
		view.add_child(raw)
		view.build_actor(raw,obstacle)
		var expected := geometry_records(raw)
		var expected_normals := normal_records.duplicate(true)
		var cached: Node3D = view.actor_pool[view.actor_signature(obstacle)][0]
		var actual := geometry_records(cached)
		expected.sort()
		actual.sort()
		if expected != actual:
			for key in expected:
				if not actual.has(key):
					print("EXPECTED ",record_details.get(key,"array triangle"))
					break
			for key in actual:
				if not expected.has(key):
					print("ACTUAL ",record_details.get(key,"array triangle"))
					break
			push_error("Instancing equivalence mismatch index%s counts%s/%s" % [index,expected.size(),actual.size()])
			game.free()
			quit(1)
			return
		for key in expected:
			if not expected_normals.has(key): continue
			for corner in 3:
				assert(expected_normals[key][corner].distance_to(normal_records[key][corner]) < .0002,
					"Normal compression may only introduce tiny floating-point rounding")
		raw.free()
	for index in range(13):
		game.flush.enter_ride(game,index)
		start = Time.get_ticks_usec()
		view.update_world()
		var cold := Time.get_ticks_usec()-start
		assert(view.actor_build_count == prepared,"Authored transition cannot build actors")
		var count := 0
		for actor in view.actors.values(): count += mesh_count(actor)
		start = Time.get_ticks_usec()
		view.update_world()
		print("ACTOR_PROFILE ",JSON.stringify({"encounter":index+1,"first_us":cold,"warm_us":Time.get_ticks_usec()-start,"meshes":count}))
	var previous: Node3D = view.actors.values()[0]
	game.flush.enter_ride(game,0)
	view.update_world()
	assert(is_instance_valid(previous) and not previous.visible,"Retired actor stays pooled but hidden")
	for index in range(13):
		game.flush.enter_ride(game,index)
		view.update_world()
	assert(view.actor_build_count == prepared,"Retries reuse authored actor pool")
	game.free()
	print("PASS: no authored transition/retry builds, exact batch geometry/materials and hidden pool retirement")
	quit()
