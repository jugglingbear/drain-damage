extends RefCounted
## A separate bowl simulation preserves first-level state and never advances it during the flush.
const Radio = preload("res://scripts/flush_radio.gd")
const Audio = preload("res://scripts/level_two_flush_audio.gd")
const Flow = preload("res://scripts/flush_flow.gd")
const Debris = preload("res://scripts/flush_debris.gd")
const Art = preload("res://scripts/flush_art.gd")
const WorldView = preload("res://scripts/ride_world_view.gd")
var world_view: Node3D
const Ride = preload("res://scripts/level_two_ride.gd")
var ride := Ride.new()
const Music = preload("res://scripts/flush_music.gd")
const CONTENT := "res://data/level-two-flush.json"
var definition: Dictionary = {}
var debris := Debris.new()
var art := Art.new()
var water_clock := 0.0
var swim_clock := 0.0
var swirl_angle := 0.0
var sink_depth := 0.0
var drain_origin := Vector2.ZERO
var last_steering := Vector2.ZERO
var active := false
var state := "idle"
var clock := 0.0
var prelude_remaining := 0.0
var prelude_duration := 26.0
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
var music := Music.new()
var radio := Radio.new()
var damage_taken := 0
var shots_fired := 0
var input_guard := true

func attach(host: Node2D) -> void:
	definition = JSON.parse_string(FileAccess.get_file_as_string(CONTENT))
	prelude_duration = float(definition.story.timing.calm_prelude_seconds)
	host.add_child(radio)
	audio.attach(host,definition.audio.cues)
	music.attach(host,definition.music)
	art.configure(definition.art)
	ride.attach(host)
	world_view = WorldView.new()
	world_view.attach(host,self)
	radio.transmission.connect(func() -> void: audio.play("radio_chirp"))

func reset() -> void:
	ride.audio.stop()
	ride.music.stop()
	ride.checkpoint_index = 0
	active = false
	state = "idle"
	gag_seen = false
	checkpoint_saved = false
	clock = 0
	prelude_remaining = 0
	hazards.clear()
	shots.clear()
	announced.clear()
	radio.clear()
	audio.stop()
	music.stop()

func center() -> Vector2:
	return Vector2(definition.layout.geometry.bowl_center[0],definition.layout.geometry.bowl_center[1])

func projection() -> float:
	var radii: Array = definition.layout.geometry.water_radii
	return float(radii[1])/float(radii[0])

func surface_depth(point: Vector2) -> float:
	var fraction := clampf(point.length()/360.0,0,1)
	return float(definition.art.get("surface_depth_pixels",0))*pow(1.0-fraction,2)

func project(point: Vector2) -> Vector2:
	return center()+Vector2(point.x,point.y*projection()+surface_depth(point))

func unproject(point: Vector2) -> Vector2:
	var relative := point-center()
	# Depth changes only presentation; invert the monotonic vertical map for explicit screen anchors.
	var low := -720.0
	var high := 720.0
	for iteration in range(32):
		var middle := (low+high)*0.5
		if middle*projection()+surface_depth(Vector2(relative.x,middle)) < relative.y: low = middle
		else: high = middle
	return Vector2(relative.x,(low+high)*0.5)

func surface_transform(point: Vector2) -> Transform2D:
	var gradient := Vector2.ZERO
	if point.length() > 0.001 and point.length() < 360:
		gradient = point.normalized()*(-2.0*float(definition.art.get("surface_depth_pixels",0))
			*(1.0-point.length()/360.0)/360.0)
	# Existing ellipse effects already include the base Y projection; add only the local depth slope.
	return Transform2D(Vector2(1,gradient.x),Vector2(0,1+gradient.y/projection()),project(point))

