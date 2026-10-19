extends RefCounted
## The silhouette is a placement guide only: every visible body pixel comes from an insect sprite.
const COUNT := 140
const EXTENT := 24.0
static var prepared_targets: Dictionary = {}
static var prepared_cells: Dictionary = {}
var targets: Dictionary = {}
var insect_textures: Array[Texture2D] = []
var insect_images: Array[Image] = []
var meshes: Array[MultiMesh] = []
var displayed := PackedVector2Array()
var previous_clock := -1.0

func prepare(frames: Dictionary, insect_source: Image) -> void:
	for phase in range(4):
		var columns := [0, 313, 627, 940, 1254]
		var image := insect_source.get_region(Rect2i(columns[phase], 0, columns[phase + 1] - columns[phase], 313))
		var insect := image.get_region(image.get_used_rect())
		insect_images.append(insect)
		insect_textures.append(ImageTexture.create_from_image(insect))
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_2D
		mesh.use_colors = true
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		mesh.mesh = quad
		mesh.instance_count = COUNT
		meshes.append(mesh)
	if prepared_cells.is_empty():
		for index in range(COUNT):
			for facing in [-1, 1]:
				var angle := insect_angle(index, 0.0)
				if facing > 0: angle = PI - angle
				var cells: Array[Rect2] = []
				for y in range(-16, 17, 4):
					for x in range(-16, 17, 4):
						var cell := Rect2(Vector2(x, y), Vector2(4, 4))
						if opaque_cell(cell, Vector2.ZERO, insect_size(index), angle): cells.append(cell)
				prepared_cells[Vector2i(index, facing)] = cells
	if not prepared_targets.is_empty():
		targets = prepared_targets
		return
	for key: String in frames:
		if key.begins_with("roach-layers"): continue
		var image: Image = frames[key].image
		var pixels := PackedVector2Array()
		var shades := PackedColorArray()
		# Scanline quantiles give each insect a consistent rank across differently shaped poses.
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color := image.get_pixel(x, y)
				if color.a > .5:
					pixels.append(Vector2(x, y))
					shades.append(color)
		# Spread anchors over the entire silhouette, including narrow tails, ears and toes.
		var candidates := PackedVector2Array()
		for point: Vector2 in pixels:
			if int(point.x) % 4 == 0 and int(point.y) % 4 == 0: candidates.append(point)
		if candidates.size() < COUNT: candidates = pixels
		var points := PackedVector2Array()
		var distances := PackedFloat32Array()
		distances.resize(candidates.size())
		distances.fill(INF)
		var chosen := candidates.size() / 2
		for index in range(COUNT):
			var point := candidates[chosen]
			points.append(point)
			var farthest := -1.0
			for candidate in range(candidates.size()):
				distances[candidate] = minf(distances[candidate], point.distance_squared_to(candidates[candidate]))
				if distances[candidate] > farthest:
					farthest = distances[candidate]
					chosen = candidate
		var sorted: Array = Array(points)
		sorted.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
		points = PackedVector2Array(sorted)
		var colors := PackedColorArray()
		var shapes: Array[Dictionary] = []
		for point: Vector2 in points:
			var shade := image.get_pixelv(Vector2i(point))
			var light := clampf(shade.get_luminance() * 2.0 + .5, .5, 1.2)
			colors.append(Color(light, light, light, 1))
			shapes.append(_fit_insect(image, point))
		targets[key] = {"points":points, "colors":colors, "shapes":shapes}
	prepared_targets = targets

func insect_position(key: String, next_key: String, blend: float, index: int, clock: float) -> Vector2:
	var point: Vector2 = targets[key].points[index].lerp(targets[next_key].points[index], smoothstep(0, 1, blend))
	var seed := index * 2.399963
	var speed := .22 + fposmod(index * .173, .24)
	# Continuous, independent paths: no texture swapping can move the insect's body.
	var mobility := lerpf(targets[key].shapes[index].mobility, targets[next_key].shapes[index].mobility, blend)
	point += Vector2(sin(clock * speed + seed), cos(clock * speed + seed)) * mobility
	return point

