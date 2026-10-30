extends Node3D
## Art-registered articulated cutouts, with world endpoints and unscaled fist silhouettes.
const Props = preload("res://scripts/ride_world_props.gd")
const REGISTRATION := "res://assets/world/ride-depth-v1/hand-registration.json"
const PIXEL := 1.75/606.0
var registration: Dictionary
var contact: Sprite3D
var curled: Sprite3D
var arm: Sprite3D
var aperture_material: ShaderMaterial
var hatch_point := Vector3(4,.6,-1.99)
var root_point := Vector3(4.7,.25,-2.05)

func configure(materials: Dictionary) -> void:
	registration = JSON.parse_string(FileAccess.get_file_as_string(REGISTRATION))
	var aperture_shader := Shader.new()
	aperture_shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D artwork : source_color, filter_linear_mipmap;
uniform mat4 hand_inverse;
varying vec3 hand_position;
void vertex() {
 hand_position = (hand_inverse * MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
 // The painted cutout may only cross the wall through the physical hatch.
 if (hand_position.z < -1.99 &&
     (hand_position.x < 3.28 || hand_position.x > 4.72 ||
      hand_position.y < 0.12 || hand_position.y > 1.08)) { discard; }
 if (hand_position.z < -2.32) { discard; }
 vec4 ink = texture(artwork, UV);
 ALBEDO = ink.rgb;
 ALPHA = ink.a;
 ALPHA_SCISSOR_THRESHOLD = 0.5;
}
"""
	aperture_material = ShaderMaterial.new()
	aperture_material.shader = aperture_shader
	aperture_material.set_shader_parameter("artwork",load("res://"+str(registration.path)))
	for x in [-.8,.8]:
		Props.box(self,Vector3(.08,1.12,.12),hatch_point+Vector3(x,0,0),materials.cast_iron)
	for y in [-.56,.56]:
		Props.box(self,Vector3(1.68,.08,.12),hatch_point+Vector3(0,y,0),materials.cast_iron)
	var recess := materials.cast_iron.duplicate() as StandardMaterial3D
	recess.albedo_color = Color(.08,.08,.08)
	Props.box(self,Vector3(1.44,.96,.12),hatch_point-Vector3(0,0,.27),recess)
	contact = cutout("contact")
	curled = cutout("curled")
	arm = cutout("forearm_a")

func cutout(id: String) -> Sprite3D:
	var frame: Dictionary = registration.frames[id]
	var crop: Array = frame.source_rect
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://"+str(registration.path))
	atlas.region = Rect2(crop[0],crop[1],crop[2],crop[3])
	var sprite := Sprite3D.new()
	sprite.texture = atlas
	sprite.pixel_size = PIXEL
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.material_override = aperture_material
	var pivot: Array = frame.get("wrist_px",frame.get("root_px",[]))
	if id.begins_with("forearm"): pivot = frame.root_px
	sprite.offset = Vector2(float(crop[2])*.5-(float(pivot[0])-float(crop[0])),
		(float(pivot[1])-float(crop[1]))-float(crop[3])*.5)
	add_child(sprite)
	return sprite

func animate(age: float, timeline: Dictionary, camera: Camera3D) -> void:
	aperture_material.set_shader_parameter("hand_inverse",global_transform.affine_inverse())
	var warning := float(timeline.warning)
	var impact := float(timeline.impact)
	var clear_at := float(timeline.clear)
	var end := float(timeline.retreat_end)
	visible = age >= warning
	if not visible: return
	var descent := clampf((age-(impact-.18))/.18,0,1)
	var strike := descent*descent*descent if age < impact else 1-smoothstep(impact+.035,clear_at,age)
	# Finish behind the opaque wall before visibility is disabled at retreat_end.
	var retreat := smoothstep(clear_at,end-.08,age)
	# Match the painted wrist-to-palm axis to the projected forearm, rather than
	# keeping the hand upright while its forearm approaches from the side.
	var contact_height := 1.0
	var contact_x := -1.2
	for iteration in 16:
		var point := Vector3(contact_x,contact_height,-.35)
		var pose := wrist_basis(point,camera)
		var lowest := opaque_contact("contact",pose)
		contact_height = -lowest.y
		contact_x = -lowest.x
	var wrist := Vector3(contact_x,lerpf(2.2,contact_height,strike),lerpf(1.5,-.35,strike))
	# Seat the painted fist at the opening before drawing it through the wall.
	# Keep the proximal endpoint rooted in the hatch throughout withdrawal.
	var hand_basis := wrist_basis(wrist,camera)
	# Freeze the raised pose during withdrawal. Re-aiming at an almost coincident
	# root flips the projected palm axis and invalidates the aperture alignment.
	var center := opaque_center("curled",hand_basis)
	var entry := Vector3(hatch_point.x-center.x,hatch_point.y-center.y,-1.35)
	var approach := smoothstep(0,.72,retreat)
	wrist.x = lerpf(wrist.x,entry.x,approach)
	wrist.z = lerpf(wrist.z,entry.z,approach)
	wrist.y = lerpf(wrist.y,entry.y,smoothstep(.35,.72,retreat))
	# Leave clearance over the jumping rider's opaque outline before seating.
	wrist.y += .12*smoothstep(clear_at-.1,clear_at,age)*(1-smoothstep(.35,.72,retreat))
	wrist.z -= 4.0*smoothstep(.72,1.0,retreat)
	var arm_root := root_point
	for sprite in [contact,curled]:
		sprite.basis = hand_basis
		sprite.position = wrist+camera.global_basis.z*.02
		sprite.visible = age < end
	contact.visible = contact.visible and age <= impact+.035
	curled.visible = curled.visible and age > impact+.035
	arm.visible = age < end
	var frame: Dictionary = registration.frames.contact if contact.visible else registration.frames.curled
	var overlap: Array = frame.arm_overlap_px
	var pivot: Array = frame.wrist_px
	var interior := wrist+hand_basis*Vector3(float(overlap[0])-float(pivot[0]),
		float(pivot[1])-float(overlap[1]),0)*PIXEL
	var delta := interior-arm_root
	var right := delta.normalized()
	var normal := camera.global_basis.z.cross(right).normalized()
	var source_delta := Vector2(608-44,-(1016-980))
	# Match the narrower painted forearm terminal to the hand's wrist, not the
	# full forearm bounding box; overlap hides the atlas cut beneath the palm.
	var thickness := 230.0/160.0
	arm.basis = Basis(right,normal,right.cross(normal))*Basis.from_scale(
		Vector3((delta.length()+.06)/(source_delta.length()*PIXEL),thickness,1))*Basis(Vector3.BACK,-source_delta.angle())
	arm.position = arm_root

func wrist_basis(wrist: Vector3, camera: Camera3D) -> Basis:
	var forward := camera.global_basis.z
	var delta := wrist-root_point
	var palm := (delta-forward*delta.dot(forward)).normalized()
	var up := -palm
	return Basis(up.cross(forward),up,forward)

func opaque_bottom(id: String, pose: Basis) -> float:
	return opaque_contact(id,pose).y

func opaque_center(id: String, pose: Basis) -> Vector3:
	var frame: Dictionary = registration.frames[id]
	var pivot: Array = frame.wrist_px
	var low := Vector3(INF,INF,INF)
	var high := Vector3(-INF,-INF,-INF)
	for point: Array in frame.opaque_convex_outline_px:
		var local := Vector3(float(point[0])-float(pivot[0]),float(pivot[1])-float(point[1]),0)*PIXEL
		var transformed := pose*local
		low = low.min(transformed)
		high = high.max(transformed)
	return (low+high)*.5

func opaque_contact(id: String, pose: Basis) -> Vector3:
	var frame: Dictionary = registration.frames[id]
	var pivot: Array = frame.wrist_px
	var bottom := Vector3(0,INF,0)
	for point: Array in frame.opaque_convex_outline_px:
		var local := Vector3(float(point[0])-float(pivot[0]),float(pivot[1])-float(point[1]),0)*PIXEL
		var transformed := pose*local
		if transformed.y < bottom.y: bottom = transformed
	return bottom
