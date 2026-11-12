extends RefCounted
## Authored pipe and water textures; gameplay owns the rain clock and target sampling.
const MANIFEST := "res://assets/specials/main-break-rain-v1/manifest.json"
var definition: Dictionary = {}
var pipe: Texture2D
var water: Texture2D
var collapse: Texture2D
var compact: Texture2D

func prepare() -> void:
	if not definition.is_empty(): return
	definition = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	pipe = cleaned_texture(definition.pipe.texture)
	water = load(definition.water.texture)
	collapse = cleaned_texture(definition.collapse.texture)
	if definition.has("collapse_compact"):
		compact = cleaned_texture(definition.collapse_compact.texture)

func cleaned_texture(path: String) -> Texture2D:
	var source: Texture2D = load(path)
	var pixels := source.get_image()
	pixels.convert(Image.FORMAT_RGBA8)
	var bytes := pixels.get_data()
	for index in range(3,bytes.size(),4):
		if bytes[index] < 16: bytes[index] = 0
	return ImageTexture.create_from_image(Image.create_from_data(
		pixels.get_width(),pixels.get_height(),false,Image.FORMAT_RGBA8,bytes))

func supported_bounds(bounds: Rect2, anchor: Vector2, solids: Array[Rect2]) -> bool:
	var supported := false
	for solid: Rect2 in solids:
		if absf(solid.position.y-anchor.y) < .1 and solid.position.x <= bounds.position.x and solid.end.x >= bounds.end.x:
			supported = true
		if bounds.grow(-.01).intersects(solid): return false
	return supported

func collapse_bounds(anchor: Vector2, facing: float, variant: String) -> Rect2:
	var bounds := pipe_bounds(anchor)
	for frame: Dictionary in definition[variant].frames:
		var body := rectangle(frame.native_destination_relative_floor)
		if facing < 0: body.position.x = -body.end.x
		body.position += anchor
		bounds = bounds.merge(body)
	return bounds

func placement_clear(anchor: Vector2, solids: Array[Rect2]) -> bool:
	prepare()
	if not supported_bounds(pipe_bounds(anchor),anchor,solids): return false
	# The compact fold stays connected to the supported base; a few pixels of bolt overhang are retained.
	if definition.has("collapse_compact"):
		var compact_bounds := collapse_bounds(anchor,1,"collapse_compact")
		for solid: Rect2 in solids:
			if compact_bounds.grow(-.01).intersects(solid): return false
	return true

func spent_variant(state: Dictionary, solids: Array[Rect2]) -> String:
	prepare()
	return "rain" if supported_bounds(collapse_bounds(state.anchor,state.facing,"collapse"),state.anchor,solids) else "rain_compact"

func draw_spent(host: Node2D, state: Dictionary) -> void:
	prepare()
	var age: float = state.spent_age
	if age < .09:
		draw_pipe(host,state.anchor)
		return
	var remaining := age-.09
	var use_compact: bool = state.spent_variant == "rain_compact"
	var frames: Array = definition["collapse_compact" if use_compact else "collapse"].frames
	var frame: Dictionary = frames[-1]
	for candidate: Dictionary in frames:
		frame = candidate
		if remaining < float(candidate.duration_seconds): break
		remaining -= float(candidate.duration_seconds)
	var destination := rectangle(frame.native_destination_relative_floor)
	var facing: float = state.facing
	host.draw_set_transform(state.anchor-Vector2(floorf(host.camera_x),0),0,Vector2(facing,1))
	host.draw_texture_rect_region(compact if use_compact else collapse,destination,rectangle(frame.source_rect))
	host.draw_set_transform(Vector2(-floorf(host.camera_x),0))

func rectangle(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])

func pipe_bounds(anchor: Vector2) -> Rect2:
	prepare()
	var spec: Dictionary = definition.pipe
	var source := rectangle(spec.source_rect)
	var foot := Vector2(spec.foot_source[0],spec.foot_source[1])
	return Rect2(anchor+(source.position-foot)*float(spec.uniform_scale),source.size*float(spec.uniform_scale))

func reveal_offset(time: float, costume: String, timeline: Dictionary) -> float:
	if time >= 3.2: return 0
	var lift := 0.0
	var poses: Dictionary = timeline.sean.poses_by_costume[costume]
	for beat: Dictionary in timeline.sean.sequence:
		if time < float(beat.start) or time >= float(beat.end): continue
		var pose: Dictionary = poses.get(beat.pose,{})
		if pose.has("source_cup_contact"):
			lift = (float(pose.source_feet_pivot[1])-float(pose.source_cup_contact[1]))*float(pose.scale)
		break
	if time >= 3.08: lift = lerpf(43.35,150.44,smoothstep(3.08,3.2,time))
	return 150.44-lift

