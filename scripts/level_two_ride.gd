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

func attach(host: Node2D) -> void:
	audio_definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-ride.json"))
	audio.attach(host,audio_definition.audio.cues)
	art.configure(JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/level-two-ride-v1/manifest.json")))
	if FileAccess.file_exists(SHOWCASE_ART):
		obstacle_art.configure(JSON.parse_string(FileAccess.get_file_as_string(SHOWCASE_ART)))

func begin(host: Node2D, index := -1) -> void:
	super.begin(host,checkpoint_index if index < 0 else index)
	audio.stop()
	mechanism_cycle = -1

func tick(host: Node2D, delta: float, steering: Vector2, jumping: bool) -> void:
	if host.paused or host.life_state != "alive" or complete: return
	var before := events.duplicate()
	var previous_encounter := encounter_index
	super.tick(host,delta,steering,jumping)
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
		var base := Vector2(float(obstacle.x)-encounter_scroll,float(obstacle.y))
		obstacle_art.draw_named(host,"float_sweep_shadow",base)
		var offset := obstacle_position(obstacle)-base
		host.draw_set_transform(base+Vector2(-185,-28),atan2(offset.y,150))
		obstacle_art.draw_named(host,"float_arm",Vector2(185,28))
		host.draw_set_transform(Vector2.ZERO)

func draw_obstacle(host: Node2D, obstacle: Dictionary) -> void:
	var point := obstacle_position(obstacle)
	if point.x+float(obstacle.width)*0.5 < -200 or point.x-float(obstacle.width)*0.5 > 1160: return
	var id := obstacle_frame_id(obstacle)
	if id == "launch_ramp":
		draw_ramp(host,obstacle,point)
		return
	assert(obstacle_art.manifest.frames.has(id),"Missing calibrated obstacle art: "+id)
	obstacle_art.draw_named(host,id,point)

func rider_transform(host: Node2D) -> Transform2D:
	var falling: bool = host.life_state != "alive" and events.has("fall")
	var fall_depth := clampf(float(host.death_time),0,1)*90 if falling else 0.0
	var recovery_bounce := sin(recovery_clock/0.6*PI)*20.0
	return Transform2D(render_pitch,position+Vector2(0,-render_height+fall_depth-recovery_bounce))

func draw_rider(host: Node2D, flush: RefCounted) -> void:
	var falling: bool = host.life_state != "alive" and events.has("fall")
	if not falling: art.draw_named(host,"shadow",position,Color(1,1,1,clampf(1-render_height/200.0,0.2,1)))
	if host.invulnerable <= 0 or int(clock*12)%2 == 0:
		var mode := "hard" if host.difficulty == "hard" else "normal"
		var pose: Dictionary = flush.art.manifest.landing[host.employee.id][mode]
		var registration: Array = obstacle_art.manifest.get("rider_contacts",{}).get(host.employee.id,{}).get(mode,[0,0])
		host.draw_set_transform_matrix(rider_transform(host))
		var offset := -Vector2(registration[0],registration[1])
		var alpha := 1.0-clampf(float(host.death_time),0,1) if falling else 1.0
		for frame: Dictionary in pose.front: flush.art.draw_frame(host,frame,offset,Color(1,1,1,alpha))
		host.draw_set_transform(Vector2.ZERO)
	if recovery_clock > 0: art.draw_named(host,"splash",position)

func draw(host: Node2D, flush: RefCounted) -> void:
	host.draw_set_transform(Vector2.ZERO)
	var scroll := clock*scroll_speed
	draw_strip(host,"course_far",scroll*0.35)
	draw_strip(host,"course_water",scroll)
	var foreground: Array[Dictionary] = []
	for obstacle: Dictionary in course.obstacles:
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
