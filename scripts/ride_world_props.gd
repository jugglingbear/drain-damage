extends RefCounted
## Constructs Art's ride-depth-v1 recipes; simulation dimensions remain authoritative.

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, material: Material, id := "") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	var surface := material.duplicate()
	if surface is StandardMaterial3D:
		surface.uv1_triplanar = true
		surface.uv1_world_triplanar = false
		surface.uv1_scale = Vector3.ONE*(256.0/619.0)
	node.material_override = surface
	node.position = at
	if not id.is_empty(): node.name = id
	parent.add_child(node)
	return node

static func box(parent: Node3D, size: Vector3, at: Vector3, mat: Material, id := "") -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent,shape,at,mat,id)

static func cylinder(parent: Node3D, radius: float, height: float, at: Vector3, mat: Material,
		top := -1.0, id := "") -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0 else top
	shape.height = height
	shape.radial_segments = 24
	return mesh(parent,shape,at,mat,id)

static func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material, id := "") -> MeshInstance3D:
	var node := cylinder(parent,radius,1,(a+b)*.5,mat,-1,id)
	align_rod(node,a,b)
	return node

static func align_rod(node: Node3D, a: Vector3, b: Vector3) -> void:
	var delta := b-a
	node.position = (a+b)*.5
	node.quaternion = Quaternion(Vector3.UP,delta.normalized()) if delta.length() > .001 else Quaternion.IDENTITY
	node.scale = Vector3(1,maxf(.001,delta.length()),1)

static func ring(parent: Node3D, radius: float, wire: float, at: Vector3, mat: Material) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius-wire
	shape.outer_radius = radius+wire
	shape.rings = 24
	shape.ring_segments = 8
	return mesh(parent,shape,at,mat)

static func chain(parent: Node3D, a: Vector3, b: Vector3, mat: Material, radius := .045) -> void:
	var count := maxi(2,int(a.distance_to(b)/(radius*1.45)))
	for i in count:
		var link := ring(parent,radius,radius*.25,a.lerp(b,float(i)/(count-1)),mat)
		link.rotation = Vector3(PI*.5,PI*.5*(i%2),0)

