extends RefCounted
## Source-art compositing only. Caller retains world transform and simulation clock.
const MANIFEST := "res://assets/world/pit-water-transition-v1/manifest.json"
var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
var textures: Dictionary = {}

func channel_exclusions(pits: Array) -> Array[Vector2]:
	## The outlet supplies water inside its mouth; the channel behind its elbow is dry.
	var result: Array[Vector2] = []
	var outlet: Dictionary = manifest.right_outlet
	var aperture := _rect(outlet.mouth_aperture_source)
	var mouth_end := 154.0 + float(outlet.destination[0]) + aperture.end.x * float(outlet.uniform_scale)
	for opening: Vector2 in pits:
		result.append(Vector2(opening.y, opening.y + mouth_end))
	return result

func _init() -> void:
	manifest.right_outlet = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/pit-water-transition-v1/outlet-contract-v2.json"))

func prepare(_host: Node, yield_frame := Callable()) -> void:
	for id in ["left_spill", "right_outlet"]:
		var entry: Dictionary = manifest[id]
		var original: Texture2D = load("res://" + entry.path)
		var image := original.get_image()
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				var color := image.get_pixel(x, y)
				var alpha := color.a * 255.0
				color.a = clampf((alpha - 160.0) / 94.0, 0, 1) if id == "left_spill" else (1.0 if alpha >= 240 else 0.0)
				image.set_pixel(x, y, color)
		textures[id] = ImageTexture.create_from_image(image)
		if yield_frame.is_valid(): await yield_frame.call()
	# Keep the original rim pixels, removing only the registered elliptical mouth interior.
	var front: Image = textures.right_outlet.get_image()
	var aperture := _rect(manifest.right_outlet.mouth_aperture_source)
	for y in range(int(aperture.position.y), int(aperture.end.y)):
		for x in range(int(aperture.position.x), int(aperture.end.x)):
			var unit := (Vector2(x + 0.5, y + 0.5) - aperture.get_center()) / (aperture.size * 0.5)
			if unit.length_squared() < 1:
				var color := front.get_pixel(x, y)
				color.a = 0
				front.set_pixel(x, y, color)
	textures.front = ImageTexture.create_from_image(front)

func draw(host: Node2D, opening: Vector2) -> void:
	if textures.is_empty() or not host.wastewater_art.ready: return
	for command: Dictionary in commands(host.wastewater_art, opening, host.elapsed):
		var texture: Texture2D
		if command.id == "water-a":
			texture = host.wastewater_art.textures[host.wastewater_art.assets["water-a"].path]
		else:
			texture = textures[command.id]
		host.draw_texture_rect_region(texture, command.rect, command.source, Color(1, 1, 1, command.alpha))

func commands(water: RefCounted, opening: Vector2, clock: float) -> Array[Dictionary]:
	## Pure draw plan: pause freezes phase; dry samples emit no pipe or water.
	var output: Array[Dictionary] = []
	var left: Dictionary = water.profile.sample(opening.x - 0.01)
	var right: Dictionary = water.profile.sample(opening.y + 0.01)
	if left.water > 0:
		var spill: Dictionary = manifest.left_spill
		var phase := fposmod(maxf(clock, 0) / float(spill.frame_seconds), spill.frames.size())
		var index := int(floorf(phase))
		var blend := phase - index
		var origin := Vector2(opening.x, 520 - 56 * float(left.water))
		var bounds := Rect2(opening.x - 12, 440, 38, 100)
		for offset in 2:
			var frame: Dictionary = spill.frames[(index + offset) % spill.frames.size()]
			var destination := _rect(frame.destination)
			destination.position += origin
			var strength := float(left.water) * (1 - blend if offset == 0 else blend)
			# Narrow strips feather only the channel join, preserving the falling source silhouette.
			for column in 38:
				var clip := Rect2(bounds.position + Vector2(column, 0), Vector2(1, 100))
				_add(output, "left_spill", destination, _rect(frame.source_rect), clip,
					strength * minf((column + 0.5) / 4.0, 1))
	if right.water > 0:
		var outlet: Dictionary = manifest.right_outlet
		var origin := Vector2(opening.y + 154, 492)
		var destination := _rect(outlet.destination)
		destination.position += origin
		var bounds := Rect2(destination.position.x, 440, destination.size.x + 60, 100)
		_add(output, "right_outlet", destination, _rect(outlet.source_rect), bounds, 1)
		var aperture := _rect(outlet.mouth_aperture_source)
		aperture.position = destination.position + aperture.position * float(outlet.uniform_scale)
		aperture.size *= float(outlet.uniform_scale)
		var source: Rect2 = water.assets["water-a"].source
		for column in 96:
			var x := aperture.position.x + column
			var top := 520 - 56 * float(right.water)
			var bottom := 520.0
			# Art: clip only inside the measured aperture; continue at its edge.
			if x + 0.5 < aperture.end.x:
				var unit := (x + 0.5 - aperture.get_center().x) / (aperture.size.x * 0.5)
				if absf(unit) >= 1: continue
				var half := sqrt(1 - unit * unit) * aperture.size.y * 0.5
				top = maxf(top, aperture.get_center().y - half)
				bottom = minf(bottom, aperture.get_center().y + half)
			if bottom <= top: continue
			var local := fposmod(x - maxf(clock, 0) * float(right.flow), 480.0)
			var strip := Rect2(source.position + Vector2(local * source.size.x / 480.0,
				(top - 464.0) * source.size.y / 56.0),
				Vector2(source.size.x / 480.0, (bottom - top) * source.size.y / 56.0))
			_add(output, "water-a", Rect2(x, top, 1, bottom - top), strip, bounds,
				float(right.water) * minf((96.0 - column - 0.5) / 8.0, 1))
		_add(output, "front", destination, _rect(outlet.source_rect), bounds, 1)
	return output

func _add(output: Array[Dictionary], id: String, destination: Rect2, source: Rect2,
		bounds: Rect2, alpha: float) -> void:
	var clipped := destination.intersection(bounds)
	if not clipped.has_area() or alpha <= 0: return
	var ratio := source.size / destination.size
	source.position += (clipped.position - destination.position) * ratio
	source.size = clipped.size * ratio
	output.append({"id":id, "rect":clipped, "source":source, "alpha":alpha})

func _rect(values: Array) -> Rect2:
	return Rect2(values[0], values[1], values[2], values[3])
