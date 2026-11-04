extends RefCounted
## Text-free, shared health and selected-hero life indicators.
const ROOT := "res://assets/ui/vitals-themes-v1/"
const SpecialHUD = preload("res://scripts/special_hud.gd")
var special_hud := SpecialHUD.new()
var themes: Dictionary = {}

func components(theme: String) -> Dictionary:
	if themes.has(theme): return themes[theme]
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+theme+"-manifest-v1.json"))
	var source: Texture2D = load(ROOT+theme+"-source-v1.png")
	var original := source.get_image()
	var output := {}
	for key in manifest.source_rects:
		if key in ["backing","shelf"]: continue
		var r: Array = manifest.source_rects[key]
		var pixels := clean_crop(original,Rect2i(r[0],r[1],r[2],r[3]))
		var component: String = "portrait_socket" if key == "portrait_rim" else key
		var size := Vector2i(320,112) if component == "housing" else Vector2i(52,52) if component == "portrait_socket" else Vector2i(32,32)
		output[component] = ImageTexture.create_from_image(on_canvas(pixels,size,
			theme == "rubber-ducks" and component.begins_with("health_")))
	if theme == "chain": output.housing = ImageTexture.create_from_image(chain_housing(original))
	if theme == "rubber-ducks": output.housing = ImageTexture.create_from_image(duck_housing(original,manifest))
	if theme in ["chain","rubber-ducks"]:
		var replacements: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"readability-components-v2.json"))
		var replacement_source: Texture2D = load(ROOT+"readability-components-v2.png")
		var keys := {"health_depleted":"chain_depleted","portrait_socket":"plug_rim"} if theme == "chain" else {"health_depleted":"duck_depleted","portrait_socket":"dish_rim"}
		for component in keys:
			var r: Array = replacements.source_rects[keys[component]]
			var pixels := clean_crop(replacement_source.get_image(),Rect2i(r[0],r[1],r[2],r[3]))
			var size := Vector2i(52,52) if component == "portrait_socket" else Vector2i(32,32)
			output[component] = ImageTexture.create_from_image(on_canvas(pixels,size,component == "health_depleted"))
	themes[theme] = output
	return output

func clean_crop(original: Image, region: Rect2i) -> Image:
	var pixels := original.get_region(region)
	pixels.convert(Image.FORMAT_RGBA8)
	# Art-approved haze removal; keep original atlas bytes intact.
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			if pixels.get_pixel(x,y).a < 240.0/255.0: pixels.set_pixel(x,y,Color.TRANSPARENT)
	return pixels

func on_canvas(pixels: Image, size: Vector2i, bottom_aligned := false) -> Image:
	var scale := minf(float(size.x)/pixels.get_width(),float(size.y)/pixels.get_height())
	pixels.resize(maxi(1,roundi(pixels.get_width()*scale)),maxi(1,roundi(pixels.get_height()*scale)),Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create_empty(size.x,size.y,false,Image.FORMAT_RGBA8)
	var offset := (size-pixels.get_size())/2
	if bottom_aligned: offset.y = size.y-pixels.get_height()
	canvas.blit_rect(pixels,Rect2i(Vector2i.ZERO,pixels.get_size()),offset)
	return canvas

func chain_housing(original: Image) -> Image:
	var canvas := Image.create_empty(320,112,false,Image.FORMAT_RGBA8)
	# Art-approved source-link assembly keeps both rows physically attached at this compact size.
	var pieces := [
		[Rect2i(466,155,72,68),Rect2i(54,16,16,14)],
		[Rect2i(466,155,72,68),Rect2i(54,36,16,18)],
		[Rect2i(84,111,398,194),Rect2i(0,16,60,29)],
		[Rect2i(535,150,790,44),Rect2i(60,12,252,14)],
		[Rect2i(535,245,657,43),Rect2i(60,44,200,13)]
	]
	for piece in pieces:
		var region: Rect2i = piece[0]
		var destination: Rect2i = piece[1]
		var pixels := on_canvas(clean_crop(original,region),destination.size)
		canvas.blend_rect(pixels,Rect2i(Vector2i.ZERO,pixels.get_size()),destination.position)
	return canvas

func duck_housing(original: Image, manifest: Dictionary) -> Image:
	var canvas := Image.create_empty(320,112,false,Image.FORMAT_RGBA8)
	for key in ["backing","shelf"]:
		var r: Array = manifest.source_rects[key]
		var d: Array = manifest.layout[key]
		var destination := Rect2i(roundi(d[0]*2),roundi(d[1]*2),roundi(d[2]*2),roundi(d[3]*2))
		var pixels := on_canvas(clean_crop(original,Rect2i(r[0],r[1],r[2],r[3])),destination.size)
		canvas.blend_rect(pixels,Rect2i(Vector2i.ZERO,pixels.get_size()),destination.position)
	return canvas

func fitted(texture: Texture2D, bounds: Rect2) -> Rect2:
	var size := texture.get_size()
	size *= minf(bounds.size.x/size.x,bounds.size.y/size.y)
	return Rect2(bounds.position+(bounds.size-size)*0.5,size)

func commands(game: Node2D, origin: Vector2, theme := "dispenser") -> Array[Dictionary]:
	var art := components(theme)
	var output: Array[Dictionary] = []
	output.append({"kind":"housing","texture":art.housing,
		"rect":fitted(art.housing,Rect2(origin,Vector2(160,56)))})
	for index in range(game.employee.max_health):
		var filled: bool = index < game.health
		var texture: Texture2D = art.health_active if filled else art.health_depleted
		output.append({"kind":"health","filled":filled,"texture":texture,
			"rect":fitted(texture,Rect2(origin+Vector2(34+18*index,8),Vector2(16,16)))})
	var renderer = game.world_art.hero_aim_art
	var icon: Dictionary = renderer.animations.heroes[game.employee.id].head_icon
	var r: Array = icon.source_rect
	var source := Rect2(r[0],r[1],r[2],r[3])
	for index in range(game.lives):
		var socket := Rect2(origin+Vector2(38+28*index,25),Vector2(26,26))
		var portrait_size: Vector2 = source.size*(16.0/maxf(source.size.x,source.size.y))
		output.append({"kind":"portrait","hero":game.employee.id,"texture":renderer.textures[icon.path],
			"source":source,"rect":Rect2(socket.get_center()-portrait_size*0.5,portrait_size)})
		output.append({"kind":"socket","texture":art.portrait_socket,
			"rect":fitted(art.portrait_socket,socket)})
	return output

func draw(game: Node2D, origin: Vector2, theme := "dispenser") -> void:
	for item in commands(game,origin,theme):
		if item.has("source"): game.draw_texture_rect_region(item.texture,item.rect,item.source)
		else: game.draw_texture_rect(item.texture,item.rect,false)
	special_hud.draw(game,origin,theme)
