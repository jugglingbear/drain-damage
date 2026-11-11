extends RefCounted
## Registered artwork follows the same clipped water geometry used for contact damage.
const WATER := "res://assets/specials/starter-v1/water-manifest-v1.json"
const PIPE := "res://assets/specials/starter-v1/pipe-manifest-v2.json"
const SPENT := "res://assets/specials/starter-v1/spent-pipe-collapse-v1.json"
const COMPACT := "res://assets/specials/starter-v1/spent-pipe-compact-v1.json"
const ACTIONS := "res://assets/specials/starter-v1/sean-actions-manifest-v1.json"
var water: Dictionary = {}
var frames: Dictionary = {}
var pipe: Dictionary = {}
var pipe_textures: Dictionary = {}
var spent: Dictionary = {}
var spent_textures: Array[Texture2D] = []
var compact: Dictionary = {}
var compact_textures: Array[Texture2D] = []
var actions: Dictionary = {}
var action_textures: Dictionary = {}

func draw_clipped(game: Node2D, points: PackedVector2Array, uv: PackedVector2Array,
		texture: Texture2D, colors: PackedColorArray) -> void:
	var clean := PackedVector2Array()
	var clean_uv := PackedVector2Array()
	var clean_colors := PackedColorArray()
	for index in range(points.size()):
		if not clean.is_empty() and clean[-1].distance_squared_to(points[index]) < 0.000001: continue
		clean.append(points[index])
		clean_uv.append(uv[index])
		clean_colors.append(colors[0] if colors.size() == 1 else colors[index])
	if clean.size() > 1 and clean[0].distance_squared_to(clean[-1]) < 0.000001:
		clean.resize(clean.size()-1)
		clean_uv.resize(clean_uv.size()-1)
		clean_colors.resize(clean_colors.size()-1)
	if clean.size() < 3: return
	var area := 0.0
	for index in range(clean.size()): area += (clean[index]-clean[0]).cross(clean[(index+1)%clean.size()]-clean[0])
	# Emergence and decay legitimately produce zero-area boundary fragments. Never submit them to the renderer.
	if absf(area) < 0.01 or Geometry2D.triangulate_polygon(clean).is_empty(): return
	game.draw_polygon(clean,clean_colors,clean_uv,texture)

func extracted(original: Image, region: Array) -> Texture2D:
	var pixels := original.get_region(Rect2i(region[0],region[1],region[2],region[3]))
	pixels.convert(Image.FORMAT_RGBA8)
	var bytes := pixels.get_data()
	# Art-approved haze removal only; original source colors and files remain intact.
	for index in range(3,bytes.size(),4):
		if bytes[index] < 240: bytes[index] = 0
	return ImageTexture.create_from_image(Image.create_from_data(
		pixels.get_width(),pixels.get_height(),false,Image.FORMAT_RGBA8,bytes))

func prepare(yield_frame := Callable()) -> void:
	if not water.is_empty(): return
	water = JSON.parse_string(FileAccess.get_file_as_string(WATER))
	var source: Texture2D = load("res://"+water.path)
	var original := source.get_image()
	for group in water.frames:
		frames[group] = []
		for frame: Dictionary in water.frames[group]:
			frames[group].append(extracted(original,frame.source_rect))
			if yield_frame.is_valid(): await yield_frame.call()
	pipe = JSON.parse_string(FileAccess.get_file_as_string(PIPE))
	var source_pipe: Texture2D = load("res://"+pipe.path)
	for key in pipe.layers:
		pipe_textures[key] = extracted(source_pipe.get_image(),pipe.layers[key].source_rect)
		if yield_frame.is_valid(): await yield_frame.call()
	spent = JSON.parse_string(FileAccess.get_file_as_string(SPENT))
	var spent_source: Texture2D = load("res://"+spent.path)
	for frame: Dictionary in spent.frames:
		spent_textures.append(extracted(spent_source.get_image(),frame.source_rect))
		if yield_frame.is_valid(): await yield_frame.call()
	compact = JSON.parse_string(FileAccess.get_file_as_string(COMPACT))
	var compact_source: Texture2D = load("res://"+compact.path)
	for frame: Dictionary in compact.frames:
		compact_textures.append(extracted(compact_source.get_image(),frame.source_rect))
		if yield_frame.is_valid(): await yield_frame.call()
	actions = JSON.parse_string(FileAccess.get_file_as_string(ACTIONS))
	for costume in actions.heroes:
		action_textures[costume] = []
		var poses: Array = actions.heroes[costume].frames
		var atlas: Texture2D = load("res://"+poses[0].path)
		for pose: Dictionary in poses:
			action_textures[costume].append(extracted(atlas.get_image(),pose.source_rect))
			if yield_frame.is_valid(): await yield_frame.call()