static func build(parent: Node3D, o: Dictionary, m: Dictionary, bank_scale := 1.0) -> void:
	var w := float(o.width)/100
	var d := float(o.depth)/100*bank_scale
	var id := str(o.art_id)
	var structural: Material = m.get("support_iron",m.cast_iron)
	if id.begins_with("valve_"):
		box(parent,Vector3(w,1.8,d),Vector3(0,.1,0),structural)
		# Recessed gate face and load-bearing frame retain the original baffle envelope.
		box(parent,Vector3(w-.18,.72,.035),Vector3(0,.53,d*.5+.018),m.cast_iron)
		for x in [-w*.5+.06,w*.5-.06]:
			box(parent,Vector3(.12,.94,.06),Vector3(x,.53,d*.5+.02),structural)
		for y in [.12,.94]:
			box(parent,Vector3(w,.12,.06),Vector3(0,y,d*.5+.02),structural)
		for x in [-w*.5+.06,w*.5-.06]:
			for y in [.18,.88]:
				var bolt := cylinder(parent,.035,.035,Vector3(x,y,d*.5+.065),m.copper)
				bolt.rotation.x = PI*.5
				bolt.mesh.radial_segments = 6
		var bearing := cylinder(parent,.13,.11,Vector3(0,.75,d*.5+.05),structural)
		bearing.rotation.x = PI*.5
		rod(parent,Vector3(0,.75,d*.5),Vector3(0,.75,d*.5+.16),.065,m.copper)
		var wheel := ring(parent,.24,.035,Vector3(0,.75,d*.5+.16),m.copper)
		wheel.rotation.x = PI*.5
		for i in 4:
			var tip := Vector3(cos(i*PI*.5)*.24,.75+sin(i*PI*.5)*.24,d*.5+.16)
			rod(parent,Vector3(0,.75,d*.5+.16),tip,.018,m.copper)
	elif id == "elbow_pipe_v2":
		box(parent,Vector3(w,.85,d),Vector3(0,-.375,0),structural)
		var points: Array[Vector3] = [Vector3(-w*.5+.35,-.6,0),Vector3(-w*.5+.35,.3,0)]
		# A continuous quarter bend has no intersecting capped cylinders at its elbow.
		for i in range(1,13):
			var angle := PI-float(i)/12*PI*.5
			points.append(Vector3(-w*.5+.8+cos(angle)*.45,.3+sin(angle)*.45,0))
		points.append(Vector3(w*.5-.35,.75,0))
		tube(parent,points,.35,.29,m.copper,structural)
		var outlet := ring(parent,.32,.03,points[-1],m.copper)
		outlet.rotation.z = PI*.5
		# A second recessed ring separates the lit lip from the hollow throat.
		var throat := ring(parent,.29,.012,points[-1]-Vector3(.10,0,0),structural)
		throat.rotation.z = PI*.5
	elif id == "chain_plug":
		box(parent,Vector3(.4,.12,.4),Vector3(0,2.4,0),m.cast_iron)
		chain(parent,Vector3(0,2.34,0),Vector3(0,1.04,0),m.copper)
		var rubber := ShaderMaterial.new()
		var rubber_shader := Shader.new()
		rubber_shader.code = """shader_type spatial;
uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
void fragment() {
	vec3 source = texture(surface_texture, UV).rgb;
	float grain = dot(source, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = vec3(0.055, 0.052, 0.048) + vec3(clamp(grain, 0.0, 1.0) * 0.045);
	ROUGHNESS = 0.82;
	SPECULAR = 0.25;
}
"""
		rubber.shader = rubber_shader
		rubber.set_shader_parameter("surface_texture",m.rubber.albedo_texture)
		var plug := cylinder(parent,.5,.4,Vector3(0,.84,0),rubber,.41)
		plug.scale = Vector3(w,1,d)
		cylinder(parent,.12,.025,Vector3(0,1.04,0),structural)
		var eye := ring(parent,.065,.018,Vector3(0,1.04,0),m.copper)
		eye.rotation.x = PI*.5
	elif id.begins_with("brush_"):
		var black_bristles := m.bristles.duplicate() as StandardMaterial3D
		black_bristles.albedo_color = Color(.025,.025,.028)
		black_bristles.roughness = .42
		cylinder(parent,.06,1.6,Vector3(0,1.6,0),m.copper)
		box(parent,Vector3(w*.88,.16,d*.88),Vector3(0,.8,0),m.cast_iron)
		for x in [-w*.44,w*.44]:
			box(parent,Vector3(.035,.08,d*.9),Vector3(x,.73,0),m.copper)
		var rows := maxi(12,int(ceil(d/.085)))
		for x in 22:
			for z in rows:
				# Deterministic stagger and splay break the comb pattern without changing clearance.
				var seed_value := x*37+z*19
				var px := (float(x)/21-.5)*(w-.12)+sin(seed_value)*.012
				var pz := (float(z)/(rows-1)-.5)*(d-.12)+cos(seed_value)*.012
				var tip_y := .16+float(seed_value%5)*.009
				var root := Vector3(px,.73,pz)
				var tip := Vector3(px+sin(seed_value*.7)*.025,tip_y,pz+cos(seed_value*.7)*.025)
				var bundle := cylinder(parent,0,1,Vector3.ZERO,black_bristles,.027)
				bundle.mesh.radial_segments = 5
				align_rod(bundle,tip,root)
	elif id == "loose_flange":
		# Paired channel-joint plates clamp a dark gasket. Their bolt axes cross
		# the mating seam, unlike the former upward-facing rail fasteners.
		box(parent,Vector3(w*.12,.94,d),Vector3(0,-.31,0),structural)
		for side in [-1,1]:
			box(parent,Vector3(w*.30,.98,d),Vector3(side*w*.22,-.31,0),m.cast_iron)
		var bolts := maxi(4,int(d/.34))
		for i in bolts:
			var z := (float(i)/(bolts-1)-.5)*(d-.16)
			for side in [-1,1]:
				var washer := cylinder(parent,.055,w*.05,Vector3(side*w*.39,.095,z),m.copper)
				washer.rotation.z = PI*.5
				var bolt := cylinder(parent,.038,w*.12,Vector3(side*w*.44,.095,z),structural)
				bolt.rotation.z = PI*.5
				bolt.mesh.radial_segments = 6
	elif id == "float_ball":
		var shape := SphereMesh.new()
		shape.radius = .5
		shape.height = 1
		var ball := mesh(parent,shape,Vector3(0,-.05,0),m.copper)
		ball.scale = Vector3(w,1,d)
		var bank := (float(o.y)-330)/100*bank_scale
		var pivot := Vector3(0,.55,-bank_scale-bank)
		var mount := cylinder(parent,.11,.12,pivot,m.cast_iron,-1,"pivot")
		mount.rotation.x = PI*.5
		rod(parent,pivot,Vector3(0,-.05,0),.028,m.copper,"arm")
	elif id == "spiked_grate":
		box(parent,Vector3(w,.8,d),Vector3(0,-.4,0),m.cast_iron)
		var worn_edge := StandardMaterial3D.new()
		worn_edge.albedo_color = Color(.65,.68,.67)
		worn_edge.metallic = .25
		worn_edge.roughness = .4
		# Torn grate ribs share the frame's metal, rather than reading as orange traffic cones.
		for x in [-w*.5+.035,w*.5-.035]:
			box(parent,Vector3(.07,.06,d),Vector3(x,.03,0),m.cast_iron)
		for z in range(int(d/.12)+1):
			box(parent,Vector3(w,.04,.025),Vector3(0,.02,-d*.5+z*.12),m.cast_iron)
		for row in 9:
			var z := (float(row)/8-.5)*(d-.16)
			var lean := .045 if row%2 == 0 else -.045
			var height := .28 if row%3 == 0 else .22+.02*(row%3)
			for side in [-1,1]:
				var x: float = side*w*.22
				rod(parent,Vector3(side*(w*.5-.07),.045,z),
					Vector3(x,.10,z),.025,m.cast_iron)
				torn_grate_tooth(parent,Vector3(x,.04,z),.13,height,lean*side,m.cast_iron)
				for edge in [-1,1]:
					rod(parent,Vector3(x+edge*.06,.06,z),
						Vector3(x+lean*side,.04+height-.014,z),.012,worn_edge)