func draw(host: CanvasItem, key: String, next_key: String, blend: float, origin: Vector2,
		facing: int, clock: float, underwater := false, water_top := 456.0, pipe: Dictionary = {}) -> void:
	var counts := [0, 0, 0, 0]
	var reset := clock == 0 or previous_clock < 0 or clock < previous_clock or clock - previous_clock > .5
	var weight := 1.0 if reset else 1.0 - exp(-18.0 * maxf(0, clock - previous_clock))
	if displayed.is_empty(): displayed.resize(COUNT)
	for index in range(COUNT):
		var point := insect_position(key, next_key, blend, index, clock if pipe.is_empty() else 0.0)
		if pipe.is_empty(): point = displayed[index].lerp(point, weight)
		displayed[index] = point
		var angle := insect_angle(index, clock if pipe.is_empty() else 0.0)
		var size := insect_size(index)
		if pipe.is_empty():
			var shape := insect_shape(key, next_key, blend, index, clock)
			angle = shape.angle
			size = shape.size
		point -= Vector2(192, 224)
		if facing > 0:
			point.x = -point.x
			angle = PI - angle
		point += origin
		var sample := pipe_sample(index, point, pipe)
		if not sample.visible: continue
		point = sample.position
		size *= float(sample.scale)
		# The caller provides room-local water limits through origin; conceal insects above/below water.
		if underwater and (point.y < water_top + 8 or point.y > water_top + 76): continue
		var phase := index % 4
		var transform := Transform2D(Vector2(cos(angle), sin(angle)) * size.x,
			Vector2(-sin(angle), cos(angle)) * size.y, point)
		meshes[phase].set_instance_transform_2d(counts[phase], transform)
		var tint: Color = targets[key].colors[index].lerp(targets[next_key].colors[index], blend)
		if underwater: tint *= Color(.65, .85, .85, .85)
		meshes[phase].set_instance_color(counts[phase], tint)
		counts[phase] += 1
	previous_clock = clock
	for phase in range(4):
		meshes[phase].visible_instance_count = counts[phase]
		host.draw_multimesh(meshes[phase], insect_textures[posmod(int(clock * 8) + phase, 4)])

static func pipe_sample(index: int, point: Vector2, pipe: Dictionary) -> Dictionary:
	if pipe.is_empty(): return {"position":point, "scale":1.0, "visible":true}
	var mouth: Vector2 = pipe.mouth
	var seed := index * 2.399963
	var pocket := mouth + Vector2(cos(seed) * (8 + index % 17), sin(seed) * (3 + index % 7))
	var mode: String = pipe.mode
	if mode == "warning":
		return {"position":pocket + Vector2(sin(float(pipe.get("elapsed", 0)) * 2 + seed) * 2, 5), "scale":.85, "visible":index < 18}
	var progress: float = pipe.progress
	var stagger := float(index % 19) / 19.0 * .35
	var amount := smoothstep(stagger, 1.0, progress)
	if mode == "launch":
		return {"position":pocket.lerp(point, amount), "scale":lerpf(.65, 1, amount), "visible":true}
	var position := point.lerp(pocket, amount)
	var visible := amount < .92
	# Partial occlusion is rendered by the authored rim; only insects fully consumed by the pipe disappear.
	return {"position":position, "scale":lerpf(1, .65, amount), "visible":visible}

static func insect_size(index: int) -> Vector2:
	return Vector2(26.0 + fposmod(index * .731, 6.0), 19.0)

static func insect_angle(index: int, clock: float) -> float:
	var seed := index * 2.399963
	var speed := .22 + fposmod(index * .173, .24)
	return Vector2(cos(clock * speed + seed) * 5, -sin(clock * speed + seed) * 3).angle() + PI

func opaque_cell(cell: Rect2, center: Vector2, size: Vector2, angle: float) -> bool:
	for corner: Vector2 in [cell.position, cell.end, Vector2(cell.end.x, cell.position.y), Vector2(cell.position.x, cell.end.y)]:
		var uv := (corner - center).rotated(-angle) / size + Vector2(.5, .5)
		if uv.x < 0 or uv.x >= 1 or uv.y < 0 or uv.y >= 1: return false
		# Only the stable opaque insect body is targetable, never changing transparent antenna/leg gaps.
		for image: Image in insect_images:
			if image.get_pixelv(Vector2i(uv * Vector2(image.get_size()))).a < .5: return false
	return true

static func _inside(image: Image, point: Vector2) -> bool:
	var p := Vector2i(point.round())
	return p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height() and image.get_pixelv(p).a > .5

static func _reach(image: Image, point: Vector2, direction: Vector2, limit: int) -> float:
	for distance in range(1, limit + 1):
		if not _inside(image, point + direction * distance): return float(distance - 1)
	return float(limit)

static func _fit_insect(image: Image, point: Vector2) -> Dictionary:
	var xx := 0.0
	var yy := 0.0
	var xy := 0.0
	for y in range(-10, 11, 2):
		for x in range(-10, 11, 2):
			if _inside(image, point + Vector2(x, y)):
				xx += x * x
				yy += y * y
				xy += x * y
	var angle := .5 * atan2(2 * xy, xx - yy)
	var axis := Vector2.from_angle(angle)
	var across := axis.orthogonal()
	var length := minf(_reach(image, point, axis, 14), _reach(image, point, -axis, 14))
	var width := minf(_reach(image, point, across, 9), _reach(image, point, -across, 9))
	return {"angle":angle, "size":Vector2(clampf(length * 2 + 4, 8, 30), clampf(width * 2 + 3, 6, 19)),
		"mobility":clampf(minf(length, width) * .15, .2, 1.5)}

func insect_shape(key: String, next_key: String, blend: float, index: int, clock: float) -> Dictionary:
	var a: Dictionary = targets[key].shapes[index]
	var b: Dictionary = targets[next_key].shapes[index]
	var amount := smoothstep(0, 1, blend)
	return {"size":Vector2(a.size).lerp(b.size, amount),
		"angle":lerp_angle(a.angle, b.angle, amount) + sin(clock * .35 + index) * (.3 if minf(a.size.y, b.size.y) > 14 else .06)}