func action_pose(time: float, costume: String) -> Dictionary:
	var poses: Array = actions.heroes[costume].frames
	var remaining := time
	for index in range(poses.size()):
		var duration: float = poses[index].duration
		if remaining < duration or index == poses.size()-1:
			return {"index":index,"blend":smoothstep(duration-0.04,duration,remaining)}
		remaining -= duration
	return {"index":5,"blend":1.0}

func pipe_rise(state: Dictionary) -> float:
	if state.elapsed >= 1: return 0
	var costume: String = state.costume
	var pose := action_pose(state.elapsed,costume)
	var poses: Array = actions.heroes[costume].frames
	if pose.index < 3:
		return 48+minf(0,lerpf(poses[pose.index].cup_relative_to_feet[1],
			poses[pose.index+1].cup_relative_to_feet[1],pose.blend))
	var height: float = 48+poses[3].cup_relative_to_feet[1]
	return height*(1-smoothstep(0.85,1,state.elapsed))

func draw_hero(game: Node2D) -> bool:
	var special = game.specials
	if not special.active or special.hero_id != "sean" or special.elapsed >= 1: return false
	var feet: Vector2 = game.player+Vector2(13,46)
	var activation_feet: Vector2 = special.anchor-Vector2(44*special.locked_facing,0)
	# Knockback must not visually tether the hero to a pipe he is no longer reaching.
	if not game.grounded or feet.distance_to(activation_feet) > 4: return false
	var pose := action_pose(special.elapsed,special.costume)
	var poses: Array = actions.heroes[special.costume].frames
	game.draw_ellipse_shadow(feet,Vector2(23,3))
	var basis := Transform2D(Vector2(special.locked_facing,0),Vector2(0,1),Vector2.ZERO)
	basis.origin = feet-Vector2(floorf(game.camera_x),0)-basis*Vector2(64,104)
	game.draw_set_transform_matrix(basis)
	for index in range(2):
		var frame: int = pose.index+index
		if frame >= poses.size(): continue
		var alpha: float = 1-pose.blend if index == 0 else pose.blend
		if alpha <= 0: continue
		var d: Array = poses[frame].destination
		game.draw_texture_rect(action_textures[special.costume][frame],Rect2(d[0],d[1],d[2],d[3]),
			false,Color(1,1,1,alpha))
	if pose.index == 5:
		game.world_art.hero_aim_art.draw(game,Color(1,1,1,pose.blend))
	game.draw_set_transform(Vector2(-floorf(game.camera_x),0))
	return true

func pipe_vertices(state: Dictionary, key: String, crop: Rect2) -> PackedVector2Array:
	var layer: Dictionary = pipe.layers[key]
	var d: Array = layer.destination
	var rectangle := Rect2(d[0],d[1],d[2],d[3])
	var angle: float = state.angle
	var rise := pipe_rise(state)
	var vertices := PackedVector2Array()
	for uv in [crop.position,Vector2(crop.end.x,crop.position.y),crop.end,Vector2(crop.position.x,crop.end.y)]:
		var point: Vector2 = rectangle.position+uv*rectangle.size
		if key == "lower":
			# Deform existing metal continuously: the base stays fixed and the top follows the bend.
			var r: Array = layer.source_rect
			var source_point: Vector2 = Vector2(r[0],r[1])+uv*Vector2(r[2],r[3])
			var t: float = (layer.source_base[1]-source_point.y)/(layer.source_base[1]-layer.source_upper_center[1])
			var across: float = (source_point.x-layer.source_base[0])*64.0/r[2]
			point = Vector2(0,-32*t)+Vector2(across,0).rotated(angle*pow(clampf(t,0,1),1.3))
		elif key != "collar":
			point = Vector2(0,-32)+(point-Vector2(0,-32)).rotated(angle)
		if key != "collar": point.y += rise
		else: point.y *= clampf((48-rise)/8,0,1)
		vertices.append(state.anchor+point)
	return vertices

