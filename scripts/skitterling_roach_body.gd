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
var anatomy_reference: Dictionary = {}

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
		if frames[key].has("anatomy"):
			targets[key] = _anatomy_targets(image, frames[key].anatomy)
			continue
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

func _anatomy_targets(image: Image, anatomy: Array) -> Dictionary:
	## Keep insect identities within authored limbs instead of moving them through mouth and belly gaps.
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var shapes: Array[Dictionary] = []
	var groups: Array[String] = []
	var claimed: Dictionary = {}
	for group: Dictionary in anatomy:
		var polygon := PackedVector2Array()
		for vertex: Array in group.polygon: polygon.append(Vector2(vertex[0], vertex[1]))
		var mask := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
		var candidates := PackedVector2Array()
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var point := Vector2(x, y)
				if claimed.has(point) or image.get_pixel(x, y).a < .5: continue
				if not Geometry2D.is_point_in_polygon(point, polygon): continue
				claimed[point] = true
				mask.set_pixel(x, y, image.get_pixel(x, y))
				if x % 2 == 0 and y % 2 == 0: candidates.append(point)
		assert(candidates.size() >= int(group.count), "Authored anatomy must contain enough opaque insect anchors")
		# Silhouette extrema often lie on one-pixel toes or scales. Seed inside the part where possible,
		# so fitted insects retain body mass instead of degenerating into a dotted outline.
		var interior := PackedVector2Array()
		var inset := 3.0 if group.id == "torso_tail" else 1.0
		for point: Vector2 in candidates:
			if _inside(mask, point + Vector2(inset, 0)) and _inside(mask, point - Vector2(inset, 0)) \
					and _inside(mask, point + Vector2(0, inset)) and _inside(mask, point - Vector2(0, inset)):
				interior.append(point)
		if interior.size() >= int(group.count): candidates = interior
		var chosen := _spread_points(candidates, int(group.count))
		var id: String = group.id
		if anatomy_reference.has(id):
			chosen = _match_anatomy(chosen, anatomy_reference[id])
		else:
			anatomy_reference[id] = chosen
		for point: Vector2 in chosen:
			points.append(point)
			groups.append(id)
			var light := clampf(image.get_pixelv(Vector2i(point)).get_luminance() * 2 + .5, .5, 1.2)
			colors.append(Color(light, light, light, 1))
			var shape := _fit_insect(mask, point)
			if id != "torso_tail":
				var axis := Vector2.from_angle(shape.angle)
				var length := minf(_reach(mask, point, axis, 12), _reach(mask, point, -axis, 12))
				var width := minf(_reach(mask, point, axis.orthogonal(), 7), _reach(mask, point, -axis.orthogonal(), 7))
				# The authored insect quad includes long transparent antenna/leg margins. Its opaque
				# body occupies roughly half that extent; fitting the whole quad erases thin anatomy.
				var minimum := Vector2(14, 9) if id in ["upper_jaw", "lower_jaw"] else Vector2(12, 8)
				shape.size = Vector2(clampf(length * 3, minimum.x, 30), clampf(width * 3, minimum.y, 19))
				shape.mobility = 0.0
			else:
				shape.size = Vector2(maxf(20, shape.size.x), maxf(14, shape.size.y))
				shape.mobility = minf(shape.mobility, .35)
			shapes.append(shape)
	assert(points.size() == COUNT, "Authored anatomy must preserve the bounded insect budget")
	return {"points":points, "colors":colors, "shapes":shapes, "groups":groups}

