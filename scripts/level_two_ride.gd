extends "res://scripts/ride_showcase_model.gd"
## Showcase presentation uses the same calibrated obstacle and rider anchors as the simulation.
const Music = preload("res://scripts/ride_music.gd")
const Fidget = preload("res://scripts/ride_fidget.gd")
const Audio = preload("res://scripts/level_two_ride_audio.gd")
const Art = preload("res://scripts/flush_art.gd")
const Strainer = preload("res://scripts/ride_ceiling_strainer.gd")
const Hand = preload("res://scripts/ride_maintenance_hand.gd")
const Water = preload("res://scripts/ride_water.gd")
const HAND_ART := "res://assets/world/maintenance-hand-poc-v1/manifest.json"
const SHOWCASE_ART := "res://assets/world/ride-showcase-v1/manifest.json"
var art := Art.new()
var obstacle_art := Art.new()
var audio := Audio.new()
var music := Music.new()
var fidget := Fidget.new()
var audio_definition: Dictionary = {}
var mechanism_cycle := -1
var fractured: Dictionary = {}
var visual_obstacles: Array[Dictionary] = []
const FALL_DURATION := 1.35
const VIEWPORT := Rect2(0,0,960,540)

func attach(host: Node2D) -> void:
	audio_definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-ride.json"))
	audio.attach(host,audio_definition.audio.cues)
	music.attach(host,audio_definition.music)
	art.configure(JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/level-two-ride-v1/manifest.json")))
	if FileAccess.file_exists(SHOWCASE_ART):
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SHOWCASE_ART))
		var hand: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HAND_ART))
		for key in ["frames","animations","obstacle_overlays"]:
			manifest[key].merge(hand[key])
		manifest["hand_parts"] = hand.hand_parts
		manifest["hand_timeline"] = hand.timeline
		for path in ["res://assets/world/giant-brush-v2/manifest.json","res://assets/world/ceiling-strainer-v1/manifest.json"]:
			var extra: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			for key in ["frames","animations","obstacle_overlays"]:
				if not manifest.has(key): manifest[key] = {}
				manifest[key].merge(extra.get(key,{}))
			if extra.has("overhead"):
				manifest.overhead.shadow_frames.merge(extra.overhead.shadow_frames)
			if extra.has("strainer_parts"):
				manifest["strainer_parts"] = extra.strainer_parts
				manifest["strainer_timeline"] = extra.timeline
		var water: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/ride-water-break-v1/manifest.json"))
		for id in ["surface_ripples","surface_swirl","inflow_foam","strainer_rail","strainer_rail_left","strainer_rail_right"]:
			water.frames[id]["alpha_cutoff"] = 179.0/255
			if id.begins_with("surface_"): water.frames[id]["edge_feather"] = 12.0
		for key in ["frames","animations","obstacle_overlays"]:
			manifest[key].merge(water[key],true)
		manifest["flow"] = water.flow
		var clarity: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/ride-surface-clarity-v1/manifest.json"))
		manifest.frames.merge(clarity.frames,true)
		obstacle_art.configure(manifest)

func begin(host: Node2D, index := -1) -> void:
	visual_obstacles.clear()
	fractured.clear()
	fidget.reset()
	super.begin(host,checkpoint_index if index < 0 else index)
	audio.stop()
	music.stop()
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
		var assembly := float_assembly(obstacle)
		bounds = bounds.merge(frame_bounds(frames.float_sweep_shadow,Transform2D(0,assembly.base)))
		for part: Dictionary in assembly.parts:
			var part_bounds := frame_bounds(frames[part.id],part.transform)
			if part.has("clip_bottom"):
				part_bounds.size.y = maxf(0,minf(part_bounds.end.y,float(part.clip_bottom))-part_bounds.position.y)
			bounds = bounds.merge(part_bounds)
	if id == "maintenance_hand_gap" or id.begins_with("strainer_gap_"):
		for part: Dictionary in hazard_assembly(obstacle).parts:
			bounds = bounds.merge(frame_bounds(frames[part.id],part.transform))
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
		# The 3D rail extends eight metres past its target, beyond the old sprite bounds.
		# Include camera yaw/bank projection and the trolley's cleared travel before retirement.
		var world_margin := 1100.0 if str(obstacle.art_id).begins_with("strainer_gap_") else 400.0
		var world_right := obstacle_position(obstacle).x+float(obstacle.width)*.5+world_margin
		if visual_bounds(obstacle).end.x+margin < 0 and world_right < 0:
			visual_obstacles.remove_at(i)

