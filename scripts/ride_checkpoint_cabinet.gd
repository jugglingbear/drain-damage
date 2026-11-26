extends Node3D
## Solid chassis and glass-front artwork share the channel camera, light and shadow map.
const BASE := Vector2(92,192)
const PIXEL := 0.0105
const FACE_OFFSET := Vector2(96,24)
const PANEL := preload("res://assets/world/spare-employee-dispenser/glass-cabinet-v1.png")
var front: Sprite3D
var viewport: SubViewport
var canvas: Node2D
var model: RefCounted
var game: Node2D
var skis: Array[Sprite3D] = []
var trails: Array[Sprite3D] = []
var chassis: Node3D
var front_transform := Transform2D.IDENTITY

func box(center: Vector3, dimensions: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.material_override = material
	chassis.add_child(part)
	part.position = center

func configure(host: Node2D, ride: RefCounted) -> void:
	game = host
	model = ride
	chassis = Node3D.new()
	add_child(chassis)
	var paint := StandardMaterial3D.new()
	var steel := AtlasTexture.new()
	steel.atlas = PANEL
	steel.region = Rect2(132,1184,296,51)
	# Extract the existing painted panel so mesh UVs address only the steel.
	paint.albedo_texture = ImageTexture.create_from_image(steel.get_image())
	paint.roughness = 0.72
	paint.emission_enabled = true
	paint.emission = Color("#163333")
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color("#ad8250")
	trim.metallic = 0.35
	var width := 112*PIXEL
	var height := 130*PIXEL
	var depth := 0.55
	box(Vector3(0,height/2+0.13,-depth/2),Vector3(width,height,depth),paint)
	for y in [0.16,height+0.1]:
		# Trim the sides and back. A full-width front lip crosses the painted sign and chute.
		for side in [-1,1]:
			box(Vector3(side*width*.5,y,-depth*.5-.025),Vector3(.035,.035,depth),trim)
		box(Vector3(0,y,-depth),Vector3(width,.035,.035),trim)
	for side in [-1,1]:
		box(Vector3(side*width*.5,height*.52,-depth+.03),Vector3(.045,height,.055),trim)
	viewport = SubViewport.new()
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.size = Vector2i(768,512)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	canvas = Node2D.new()
	viewport.add_child(canvas)
	canvas.scale = Vector2(2,2)
	canvas.draw.connect(draw_front)
	front = Sprite3D.new()
	front.texture = viewport.get_texture()
	front.pixel_size = PIXEL/2
	front.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	front.position = Vector3((192-FACE_OFFSET.x-BASE.x)*PIXEL,(BASE.y-128+FACE_OFFSET.y)*PIXEL,.015)
	front.shaded = true
	front.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	chassis.add_child(front)
	for key in ["sean-ski","tony-ski","blood-wake","blood-wake"]:
		var sprite := Sprite3D.new()
		var spec: Dictionary = ride.checkpoint_view.layers[key]
		sprite.texture = ride.checkpoint_view.textures[spec.path]
		sprite.pixel_size = float(spec.display_width)*0.014/sprite.texture.get_width()
		sprite.shaded = true
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		if key == "blood-wake":
			sprite.rotation.x = -PI/2
			sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			trails.append(sprite)
		else:
			sprite.flip_h = true
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			skis.append(sprite)
		add_child(sprite)
	visible = false

func draw_front() -> void:
	var d: RefCounted = game.dispenser
	var cp: RefCounted = model.checkpoint
	var state := "activated"
	if cp.phase == "replacement": state = "dispense" if "vend" in d.events else "scan"
	canvas.draw_set_transform(FACE_OFFSET)
	d.draw_frame(canvas,d.art.machine.states[state],Vector2.ZERO)
	for occupant in d.sleeping_frames(game.employee.id,model.clock,cp.DISPENSER_ID):
		d.draw_frame(canvas,occupant.frame,Vector2.ZERO,1,1,occupant.clip)
	d.draw_frame(canvas,d.art.machine.glass_front,Vector2.ZERO)
	if cp.phase != "replacement":
		var sway := sin(model.clock*2.5)*4
		d.ride_canvas = Transform2D(0,FACE_OFFSET)
		model.checkpoint_view.balance_arm(canvas,d,Vector2(27,95),Vector2(-61,91+sway),-1)
		model.checkpoint_view.balance_arm(canvas,d,Vector2(145,95),Vector2(235,84-sway),1)
		d.ride_canvas = Transform2D.IDENTITY

func update(view: Node3D, active: bool) -> void:
	var cp: RefCounted = model.checkpoint
	visible = active and cp.phase in ["approach","waiting","docking","replacement","departure"]
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if visible else SubViewport.UPDATE_DISABLED
	if not visible: return
	var enter := 1.0-smoothstep(0,3,cp.age) if cp.phase == "approach" else 0.0
	var lift := smoothstep(cp.LIFT_DELAY,cp.LIFT_DELAY+cp.LIFT_SECONDS,cp.age) if cp.phase == "departure" else 0.0
	var sink := smoothstep(.28,1.55,cp.age) if cp.phase == "departure" else 0.0
	position = view.world(Vector2(505+enter*1250,330))
	chassis.position.y = .22+lift*12
	for i in 2:
		var spec_size := skis[i].texture.get_size()*skis[i].pixel_size
		var x := -.18 if i==0 else .16
		var z := -.04 if i==0 else .28
		skis[i].position = Vector3(x,spec_size.y*.42-sink*.8,z)
		skis[i].visible = sink < .95
		var alpha := 1.0 if cp.phase == "approach" else 1.0-smoothstep(0,1.2,cp.age) if cp.phase == "waiting" else 0.0
		trails[i].position = Vector3(x-spec_size.x*.5-.51,.012,z)
		trails[i].modulate.a = alpha
		trails[i].visible = alpha > 0
	var base: Vector3 = chassis.global_position+Vector3(0,0,.012)
	var origin: Vector2 = view.camera.unproject_position(base)
	var x_axis: Vector2 = view.camera.unproject_position(base+Vector3(PIXEL,0,0))-origin
	var y_axis: Vector2 = view.camera.unproject_position(base-Vector3(0,PIXEL,0))-origin
	front_transform = Transform2D(x_axis,y_axis,origin-x_axis*BASE.x-y_axis*BASE.y)
	if cp.phase == "departure" and not cp.rocket_cleared:
		cp.rocket_cleared = model.checkpoint_view.exhaust_above_screen(front_transform)
	canvas.queue_redraw()
