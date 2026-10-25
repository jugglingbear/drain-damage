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
	if not textures.has(frame.path): textures[frame.path] = load("res://"+str(frame.path))

func frame_at(id: String, time: float) -> Dictionary:
	var animation: Dictionary = manifest.animations[id]
	var frames: Array = animation.frames
	var index := int(floor(time*float(animation.fps)))
	return frames[posmod(index,frames.size()) if animation.loop else mini(index,frames.size()-1)]

func draw_frame(host: Node2D, frame: Dictionary, offset := Vector2.ZERO, tint := Color.WHITE,
		clip_bottom := INF) -> void:
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

func water(host: Node2D, model: RefCounted) -> void:
	var frame := frame_at("water",model.water_clock)
	# Rotate the authored changing surface in its circular plane, then project it into the bowl.
	var plane := Transform2D(0,Vector2(1,model.projection()),0,model.center())
	host.draw_set_transform_matrix(plane*Transform2D(model.swirl_angle,Vector2.ZERO))
	var phase: float = model.water_clock*float(manifest.animations.water.fps)
	var fraction := fposmod(phase,1.0)
	var following := frame_at("water",model.water_clock+1.0/float(manifest.animations.water.fps))
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
	if model.clock < 40: draw_frame(host,frame_at("waterline",model.water_clock),anchor)

func debris(host: Node2D, model: RefCounted, item: Dictionary) -> void:
	var point: Vector2 = model.project(item.pos)
	var height: float = model.debris.fall_height(item,model.clock)
	draw_named(host,str(item.prop),point-Vector2(0,height))
	var age: float = model.clock-float(item.impact_at)
	if age >= 0 and age < 0.35:
		draw_frame(host,frame_at("splash",age),point)

func shadows(host: Node2D, model: RefCounted, item: Dictionary) -> void:
	var point: Vector2 = model.project(item.pos)
	if model.clock < float(item.impact_at):
		draw_named(host,"warning",model.project(item.impact_pos),Color(1,1,1,0.75+0.25*sin(model.clock*12)))
		var remaining: float = (float(item.impact_at)-model.clock)/float(item.duration)
		var size := lerpf(1.0,0.35,clampf(remaining,0,1))
		host.draw_set_transform(point,0,Vector2.ONE*size)
		draw_named(host,"shadow",Vector2.ZERO,Color(1,1,1,lerpf(0.9,0.3,remaining)))
		host.draw_set_transform(Vector2.ZERO)