func tick(host: Node2D, delta: float, steering: Vector2, jumping: bool, firing := false) -> void:
	if host.paused or host.life_state != "alive" or complete: return
	var before := events.duplicate()
	var previous_encounter := encounter_index
	var previous_clock := clock
	super.tick(host,delta,steering,jumping)
	prune_departed_visuals()
	update_fracture_audio(previous_clock)
	if host.life_state != "alive" or complete:
		fidget.reset(firing)
		audio.stop()
		music.stop()
		if int(events.get("fall",0)) > int(before.get("fall",0)):
			host.hero_death_audio.stop()
			audio.play("fall_panic")
		return
	if fidget.step(self,firing,delta).triggered: audio.play("board_fart")
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
		audio.play({"metal":"metal_impact","porcelain":"porcelain_contact"}.get(landing_material,"ride_land"))
	if previous_encounter != encounter_index: mechanism_cycle = -1
	update_mechanism_audio()
	sync_hero(host)

func update_fracture_audio(previous_clock: float) -> void:
	for obstacle: Dictionary in visual_obstacles:
		if not obstacle.has("activates_at"): continue
		var key := str(obstacle.id)+":"+str(obstacle.visual_started)
		var impact := float(obstacle.visual_started)+float(obstacle.activates_at)
		if previous_clock < impact and clock >= impact and not fractured.has(key):
			fractured[key] = true
			audio.play("track_smash")

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
	music.advance(clock,host.paused or host.flush.input_guard,
		host.flush.active and host.flush.state == "ride" and not complete and host.life_state == "alive" and not host.won,
		host.music_director != null and host.music_director.muted)
	if host.paused or host.life_state != "alive" or complete:
		fidget.step(self,Input.is_action_pressed("shoot"),0,not complete,host.paused,host.life_state == "alive")
	audio.advance(delta,host.paused,not complete and host.life_state == "alive",
		host.life_state == "dying" and events.has("fall"))

func draw_strip(host: Node2D, id: String, scroll: float, clip := VIEWPORT) -> void:
	var first := int(floor(scroll/960.0))
	for tile in [first,first+1]:
		var x := float(tile)*960.0-scroll
		var mirrored: bool = posmod(tile,2) == 1
		var transform := Transform2D(0,Vector2(-1 if mirrored else 1,1),0,Vector2(x+(960.0 if mirrored else 0.0),0))
		host.draw_set_transform_matrix(transform)
		var frame: Dictionary = art.manifest.frames[id]
		var d: Array = frame.destination
		Water.patch(host,art,frame,Rect2(d[0],d[1],d[2],d[3]),transform.affine_inverse()*clip)
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
		var assembly := float_assembly(obstacle)
		obstacle_art.draw_named(host,"float_sweep_shadow",assembly.base)
		for part: Dictionary in assembly.parts:
			if part.has("clip_bottom"):
				host.draw_set_transform(Vector2.ZERO)
				obstacle_art.draw_frame(host,obstacle_art.manifest.frames[part.id],
					part.transform.origin,Color.WHITE,float(part.clip_bottom))
			else:
				host.draw_set_transform_matrix(part.transform)
				obstacle_art.draw_named(host,part.id)
		host.draw_set_transform(Vector2.ZERO)

