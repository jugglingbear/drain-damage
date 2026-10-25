extends RefCounted
## A separate bowl simulation preserves first-level state and never advances it during the flush.
const Radio = preload("res://scripts/flush_radio.gd")
const Audio = preload("res://scripts/level_two_flush_audio.gd")
const CONTENT := "res://data/level-two-flush.json"
var definition: Dictionary = {}
var active := false
var state := "idle"
var clock := 0.0
var landing_clock := 0.0
var gag_seen := false
var checkpoint_saved := false
var position := Vector2.ZERO
var aim := Vector2.RIGHT
var jump_height := 0.0
var jump_velocity := 0.0
var fire_clock := 0.0
var hazards: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var announced: Dictionary = {}
var audio := Audio.new()
var radio := Radio.new()
var textures: Dictionary = {}
var damage_taken := 0
var shots_fired := 0
var input_guard := true

func attach(host: Node2D) -> void:
	definition = JSON.parse_string(FileAccess.get_file_as_string(CONTENT))
	host.add_child(radio)
	audio.attach(host,definition.audio.cues)
	for frame: Dictionary in definition.art.frames.values():
		if not textures.has(frame.path): textures[frame.path] = load("res://"+str(frame.path))
	radio.transmission.connect(func() -> void: audio.play("radio_chirp"))

func reset() -> void:
	active = false
	state = "idle"
	gag_seen = false
	checkpoint_saved = false
	clock = 0
	hazards.clear()
	shots.clear()
	announced.clear()
	radio.clear()
	audio.stop()

func center() -> Vector2:
	return Vector2(definition.layout.geometry.bowl_center[0],definition.layout.geometry.bowl_center[1])

func projection() -> float:
	var radii: Array = definition.layout.geometry.water_radii
	return float(radii[1])/float(radii[0])

func project(point: Vector2) -> Vector2:
	return center()+Vector2(point.x,point.y*projection())

func unproject(point: Vector2) -> Vector2:
	var relative := point-center()
	return Vector2(relative.x,relative.y/projection())

func begin(host: Node2D, retry := false) -> void:
	active = true
	state = "bowl"
	clock = 0
	landing_clock = 0
	checkpoint_saved = false
	position = unproject(Vector2(definition.layout.geometry.hero_spawn[0],definition.layout.geometry.hero_spawn[1]))
	aim = Vector2.RIGHT
	jump_height = 0
	jump_velocity = 0
	fire_clock = 0
	hazards.clear()
	shots.clear()
	announced.clear()
	damage_taken = 0
	shots_fired = 0
	input_guard = true
	audio.stop()
	radio.configure(definition.story.routes[host.employee.id],host.difficulty == "hard",retry or gag_seen)
	gag_seen = true
	host.won = false
	host.camera_x = 0
	host.boss_hud.end_encounter()
	host.boss_intro.reset()
	host.dialogue.finish()
	host.dispenser.cancel()
	host.enemies.clear()
	host.actors.clear()
	host.swarms.actors.clear()
	host.shots.clear()
	host.hostile_shots.clear()
	host.skitterling.audio.stop()
	host.clogfather.audio.stop()
	host.swarm_audio.stop()
	host.starter_weapon_audio.stop()
	host.hero_death_audio.stop()
	host.checkpoint_active = true
	host.checkpoint_index = 3
	host.respawn_origin = 15200
	host.life_state = "alive"
	host.velocity = Vector2.ZERO
	host.grounded = true
	host.animation_state = "idle"
	host.transform = Transform2D.IDENTITY
	if host.music_director != null: host.music_director.stop_music()
	sync_hero(host)

func enter_landing(host: Node2D) -> void:
	# Shared by survival completion and the direct post-flush playtest entry.
	state = "landing"
	clock = 45.0
	landing_clock = 0.0
	checkpoint_saved = true
	position = unproject(Vector2(480,385))
	jump_height = 0
	jump_velocity = 0
	hazards.clear()
	shots.clear()
	audio.stop()
	var lines: Array = definition.story.landing_routes[host.employee.id].duplicate(true)
	var at := 0.0
	for line: Dictionary in lines:
		line.at = at
		at += float(line.duration)
	radio.configure(lines,host.difficulty == "hard",false)
	radio.advance(0,0,false)
	sync_hero(host)

func sync_hero(host: Node2D) -> void:
	host.player = project(position)-Vector2(13,46)-Vector2(0,jump_height*projection())
	host.current_aim = aim
	host.grounded = jump_height <= 0

