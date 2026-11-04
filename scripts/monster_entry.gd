extends RefCounted
## World-anchored arrival motion. Camera changes never change either endpoint.

static func create(home: Vector2, radius: float, duration: float, mode := "foreground",
		mouth := Vector2.ZERO, camera_left := NAN, hero_center := Vector2.INF,
		source_override := Vector2.INF, waypoints: Array[Vector2] = []) -> Dictionary:
	var staging := Vector2(home.x,500)
	if mode == "foreground" and is_finite(camera_left) and hero_center.is_finite():
		var away := -1.0 if home.x < hero_center.x else 1.0
		var margin := clampf(radius*1.5,120,240)
		staging.x = clampf(home.x+away*120,camera_left+margin,camera_left+960-margin)
	var pocket_scale := minf(0.45,28.0/maxf(radius,1))
	var start := Vector2(home.x,-radius-32) if mode == "top" else Vector2(staging.x,540+radius*3+32)
	if mode == "background": start = mouth+Vector2(0,48+radius*pocket_scale)
	elif mode == "left": start = Vector2((camera_left if is_finite(camera_left) else 0)-radius-32,home.y)
	elif mode == "right": start = Vector2((camera_left if is_finite(camera_left) else 0)+960+radius+32,home.y)
	elif mode == "floor": start = home+Vector2(0,radius+32)
	elif mode == "ceiling": start = home-Vector2(0,radius+32)
	elif mode == "bottom": start = Vector2(home.x,540+radius+32)
	if source_override.is_finite(): start = source_override
	var path: Array[Vector2] = [start]
	path.append_array(waypoints)
	path.append(home)
	var length := 0.0
	for index in range(1,path.size()): length += path[index-1].distance_to(path[index])
	return {"start":start,"staging":staging,"home":home,"mouth":mouth,"mode":mode,"clock":0.0,
		"duration":maxf(0.1,duration),"radius":radius,"pos":start,"path":path,"length":length,
		"pocket_scale":pocket_scale,"scale":pocket_scale if mode == "background" else 3.0 if mode == "foreground" else 1.0,
		"complete":false,"clip":Rect2(mouth-Vector2(32,32),Vector2(64,64)) if mode == "background" else Rect2()}

static func advance(entry: Dictionary, delta: float) -> void:
	entry.clock = minf(entry.duration,entry.clock+maxf(0,delta))
	var progress := clampf(float(entry.clock)/float(entry.duration),0,1)
	var blend := smoothstep(0,1,progress)
	entry.clip = Rect2()
	if entry.mode == "background":
		if progress < 0.3:
			entry.pos = entry.start.lerp(entry.mouth,smoothstep(0,0.3,progress))
			entry.scale = entry.pocket_scale
			entry.clip = Rect2(entry.mouth-Vector2(32,32),Vector2(64,64))
		else:
			blend = smoothstep(0.3,1,progress)
			entry.pos = entry.mouth.lerp(entry.home,blend)
			entry.scale = lerpf(entry.pocket_scale,1,blend)
	elif entry.mode == "foreground":
		# Keep the large silhouette visible before spending the recession in scale.
		if progress < 0.4:
			entry.pos = entry.start.lerp(entry.staging,smoothstep(0,0.4,progress))
			entry.scale = 3.0
		else:
			blend = smoothstep(0.4,1,progress)
			entry.pos = entry.staging.lerp(entry.home,blend)
			entry.scale = lerpf(3,1,blend)
	else:
		entry.pos = path_position(entry,blend)
		entry.scale = 1.0
		if entry.mode == "floor":
			entry.clip = Rect2(entry.home.x-entry.radius*2,-1024,entry.radius*4,entry.home.y+1024)
		elif entry.mode == "ceiling":
			entry.clip = Rect2(entry.home.x-entry.radius*2,entry.home.y,entry.radius*4,2048)
	entry.complete = progress >= 1

static func path_position(entry: Dictionary, progress: float) -> Vector2:
	var remaining: float = progress*entry.length
	for index in range(1,entry.path.size()):
		var segment: float = entry.path[index-1].distance_to(entry.path[index])
		if remaining <= segment:
			return entry.path[index-1].lerp(entry.path[index],remaining/segment if segment > 0 else 1.0)
		remaining -= segment
	return entry.home

static func active(actor: Dictionary) -> bool:
	return actor.has("entry") and not actor.entry.complete