func float_assembly(obstacle: Dictionary) -> Dictionary:
	var spec: Dictionary = obstacle_art.manifest.float_wall_mount
	var base := Vector2(float(obstacle.x)-visual_age(obstacle)*scroll_speed,float(obstacle.y))
	var offset: Array = spec.mount_pivot_relative_base
	var pivot := base+Vector2(offset[0],offset[1])
	var socket_offset: Array = spec.ball_socket_relative_moving_ball
	var socket := obstacle_position(obstacle)+Vector2(socket_offset[0],socket_offset[1])
	var delta := socket-pivot
	var angle := delta.angle()
	# Telescope only the authored shaft; wall hardware and endpoint joints retain their dimensions.
	var shaft := Transform2D(angle,Vector2(delta.length()/150.0,1),0,pivot)
	return {"base":base,"pivot":pivot,"socket":socket,"span":delta.length(),"parts":[
		{"id":"float_wall_mount_v2","transform":Transform2D(0,pivot),"clip_bottom":float(spec.wall_clip_y)},
		{"id":"float_rod_shaft_v2","transform":shaft},
		{"id":"float_rod_pivot_v2","transform":Transform2D(angle,pivot)},
		{"id":"float_rod_socket_v2","transform":Transform2D(angle,socket)}]}

func hand_assembly(obstacle: Dictionary) -> Dictionary:
	return Hand.assembly(obstacle_art.manifest,obstacle_position(obstacle),visual_age(obstacle))

func obstacle_active(obstacle: Dictionary) -> bool:
	return visual_age(obstacle) >= float(obstacle.get("activates_at",0))

func hazard_assembly(obstacle: Dictionary) -> Dictionary:
	if obstacle_frame_id(obstacle).begins_with("strainer_gap_"):
		return Strainer.assembly(obstacle_art.manifest,obstacle_position(obstacle),float(obstacle.depth),visual_age(obstacle))
	return hand_assembly(obstacle)

func draw_hand(host: Node2D, obstacle: Dictionary) -> void:
	for part: Dictionary in hazard_assembly(obstacle).parts:
		host.draw_set_transform_matrix(part.transform)
		obstacle_art.draw_named(host,part.id,Vector2.ZERO,Color(1,1,1,part.alpha))
	host.draw_set_transform(Vector2.ZERO)

func draw_obstacle(host: Node2D, obstacle: Dictionary) -> void:
	var point := obstacle_position(obstacle)
	var id := obstacle_frame_id(obstacle)
	if id == "launch_ramp":
		draw_ramp(host,obstacle,point)
		return
	if not obstacle_active(obstacle):
		if id == "maintenance_hand_gap" and visual_age(obstacle) >= float(obstacle_art.manifest.hand_timeline.warning):
			obstacle_art.draw_named(host,"hand_cracks",point)
		return
	assert(obstacle_art.manifest.frames.has(id),"Missing calibrated obstacle art: "+id)
	if id.begins_with("strainer_gap_"):
		Water.gap(host,obstacle_art,obstacle_art.manifest.frames[id],point,float(obstacle.depth),clock)
		return
	if id == "catch_basin":
		var clip := Rect2(point-Vector2(232.5,100),Vector2(465,200)).intersection(VIEWPORT)
		draw_strip(host,"course_water",clock*(scroll_speed+34),clip)
		Water.surface(host,obstacle_art,clock,clock*scroll_speed,clip)
	obstacle_art.draw_named(host,id,point)
	draw_obstacle_overlays(host,obstacle,false)
	if id == "maintenance_hand_gap":
		var debris_alpha := 1.0-clampf((visual_age(obstacle)-float(obstacle.activates_at))/0.12,0,1)
		if debris_alpha > 0: obstacle_art.draw_named(host,"hand_collapse",point,Color(1,1,1,debris_alpha))

func draw_obstacle_overlays(host: Node2D, obstacle: Dictionary, foreground: bool) -> void:
	if not obstacle_active(obstacle): return
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
	var fall_depth := pow(maxf(0,minf(float(host.death_time),FALL_DURATION)-0.10),2)*460 if falling else 0.0
	var recovery_bounce := sin(recovery_clock/0.6*PI)*20.0
	var anchor := position
	if falling:
		var opening := fall_opening()
		if opening.has_area():
			var inset := Vector2(minf(55,opening.size.x*0.5),minf(14,opening.size.y*0.5))
			var inside := position.clamp(opening.position+inset,opening.end-inset)
			# The collision pit may extend UNDER islands. Move into its actual unsupported opening,
			# never through a solid deck, while retaining the frozen gameplay/checkpoint position.
			anchor = position.lerp(inside,smoothstep(0,0.22,float(host.death_time)))
	return Transform2D(render_pitch,anchor+Vector2(0,-render_height+fall_depth-recovery_bounce))