func tick(host: Node2D, delta: float, steering: Vector2, jumping: bool, firing: bool) -> void:
	if not active or host.paused or host.life_state != "alive" or host.won: return
	if state == "landing":
		landing_clock += delta
		radio.advance(landing_clock,delta,false)
		if radio.next_index >= radio.entries.size() and radio.current.is_empty(): finish(host)
		return
	clock = minf(45.0,clock+delta)
	host.invulnerable = maxf(0,host.invulnerable-delta)
	host.hurt_time = maxf(0,host.hurt_time-delta)
	fire_clock = maxf(0,fire_clock-delta)
	if clock >= 35:
		if state != "drain":
			state = "drain"
			hazards.clear()
			shots.clear()
			audio.play("flush_surge")
		position = position.move_toward(Vector2.ZERO,70*delta)
		jump_height = move_toward(jump_height,0,120*delta)
		if clock >= 43:
			position = unproject(Vector2(480,385))
		if clock >= 45:
			enter_landing(host)
			return
	else:
		move_hero(host,delta,steering,jumping)
		if firing and fire_clock <= 0:
			shots.append({"pos":position,"dir":aim,"distance":0.0})
			shots_fired += 1
			fire_clock = host.weapon.attack_interval_seconds
			host.starter_weapon_audio.play_shot(host.employee.id)
		step_hazards(host,delta)
		step_shots(host,delta)
	sync_hero(host)
	radio.advance(clock,delta,false)
	if clock >= 8 and not announced.has("onset"):
		announced.onset = true
		audio.play("flush_onset")

func move_hero(host: Node2D, delta: float, steering: Vector2, jumping: bool) -> void:
	var input := steering.limit_length()
	if input.length() > 0.1:
		aim = Vector2(roundf(input.x),roundf(input.y)).normalized()
		if aim == Vector2.ZERO: aim = input.normalized()
		host.facing = -1 if aim.x < 0 else 1
	var current := float({"easy":40,"normal":60,"hard":80}[host.difficulty])
	var tangent := Vector2(-position.y,position.x).normalized()
	position += (input*float(host.employee.move_speed)+tangent*current)*delta
	var radius := float(definition.layout.geometry.water_radii[0])
	var bounds: Array = definition.layout.geometry.playable_normalized_radius
	position = position.normalized()*clampf(position.length(),radius*bounds[0],radius*bounds[1])
	if jumping and jump_height <= 0:
		jump_velocity = 465
		host.play_tone(360.0,0.08)
	if jump_velocity != 0 or jump_height > 0:
		jump_velocity -= 1250*delta
		jump_height = maxf(0,jump_height+jump_velocity*delta)
		if jump_height == 0: jump_velocity = 0
	host.animation_state = "rising" if jump_height > 0 else "run" if input.length() > 0.1 else "idle"
	host.animation_time += delta

func step_hazards(host: Node2D, _delta: float) -> void:
	for event: Dictionary in definition.layout.difficulty[host.difficulty].hazards:
		if clock < float(event.at) or announced.has(event.id): continue
		announced[event.id] = true
		var entry: Dictionary = event.duplicate(true)
		entry.pos = Vector2.from_angle(float(event.angle_radians))*360.0*float(event.radius_fraction)
		entry.hp = 24 if event.kind == "soft" else 999999
		if reachable_safe_pocket(entry): hazards.append(entry)
	for index in range(hazards.size()-1,-1,-1):
		var hazard := hazards[index]
		var impact := float(hazard.at)+float(hazard.warning_seconds)
		if clock >= impact+float(hazard.lifetime_seconds) or hazard.hp <= 0:
			hazards.remove_at(index)
			continue
		if clock < impact: continue
		if not hazard.get("sounded",false):
			hazard.sounded = true
			audio.play("debris_impact")
		if jump_height <= 24 and position.distance_to(hazard.pos) < float(hazard.radius_pixels)+float(definition.layout.geometry.hero_collision_radius):
			var before: int = host.health
			host.hurt_player()
			if host.health < before: damage_taken += 1

func step_shots(host: Node2D, delta: float) -> void:
	for index in range(shots.size()-1,-1,-1):
		var shot := shots[index]
		var start: Vector2 = shot.pos
		var distance: float = host.weapon.projectile.speed_pixels_per_second*delta
		shot.pos += shot.dir*distance
		shot.distance += distance
		var hit := false
		for hazard: Dictionary in hazards:
			if hazard.kind == "hard" and clock < float(hazard.at)+float(hazard.warning_seconds): continue
			# Soft plugs float visibly at the target plane throughout the warning.
			var nearest := Geometry2D.get_closest_point_to_segment(hazard.pos,start,shot.pos)
			if nearest.distance_to(hazard.pos) > float(hazard.radius_pixels): continue
			if hazard.kind == "soft":
				hazard.hp -= host.weapon.damage
				if hazard.hp <= 0: audio.play("debris_break")
			hit = true
			break
		if hit or shot.distance >= float(host.weapon.projectile.max_travel_distance_pixels): shots.remove_at(index)

func process_audio(host: Node2D, delta: float) -> void:
	audio.advance(delta,host.paused or host.life_state != "alive",active and clock < 43 and host.life_state == "alive",
		not radio.current.is_empty())
	radio.visible = active and host.life_state == "alive" and not host.paused and not host.won

func finish(host: Node2D) -> void:
	state = "complete"
	host.won = true
	radio.clear()
	audio.stop()
	host.dialogue.awaiting_release = true
	host.dialogue.release_guard = 0.2