func draw_pipe_piece(game: Node2D, key: String, state: Dictionary, alpha := 1.0) -> void:
	if state.elapsed <= 0.26 or alpha <= 0: return
	var rows := 16 if key == "lower" else 1
	var columns := 4 if key == "lower" else 1
	for row in range(rows):
		for column in range(columns):
			var crop := Rect2(float(column)/columns,float(row)/rows,1.0/columns,1.0/rows)
			var vertices := pipe_vertices(state,key,crop)
			var uv := PackedVector2Array([crop.position,Vector2(crop.end.x,crop.position.y),crop.end,
				Vector2(crop.position.x,crop.end.y)])
			# Clip each textured triangle at the floor, preserving its UV mapping during emergence.
			for indices in [[0,1,2],[0,2,3]]:
				var points := PackedVector2Array([vertices[indices[0]],vertices[indices[1]],vertices[indices[2]]])
				var tex := PackedVector2Array([uv[indices[0]],uv[indices[1]],uv[indices[2]]])
				var clipped := PackedVector2Array()
				var clipped_uv := PackedVector2Array()
				for index in range(3):
					var previous := (index+2)%3
					var inside: bool = points[index].y <= state.anchor.y
					var previous_inside: bool = points[previous].y <= state.anchor.y
					if inside != previous_inside:
						var fraction: float = (state.anchor.y-points[previous].y)/(points[index].y-points[previous].y)
						clipped.append(points[previous].lerp(points[index],fraction))
						clipped_uv.append(tex[previous].lerp(tex[index],fraction))
					if inside:
						clipped.append(points[index])
						clipped_uv.append(tex[index])
				if clipped.size() >= 3:
					draw_clipped(game,clipped,clipped_uv,pipe_textures[key],PackedColorArray([Color(1,1,1,alpha)]))

func spent_variant(state: Dictionary, solids: Array[Rect2]) -> String:
	for frame: Dictionary in spent.frames:
		var d: Array = frame.opaque_bounds_relative
		var body := Rect2(d[0],d[1],d[2],d[3])
		if state.angle < 0: body.position.x = -body.end.x
		body.position += state.anchor
		for solid: Rect2 in solids:
			if body.grow(-0.001).intersects(solid): return "compact"
	return "normal"

func spent_pose(age: float, variant := "normal") -> Dictionary:
	var contract := compact if variant == "compact" else spent
	var handoff: float = contract.handoff_seconds if variant == "compact" else contract.handoff.seconds
	if age < handoff:
		return {"index":0,"next":0,"blend":0.0,"mesh_alpha":1-smoothstep(0,handoff,age)}
	var remaining := age-handoff
	for index in range(contract.frames.size()-1):
		var duration: float = contract.frames[index].duration_seconds
		if remaining < duration:
			return {"index":index,"next":index+1,"blend":smoothstep(0,duration,remaining),"mesh_alpha":0.0}
		remaining -= duration
	return {"index":int(contract.settled_frame),"next":int(contract.settled_frame),"blend":0.0,"mesh_alpha":0.0}

func draw_spent_pipe(game: Node2D, state: Dictionary) -> void:
	# Keep the existing opaque pipe until Art approves a physical collapse transition.
	for key in ["lower","upper_back","front_rim","collar"]:
		draw_pipe_piece(game,key,state)