func begin(host: Node2D, retry := false) -> void:
	ride.music.stop()
	active = true
	state = "bowl"
	clock = 0
	prelude_remaining = prelude_duration
	landing_clock = 0
	checkpoint_saved = false
	var spawn: Array = definition.layout.geometry.hero_spawn
	position = Vector2(float(spawn[0])-center().x,(float(spawn[1])-center().y)/projection())
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
	water_clock = 0
	swim_clock = 0
	swirl_angle = 0
	sink_depth = 0
	last_steering = Vector2.ZERO
	debris.configure(definition.layout,host.difficulty,host.run_seed,definition.art)
	debris.render_frames = definition.art.frames
	hazards = debris.items
	audio.stop()
	music.stop()
	radio.configure(definition.story.routes[host.employee.id],host.difficulty,retry or gag_seen)
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
	if retry:
		# Restore the authored hazard boundary, rather than simulating skipped intro time.
		# A fresh scheduler receives exactly its first cohort, with the full warning duration.
		clock = float(definition.layout.difficulty[host.difficulty].waves[0].at)
		prelude_remaining = 0
		debris.advance(self,host,0)
		# An introductory line ending exactly at the checkpoint is already over.
		while radio.next_index < radio.entries.size():
			var line: Dictionary = radio.entries[radio.next_index]
			if float(line.at)+float(line.get("duration",4.0)) > clock+prelude_duration: break
			radio.next_index += 1
		radio.advance(clock+prelude_duration,0,false)
		announced.onset = true
		audio.play("flush_onset")
	sync_hero(host)

func enter_landing(host: Node2D) -> void:
	ride.music.stop()
	# Shared by survival completion and the direct post-flush playtest entry.
	state = "landing"
	clock = 45.0
	prelude_remaining = 0
	landing_clock = 0.0
	checkpoint_saved = true
	position = unproject(Vector2(480,385))
	jump_height = 0
	jump_velocity = 0
	hazards.clear()
	shots.clear()
	audio.stop()
	music.stop()
	var lines: Array = definition.story.landing_routes[host.employee.id].duplicate(true)
	var at := 0.0
	for line: Dictionary in lines:
		line.at = at
		at += float(line.duration)
	radio.configure(lines,host.difficulty,false)
	radio.advance(0,0,false)
	sync_hero(host)

func enter_ride(host: Node2D, encounter_index := -1) -> void:
	state = "ride"
	checkpoint_saved = true
	radio.clear()
	audio.stop()
	music.stop()
	ride.begin(host,encounter_index)
	input_guard = true

func sync_hero(host: Node2D) -> void:
	if state == "ride":
		ride.sync_hero(host)
		return
	host.player = project(position)-Vector2(13,46)-Vector2(0,jump_height*projection())
	host.current_aim = aim
	host.grounded = jump_height <= 0

func tick(host: Node2D, delta: float, steering: Vector2, _jumping: bool, _firing: bool) -> void:
	# Bound collision travel and split exactly where the scripted capture takes ownership.
	if state in ["ride","landing"]:
		_tick_step(host,delta,steering,_jumping,_firing)
		return
	var remaining := delta
	while remaining > 0.000001 and active and not host.paused and host.life_state == "alive":
		var step := minf(remaining,1.0/120.0)
		if prelude_remaining > 0: step = minf(step,prelude_remaining)
		elif clock < 35: step = minf(step,35-clock)
		_tick_step(host,step,steering,_jumping,_firing)
		remaining -= step