func dispose() -> void:
	audio.dispose()
	radio.clear()

func draw(host: Node2D) -> void:
	host.draw_set_transform(Vector2.ZERO)
	if clock >= 43:
		draw_frame(host,"landing")
		draw_frame(host,"log")
	else:
		draw_frame(host,"bowl_top")
		draw_frame(host,"bowl")
		var plane := Transform2D(0,Vector2(1,projection()),0,center())
		host.draw_set_transform_matrix(plane*Transform2D(clock*0.12,Vector2.ZERO))
		var current: Dictionary = definition.art.frames.current
		host.draw_texture_rect_region(textures[current.path],Rect2(-360,-360,720,720),
			host.region(current.source_rect),Color(1,1,1,0.18))
		host.draw_set_transform(Vector2.ZERO)
	draw_frame(host,"shadow",project(position))
	var drawables: Array[Dictionary] = [{"hero":true,"pos":position}]
	for hazard: Dictionary in hazards:
		var point := project(hazard.pos)
		var impact: float = float(hazard.at)+float(hazard.warning_seconds)
		if clock < impact:
			draw_frame(host,"warning",point,Color(1,1,1,0.65+0.35*sin(clock*12)))
		drawables.append({"hero":false,"pos":hazard.pos,"hazard":hazard})
	drawables.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.pos.y < b.pos.y)
	for drawable: Dictionary in drawables:
		if drawable.hero:
			if host.invulnerable <= 0 or int(clock*12)%2 == 0 or state != "bowl": host.world_art.hero_aim_art.draw(host)
		else:
			var hazard: Dictionary = drawable.hazard
			var remaining := maxf(0,float(hazard.at)+float(hazard.warning_seconds)-clock)
			draw_frame(host,str(hazard.kind),project(hazard.pos)-Vector2(0,remaining*36 if hazard.kind == "hard" else 0))
			if remaining == 0: draw_frame(host,"splash",project(hazard.pos))
	for shot: Dictionary in shots:
		var point := project(shot.pos)
		var direction := Vector2(shot.dir.x,shot.dir.y*projection())
		host.draw_set_transform(point,direction.angle())
		# Retain the already integrated starter projectile presentation.
		if host.employee.id == "tony":
			host.box(-15,-2,21,4,Color("70dfff"))
			host.box(-4,-1,12,2,Color("eaffff"))
		else:
			host.box(-16,-1,16,3,Color("ad7546"))
			host.box(0,-5,5,11,Color("e57356"))
		host.draw_set_transform(Vector2.ZERO)
	host.box(0,0,960,64,Color("101d29"))
	host.label_at("THE FLUSH",Vector2(24,27),22,host.MINT)
	host.label_at("Steer: arrows / stick   Jump: Space / A   Fire: Enter / X",Vector2(24,52),14,host.GOLD)
	host.label_at("%s  HP %d/%d  LIVES %d" % [host.employee.name,host.health,host.employee.max_health,host.lives],
		Vector2(550,27),16,host.GOLD)
	host.label_at("%.0f / 45 s" % clock,Vector2(800,52),14,host.MINT)
	host.BuildVersion.draw(host)
	if host.paused or host.won:
		host.box(0,0,960,540,Color(0.03,0.07,0.12,0.88))
		if host.life_state in ["death_popup","game_over"]: host.draw_death_popup()
		elif host.won:
			host.label_at("LOG LANDING REACHED",Vector2(280,195),28,host.GOLD)
			host.label_at("Log ride under construction",Vector2(310,230),21,host.MINT)
			host.draw_pause_plates()
		else: host.draw_pause_panel()

func reachable_safe_pocket(incoming: Dictionary) -> bool:
	var obstacles: Array[Dictionary] = hazards.duplicate()
	obstacles.append(incoming)
	var budget := maxf(0,float(incoming.warning_seconds)-0.15)*155.0
	for radius in [0.48,0.66,0.85]:
		for index in range(72):
			var candidate: Vector2 = Vector2.from_angle(index*TAU/72)*360.0*radius
			if position.distance_to(candidate) > budget: continue
			var safe := true
			for obstacle: Dictionary in obstacles:
				if candidate.distance_to(obstacle.pos) < 48.0:
					safe = false
					break
			if not safe: continue
			for step in range(21):
				var point := position.lerp(candidate,step/20.0)
				if point.length() < 360*.45 or point.length() > 360*.88:
					safe = false
					break
				for obstacle: Dictionary in hazards:
					if clock >= float(obstacle.at)+float(obstacle.warning_seconds) \
							and point.distance_to(obstacle.pos) < 36.0:
						safe = false
						break
			if safe: return true
	return false

func draw_frame(host: Node2D, id: String, offset := Vector2.ZERO, tint := Color.WHITE) -> void:
	var frame: Dictionary = definition.art.frames[id]
	var destination: Rect2 = host.region(frame.destination)
	destination.position += offset
	host.draw_texture_rect_region(textures[frame.path],destination,host.region(frame.source_rect),tint)
