extends RefCounted
## Instance identical static primitives without baking transforms, UVs, normals or materials.
const ANIMATED_NAMES := ["arm","pivot","rail"]

static func material_state(material: Material) -> Dictionary:
	var state := {}
	for property in material.get_property_list():
		if int(property.usage)&PROPERTY_USAGE_STORAGE == 0: continue
		var key := str(property.name)
		if key in ["resource_name","resource_path","resource_local_to_scene"]: continue
		state[key] = material.get(key)
	return state

static func compact(parent: Node3D) -> int:
	var removed := 0
	for child in parent.get_children():
		if child is Node3D and not child is MeshInstance3D: removed += compact(child)
	var groups := {}
	for child in parent.get_children():
		if not child is MeshInstance3D or not child.mesh is PrimitiveMesh: continue
		if child.name in ANIMATED_NAMES or child.get_child_count() > 0 or child.get_script() != null: continue
		if not child.material_override is StandardMaterial3D or child.material_overlay != null: continue
		var definition := [child.mesh.get_class(),child.mesh.surface_get_arrays(0),material_state(child.material_override),
			child.cast_shadow,child.layers,child.visible,child.gi_mode]
		var key := hash(definition)
		if groups.has(key) and groups[key].definition != definition: continue
		if not groups.has(key): groups[key] = {"definition":definition,"nodes":[]}
		groups[key].nodes.append(child)
	for group in groups.values():
		var nodes: Array = group.nodes
		if nodes.size() < 3: continue
		var first: MeshInstance3D = nodes[0]
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = first.mesh
		instances.instance_count = nodes.size()
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = instances
		batch.material_override = first.material_override
		batch.cast_shadow = first.cast_shadow
		batch.layers = first.layers
		batch.visible = first.visible
		batch.gi_mode = first.gi_mode
		var transforms: Array[Transform3D] = []
		for index in nodes.size():
			transforms.append(nodes[index].transform)
			instances.set_instance_transform(index,nodes[index].transform)
		# The headless dummy renderer cannot read MultiMesh buffers back; retain exact upload inputs.
		batch.set_meta("source_transforms",transforms)
		parent.add_child(batch)
		for node in nodes:
			parent.remove_child(node)
			node.free()
		removed += nodes.size()-1
	return removed+merge_identity_arrays(parent)

static func merge_identity_arrays(parent: Node3D) -> int:
	# Geometry quads already share their parent's coordinate system. Concatenate only identity
	# transforms and the same material/vertex format, preserving local-space shader coordinates.
	var groups := {}
	for child in parent.get_children():
		if not child is MeshInstance3D or not child.mesh is ArrayMesh: continue
		if child.name in ANIMATED_NAMES or child.get_child_count() > 0 or child.get_script() != null: continue
		if child.transform != Transform3D.IDENTITY or child.material_overlay != null: continue
		if child.mesh.get_surface_count() != 1 or child.mesh.surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES: continue
		var definition := [child.material_override,child.mesh.surface_get_format(0),child.cast_shadow,child.layers,child.visible,child.gi_mode]
		var key := hash(definition)
		if groups.has(key) and groups[key].definition != definition: continue
		if not groups.has(key): groups[key] = {"definition":definition,"nodes":[]}
		groups[key].nodes.append(child)
	var removed := 0
	for group in groups.values():
		var nodes: Array = group.nodes
		if nodes.size() < 3: continue
		var first: MeshInstance3D = nodes[0]
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for node in nodes: tool.append_from(node.mesh,0,Transform3D.IDENTITY)
		var batch := MeshInstance3D.new()
		batch.mesh = tool.commit()
		batch.material_override = first.material_override
		batch.cast_shadow = first.cast_shadow
		batch.layers = first.layers
		batch.visible = first.visible
		batch.gi_mode = first.gi_mode
		parent.add_child(batch)
		for node in nodes:
			parent.remove_child(node)
			node.free()
		removed += nodes.size()-1
	return removed