func failed_gap() -> Dictionary:
	for obstacle: Dictionary in course.obstacles:
		if obstacle.id == str(last_event.get("obstacle_id","")) and obstacle.kind in ["gap","long_pit"]:
			return obstacle
	return {}

func fall_opening() -> Rect2:
	var gap := failed_gap()
	if gap.is_empty(): return Rect2()
	var center := obstacle_position(gap)
	var size := Vector2(float(gap.width),float(gap.depth))
	var openings: Array[Rect2] = [Rect2(center-size*0.5,size)]
	for deck: Dictionary in course.obstacles:
		if deck.kind != "deck": continue
		var deck_size := Vector2(float(deck.width),float(deck.depth))
		var solid := Rect2(obstacle_position(deck)-deck_size*0.5,deck_size)
		var remaining: Array[Rect2] = []
		for region: Rect2 in openings:
			var overlap := region.intersection(solid)
			if not overlap.has_area():
				remaining.append(region)
				continue
			for piece in [Rect2(region.position,Vector2(overlap.position.x-region.position.x,region.size.y)),
				Rect2(Vector2(overlap.end.x,region.position.y),Vector2(region.end.x-overlap.end.x,region.size.y)),
				Rect2(Vector2(overlap.position.x,region.position.y),Vector2(overlap.size.x,overlap.position.y-region.position.y)),
				Rect2(Vector2(overlap.position.x,overlap.end.y),Vector2(overlap.size.x,region.end.y-overlap.end.y))]:
				if piece.has_area(): remaining.append(piece)
		openings = remaining
	var chosen := Rect2()
	var distance := INF
	for region: Rect2 in openings:
		var next := position.distance_squared_to(position.clamp(region.position,region.end))
		if next < distance:
			distance = next
			chosen = region
	return chosen

func fall_clip_bottom(elapsed := INF) -> float:
	var opening := fall_opening()
	if not opening.has_area(): return 540.0
	return lerpf(maxf(position.y+14,opening.end.y),opening.end.y,smoothstep(0.12,0.28,elapsed))

func falling_polygons(frame: Dictionary, transform: Transform2D, elapsed := 0.0) -> Array[PackedVector2Array]:
	var d: Array = frame.destination
	var target := Rect2(d[0],d[1],d[2],d[3])
	var polygon := PackedVector2Array([target.position,Vector2(target.end.x,target.position.y),
		target.end,Vector2(target.position.x,target.end.y)])
	polygon = transform*polygon
	var bottom := fall_clip_bottom(elapsed)
	var left := 0.0
	var right := 960.0
	var opening := fall_opening()
	if opening.has_area():
		var entered := smoothstep(0.12,0.28,elapsed)
		left = lerpf(0,maxf(0,opening.position.x),entered)
		right = lerpf(960,minf(960,opening.end.x),entered)
	return Geometry2D.intersect_polygons(polygon,PackedVector2Array([
		Vector2(left,0),Vector2(right,0),Vector2(right,bottom),Vector2(left,bottom)]))

func draw_falling_frame(host: Node2D, frame: Dictionary, transform: Transform2D, tint: Color) -> void:
	if frame.has("layers"):
		for layer: Dictionary in frame.layers: draw_falling_frame(host,layer,transform,tint)
		return
	var d: Array = frame.destination
	var target := Rect2(d[0],d[1],d[2],d[3])
	var clipped := falling_polygons(frame,transform,float(host.death_time))
	var texture: Texture2D = host.flush.art.textures[frame.path]
	var source := Rect2(frame.source_rect[0],frame.source_rect[1],frame.source_rect[2],frame.source_rect[3])
	for piece: PackedVector2Array in clipped:
		var uv := PackedVector2Array()
		for point: Vector2 in piece:
			var local := transform.affine_inverse()*point
			uv.append((source.position+(local-target.position)/target.size*source.size)/texture.get_size())
		host.draw_polygon(piece,PackedColorArray([tint]),uv,texture)

func fall_occluding_frames(frame: Dictionary, near_edge := -INF) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not bool(frame.get("occludes_fall",true)): return result
	if frame.has("layers"):
		for layer: Dictionary in frame.layers: result.append_array(fall_occluding_frames(layer,near_edge))
	elif float(frame.destination[1]) >= near_edge:
		# Adjacent island tops must not blanket the initial fall at a leading-edge contact.
		result.append(frame)
	return result

