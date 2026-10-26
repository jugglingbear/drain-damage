extends "res://scripts/ride_showcase_model.gd"
## Showcase presentation uses the same calibrated obstacle and rider anchors as the simulation.
const Audio = preload("res://scripts/level_two_ride_audio.gd")
const Art = preload("res://scripts/flush_art.gd")
const SHOWCASE_ART := "res://assets/world/ride-showcase-v1/manifest.json"
var art := Art.new()
var obstacle_art := Art.new()
var audio := Audio.new()
var audio_definition: Dictionary = {}
var mechanism_cycle := -1
var visual_obstacles: Array[Dictionary] = []
const VIEWPORT := Rect2(0,0,960,540)

func attach(host: Node2D) -> void:
	audio_definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-ride.json"))
	audio.attach(host,audio_definition.audio.cues)
	art.configure(JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/level-two-ride-v1/manifest.json")))
	if FileAccess.file_exists(SHOWCASE_ART):
		obstacle_art.configure(JSON.parse_string(FileAccess.get_file_as_string(SHOWCASE_ART)))

func begin(host: Node2D, index := -1) -> void:
	visual_obstacles.clear()
	super.begin(host,checkpoint_index if index < 0 else index)
	audio.stop()
	mechanism_cycle = -1

func _start_encounter(index: int) -> void:
	super._start_encounter(index)
	# Visuals own their world clock; collision teardown and the next encounter cannot reset them.
	for obstacle: Dictionary in course.obstacles:
		var visual := obstacle.duplicate(true)
		visual["visual_started"] = clock
		visual_obstacles.append(visual)

func visual_age(obstacle: Dictionary) -> float:
	return clock-float(obstacle.visual_started) if obstacle.has("visual_started") else encounter_clock

func obstacle_position(obstacle: Dictionary) -> Vector2:
	if not obstacle.has("visual_started"): return super.obstacle_position(obstacle)
	var age := visual_age(obstacle)
	return Vector2(float(obstacle.x)-age*scroll_speed,float(obstacle.y))+motion_offset(obstacle,age)

func frame_bounds(frame: Dictionary, transform: Transform2D) -> Rect2:
	if frame.has("layers"):
		var bounds := Rect2()
		for layer: Dictionary in frame.layers:
			var next := frame_bounds(layer,transform)
			bounds = bounds.merge(next) if bounds.has_area() else next
		return bounds
	var d: Array = frame.destination
	return transform*Rect2(float(d[0]),float(d[1]),float(d[2]),float(d[3]))

func visual_bounds(obstacle: Dictionary) -> Rect2:
	var point := obstacle_position(obstacle)
	var id := obstacle_frame_id(obstacle)
	var frames: Dictionary = obstacle_art.manifest.frames
	var bounds: Rect2
	if id == "launch_ramp":
		var width := float(obstacle.width)
		var depth := float(obstacle.depth)
		var rise := float(obstacle.get("rise",40))
		bounds = Rect2(point-Vector2(width*0.5,depth*0.5+rise),Vector2(width,depth+rise))
	else:
		bounds = frame_bounds(frames[id],Transform2D(0,point))
	var shadow: String = str(obstacle_art.manifest.get("overhead",{}).get("shadow_frames",{}).get(id,""))
	if not shadow.is_empty(): bounds = bounds.merge(frame_bounds(frames[shadow],Transform2D(0,point)))
	if id == "float_ball":
		var base := Vector2(float(obstacle.x)-visual_age(obstacle)*scroll_speed,float(obstacle.y))
		bounds = bounds.merge(frame_bounds(frames.float_sweep_shadow,Transform2D(0,base)))
		var arm := Transform2D(atan2((point-base).y,150),base+Vector2(-185,-28))
		bounds = bounds.merge(frame_bounds(frames.float_arm,arm*Transform2D(0,Vector2(185,28))))
	for overlay: Dictionary in obstacle_art.manifest.get("obstacle_overlays",{}).get(id,[]):
		for frame: Dictionary in obstacle_art.manifest.animations[str(overlay.animation)].frames:
			bounds = bounds.merge(frame_bounds(frame,Transform2D(0,point)))
	return bounds

func prune_departed_visuals() -> void:
	for i in range(visual_obstacles.size()-1,-1,-1):
		var obstacle: Dictionary = visual_obstacles[i]
		var motion: Dictionary = obstacle.get("motion",{})
		# Keep a conservative margin for moving/rotating decorations that could swing back into view.
		var margin := absf(float(motion.get("amplitude",0)))*2
		if obstacle_frame_id(obstacle) == "float_ball": margin += 400
		if visual_bounds(obstacle).end.x+margin < 0: visual_obstacles.remove_at(i)

func tick(host: Node2D, delta: float, steering: Vector2, jumping: bool) -> void:
	if host.paused or host.life_state != "alive" or complete: return
	var before := events.duplicate()
	var previous_encounter := encounter_index
	super.tick(host,delta,steering,jumping)
	prune_departed_visuals()
	if host.life_state != "alive" or complete:
		audio.stop()
		return
	if int(events.get("jump",0)) > int(before.get("jump",0)): host.play_tone(360.0,0.08)
	if int(events.get("hit",0)) > int(before.get("hit",0)):
		host.tone_time = 0
		var cue := "metal_impact"
		if previous_encounter in [2,3,5]: cue = "soft_contact"
		elif previous_encounter == 7: cue = "porcelain_contact"
		audio.play(cue)
	elif int(events.get("ramp",0)) > int(before.get("ramp",0)):
		audio.play("water_launch")
	elif int(events.get("landed",0)) > int(before.get("landed",0)):
		audio.play("porcelain_contact" if previous_encounter == 7 else "ride_land")
	if previous_encounter != encounter_index: mechanism_cycle = -1
	update_mechanism_audio()
	sync_hero(host)

func update_mechanism_audio() -> void:
	if phase != "encounter" or encounter_index != 5:
		audio.stop_mechanism()
		return
	for obstacle: Dictionary in course.obstacles:
		if not obstacle.has("motion"): continue
		var point := obstacle_position(obstacle)
		if point.x+float(obstacle.width)*0.5 < 0 or point.x-float(obstacle.width)*0.5 > 960:
			audio.stop_mechanism()
			continue
		var period := float(obstacle.motion.period)
		var cycle := int(floor((encounter_clock+period*0.25)/(period*0.5)))
		if cycle != mechanism_cycle:
			mechanism_cycle = cycle
			audio.play("hinge_move")

func sync_hero(host: Node2D) -> void:
	host.player = position-Vector2(13,46+render_height)
	host.grounded = jump_age < 0
	host.velocity = Vector2.ZERO
	host.current_aim = Vector2.RIGHT

func process_audio(host: Node2D, delta: float) -> void:
	audio.advance(delta,host.paused,not complete and host.life_state == "alive")

func draw_strip(host: Node2D, id: String, scroll: float) -> void:
	var first := int(floor(scroll/960.0))
	for tile in [first,first+1]:
		var x := float(tile)*960.0-scroll
		var mirrored: bool = posmod(tile,2) == 1
		host.draw_set_transform(Vector2(x+(960.0 if mirrored else 0.0),0),0,Vector2(-1 if mirrored else 1,1))
		art.draw_named(host,id)
	host.draw_set_transform(Vector2.ZERO)

func draw_ramp(host: Node2D, obstacle: Dictionary, point: Vector2) -> void:
	var frames: Dictionary = obstacle_art.manifest.frames
	var run := float(obstacle.width)
	var depth := float(obstacle.depth)
	var rise := float(obstacle.get("rise",40))
	# Authored materials follow the same quadratic surface as the collider, including transparent padding.
	for pixel in range(ceili(run)):
		var width := minf(1.0,run-pixel)
		var u := (float(pixel)+width*0.5)/run
		var elevation := rise*u*u
		for layer in ["ramp_surface","ramp_fascia"]:
			var frame: Dictionary = frames[layer]
			var source := Rect2(frame.source_rect[0],frame.source_rect[1],frame.source_rect[2],frame.source_rect[3])
			var strip := Rect2(source.position+Vector2(source.size.x*float(pixel)/run,0),
				Vector2(source.size.x*width/run,source.size.y))
			var y := point.y-depth*0.5-elevation if layer == "ramp_surface" else point.y+depth*0.5-elevation
			var height := depth if layer == "ramp_surface" else elevation
			if height <= 0: continue
			host.draw_texture_rect_region(obstacle_art.textures[frame.path],
				Rect2(point.x-run*0.5+pixel,y,width,height),strip)

func obstacle_frame_id(obstacle: Dictionary) -> String:
	var id: String = str(obstacle.get("art_id",obstacle.kind))
	var sizes: Dictionary = obstacle_art.manifest.get("size_variants",{}).get(id,{})
	id = str(sizes.get(str(int(obstacle.width)),id))
	var banks: Dictionary = obstacle_art.manifest.get("bank_variants",{}).get(id,{})
	return str(banks.get("near" if bool(obstacle.get("mirror_bank",false)) else "far",id))

func draw_obstacle_shadow(host: Node2D, obstacle: Dictionary) -> void:
	var id := obstacle_frame_id(obstacle)
	var shadow: String = str(obstacle_art.manifest.get("overhead",{}).get("shadow_frames",{}).get(id,""))
	if not shadow.is_empty(): obstacle_art.draw_named(host,shadow,obstacle_position(obstacle))
	if id == "float_ball":
		var base := Vector2(float(obstacle.x)-visual_age(obstacle)*scroll_speed,float(obstacle.y))
		obstacle_art.draw_named(host,"float_sweep_shadow",base)
		var offset := obstacle_position(obstacle)-base
		host.draw_set_transform(base+Vector2(-185,-28),atan2(offset.y,150))
		obstacle_art.draw_named(host,"float_arm",Vector2(185,28))
		host.draw_set_transform(Vector2.ZERO)

func draw_obstacle(host: Node2D, obstacle: Dictionary) -> void:
	var point := obstacle_position(obstacle)
	var id := obstacle_frame_id(obstacle)
	if id == "launch_ramp":
		draw_ramp(host,obstacle,point)
		return
	assert(obstacle_art.manifest.frames.has(id),"Missing calibrated obstacle art: "+id)
	obstacle_art.draw_named(host,id,point)
	draw_obstacle_overlays(host,obstacle,false)

func draw_obstacle_overlays(host: Node2D, obstacle: Dictionary, foreground: bool) -> void:
	var id := obstacle_frame_id(obstacle)
	for overlay: Dictionary in obstacle_art.manifest.get("obstacle_overlays",{}).get(id,[]):
		if bool(overlay.get("foreground",false)) != foreground: continue
		var animation: Dictionary = obstacle_art.manifest.animations[str(overlay.animation)]
		var age := visual_age(obstacle)
		var blend := fposmod(age*float(animation.fps),1.0) if bool(overlay.get("interpolate",animation.get("interpolate",false))) else 0.0
		obstacle_art.draw_frame(host,obstacle_art.frame_at(str(overlay.animation),age),
			obstacle_position(obstacle),Color(1,1,1,1-blend))
		if blend > 0:
			obstacle_art.draw_frame(host,obstacle_art.frame_at(str(overlay.animation),age+1.0/float(animation.fps)),
				obstacle_position(obstacle),Color(1,1,1,blend))

func rider_transform(host: Node2D) -> Transform2D:
	var falling: bool = host.life_state != "alive" and events.has("fall")
	var fall_depth := pow(clampf(float(host.death_time),0,1),2)*260 if falling else 0.0
	var recovery_bounce := sin(recovery_clock/0.6*PI)*20.0
	return Transform2D(render_pitch,position+Vector2(0,-render_height+fall_depth-recovery_bounce))

func fall_clip_bottom() -> float:
	for obstacle: Dictionary in course.obstacles:
		if obstacle.id == str(last_event.get("obstacle_id","")) and obstacle.kind in ["gap","long_pit"]:
			return float(obstacle.y)+float(obstacle.depth)*0.5
	return 540.0

func draw_falling_frame(host: Node2D, frame: Dictionary, transform: Transform2D, tint: Color) -> void:
	if frame.has("layers"):
		for layer: Dictionary in frame.layers: draw_falling_frame(host,layer,transform,tint)
		return
	var d: Array = frame.destination
	var target := Rect2(d[0],d[1],d[2],d[3])
	var polygon := PackedVector2Array([target.position,Vector2(target.end.x,target.position.y),
		target.end,Vector2(target.position.x,target.end.y)])
	polygon = transform*polygon
	var bottom := fall_clip_bottom()
	var clipped := Geometry2D.intersect_polygons(polygon,PackedVector2Array([
		Vector2(0,0),Vector2(960,0),Vector2(960,bottom),Vector2(0,bottom)]))
	var texture: Texture2D = host.flush.art.textures[frame.path]
	var source := Rect2(frame.source_rect[0],frame.source_rect[1],frame.source_rect[2],frame.source_rect[3])
	for piece: PackedVector2Array in clipped:
		var uv := PackedVector2Array()
		for point: Vector2 in piece:
			var local := transform.affine_inverse()*point
			uv.append((source.position+(local-target.position)/target.size*source.size)/texture.get_size())
		host.draw_polygon(piece,PackedColorArray([tint]),uv,texture)

func draw_fall_occluder(host: Node2D, frame: Dictionary, point: Vector2) -> void:
	if not bool(frame.get("occludes_fall",true)): return
	if frame.has("layers"):
		for layer: Dictionary in frame.layers: draw_fall_occluder(host,layer,point)
	else: obstacle_art.draw_frame(host,frame,point)

func draw_rider(host: Node2D, flush: RefCounted) -> void:
	var falling: bool = host.life_state != "alive" and events.has("fall")
	if not falling: art.draw_named(host,"shadow",position,Color(1,1,1,clampf(1-render_height/200.0,0.2,1)))
	if host.invulnerable <= 0 or int(clock*12)%2 == 0:
		var mode := "hard" if host.difficulty == "hard" else "normal"
		var pose: Dictionary = flush.art.manifest.landing[host.employee.id][mode]
		var registration: Array = obstacle_art.manifest.get("rider_contacts",{}).get(host.employee.id,{}).get(mode,[0,0])
		host.draw_set_transform_matrix(rider_transform(host))
		var offset := -Vector2(registration[0],registration[1])
		var alpha := 1.0-clampf((float(host.death_time)-0.75)/0.25,0,1) if falling else 1.0
		for frame: Dictionary in pose.front:
			if falling:
				host.draw_set_transform(Vector2.ZERO)
				draw_falling_frame(host,frame,rider_transform(host)*Transform2D(0,offset),Color(1,1,1,alpha))
			else: flush.art.draw_frame(host,frame,offset,Color(1,1,1,alpha))
		host.draw_set_transform(Vector2.ZERO)
	if recovery_clock > 0: art.draw_named(host,"splash",position)

func draw(host: Node2D, flush: RefCounted) -> void:
	host.draw_set_transform(Vector2.ZERO)
	var scroll := clock*scroll_speed
	draw_strip(host,"course_far",scroll*0.35)
	draw_strip(host,"course_water",scroll)
	var foreground: Array[Dictionary] = []
	for obstacle: Dictionary in visual_obstacles:
		if not visual_bounds(obstacle).intersects(VIEWPORT,true): continue
		draw_obstacle_shadow(host,obstacle)
		if obstacle.kind in ["support","overhead"]:
			foreground.append(obstacle)
		else: draw_obstacle(host,obstacle)
	foreground.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return obstacle_position(a).y < obstacle_position(b).y)
	var rider_drawn := false
	for obstacle: Dictionary in foreground:
		if not rider_drawn and obstacle_position(obstacle).y >= position.y:
			draw_rider(host,flush)
			rider_drawn = true
		draw_obstacle(host,obstacle)
	if not rider_drawn: draw_rider(host,flush)
	if host.life_state != "alive" and events.has("fall"):
		# Solid island tops and sidewalls occlude the descending composite at its failed position.
		for obstacle: Dictionary in visual_obstacles:
			var frame: Dictionary = obstacle_art.manifest.frames[obstacle_frame_id(obstacle)]
			if obstacle.kind == "deck" or bool(frame.get("has_fall_occlusion",false)):
				draw_fall_occluder(host,frame,obstacle_position(obstacle))
	for obstacle: Dictionary in visual_obstacles:
		if visual_bounds(obstacle).intersects(VIEWPORT,true): draw_obstacle_overlays(host,obstacle,true)
	draw_strip(host,"course_near",scroll)
	host.box(0,0,960,64,Color("101d29"))
	host.label_at("RIDE OBSTACLE TEST",Vector2(24,27),22,host.MINT)
	host.label_at("Steer: arrows / stick   Jump: Space / A",Vector2(24,52),14,host.GOLD)
	host.draw_vitals(Vector2(550,10))
	host.label_at("%02d / 10" % (encounter_index+1),Vector2(830,52),14,host.MINT)
	if phase == "rest":
		host.label_at("REST — %.1f s" % rest_remaining,Vector2(24,92),22,host.MINT)
	elif phase == "encounter":
		host.label_at("%02d  %s" % [encounter_index+1,str(encounter.get("title",""))],Vector2(24,92),22,host.GOLD)
		host.label_at(str(encounter.get("action_hint","")),Vector2(24,117),16,host.MINT)
	host.BuildVersion.draw(host)
	if host.paused or host.won:
		host.box(0,0,960,540,Color(0.03,0.07,0.12,0.88))
		if host.life_state in ["death_popup","game_over"]: host.draw_death_popup()
		elif host.won:
			host.label_at("OBSTACLE TEST COMPLETE",Vector2(270,195),28,host.GOLD)
			host.label_at("All ten encounters finished",Vector2(330,230),21,host.MINT)
			host.draw_pause_plates()
		else: host.draw_pause_panel()