static func torn_grate_tooth(parent: Node3D, at: Vector3, width: float, height: float,
		lean: float, material: Material) -> void:
	# Extruded triangular sheet metal: a broad broken rib with a sharp edge, not a round spike.
	var vertices := [Vector3(-width*.5,0,-.018),Vector3(width*.5,0,-.018),
		Vector3(lean,height,-.018),Vector3(-width*.5,0,.018),
		Vector3(width*.5,0,.018),Vector3(lean,height,.018)]
	var indices := [0,2,1,3,4,5,0,1,4,0,4,3,1,2,5,1,5,4,2,0,3,2,3,5]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in indices:
		surface.add_vertex(vertices[index])
	surface.generate_normals()
	mesh(parent,surface.commit(),at,material)

static func strainer(parent: Node3D, w: float, d: float, m: Dictionary) -> void:
	box(parent,Vector3(16,.12,.16),Vector3(0,3.3,0),m.cast_iron,"rail")
	var winch := cylinder(parent,.16,.32,Vector3(0,3.08,0),m.copper)
	winch.rotation.x = PI*.5
	var basket := Node3D.new()
	basket.name = "basket"
	parent.add_child(basket)
	for z in range(int(d/.12)+1):
		box(basket,Vector3(w,.025,.025),Vector3(0,0,-d*.5+z*.12),m.cast_iron)
	for x in range(int(w/.12)+1):
		var at := -w*.5+x*.12
		box(basket,Vector3(.025,.025,d),Vector3(at,0,0),m.cast_iron)
		for z in [-d*.5,d*.5]:
			box(basket,Vector3(.025,.45,.025),Vector3(at,.225,z),m.cast_iron)
	for z in range(int(d/.12)+1):
		for x in [-w*.5,w*.5]:
			box(basket,Vector3(.025,.45,.025),Vector3(x,.225,-d*.5+z*.12),m.cast_iron)
	for z in [-d*.5,d*.5]:
		box(basket,Vector3(w,.035,.035),Vector3(0,.45,z),m.copper)
	for x in [-w*.5,w*.5]:
		box(basket,Vector3(.035,.035,d),Vector3(x,.45,0),m.copper)
	for side in [-1,1]:
		var links := Node3D.new()
		links.name = "chain_left" if side < 0 else "chain_right"
		parent.add_child(links)
		chain(links,Vector3(side*w*.35,0,0),Vector3(side*w*.35,1,0),m.copper,.035)

static func tube(parent: Node3D, centers: Array[Vector3], radius: float, inside: float,
		outer: Material, inner: Material) -> void:
	var geometry = preload("res://scripts/camera_test_geometry.gd")
	for i in range(centers.size()-1):
		var a := centers[i]
		var b := centers[i+1]
		var tangent_a := (centers[mini(i+1,centers.size()-1)]-centers[maxi(0,i-1)]).normalized()
		var tangent_b := (centers[mini(i+2,centers.size()-1)]-a).normalized()
		var side_a := tangent_a.cross(Vector3.BACK).normalized()
		var side_b := tangent_b.cross(Vector3.BACK).normalized()
		for j in 24:
			var r0 := TAU*j/24
			var r1 := TAU*(j+1)/24
			for r in [radius,inside]:
				geometry.quad(parent,[a+(side_a*cos(r0)+Vector3.BACK*sin(r0))*r,
					b+(side_b*cos(r0)+Vector3.BACK*sin(r0))*r,
					b+(side_b*cos(r1)+Vector3.BACK*sin(r1))*r,
					a+(side_a*cos(r1)+Vector3.BACK*sin(r1))*r],outer if r == radius else inner)