func deck_occludes_fall(obstacle: Dictionary) -> bool:
	var opening := fall_opening()
	var front := obstacle_position(obstacle).y+float(obstacle.depth)*0.5
	# A fall over the NEAR edge is in front of the deck's face, not behind that wall.
	return opening.position.y < front-EPS

func draw_fall_occluder(host: Node2D, frame: Dictionary, point: Vector2, near_edge := -INF) -> void:
	for layer: Dictionary in fall_occluding_frames(frame,near_edge):
		obstacle_art.draw_frame(host,layer,point)

func rider_visible(host: Node2D) -> bool:
	# Death freezes the ride clock: never freeze a fatal fall on the hidden damage-blink phase.
	return host.life_state != "alive" or host.invulnerable <= 0 or int(clock*12)%2 == 0

func draw_rider(host: Node2D, flush: RefCounted) -> void:
	var falling: bool = host.life_state != "alive" and events.has("fall")
	if not falling: art.draw_named(host,"shadow",position,Color(1,1,1,clampf(1-render_height/200.0,0.2,1)))
	if rider_visible(host):
		var mode: String = host.difficulty
		var pose: Dictionary = flush.art.manifest.landing[host.employee.id][mode]
		var registration: Array = obstacle_art.manifest.get("rider_contacts",{}).get(host.employee.id,{}).get(mode,[0,0])
		host.draw_set_transform_matrix(rider_transform(host))
		var offset := -Vector2(registration[0],registration[1])
		var alpha := 1.0
		for frame: Dictionary in pose.front:
			if falling:
				host.draw_set_transform(Vector2.ZERO)
				draw_falling_frame(host,frame,rider_transform(host)*Transform2D(0,offset),Color(1,1,1,alpha))
			else: flush.art.draw_frame(host,frame,offset,Color(1,1,1,alpha))
		host.draw_set_transform(Vector2.ZERO)
	if recovery_clock > 0: art.draw_named(host,"splash",position)

func draw(host: Node2D, flush: RefCounted) -> void:
	host.draw_set_transform(Vector2.ZERO)
	host.box(0,0,960,64,Color("101d29"))
	host.label_at("RIDE OBSTACLE TEST",Vector2(24,27),22,host.MINT)
	host.draw_vitals(Vector2(550,10))
	host.label_at("%02d / %02d" % [encounter_index+1,definition.encounters.size()],Vector2(830,52),14,host.MINT)
	if phase == "rest":
		host.label_at("REST — %.1f s" % rest_remaining,Vector2(24,92),22,host.MINT)
	elif phase == "encounter":
		host.label_at("%02d  %s" % [encounter_index+1,str(encounter.get("title",""))],Vector2(24,92),22,host.GOLD)
	if phase == "encounter" and (encounter.has("hand_timeline") or encounter.has("strainer_timeline")):
		var warning := float(encounter.get("hand_timeline",encounter.get("strainer_timeline",{})).warning_at)
		var pit: Dictionary = course.obstacles[0]
		if encounter_clock >= warning and obstacle_position(pit).x+float(pit.width)*0.5 > position.x-HALF.x:
			var response := "DODGE FAR OR JUMP →" if encounter.has("strainer_timeline") else "JUMP THE FULL-WIDTH GAP →"
			host.box(550,470,410,44,Color("101d29"))
			host.label_at("TRACK BREAK AHEAD →" if not obstacle_active(pit) else response,
				Vector2(580,496),18,host.GOLD)

	host.BuildVersion.draw(host)
	if host.paused or host.won:
		host.box(0,0,960,540,Color(0.03,0.07,0.12,0.88))
		if host.life_state in ["death_popup","game_over"]: host.draw_death_popup()
		elif host.won:
			host.label_at("OBSTACLE TEST COMPLETE",Vector2(270,195),28,host.GOLD)
			host.label_at("All %d encounters finished" % definition.encounters.size(),Vector2(330,230),21,host.MINT)
			host.draw_pause_plates()
		else: host.draw_pause_panel()