func draw_pipe(host: Node2D, anchor: Vector2, offset := 0.0) -> void:
	var source := rectangle(definition.pipe.source_rect)
	var destination := pipe_bounds(anchor)
	destination.position.y += offset
	# Translate the full-size pipe through the floor; never squash it to simulate emergence.
	var height := clampf(anchor.y-destination.position.y,0,destination.size.y)
	if height <= 0: return
	source.size.y *= height/destination.size.y
	destination.size.y = height
	host.draw_texture_rect_region(pipe,destination,source)

func draw_geyser(host: Node2D, anchor: Vector2, time: float) -> void:
	var outlet := anchor+Vector2(0,float(definition.pipe.outlet_native_from_foot[1]))
	var strength := smoothstep(3.2,3.26,time)
	for layer in range(2):
		var source := rectangle(definition.water["geyser_a_rect" if layer == 0 else "geyser_b_rect"])
		# Authored water moves continuously; the mouth remains fixed under the front pipe lip.
		var scale := Vector2(.43+sin(time*31+layer)*.012,.82+sin(time*23+layer)*.015)
		var destination := Rect2(outlet-Vector2(310,608)*scale,source.size*scale)
		host.draw_texture_rect_region(water,destination,source,Color(1,1,1,strength*(.8 if layer == 0 else .35)))

func draw_cinematic_pipe(host: Node2D, timeline: Dictionary) -> void:
	prepare()
	var time: float = host.cinematic.elapsed
	if time < 2.7: return
	var anchor: Vector2 = host.cinematic_feet+Vector2(44*host.cinematic_facing,0)
	draw_pipe(host,anchor,reveal_offset(time,host.cinematic_costume,timeline))
	if time >= 3.2:
		draw_geyser(host,anchor,time)
		# Only the near lip occludes the stream; the dark mouth must not cover its origin.
		var scale: float = definition.pipe.uniform_scale
		var source := Rect2(75,210,843,240)
		var foot := Vector2(definition.pipe.foot_source[0],definition.pipe.foot_source[1])
		host.draw_texture_rect_region(pipe,Rect2(anchor+(source.position-foot)*scale,source.size*scale),source)

func draw_active_pipe(host: Node2D) -> void:
	prepare()
	draw_pipe(host,host.specials.anchor)

func draw_rain(host: Node2D) -> void:
	prepare()
	var time: float = host.specials.elapsed
	var alpha := minf(clampf(time/.1,0,1),clampf((7.5-time)/.6,0,1))
	var source := rectangle(definition.water.rain_rect)
	# Small copies of the authored sparse streak field scroll independently across the playfield.
	var size := Vector2(definition.water.rain_native_tile_size[0],definition.water.rain_native_tile_size[1])
	for column in range(9):
		var x := float(host.camera_x)+column*120-35+fmod(time*float(definition.water.rain_scroll_speed[0]),20)
		var phase := fposmod(time*float(definition.water.rain_scroll_speed[1])+column*73,size.y)
		for row in range(4):
			var destination := Rect2(Vector2(x,80+row*size.y+phase-size.y),size)
			var visible := destination.intersection(Rect2(host.camera_x,80,960,460))
			if not visible.has_area(): continue
			var uv := Rect2((visible.position-destination.position)/size,visible.size/size)
			var crop := Rect2(source.position+uv.position*source.size,uv.size*source.size)
			host.draw_texture_rect_region(water,visible,crop,Color(1,1,1,alpha*.52))
	var splash := rectangle(definition.water.splash_rect)
	var solids: Array[Rect2] = host.special_solids()
	for index in range(28):
		var x := float(host.camera_x)+index*36+fmod(index*31,37)
		var contact := 10000.0
		for solid: Rect2 in solids:
			if x >= solid.position.x and x < solid.end.x and solid.position.y >= 100:
				contact = minf(contact,solid.position.y)
		if contact > 540: continue
		var phase := fposmod(time*2.8+index*.37,1)
		var width := 26+phase*14
		host.draw_texture_rect_region(water,Rect2(x-width/2,contact-18,width,18),splash,
			Color(1,1,1,alpha*(1-phase)*.85))