func draw_back(game: Node2D) -> void:
	for state: Dictionary in game.specials.spent_pipes: draw_spent_pipe(game,state)
	if game.has_method("start_special_cinematic") and game.cinematic.active: return
	if not game.specials.active or game.specials.hero_id != "sean": return
	draw_pipe_piece(game,"lower",game.specials.pipe_state())
	draw_pipe_piece(game,"upper_back",game.specials.pipe_state())

func draw_front(game: Node2D) -> void:
	if game.has_method("start_special_cinematic") and game.cinematic.active: return
	draw_water(game)
	if game.specials.active and game.specials.hero_id == "sean":
		draw_pipe_piece(game,"front_rim",game.specials.pipe_state())
		draw_pipe_piece(game,"collar",game.specials.pipe_state())

func water_patch(game: Node2D, texture: Texture2D, destination: Rect2, segment: Dictionary,
		color := Color.WHITE, role := "bloom") -> void:
	var origin: Vector2 = segment.origin
	var direction: Vector2 = (segment.end-origin).normalized()
	var basis := Transform2D(direction.angle(),origin)
	var inverse := basis.affine_inverse()
	var bounds := Rect2(0,-float(segment.width)*0.5,origin.distance_to(segment.end),segment.width)
	var crop := destination.intersection(bounds)
	if not crop.has_area(): return
	var viewport: Rect2 = segment.clip
	var clip := PackedVector2Array([viewport.position,Vector2(viewport.end.x,viewport.position.y),
		viewport.end,Vector2(viewport.position.x,viewport.end.y)])
	# Short textured strips provide local alpha ramps without stretching or repainting the source water.
	var x := crop.position.x
	while x < crop.end.x:
		var right := minf(x+8,crop.end.x)
		var quad := PackedVector2Array([basis*Vector2(x,crop.position.y),basis*Vector2(right,crop.position.y),
			basis*Vector2(right,crop.end.y),basis*Vector2(x,crop.end.y)])
		for polygon in Geometry2D.intersect_polygons(quad,clip):
			var uv := PackedVector2Array()
			var colors := PackedColorArray()
			for point in polygon:
				var local: Vector2 = inverse*point
				uv.append((local-destination.position)/destination.size)
				var alpha := color.a
				if role == "core":
					alpha *= clampf((local.x-destination.position.x)/8,0,1)
					if game.specials.hero_id == "tony": alpha *= smoothstep(16,40,local.x)
				else:
					alpha *= clampf((destination.end.x-local.x)/16,0,1)
				colors.append(Color(color.r,color.g,color.b,alpha))
			draw_clipped(game,polygon,uv,texture,colors)
		x = right

func draw_water(game: Node2D) -> void:
	var special = game.specials
	if not special.active: return
	prepare()
	var clock: float = special.elapsed/0.06
	var frame := int(clock)%4
	var blend := fmod(clock,1.0)
	var strength: float = special.water_width()/float(water.nominal_core_thickness)
	for segment in special.water_segments(game):
		var length: float = segment.origin.distance_to(segment.end)
		var start := 24.0-fmod(special.elapsed*220,120.0)
		while start < length:
			var rectangle := Rect2(start,-32*strength,128,64*strength)
			water_patch(game,frames.core[frame],rectangle,segment,Color.WHITE,"core")
			water_patch(game,frames.core[(frame+1)%4],rectangle,segment,Color(1,1,1,blend),"core")
			start += 120
		var bloom := Rect2(-2,-32*strength,128,64*strength)
		if special.hero_id == "tony":
			# The fourth generated bloom has a square inlet; Art approved only the first three here.
			var bloom_frame := int(clock)%3
			water_patch(game,frames.bloom[bloom_frame],bloom,segment)
			water_patch(game,frames.bloom[(bloom_frame+1)%3],bloom,segment,Color(1,1,1,blend))
		else:
			water_patch(game,frames.bloom[3],bloom,segment)
	game.draw_set_transform(Vector2(-floorf(game.camera_x),0))
