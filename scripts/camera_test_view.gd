extends Node3D
## Shared world-space presentation experiment. Simulation never reads the camera.
const Geometry = preload("res://scripts/camera_test_geometry.gd")
const MANIFEST := "res://assets/world/level-two-camera-test-v1/manifest.json"
var camera := Camera3D.new()
var rider := Node3D.new()
var materials: Dictionary = {}
const FIRST_YAW := 18.0
const SECOND_YAW := -18.0
var yaw := FIRST_YAW
var target_yaw := FIRST_YAW
var turn_start := FIRST_YAW
var turn_age := 1.2
var ready_art := false
var contact_shadow: MeshInstance3D

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
	material.roughness = 1.0
	material.metallic_specular = .1
	return material

func configure(model: RefCounted, hero_art: Dictionary, hero: String, hard: bool,
		contacts: Dictionary) -> void:
	assert(FileAccess.file_exists(MANIFEST),"Camera proof requires Art's registered materials")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for key: String in manifest.materials:
		materials[key] = material_from(manifest.materials[key])
	var water := ShaderMaterial.new()
	water.shader = preload("res://scripts/camera_test_water.gdshader")
	water.set_shader_parameter("water_texture",frame_texture(manifest.materials.water))
	materials.water = water
	materials.channel.albedo_color = Color(.52,.58,.56)
	var layout: Dictionary = model.LAYOUT
	water.set_shader_parameter("foundation_min",Vector3(layout.ramp.rect.position.x,-.6,layout.ramp.rect.position.y))
	water.set_shader_parameter("foundation_max",Vector3(layout.ramp.rect.end.x,0,layout.ramp.rect.end.y))
	var basin: Dictionary = layout.basin
	Geometry.slab(self,Rect2(basin.center-basin.size*.5,basin.size),basin.top,.7,
		materials.porcelain_top,materials.porcelain_side)
	if materials.has("basin_drain"):
		Geometry.ellipse(self,basin.center,Vector2(.14,.14),basin.top+.003,basin.top,
			materials.basin_drain,materials.porcelain_side)
	var platform: Dictionary = layout.platform
	Geometry.slab(self,Rect2(platform.center-platform.size*.56,platform.size*1.12),-.03,.65,
		materials.brass_side,materials.brass_side)
	Geometry.ellipse(self,platform.center,platform.size*.5,platform.top,platform.top-platform.thickness,
		materials.brass_top,materials.brass_side)
	Geometry.water_track(self,layout.hole.center,layout.hole.radius,materials.water)
	Geometry.ellipse(self,layout.hole.center,Vector2.ONE*layout.hole.radius,-.005,-1.2,
		materials.hole_wall,materials.hole_wall,false)
	var inflow: ShaderMaterial = materials.water.duplicate()
	materials["inflow"] = inflow
	Geometry.inflow_ring(self,layout.hole.center,layout.hole.radius,inflow)
	var downflow: ShaderMaterial = materials.water.duplicate()
	downflow.set_shader_parameter("water_tint",Color(.32,.55,.54,.22))
	materials["downflow"] = downflow
	Geometry.ellipse(self,layout.hole.center,Vector2.ONE*(layout.hole.radius-.008),0,-1.1,
		downflow,downflow,false)
	Geometry.ramp(self,layout.ramp.rect,layout.ramp.rise,materials.ramp_top,materials.ramp_side)
	# Side banks provide depth cues; the round opening remains clear down to its interior wall.
	Geometry.slab(self,Rect2(0,-2.4,24,.4),1.1,1.8,materials.channel,materials.channel)
	Geometry.slab(self,Rect2(0,2,24,.3),.12,.8,materials.channel,materials.channel)
	Geometry.slab(self,Rect2(0,-4,24,1.6),-.6,.2,materials.hole_wall,materials.hole_wall)
	Geometry.slab(self,Rect2(0,2.3,24,1.7),-.6,.2,materials.hole_wall,materials.hole_wall)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("10242d")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d0d4d5")
	environment.environment.ambient_light_energy = .22
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-30,0)
	light.light_energy = .55
	light.shadow_enabled = true
	add_child(light)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.2
	camera.near = .1
	camera.far = 100
	add_child(camera)
	camera.current = true
	add_child(rider)
	var ride_art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/level-two-ride-v1/manifest.json"))
	var shadow_material := material_from(ride_art.frames.shadow)
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.albedo_color = Color(0,0,0,.7)
	contact_shadow = Geometry.quad(self,[Vector3(-.5,0,-.17),Vector3(.5,0,-.17),
		Vector3(.5,0,.17),Vector3(-.5,0,.17)],shadow_material)
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
	# Offset within the billboard so its contact pixel, not its center, pivots at the world anchor.
	sprite.offset = Vector2((float(d[0])+float(d[2])*.5-contact.x)*float(s[2])/float(d[2]),
		-(float(d[1])+float(d[3])*.5-contact.y)*float(s[3])/float(d[3]))
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
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
	target_yaw = SECOND_YAW if target_yaw == FIRST_YAW else FIRST_YAW
	turn_age = 0
	return true

func turning() -> bool:
	return turn_age < 1.2

func update_view(model: RefCounted, delta: float, paused: bool, fall_age: float) -> void:
	if not ready_art: return
	if not paused:
		turn_age = minf(1.2,turn_age+delta)
		yaw = lerpf(turn_start,target_yaw,smoothstep(0,1.2,turn_age))
	var focus := Vector3(clampf(model.position.x+1.2,3.8,20.0),0,0)
	var angle := deg_to_rad(yaw)
	var pitch := deg_to_rad(35)
	camera.position = focus+Vector3(sin(angle)*cos(pitch),sin(pitch),cos(angle)*cos(pitch))*16
	camera.look_at(focus)
	rider.position = Vector3(model.position.x,model.elevation-.9*minf(fall_age,1.2),model.position.y)
	contact_shadow.position = Vector3(model.position.x,float(model.support_at(model.position).height)+.009,model.position.y)
	contact_shadow.visible = not model.dead
	materials.water.set_shader_parameter("flow_offset",Vector2(-model.clock*.14,0))
	materials.downflow.set_shader_parameter("flow_offset",Vector2(0,-model.clock*.8))
	materials.inflow.set_shader_parameter("flow_offset",Vector2(0,-model.clock*.7))
