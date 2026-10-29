extends RefCounted
## Textured geometry for the isolated camera proof; all dimensions come from the model.

static func mesh(parent: Node3D, points: PackedVector3Array, uvs: PackedVector2Array,
		material: Material) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in points.size():
		tool.set_uv(uvs[index])
		tool.add_vertex(points[index])
	tool.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = tool.commit()
	instance.material_override = material
	parent.add_child(instance)
	return instance

static func append_quad(points: PackedVector3Array, mapped: PackedVector2Array,
		corners: Array[Vector3], uvs: Array[Vector2]) -> void:
	for index in [0,2,1,0,3,2]:
		points.append(corners[index])
		mapped.append(uvs[index])

static func quad(parent: Node3D, corners: Array[Vector3], material: Material,
		uvs: Array[Vector2] = []) -> MeshInstance3D:
	if uvs.is_empty(): uvs = [Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)]
	var points := PackedVector3Array()
	var mapped := PackedVector2Array()
	append_quad(points,mapped,corners,uvs)
	return mesh(parent,points,mapped,material)

static func floor_patch(parent: Node3D, bounds: Rect2, height: float, material: Material,
		world_uv := false) -> void:
	var a := bounds.position
	var b := bounds.end
	var corners: Array[Vector3] = [Vector3(a.x,height,a.y),Vector3(b.x,height,a.y),
		Vector3(b.x,height,b.y),Vector3(a.x,height,b.y)]
	var uvs: Array[Vector2] = []
	if world_uv:
		for p in corners: uvs.append(Vector2(p.x,p.z)/4.0)
	quad(parent,corners,material,uvs)

static func slab(parent: Node3D, bounds: Rect2, top: float, thickness: float,
		top_material: Material, side_material: Material) -> void:
	floor_patch(parent,bounds,top,top_material)
	var a := bounds.position
	var b := bounds.end
	var rim: Array[Vector3] = [Vector3(a.x,top,a.y),Vector3(b.x,top,a.y),
		Vector3(b.x,top,b.y),Vector3(a.x,top,b.y)]
	for index in 4:
		var p := rim[index]
		var q := rim[(index+1)%4]
		quad(parent,[p,q,q-Vector3.UP*thickness,p-Vector3.UP*thickness],side_material)

static func ellipse(parent: Node3D, center: Vector2, radii: Vector2, top: float,
		bottom: float, top_material: Material, side_material: Material, cap := true) -> void:
	var points := PackedVector3Array()
	var uvs := PackedVector2Array()
	var walls := PackedVector3Array()
	var wall_uvs := PackedVector2Array()
	for index in 96:
		var a := Vector2.from_angle(TAU*index/96.0)
		var b := Vector2.from_angle(TAU*(index+1)/96.0)
		var p := Vector3(center.x+a.x*radii.x,top,center.y+a.y*radii.y)
		var q := Vector3(center.x+b.x*radii.x,top,center.y+b.y*radii.y)
		if cap:
			points.append_array([Vector3(center.x,top,center.y),q,p])
			uvs.append_array([Vector2(.5,.5),(b+Vector2.ONE)/2,(a+Vector2.ONE)/2])
		append_quad(walls,wall_uvs,[p,q,Vector3(q.x,bottom,q.z),Vector3(p.x,bottom,p.z)],
			[Vector2(index/96.0,0),Vector2((index+1)/96.0,0),Vector2((index+1)/96.0,1),Vector2(index/96.0,1)])
	mesh(parent,walls,wall_uvs,side_material)
	if cap: mesh(parent,points,uvs,top_material)

static func water_track(parent: Node3D, hole: Vector2, radius: float, material: Material) -> void:
	floor_patch(parent,Rect2(0,-2,hole.x-radius,4),0,material,true)
	floor_patch(parent,Rect2(hole.x+radius,-2,24-hole.x-radius,4),0,material,true)
	floor_patch(parent,Rect2(hole.x-radius,-2,radius*2,hole.y-radius+2),0,material,true)
	floor_patch(parent,Rect2(hole.x-radius,hole.y+radius,radius*2,2-hole.y-radius),0,material,true)
	# Fill the square's corners up to the circular opening, not a rectangular cutout.
	var points := PackedVector3Array()
	var mapped := PackedVector2Array()
	for index in 96:
		var a := Vector2.from_angle(TAU*index/96.0)
		var b := Vector2.from_angle(TAU*(index+1)/96.0)
		var corners: Array[Vector3] = []
		var uvs: Array[Vector2] = []
		for p in [hole+a*radius,hole+b*radius,hole+b*radius/maxf(absf(b.x),absf(b.y)),
				hole+a*radius/maxf(absf(a.x),absf(a.y))]:
			corners.append(Vector3(p.x,0,p.y))
			uvs.append(p/4.0)
		append_quad(points,mapped,corners,uvs)
	mesh(parent,points,mapped,material)

static func ramp(parent: Node3D, bounds: Rect2, rise: float, top: Material, side: Material) -> void:
	var a := bounds.position
	var b := bounds.end
	quad(parent,[Vector3(a.x,0,a.y),Vector3(b.x,rise,a.y),Vector3(b.x,rise,b.y),Vector3(a.x,0,b.y)],top)
	for z in [a.y,b.y]:
		quad(parent,[Vector3(a.x,0,z),Vector3(b.x,rise,z),Vector3(b.x,0,z),Vector3(a.x,0,z)],side)
	quad(parent,[Vector3(b.x,rise,a.y),Vector3(b.x,rise,b.y),Vector3(b.x,0,b.y),Vector3(b.x,0,a.y)],side)

static func inflow_ring(parent: Node3D, center: Vector2, radius: float, material: Material) -> void:
	var vertices := PackedVector3Array()
	var mapped := PackedVector2Array()
	for index in 96:
		var a := Vector2.from_angle(TAU*index/96.0)
		var b := Vector2.from_angle(TAU*(index+1)/96.0)
		var points: Array[Vector3] = []
		for p in [center+a*(radius+.22),center+b*(radius+.22),center+b*radius,center+a*radius]:
			points.append(Vector3(p.x,.002,p.y))
		append_quad(vertices,mapped,points,[Vector2(index/24.0,0),Vector2((index+1)/24.0,0),
			Vector2((index+1)/24.0,1),Vector2(index/24.0,1)])
	mesh(parent,vertices,mapped,material)
