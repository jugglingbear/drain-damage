extends RefCounted
## Authored frame animation, waterline clipping and actual fall height share the simulation's anchors.
var manifest: Dictionary = {}
var textures: Dictionary = {}

func configure(data: Dictionary) -> void:
	manifest = data
	textures.clear()
	for frame: Dictionary in manifest.frames.values(): load_frame(frame)
	for animation: Dictionary in manifest.animations.values():
		for frame: Dictionary in animation.frames: load_frame(frame)

func load_frame(frame: Dictionary) -> void:
	if frame.has("layers"):
		for layer: Dictionary in frame.layers: load_frame(layer)
		return
	if not textures.has(frame.path): textures[frame.path] = load("res://"+str(frame.path))

func frame_at(id: String, time: float) -> Dictionary:
	var animation: Dictionary = manifest.animations[id]
	var frames: Array = animation.frames
	var index := int(floor(time*float(animation.fps)))
	return frames[posmod(index,frames.size()) if animation.loop else mini(index,frames.size()-1)]

func draw_frame(host: Node2D, frame: Dictionary, offset := Vector2.ZERO, tint := Color.WHITE,
		clip_bottom := INF) -> void:
	if frame.has("layers"):
		for layer: Dictionary in frame.layers: draw_frame(host,layer,offset,tint,clip_bottom)
		return
	var source: Rect2 = host.region(frame.source_rect)
	var target: Rect2 = host.region(frame.destination)
	target.position += offset
	if target.position.y >= clip_bottom: return
	if target.end.y > clip_bottom:
		var fraction := (clip_bottom-target.position.y)/target.size.y
		source.size.y *= fraction
		target.size.y *= fraction
	host.draw_texture_rect_region(textures[frame.path],target,source,tint)

func draw_named(host: Node2D, id: String, offset := Vector2.ZERO, tint := Color.WHITE) -> void:
	draw_frame(host,manifest.frames[id],offset,tint)

func landing_presentation(hero: String, hard: bool, elapsed: float) -> Dictionary:
	var pose: Dictionary = manifest.landing[hero]["hard" if hard else "normal"]
	var settled := smoothstep(0.0,1.4,elapsed)
	var bob := sin(elapsed*3.0)*2.0*settled
	var anchor := Vector2(pose.screen_anchor[0],pose.screen_anchor[1])
	var transform := Transform2D(sin(elapsed*2.1)*0.025*settled,
		anchor+Vector2(0,-64.0*(1.0-settled)+bob))
	return {"pose":pose,"transform":transform}

func landing(host: Node2D, model: RefCounted) -> void:
	var elapsed: float = maxf(0,model.clock-43.0)+model.landing_clock
	var presentation := landing_presentation(host.employee.id,host.difficulty == "hard",elapsed)
	var pose: Dictionary = presentation.pose
	# Contact and leg occlusion are authored into the rider/board composite, so every part shares one transform.
	host.draw_set_transform_matrix(presentation.transform)
	var offset := -Vector2(pose.contact_anchor[0],pose.contact_anchor[1])
	for frame: Dictionary in pose.rear: draw_frame(host,frame,offset)
	if not pose.composite_includes_board: draw_named(host,"landing_board",offset)
	for frame: Dictionary in pose.front: draw_frame(host,frame,offset)
	host.draw_set_transform(Vector2.ZERO)

func water(host: Node2D, model: RefCounted) -> void:
	var frame := frame_at("water",model.water_clock)
	# Rotate the authored changing surface in its circular plane, then project it into the bowl.
	var phase: float = model.water_clock*float(manifest.animations.water.fps)
	var fraction := fposmod(phase,1.0)
	var following := frame_at("water",model.water_clock+1.0/float(manifest.animations.water.fps))
	if float(manifest.get("surface_depth_pixels",0)) > 0:
		# The funnel's depth shading and throat stay registered; authored flow phases supply motion.
		host.draw_set_transform(model.center())
		draw_frame(host,frame)
		draw_frame(host,following,Vector2.ZERO,Color(1,1,1,fraction))
	else:
		var plane := Transform2D(0,Vector2(1,model.projection()),0,model.center())
		host.draw_set_transform_matrix(plane*Transform2D(model.swirl_angle,Vector2.ZERO))
		var first_rect: Rect2 = host.region(frame.destination)
		first_rect.position.y /= model.projection()
		first_rect.size.y /= model.projection()
		var next_rect: Rect2 = host.region(following.destination)
		next_rect.position.y /= model.projection()
		next_rect.size.y /= model.projection()
		host.draw_texture_rect_region(textures[frame.path],first_rect,host.region(frame.source_rect))
		host.draw_texture_rect_region(textures[following.path],next_rect,
			host.region(following.source_rect),Color(1,1,1,fraction))
	host.draw_set_transform(Vector2.ZERO)

func swimmer(host: Node2D, model: RefCounted) -> void:
	if model.clock >= 43: return
	var id: String = host.employee.id+("_hard" if host.difficulty == "hard" else "_normal")
	var frame := frame_at(id,model.swim_clock)
	var anchor: Vector2 = model.project(model.position)
	var depth: float = model.sink_depth*64.0
	# Clip below the fixed water surface. Downward translation exposes less body until even the head is submerged.
	host.draw_set_transform(anchor,0,Vector2(host.facing,1))
	draw_frame(host,frame,Vector2(0,depth),Color.WHITE,0.0)
	host.draw_set_transform(Vector2.ZERO)
	if model.clock < 40:
		host.draw_set_transform_matrix(model.surface_transform(model.position))
		draw_frame(host,frame_at("waterline",model.water_clock))
		host.draw_set_transform(Vector2.ZERO)

func debris(host: Node2D, model: RefCounted, item: Dictionary) -> void:
	var point: Vector2 = model.project(item.pos)
	var height: float = model.debris.fall_height(item,model.clock)
	draw_named(host,str(item.prop),point-Vector2(0,height))
	var age: float = model.clock-float(item.impact_at)
	if age >= 0 and age < 0.35:
		draw_frame(host,frame_at("splash",age),point)

func shadows(host: Node2D, model: RefCounted, item: Dictionary) -> void:
	if model.clock < float(item.impact_at):
		var radius := float(item.get("radius",40.0 if item.prop == "dead_hamster" else 22.0))
		var warning_radius := float(item.get("warning_radius",radius+14.0))
		var warning_size := Vector2(warning_radius*2.0/float(manifest.frames.warning.destination[2]),
			warning_radius*2.0*model.projection()/float(manifest.frames.warning.destination[3]))
		host.draw_set_transform_matrix(model.surface_transform(item.impact_pos)
			*Transform2D(0,warning_size,0,Vector2.ZERO))
		draw_named(host,"warning",Vector2.ZERO,Color(1,1,1,0.75+0.25*sin(model.clock*12)))
		host.draw_set_transform(Vector2.ZERO)
		var remaining: float = (float(item.impact_at)-model.clock)/float(item.duration)
		var size := lerpf(1.0,0.35,clampf(remaining,0,1))*radius/22.0
		host.draw_set_transform_matrix(model.surface_transform(item.pos)*Transform2D(0,Vector2.ONE*size,0,Vector2.ZERO))
		draw_named(host,"shadow",Vector2.ZERO,Color(1,1,1,lerpf(0.9,0.3,remaining)))
		host.draw_set_transform(Vector2.ZERO)