func _spread_points(candidates: PackedVector2Array, count: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	var distances := PackedFloat32Array()
	distances.resize(candidates.size())
	distances.fill(INF)
	var chosen := candidates.size() / 2
	for index in range(count):
		var point := candidates[chosen]
		result.append(point)
		var farthest := -1.0
		for candidate in range(candidates.size()):
			distances[candidate] = minf(distances[candidate], point.distance_squared_to(candidates[candidate]))
			if distances[candidate] > farthest:
				farthest = distances[candidate]
				chosen = candidate
	return result

func _match_anatomy(points: PackedVector2Array, reference: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	var remaining := Array(points)
	# Local normalized coordinates keep identities along a limb when that limb flexes or swings.
	var bounds := Rect2(points[0], Vector2.ONE)
	var reference_bounds := Rect2(reference[0], Vector2.ONE)
	for point: Vector2 in points: bounds = bounds.expand(point)
	for point: Vector2 in reference: reference_bounds = reference_bounds.expand(point)
	for point: Vector2 in reference:
		var wanted := bounds.position + (point - reference_bounds.position) / reference_bounds.size * bounds.size
		var best := 0
		for index in range(1, remaining.size()):
			if wanted.distance_squared_to(remaining[index]) < wanted.distance_squared_to(remaining[best]): best = index
		result.append(remaining[best])
		remaining.remove_at(best)
	return result

func insect_position(key: String, next_key: String, blend: float, index: int, clock: float) -> Vector2:
	# Distance-driven authored feet use linear travel; easing every frame would make planted feet slide.
	var amount := blend if targets[key].has("groups") else smoothstep(0, 1, blend)
	var point: Vector2 = targets[key].points[index].lerp(targets[next_key].points[index], amount)
	var seed := index * 2.399963
	var speed := .22 + fposmod(index * .173, .24)
	# Continuous, independent paths: no texture swapping can move the insect's body.
	var mobility := lerpf(targets[key].shapes[index].mobility, targets[next_key].shapes[index].mobility, blend)
	point += Vector2(sin(clock * speed + seed), cos(clock * speed + seed)) * mobility
	return point

func draw(host: CanvasItem, key: String, next_key: String, blend: float, origin: Vector2,
		facing: int, clock: float, underwater := false, water_top := 456.0, pipe: Dictionary = {}, deterministic := false,
		body_scale := 1.0, overrides: Dictionary = {}) -> void:
	var counts := [0, 0, 0, 0]
	var reset := clock == 0 or previous_clock < 0 or clock < previous_clock or clock - previous_clock > .5
	var weight := 1.0 if reset else 1.0 - exp(-18.0 * maxf(0, clock - previous_clock))
	if displayed.is_empty(): displayed.resize(COUNT)
	for index in range(COUNT):
		var pose := pose_keys(key, next_key, blend, index, overrides)
		var point := insect_position(pose.key, pose.next_key, pose.blend, index, clock if pipe.is_empty() else 0.0)
		if pipe.is_empty() and not deterministic: point = displayed[index].lerp(point, weight)
		displayed[index] = point
		var angle := insect_angle(index, clock if pipe.is_empty() else 0.0)
		var size := insect_size(index)
		if pipe.is_empty():
			var shape := insect_shape(pose.key, pose.next_key, pose.blend, index, clock)
			angle = shape.angle
			size = shape.size
		point -= Vector2(192, 224)
		if facing > 0:
			point.x = -point.x
			angle = PI - angle
		point *= body_scale
		size *= body_scale
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
		var tint: Color = targets[pose.key].colors[index].lerp(targets[pose.next_key].colors[index], pose.blend)
		if underwater: tint *= Color(.65, .85, .85, .85)
		meshes[phase].set_instance_color(counts[phase], tint)
		counts[phase] += 1
	previous_clock = clock
	for phase in range(4):
		meshes[phase].visible_instance_count = counts[phase]
		host.draw_multimesh(meshes[phase], insect_textures[posmod(int(clock * 8) + phase, 4)])

func pose_keys(key: String, next_key: String, blend: float, index: int, overrides: Dictionary = {}) -> Dictionary:
	## Jaw pose may advance independently while the same insect groups continue a grounded gait.
	if not overrides.is_empty() and targets[key].has("groups"):
		var group: String = targets[key].groups[index]
		if overrides.has(group): return overrides[group]
	return {"key":key, "next_key":next_key, "blend":blend}

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
	var sway := .3 if minf(a.size.y, b.size.y) > 14 else .06
	if targets[key].has("groups"):
		sway = .06 if targets[key].groups[index] == "torso_tail" else 0.0
	return {"size":Vector2(a.size).lerp(b.size, amount),
		"angle":lerp_angle(a.angle, b.angle, amount) + sin(clock * .35 + index) * sway}
