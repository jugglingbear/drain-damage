extends RefCounted
## Art-registered hanging body with an independently aimed barrel.
const MANIFEST := "res://assets/bestiary/opening-trial/sputtervalve-ceiling-v1.json"
const IMAGE := "res://assets/bestiary/opening-trial/sputtervalve-ceiling-v1.png"
var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
var bodies: Array[Texture2D] = []
var barrel: Texture2D

func prepare() -> void:
	if not bodies.is_empty(): return
	var texture: Texture2D = load(IMAGE)
	var source := texture.get_image()
	for values in definition.body_frames:
		var crop := cleaned(source,Rect2i(values[0],values[1],values[2],values[3]))
		var padded := Image.create_empty(475,498,false,Image.FORMAT_RGBA8)
		padded.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),Vector2i.ZERO)
		bodies.append(ImageTexture.create_from_image(padded))
	var r: Array = definition.barrel_source_rect
	barrel = ImageTexture.create_from_image(cleaned(source,Rect2i(r[0],r[1],r[2],r[3])))

func cleaned(source: Image, rect: Rect2i) -> Image:
	var crop := source.get_region(rect)
	crop.convert(Image.FORMAT_RGBA8)
	for y in range(crop.get_height()):
		for x in range(crop.get_width()):
			if crop.get_pixel(x,y).a < 240.0/255.0: crop.set_pixel(x,y,Color.TRANSPARENT)
	return crop

func vector(values: Array) -> Vector2: return Vector2(values[0],values[1])

func pivot(mount: Vector2) -> Vector2:
	return mount+(vector(definition.body_pivot_in_frame)-vector(definition.body_anchor_in_frame))*float(definition.body_scale)

func muzzle_vector() -> Vector2:
	return (vector(definition.barrel_muzzle_in_frame)-vector(definition.barrel_pivot_in_frame))*float(definition.barrel_scale)

func angle(direction: Vector2) -> float: return direction.angle()-muzzle_vector().angle()

func muzzle(mount: Vector2, direction: Vector2) -> Vector2:
	return pivot(mount)+muzzle_vector().rotated(angle(direction))

func body_rect(mount: Vector2) -> Rect2:
	return Rect2(mount-vector(definition.body_anchor_in_frame)*float(definition.body_scale),Vector2(475,498)*float(definition.body_scale))

func barrel_corners(mount: Vector2, direction: Vector2) -> PackedVector2Array:
	var r: Array = definition.barrel_source_rect
	var rect := Rect2(-vector(definition.barrel_pivot_in_frame)*float(definition.barrel_scale),Vector2(r[2],r[3])*float(definition.barrel_scale))
	var points := PackedVector2Array()
	for point in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
		points.append(pivot(mount)+point.rotated(angle(direction)))
	return points

func bounds(mount: Vector2, direction: Vector2) -> Rect2:
	var result := body_rect(mount)
	for point in barrel_corners(mount,direction): result = result.expand(point)
	return result

func radius() -> float:
	var result := 0.0
	for index in range(32):
		var rect := bounds(Vector2.ZERO,Vector2.from_angle(index*TAU/32))
		result = maxf(result,maxf(rect.position.length(),rect.end.length()))
	return result

func draw(host: Node2D, actor: Dictionary, direction: Vector2) -> void:
	prepare()
	var body := body_rect(actor.feet)
	var plane: float = actor.home.y
	var visible := body.intersection(Rect2(body.position.x,plane,body.size.x,1024))
	var body_texture: Texture2D = bodies[0 if actor.hp <= 0 else int(actor.clock*(20 if actor.winding else 8))%2]
	var tint := Color(1.8,1.5,1.2) if actor.flash > 0 else Color.WHITE
	if actor.winding:
		tint = Color(1.2,0.75+0.25*sin(actor.clock*35),1.35)
	if actor.hp <= 0:
		tint = Color(0.35,0.3,0.4,1-clampf(actor.death/0.6,0,1))
	# Keep the upper mounting plate unmodulated while the lower mechanism charges.
	for band in [Rect2(body.position,Vector2(body.size.x,10)),
		Rect2(body.position+Vector2(0,10),body.size-Vector2(0,10))]:
		var piece: Rect2 = visible.intersection(band)
		if not piece.has_area(): continue
		var source := Rect2((piece.position-body.position)/float(definition.body_scale),piece.size/float(definition.body_scale))
		var shade := Color.WHITE if actor.hp > 0 and band.position == body.position else tint
		host.draw_texture_rect_region(body_texture,piece,source,shade)
	var corners := barrel_corners(actor.feet,direction)
	var mask := PackedVector2Array([Vector2(-100000,plane),Vector2(100000,plane),Vector2(100000,2048),Vector2(-100000,2048)])
	var transform := Transform2D(angle(direction),pivot(actor.feet))
	var inverse := transform.affine_inverse()
	var r: Array = definition.barrel_source_rect
	for polygon: PackedVector2Array in Geometry2D.intersect_polygons(corners,mask):
		var uvs := PackedVector2Array()
		for point in polygon:
			uvs.append((inverse*point/float(definition.barrel_scale)+vector(definition.barrel_pivot_in_frame))/Vector2(r[2],r[3]))
		host.draw_polygon(polygon,PackedColorArray([tint]),uvs,barrel)
