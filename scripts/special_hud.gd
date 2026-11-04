extends RefCounted
## Selected attached side module; existing health and life artwork remains independent.
const MANIFEST := "res://assets/ui/specials-module-v1/manifest.json"
var definition: Dictionary = {}
var textures: Dictionary = {}

func texture_crop(image: Image, values: Array) -> Texture2D:
	var pixels := image.get_region(Rect2i(values[0],values[1],values[2],values[3]))
	pixels.convert(Image.FORMAT_RGBA8)
	var bytes := pixels.get_data()
	for index in range(3,bytes.size(),4):
		if bytes[index] < 240: bytes[index] = 0
	return ImageTexture.create_from_image(Image.create_from_data(
		pixels.get_width(),pixels.get_height(),false,Image.FORMAT_RGBA8,bytes))

func prepare() -> void:
	if not definition.is_empty(): return
	definition = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var atlas: Texture2D = load("res://"+definition.source)
	for theme in definition.themes:
		var parts: Dictionary = definition.themes[theme]
		textures[theme+"-housing"] = texture_crop(atlas.get_image(),parts.housing_source_rect)
		textures[theme+"-socket"] = texture_crop(atlas.get_image(),parts.socket_source_rect)
	for key in definition.components:
		textures[key] = texture_crop(atlas.get_image(),definition.components[key].source_rect)
	for key in definition.weapons:
		var weapon: Dictionary = definition.weapons[key]
		var source: Texture2D = load("res://"+weapon.path)
		textures[key] = texture_crop(source.get_image(),weapon.source_rect)

func destination(origin: Vector2, values: Array) -> Rect2:
	return Rect2(origin+Vector2(values[0],values[1]),Vector2(values[2],values[3]))

func fitted(texture: Texture2D, bounds: Rect2, bottom := false) -> Rect2:
	var size := texture.get_size()
	size *= minf(bounds.size.x/size.x,bounds.size.y/size.y)
	var offset := (bounds.size-size)*0.5
	if bottom: offset.y = bounds.size.y-size.y
	return Rect2(bounds.position+offset,size)

func commands(game: Node2D, origin: Vector2, theme: String) -> Array[Dictionary]:
	prepare()
	var geometry: Dictionary = definition.geometry
	var offset: Array = geometry.module_origin_relative_to_vitals
	var position := origin+Vector2(offset[0],offset[1])
	var weapon: String = game.employee.weapon_id
	var output: Array[Dictionary] = [
		{"kind":"housing","texture":textures[theme+"-housing"],"rect":destination(position,geometry.housing)},
		{"kind":"socket","texture":textures[theme+"-socket"],"rect":destination(position,geometry.weapon_socket)},
		{"kind":"weapon","weapon":weapon,"texture":textures[weapon],
			"rect":fitted(textures[weapon],destination(position,geometry.weapon_icon_fit))}
	]
	var count: int = game.specials.remaining()
	for index in range(2):
		var filled := index < count
		var texture: Texture2D = textures["charged" if filled else "depleted"]
		output.append({"kind":"charge","filled":filled,"texture":texture,
			"rect":fitted(texture,destination(position,geometry.canisters[index]),true)})
	return output

func draw(game: Node2D, origin: Vector2, theme: String) -> void:
	for item in commands(game,origin,theme): game.draw_texture_rect(item.texture,item.rect,false)
