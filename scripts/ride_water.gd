extends RefCounted
## Continuous authored water patches and inward edge foam share a simulation clock.
const CHANNEL := Rect2(0,230,960,200)

static func patch(host: Node2D, art: RefCounted, frame: Dictionary, target: Rect2, clip: Rect2,
		opacity := 1.0) -> void:
	var visible := target.intersection(clip)
	if not visible.has_area(): return
	var s: Array = frame.get("runtime_source_rect",frame.source_rect)
	var source := Rect2(s[0],s[1],s[2],s[3])
	source.position += (visible.position-target.position)/target.size*source.size
	source.size *= visible.size/target.size
	host.draw_texture_rect_region(art.textures[frame.get("runtime_texture_key",frame.path)],visible,source,
		Color(1,1,1,opacity))

static func tiles(host: Node2D, art: RefCounted, frame: Dictionary, clip: Rect2,
		phase: float, y: float, height: float, opacity := 1.0) -> void:
	var width := float(frame.destination[2])
	var period := width-float(frame.get("edge_feather",0))*2
	var first := floori((clip.position.x+phase)/period)
	for tile in range(first-1,first+3):
		patch(host,art,frame,Rect2(tile*period-phase,y,width,height),clip,opacity)

static func surface(host: Node2D, art: RefCounted, age: float, scroll: float, clip := CHANNEL) -> void:
	for row: Dictionary in surface_rows(art.manifest,age,scroll):
		var frame: Dictionary = art.manifest.frames[row.id]
		tiles(host,art,frame,clip,row.phase,row.y,float(frame.destination[3]),float(art.manifest.flow.surface_opacity))

static func surface_rows(manifest: Dictionary, age: float, scroll: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var flow: Dictionary = manifest.flow
	for row in range(4):
		var speed := float(flow.speed_x if row%2 == 0 else flow.secondary_speed_x)
		var phase := scroll-age*speed+row*372
		var y := 230+row*52.0+sin(age*TAU/3.7+row)*2
		result.append({"id":flow.surface_frames[row%2],"phase":phase,"y":y})
	return result

static func foam(host: Node2D, art: RefCounted, point: Vector2, depth: float, age: float) -> void:
	var frame: Dictionary = art.manifest.frames.inflow_foam
	var phase := age*34
	# Four local inward-facing strips; no full-height waterfall or opaque water panel.
	for edge in [0,1,2,3]:
		var origin: Vector2
		var rotation := 0.0
		var scale := Vector2.ONE
		var length := 140.0
		if edge == 0: origin = point+Vector2(-70,-depth/2)
		elif edge == 1:
			origin = point+Vector2(-70,depth/2)
			scale.y = -1
		elif edge == 2:
			origin = point+Vector2(-70,depth/2)
			rotation = -PI/2
			length = depth
		else:
			origin = point+Vector2(70,-depth/2)
			rotation = PI/2
			length = depth
		host.draw_set_transform(origin,rotation,scale)
		# Local +Y always points into the aperture, including the flipped near edge.
		var inward := fposmod(age*10,8)
		for row in [-1,0]:
			tiles(host,art,frame,Rect2(0,0,length,8),phase,inward+row*8,8,0.85)
	host.draw_set_transform(Vector2.ZERO)

static func gap(host: Node2D, art: RefCounted, frame: Dictionary, point: Vector2,
		depth: float, age: float) -> void:
	for layer: Dictionary in frame.layers:
		if not str(layer.get("role","")).begins_with("wet_"): art.draw_frame(host,layer,point)
	foam(host,art,point,depth,age)
	for layer: Dictionary in frame.layers:
		if str(layer.get("role","")).begins_with("wet_"): art.draw_frame(host,layer,point)