func _tick_step(host: Node2D, delta: float, steering: Vector2, _jumping: bool, _firing: bool) -> void:
	if not active or host.paused or host.life_state != "alive" or host.won: return
	if state == "ride":
		ride.tick(host,delta,steering,_jumping,_firing)
		return
	if state == "landing":
		landing_clock += delta
		radio.advance(landing_clock,delta,false)
		if radio.next_index >= radio.entries.size() and radio.current.is_empty(): enter_ride(host)
		return
	if state == "bowl" and clock < 35 and drain_contact(position):
		enter_drain_death(host)
		return
	if prelude_remaining > 0:
		var reading_delta := minf(delta,prelude_remaining)
		prelude_remaining = maxf(0,prelude_remaining-reading_delta)
		if prelude_remaining < 0.000001: prelude_remaining = 0
		water_clock += reading_delta
		swim_clock += reading_delta*(1.0 if steering.length() > 0.1 else 0.35)
		host.invulnerable = maxf(0,host.invulnerable-reading_delta)
		host.hurt_time = maxf(0,host.hurt_time-reading_delta)
		move_hero(host,reading_delta,steering,false)
		if host.life_state != "alive": return
		sync_hero(host)
		radio.advance(prelude_duration-prelude_remaining,reading_delta,false)
		delta -= reading_delta
		if delta <= 0.000001: return
	# Resolve the final controllable interval before making the finale immune.
	if clock < 35 and clock+delta >= 35:
		move_hero(host,delta,steering,false,true)
		if host.life_state != "alive": return
	clock = minf(45.0,clock+delta)
	if 45.0-clock < 0.000001: clock = 45.0
	water_clock += delta*lerpf(1.0,1.8,clampf(clock/43.0,0,1))
	swirl_angle += Flow.visual_speed(clock)*delta
	swim_clock += delta*(1.0 if steering.length() > 0.1 else 0.35)
	host.invulnerable = maxf(0,host.invulnerable-delta)
	host.hurt_time = maxf(0,host.hurt_time-delta)
	fire_clock = maxf(0,fire_clock-delta)
	if clock >= 35:
		if state != "drain":
			state = "drain"
			drain_origin = position
			shots.clear()
			audio.play("flush_surge")
		if clock < 40:
			var progress := smoothstep(35.0,40.0,clock)
			position = drain_origin.rotated((clock-35.0)*1.8)*(1.0-progress)
		else:
			position = Vector2.ZERO
			sink_depth = smoothstep(40.0,43.0,clock)
			if not announced.has("burble"):
				announced.burble = true
				audio.play("suction_burble")
		debris.advance(self,host,delta)
		if clock >= 43: position = unproject(Vector2(480,385))
		if clock >= 45:
			enter_landing(host)
			return
	else:
		move_hero(host,delta,steering,false)
		if host.life_state != "alive": return
		# Swimming owns this sequence: neither held nor tapped attack/jump inputs create effects.
		debris.advance(self,host,delta)
		if host.life_state != "alive": return
	sync_hero(host)
	radio.advance(clock+prelude_duration,delta,false)
	if clock >= 8 and not announced.has("onset"):
		announced.onset = true
		audio.play("flush_onset")

func drain_contact(point: Vector2) -> bool:
	var radii: Array = definition.layout.geometry.drain_visual_radii
	return Flow.drain_contact(point,Vector2(radii[0],radii[1]),projection(),
		float(definition.art.get("surface_depth_pixels",0)),
		float(definition.layout.geometry.hero_collision_radius))

func enter_drain_death(host: Node2D) -> void:
	if host.life_state != "alive" or state != "bowl" or clock >= 35: return
	state = "drain_death"
	drain_origin = position
	sink_depth = 0
	shots.clear()
	hazards.clear()
	host.health = 1
	host.invulnerable = 0
	host.hurt_player()
	sync_hero(host)

