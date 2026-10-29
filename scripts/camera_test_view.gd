extends Node3D
## Shared world-space presentation experiment. Simulation never reads the camera.
const Geometry = preload("res://scripts/camera_test_geometry.gd")
const MANIFEST := "res://assets/world/level-two-camera-test-v1/manifest.json"
var camera := Camera3D.new()
var rider := Node3D.new()
var materials: Dictionary = {}
var yaw := 0.0
var target_yaw := 0.0
var turn_start := 0.0
var turn_age := 1.2
var ready_art := false

func frame_texture(frame: Dictionary) -> Texture2D:
	var texture: Texture2D = load("res://"+str(frame.path))
	if not frame.has("source_rect"): return texture
	# Spatial materials repeat a complete texture; crop registered atlas regions once before upload.
	var image := texture.get_image()
	if image.is_compressed(): image.decompress()
	var s: Array = frame.source_rect
	var cropped := image.get_region(Rect2i(s[0],s[1],s[2],s[3]))
	cropped.generate_mipmaps()
	return ImageTexture.create_from_image(cropped)

func material_from(frame: Dictionary) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = frame_texture(frame)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = .85
	return material

func configure(model: RefCounted, hero_art: Dictionary, hero: String, hard: bool,
		contacts: Dictionary) -> void:
	assert(FileAccess.file_exists(MANIFEST),"Camera proof requires Art's registered materials")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for key: String in manifest.materials:
		materials[key] = material_from(manifest.materials[key])
	var layout: Dictionary = model.LAYOUT
	var basin: Dictionary = layout.basin
	Geometry.slab(self,Rect2(basin.center-basin.size*.5,basin.size),basin.top,basin.thickness,
		materials.porcelain_top,materials.porcelain_side)
	var platform: Dictionary = layout.platform
	Geometry.ellipse(self,platform.center,platform.size*.5,platform.top,platform.top-platform.thickness,
		materials.brass_top,materials.brass_side)
	Geometry.water_track(self,layout.hole.center,layout.hole.radius,materials.water)
	Geometry.ellipse(self,layout.hole.center,Vector2.ONE*layout.hole.radius,-.005,-1.2,
		materials.hole_wall,materials.hole_wall,false)
	var inflow: StandardMaterial3D = materials.water.duplicate()
	materials["inflow"] = inflow
	Geometry.inflow_ring(self,layout.hole.center,layout.hole.radius,inflow)
	var downflow: StandardMaterial3D = materials.water.duplicate()
	downflow.albedo_color.a = .65
	downflow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materials["downflow"] = downflow
	Geometry.ellipse(self,layout.hole.center,Vector2.ONE*(layout.hole.radius-.008),0,-1.1,
		downflow,downflow,false)
	Geometry.ramp(self,layout.ramp.rect,layout.ramp.rise,materials.ramp_top,materials.ramp_side)
	# Side banks provide depth cues; the round opening remains clear down to its interior wall.
	for z in [-2.18,2.0]:
		Geometry.slab(self,Rect2(0,z,24,.18),.15,.6,materials.channel,materials.channel)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("10242d")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c4e4ed")
	environment.environment.ambient_light_energy = .7
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-30,0)
	light.light_energy = .7
	light.shadow_enabled = true
	add_child(light)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.2
	camera.near = .1
	camera.far = 100
	add_child(camera)
	camera.current = true
	add_child(rider)
	var mode := "hard" if hard else "normal"
	var contact: Array = contacts[hero][mode]
	for frame: Dictionary in hero_art.landing[hero][mode].front:
		add_rider_frame(frame,Vector2(contact[0],contact[1]))
	ready_art = true
	update_view(model,0,false,0)

func add_rider_frame(frame: Dictionary, contact: Vector2) -> void:
	if frame.has("layers"):
		for layer: Dictionary in frame.layers: add_rider_frame(layer,contact)
		return
	var sprite := Sprite3D.new()
	var s: Array = frame.source_rect
	var d: Array = frame.destination
	sprite.texture = frame_texture(frame)
	sprite.pixel_size = float(d[2])/float(s[2])/100.0
	sprite.scale.y = float(d[3])/float(s[3])/(float(d[2])/float(s[2]))
	sprite.position = Vector3((float(d[0])+float(d[2])*.5-contact.x)/100.0,
		-(float(d[1])+float(d[3])*.5-contact.y)/100.0,0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = .3
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	rider.add_child(sprite)

func request_turn(model: RefCounted) -> bool:
	# Compare angles only from safe water. Held movement cannot carry the rider into a hazard mid-turn.
	if turning() or model.dead or not model.grounded or model.surface != "track": return false
	if model.position.distance_to(model.LAYOUT.hole.center) < 2: return false
	turn_start = yaw
	target_yaw = 20.0 if target_yaw == 0 else 0.0
	turn_age = 0
	return true

func turning() -> bool:
	return turn_age < 1.2

func update_view(model: RefCounted, delta: float, paused: bool, fall_age: float) -> void:
	if not ready_art: return
	if not paused:
		turn_age = minf(1.2,turn_age+delta)
		yaw = lerpf(turn_start,target_yaw,smoothstep(0,1.2,turn_age))
	var focus := Vector3(clampf(model.position.x,5.7,18.3),0,0)
	var angle := deg_to_rad(yaw)
	var pitch := deg_to_rad(50)
	camera.position = focus+Vector3(sin(angle)*cos(pitch),sin(pitch),cos(angle)*cos(pitch))*16
	camera.look_at(focus)
	rider.position = Vector3(model.position.x,model.elevation-.9*minf(fall_age,1.2),model.position.y)
	materials.water.uv1_offset = Vector3(-model.clock*.14,0,0)
	materials.downflow.uv1_offset = Vector3(0,-model.clock*.8,0)
	materials.inflow.uv1_offset = Vector3(0,-model.clock*.7,0)
