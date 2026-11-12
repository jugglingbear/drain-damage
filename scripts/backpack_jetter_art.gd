extends RefCounted
## Reusable equipment follows the existing body, grip and muzzle registration.
const MANIFEST := "res://assets/weapons/backpack-jetter-v1/manifest.json"
var definition: Dictionary = {}
var texture: Texture2D
const PACK_HEIGHT := 28.0

func prepare() -> void:
	if not definition.is_empty(): return
	definition = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var source: Texture2D = load(definition.texture)
	var pixels := source.get_image()
	pixels.convert(Image.FORMAT_RGBA8)
	var bytes := pixels.get_data()
	for index in range(3,bytes.size(),4):
		if bytes[index] < 16: bytes[index] = 0
	texture = ImageTexture.create_from_image(Image.create_from_data(
		pixels.get_width(),pixels.get_height(),false,Image.FORMAT_RGBA8,bytes))

func vector(values: Array) -> Vector2:
	return Vector2(values[0],values[1])

func rectangle(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])

func enabled(game: Node2D) -> bool:
	return game.employee.weapon_id in definition.weapon_ids

func pack_transform(hero: String, costume: String, offset: Vector2) -> Transform2D:
	var part: Dictionary = definition.parts.pack
	var scale := PACK_HEIGHT/float(part.source_rect[3])
	var basis := Transform2D(Vector2(scale,0),Vector2(0,scale),Vector2.ZERO)
	basis.origin = vector(definition.hero_registrations[hero][costume].pack_mount)+offset-basis*vector(part.mount_source)
	return basis

func nozzle_transform(pose: Dictionary) -> Transform2D:
	var part: Dictionary = definition.parts.nozzle
	var grip := vector(pose.grip)
	var direction := vector(pose.muzzle)-grip
	var scale := direction.length()/vector(part.grip_source).distance_to(vector(part.muzzle_source))
	var basis := Transform2D(direction.angle(),Vector2.ZERO).scaled(Vector2(scale,scale))
	basis.origin = grip-basis*vector(part.grip_source)
	return basis

func draw_part(host: Node2D, part: String, basis: Transform2D, tint: Color) -> void:
	host.draw_set_transform_matrix(basis)
	var source := rectangle(definition.parts[part].source_rect)
	host.draw_texture_rect_region(texture,source,source,tint)

func draw_back(host: Node2D, base: Transform2D, hero: String, costume: String,
		pose: Dictionary, offset: Vector2, tint: Color) -> void:
	var pack := pack_transform(hero,costume,offset)
	draw_part(host,"pack",base*pack,tint)
	var nozzle := nozzle_transform(pose)
	draw_hose(host,base,pack,nozzle,tint)

func draw_hose(host: Node2D, base: Transform2D, pack: Transform2D, nozzle: Transform2D, tint: Color) -> void:
	var start := pack*vector(definition.parts.pack.outlet_source)
	var finish := nozzle*vector(definition.parts.nozzle.hose_inlet_source)
	var control_a := start+Vector2(-4,15)
	var control_b := finish+Vector2(-15,18)
	host.draw_set_transform_matrix(base)
	var source := rectangle(definition.parts.hose_straight.source_rect)
	var thickness: float = definition.parts.hose_straight.native_thickness
	for index in range(20):
		var a := start.bezier_interpolate(control_a,control_b,finish,index/20.0)
		var b := start.bezier_interpolate(control_a,control_b,finish,(index+1)/20.0)
		var normal := (b-a).normalized().orthogonal()*thickness*.5
		var points := PackedVector2Array([a-normal,b-normal,b+normal,a+normal])
		var atlas_size := texture.get_size()
		var left := source.position/atlas_size
		var right := source.end/atlas_size
		var uv := PackedVector2Array([left,Vector2(right.x,left.y),right,Vector2(left.x,right.y)])
		host.draw_polygon(points,PackedColorArray([tint]),uv,texture)

func draw_strap(host: Node2D, base: Transform2D, hero: String, costume: String,
		offset: Vector2, tint: Color) -> void:
	var part: Dictionary = definition.parts.strap
	var source := rectangle(part.source_rect)
	var scale := float(part.native_height)/source.size.y
	var mount := vector(definition.hero_registrations[hero][costume].pack_mount)+offset
	var destination := Rect2(mount+Vector2(0,-1),source.size*scale)
	host.draw_set_transform_matrix(base)
	host.draw_texture_rect_region(texture,destination,source,tint)

func draw_nozzle(host: Node2D, base: Transform2D, pose: Dictionary, tint: Color) -> void:
	draw_part(host,"nozzle",base*nozzle_transform(pose),tint)

func death_transforms(hero: String, costume: String, stage: int) -> Dictionary:
	# Death registrations already include the body frame placement; never add a living offset.
	var frame: Dictionary = definition.death_adapters.heroes[hero][costume].frames[stage]
	var pack_part: Dictionary = definition.parts.pack
	var pack_scale := PACK_HEIGHT/float(pack_part.source_rect[3])
	var pack := Transform2D(deg_to_rad(frame.pack_rotation_degrees),Vector2.ZERO).scaled(Vector2.ONE*pack_scale)
	pack.origin = vector(frame.pack_mount)-pack*vector(pack_part.mount_source)
	var nozzle_part: Dictionary = definition.parts.nozzle
	var nozzle_scale := float(frame.released_nozzle_native_grip_to_muzzle)/vector(nozzle_part.grip_source).distance_to(vector(nozzle_part.muzzle_source))
	var nozzle := Transform2D(deg_to_rad(frame.released_nozzle_rotation_degrees),Vector2.ZERO).scaled(Vector2.ONE*nozzle_scale)
	nozzle.origin = vector(frame.released_nozzle_grip)-nozzle*vector(nozzle_part.grip_source)
	return {"pack":pack,"nozzle":nozzle}

func draw_death_back(host: Node2D, base: Transform2D, transforms: Dictionary, tint: Color) -> void:
	draw_part(host,"pack",base*transforms.pack,tint)
	draw_hose(host,base,transforms.pack,transforms.nozzle,tint)