func move_hero(host: Node2D, delta: float, steering: Vector2, _jumping: bool, capture_boundary := false) -> void:
	var start_position := position
	var input := steering.limit_length()
	if input.length() > 0.1:
		aim = Vector2(roundf(input.x),roundf(input.y)).normalized()
		if aim == Vector2.ZERO: aim = input.normalized()
		host.facing = -1 if aim.x < 0 else 1
	last_steering = input
	position = Flow.swim(position,input,float(host.employee.move_speed),clock,delta,
		definition.layout.difficulty[host.difficulty].flow)
	if clock < 35 and drain_contact(position):
		var low := 0.0
		var high := 1.0
		# Four refinements locate the fall within 1/16 of a 120 Hz step without a frame stall.
		for iteration in range(4):
			var middle := (low+high)*0.5
			if drain_contact(start_position.lerp(position,middle)): high = middle
			else: low = middle
		# Exact 35s contact belongs to capture; an earlier entry still kills on a straddling frame.
		if not capture_boundary or high < 1.0-0.000001 or drain_contact(start_position.lerp(position,1.0-0.000001)):
			position = start_position.lerp(position,high)
			enter_drain_death(host)
			return
	jump_height = 0
	jump_velocity = 0
	host.animation_state = "idle"
	host.animation_time += delta

func process_audio(host: Node2D, delta: float) -> void:
	if state == "ride":
		ride.process_audio(host,delta)
		return
	audio.advance(delta,host.paused or input_guard or host.life_state != "alive",active and clock < 43 and host.life_state == "alive",
		not radio.current.is_empty(),clampf(clock/35.0,0,1))
	music.advance(clock,delta,host.paused or input_guard,
		active and prelude_remaining <= 0 and clock < 45 and host.life_state == "alive" and not host.won,
		not radio.current.is_empty(),audio.voices.panic.playing)
	radio.visible = active and host.life_state == "alive" and not host.paused and not host.won

func finish(host: Node2D) -> void:
	ride.music.stop()
	state = "complete"
	host.won = true
	radio.clear()
	audio.stop()
	music.stop()
	host.dialogue.awaiting_release = true
	host.dialogue.release_guard = 0.2

func dispose() -> void:
	ride.audio.dispose()
	ride.music.dispose()
	audio.dispose()
	music.dispose()
	radio.clear()

func draw_bowl_actors(host: Node2D) -> void:
	for item: Dictionary in hazards: art.shadows(host,self,item)
	var ordered := hazards.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return project(a.pos).y < project(b.pos).y)
	for item: Dictionary in ordered: art.debris(host,self,item)
	var submerging := clock >= 40.0 or state == "drain_death"
	# The opaque throat patch belongs behind an active swimmer, even at the front of the bowl.
	# Both fatal entry and scripted descent put the throat patch over the sinking hero.
	if not submerging: art.draw_named(host,"drain_front",project(Vector2.ZERO))
	if host.invulnerable <= 0 or int(clock*12)%2 == 0 or state != "bowl": art.swimmer(host,self)
	if submerging:
		art.draw_named(host,"drain_front",project(Vector2.ZERO))
		art.draw_frame(host,art.frame_at("burble",host.death_time if state == "drain_death" else clock-40),project(Vector2.ZERO))

func draw(host: Node2D) -> void:
	if state == "ride":
		ride.draw(host,self)
		return
	host.draw_set_transform(Vector2.ZERO)
	if clock < 43:
		draw_frame(host,"bowl_top")
		draw_frame(host,"bowl")
		art.water(host,self)
		art.draw_named(host,"drain_back",project(Vector2.ZERO))
	if clock < 43:
		draw_bowl_actors(host)
	host.box(0,0,960,64,Color("101d29"))
	host.label_at("THE FLUSH",Vector2(24,27),22,host.MINT)
	host.draw_vitals(Vector2(550,10))
	host.BuildVersion.draw(host)
	if host.paused or host.won:
		host.box(0,0,960,540,Color(0.03,0.07,0.12,0.88))
		if host.life_state in ["death_popup","game_over"]: host.draw_death_popup()
		elif host.won:
			host.label_at("LOG LANDING REACHED",Vector2(280,195),28,host.GOLD)
			host.label_at("Log ride under construction",Vector2(310,230),21,host.MINT)
			host.draw_pause_plates()
		else: host.draw_pause_panel()

func draw_frame(host: Node2D, id: String, offset := Vector2.ZERO, tint := Color.WHITE) -> void:
	art.draw_named(host,id,offset,tint)
