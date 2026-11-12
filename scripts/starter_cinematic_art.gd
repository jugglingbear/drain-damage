extends RefCounted
## Presentation-only rendering; the host owns freezing, clocks, audio and damage handoff.
const ROOT := "res://assets/specials/activation-cinematics-v1/"
const SpecialArt = preload("res://scripts/starter_special_art.gd")
var timeline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"candidate-timeline.json"))
var gauge: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"gauge-manifest.json"))
var poses: Dictionary = {}
var components: Dictionary = {}

func vector(values: Array) -> Vector2:
	return Vector2(values[0],values[1])

func rectangle(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])

func prepare(yield_frame := Callable()) -> void:
	if not components.is_empty(): return
	var extractor := SpecialArt.new()
	var sources: Dictionary = {}
	for costume in timeline.sean.poses_by_costume:
		poses[costume] = {}
		for id in timeline.sean.poses_by_costume[costume]:
			var pose: Dictionary = timeline.sean.poses_by_costume[costume][id]
			if not sources.has(pose.source):
				var texture: Texture2D = load("res://"+pose.source)
				sources[pose.source] = texture.get_image()
			poses[costume][id] = extractor.extracted(sources[pose.source],pose.source_rect)
			if yield_frame.is_valid(): await yield_frame.call()
	var atlas: Texture2D = load("res://"+gauge.path)
	var pixels := atlas.get_image()
	for id in ["housing","needle","wheel"]:
		components[id] = extractor.extracted(pixels,gauge[id].source_rect)
		if yield_frame.is_valid(): await yield_frame.call()

func pose_id(elapsed: float) -> String:
	for beat: Dictionary in timeline.sean.sequence:
		if elapsed < float(beat.end): return beat.pose
	return "gameplay_pose"

func pose_transform(pose: Dictionary, feet: Vector2, facing: int) -> Transform2D:
	var scale: float = pose.scale
	var basis := Transform2D(Vector2(scale*facing,0),Vector2(0,scale),Vector2.ZERO)
	basis.origin = feet-basis*vector(pose.source_feet_pivot)
	return basis

func framing_bounds(costume: String, feet: Vector2, facing: int) -> Rect2:
	# Use the complete sequence envelope so camera framing never pops when the held pose changes.
	var bounds := Rect2(feet-Vector2(24,48),Vector2(48,48))
	for pose: Dictionary in timeline.sean.poses_by_costume[costume].values():
		var size := Vector2(pose.source_rect[2],pose.source_rect[3])
		bounds = bounds.merge(pose_transform(pose,feet,facing)*Rect2(Vector2.ZERO,size))
	return bounds.merge(Rect2(feet+Vector2(44*facing-48,-160),Vector2(96,160)))

func camera_transform(game: Node2D) -> Transform2D:
	if not game.cinematic.active or game.cinematic.hero_id != "sean": return Transform2D.IDENTITY
	var time: float = game.cinematic.elapsed
	if time <= 0 or time >= float(timeline.sean.duration): return Transform2D.IDENTITY
	var feet: Vector2 = game.cinematic_feet-Vector2(floorf(game.camera_x),0)
	var bounds := framing_bounds(game.cinematic_costume,feet,game.cinematic_facing)
	var safe := rectangle(timeline.safe_rect)
	var peak := minf(2.0,minf((safe.size.x-6)/bounds.size.x,(safe.size.y-6)/bounds.size.y))
	peak = maxf(1.0,peak)
	var weight := smoothstep(0,0.3,time)*(1-smoothstep(2.7,3.4,time))
	var zoom := lerpf(1.0,peak,weight)
	var target := safe.get_center()-bounds.get_center()*peak
	# Keep the original viewport covered: cinematic framing must not reveal outside the rendered world.
	target.x = clampf(target.x,960*(1-peak),0)
	target.y = clampf(target.y,540*(1-peak),0)
	var offset := target*weight
	var shake: Dictionary = timeline.sean.impact_shake
	if time >= float(shake.start) and time < float(shake.end):
		var age := time-float(shake.start)
		var decay := 1-age/(float(shake.end)-float(shake.start))
		offset += Vector2(sin(age*140),sin(age*190))*float(shake.peak_native_pixels)*decay
	# Clamp after shake too; the transform never changes camera_x or any simulation coordinates.
	offset.x = clampf(offset.x,960*(1-zoom),0)
	offset.y = clampf(offset.y,540*(1-zoom),0)
	return Transform2D(Vector2(zoom,0),Vector2(0,zoom),offset)

func pipe_state(game: Node2D) -> Dictionary:
	var reveal: Dictionary = timeline.sean.pipe_reveal
	return {"anchor":game.cinematic_feet+Vector2(44*game.cinematic_facing,0),
		"elapsed":clampf(inverse_lerp(reveal.start,reveal.end,game.cinematic.elapsed),0,1),
		"angle":0.0,"costume":game.cinematic_costume}

func draw_hero(game: Node2D) -> bool:
	if not game.cinematic.active or game.cinematic.hero_id != "sean": return false
	game.special_art.rain.draw_cinematic_pipe(game,timeline)
	var id := pose_id(game.cinematic.elapsed)
	if id != "gameplay_pose":
		var pose: Dictionary = timeline.sean.poses_by_costume[game.cinematic_costume][id]
		var basis := pose_transform(pose,game.cinematic_feet,game.cinematic_facing)
		basis.origin.x -= floorf(game.camera_x)
		game.draw_set_transform_matrix(basis)
		game.draw_texture(poses[game.cinematic_costume][id],Vector2.ZERO)
		game.draw_set_transform(Vector2(-floorf(game.camera_x),0))
	return id != "gameplay_pose"

func gauge_state(elapsed: float) -> Dictionary:
	var crank := smoothstep(0.55,1.75,elapsed)
	var alpha := smoothstep(0,0.25,elapsed)*(1-smoothstep(2.75,3.2,elapsed))
	var tremble := Vector2.ZERO
	if elapsed >= 1.75 and elapsed < 2.75:
		var age := elapsed-1.75
		# Smooth amplitude prevents a positional snap at either end of the one-second tremble.
		var envelope := smoothstep(0,0.06,age)*(1-smoothstep(0.94,1,age))
		tremble = Vector2(sin(age*93),sin(age*117))*2*envelope
	return {"alpha":alpha,"offset":tremble,"wheel":TAU*crank,
		"needle":deg_to_rad(lerpf(gauge.needle.start_rotation_degrees,
			gauge.needle.maximum_rotation_degrees,crank))}

func draw_overlay(game: Node2D) -> void:
	if not game.cinematic.active or game.cinematic.hero_id != "tony": return
	var state := gauge_state(game.cinematic.elapsed)
	var color := Color(1,1,1,state.alpha)
	var housing := rectangle(gauge.housing.destination)
	housing.position += state.offset
	game.draw_texture_rect(components.housing,housing,false,color)
	var housing_scale := housing.size.x/float(gauge.housing.source_rect[2])
	var source_origin := Vector2(gauge.housing.source_rect[0],gauge.housing.source_rect[1])
	for id in ["needle","wheel"]:
		var component: Dictionary = gauge[id]
		var pivot: Array = gauge.housing.source_gauge_pivot if id == "needle" else gauge.housing.source_wheel_socket
		var anchor := housing.position+(vector(pivot)-source_origin)*housing_scale
		var scale: float = housing_scale*float(component.scale_relative_to_housing)
		game.draw_set_transform(anchor,state[id],Vector2.ONE*scale)
		game.draw_texture(components[id],-vector(component.source_pivot),color)
	game.draw_set_transform(Vector2.ZERO)
