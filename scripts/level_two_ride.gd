extends RefCounted
## Deterministic water-plane movement keeps jump rendering separate from swept board contacts.
const Audio = preload("res://scripts/level_two_ride_audio.gd")
const Art = preload("res://scripts/flush_art.gd")
var definition: Dictionary = {}
var course: Dictionary = {}
var art := Art.new()
var audio := Audio.new()
var clock := 0.0
var position := Vector2(300,330)
var jump_age := -1.0
var jump_height := 0.0
var cooldown := 0.0
var complete := false
var events: Dictionary = {}
var hit_ids: Dictionary = {}

func attach(host: Node2D) -> void:
	definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-ride.json"))
	audio.attach(host,definition.audio.cues)
	art.configure(JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/level-two-ride-v1/manifest.json")))

func begin(host: Node2D) -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride.json"))
	course = {"obstacles":[]}
	for source: Dictionary in layout.obstacles:
		if host.difficulty not in source.modes: continue
		var obstacle := source.duplicate(true)
		obstacle.world_x = float(layout.reference_x)+float(layout.scroll_speed)*float(source.crossing_time)
		obstacle.y = (float(source.y_min)+float(source.y_max))*0.5
		obstacle.depth = float(source.y_max)-float(source.y_min)
		course.obstacles.append(obstacle)
	clock = 0
	position = Vector2(300,330)
	jump_age = -1
	jump_height = 0
	cooldown = 0
	complete = false
	events.clear()
	hit_ids.clear()
	audio.stop()
	host.won = false
	host.grounded = true
	sync_hero(host)

func height(age: float) -> float:
	if age < 0 or age >= 1.2: return 0.0
	var u := age/1.2
	return 288.0*u*(1.0-u)

static func overlap_interval(start: Vector2, finish: Vector2, rect: Rect2) -> Vector2:
	var enter := 0.0
	var leave := 1.0
	var motion := finish-start
	for axis in [0,1]:
		if absf(motion[axis]) < 0.000001:
			if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]: return Vector2(-1,-1)
		else:
			var a: float = (rect.position[axis]-start[axis])/motion[axis]
			var b: float = (rect.end[axis]-start[axis])/motion[axis]
			enter = maxf(enter,minf(a,b))
			leave = minf(leave,maxf(a,b))
			if enter > leave: return Vector2(-1,-1)
	return Vector2(enter,leave)

func unsafe_intervals(kind: String, age: float, dt: float, overlap: Vector2) -> Array[Vector2]:
	if kind == "support" or age < 0: return [overlap]
	var ascent := 0.0
	var descent := 1.2
	if kind == "low_barrier":
		var root := sqrt(1.0-28.0/72.0)
		ascent = 0.6*(1.0-root)
		descent = 0.6*(1.0+root)
	var result: Array[Vector2] = []
	for span: Vector2 in [Vector2(-INF,(ascent-age)/dt),Vector2((descent-age)/dt,INF)]:
		var enter := maxf(overlap.x,span.x)
		var leave := minf(overlap.y,span.y)
		if leave > enter or (kind == "gap" and leave == enter): result.append(Vector2(enter,leave))
	return result

func obstacle_rect(obstacle: Dictionary) -> Rect2:
	return Rect2(float(obstacle.world_x)-float(obstacle.width)*0.5,
		float(obstacle.y)-float(obstacle.depth)*0.5,float(obstacle.width),float(obstacle.depth))

func tick(host: Node2D, delta: float, steering: Vector2, jumping: bool) -> void:
	if complete or host.paused or host.life_state != "alive": return
	var dt := minf(delta,45.0-clock)
	if dt <= 0: return
	var start := position+Vector2(clock*180.0,0)
	var old_age := jump_age
	cooldown = maxf(0,cooldown-dt)
	if jumping and jump_age < 0 and cooldown <= 0:
		jump_age = 0
		old_age = 0
		host.play_tone(360.0,0.08)
		events.jump = int(events.get("jump",0))+1
	var input := steering.limit_length()
	position += Vector2(input.x*160.0,input.y*140.0)*dt
	position.x = clampf(position.x,180,650)
	position.y = clampf(position.y,260,400)
	clock += dt
	var finish := position+Vector2(clock*180.0,0)
	var initial_immunity: float = host.invulnerable
	host.hurt_time = maxf(0,host.hurt_time-dt)
	var damaged := false
	var contacts: Array[Dictionary] = []
	for obstacle: Dictionary in course.obstacles:
		var rect := obstacle_rect(obstacle).grow_individual(45,14,45,14)
		var interval := overlap_interval(start,finish,rect)
		if interval.x < 0: continue
		for unsafe: Vector2 in unsafe_intervals(str(obstacle.kind),old_age,dt,interval):
			var contact_at := unsafe.x
			if obstacle.kind != "gap":
				contact_at = maxf(contact_at,initial_immunity/dt)
				if contact_at > unsafe.y: continue
			contacts.append({"obstacle":obstacle,"at":contact_at})
	contacts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.at < b.at)
	var processed_time := 0.0
	for contact: Dictionary in contacts:
		var event_time := float(contact.at)*dt
		host.invulnerable = maxf(0,host.invulnerable-(event_time-processed_time))
		processed_time = event_time
		var obstacle: Dictionary = contact.obstacle
		if obstacle.kind == "gap":
			# Fall owns one normal death transition; immunity cannot supply missing water support.
			host.invulnerable = 0
			host.health = 1
			host.hurt_player()
			events.fall = int(events.get("fall",0))+1
			audio.stop()
			return
		if host.invulnerable <= 0:
			host.hurt_player()
			damaged = true
			hit_ids[obstacle.id] = true
			events.hit = int(events.get("hit",0))+1
			if host.life_state != "alive":
				audio.stop()
				return
			host.tone_time = 0
			audio.play("ride_impact")
	host.invulnerable = maxf(0,host.invulnerable-(dt-processed_time))
	if jump_age >= 0:
		jump_age += dt
		if jump_age >= 1.2:
			jump_age = -1
			cooldown = 0.15
			if not damaged: audio.play("ride_land")
			events.landed = int(events.get("landed",0))+1
	jump_height = height(jump_age)
	sync_hero(host)
	if clock >= 45:
		complete = true
		host.won = true
		audio.stop()
		events.finished = 1

func sync_hero(host: Node2D) -> void:
	host.player = position-Vector2(13,46+jump_height)
	host.grounded = jump_age < 0
	host.velocity = Vector2.ZERO
	host.current_aim = Vector2.RIGHT

func process_audio(host: Node2D, delta: float) -> void:
	audio.advance(delta,host.paused,not complete and host.life_state == "alive")

func draw(host: Node2D, flush: RefCounted) -> void:
	host.draw_set_transform(Vector2.ZERO)
	if art.manifest.is_empty(): return
	var scroll := clock*180.0
	draw_strip(host,"course_far",scroll*0.35)
	draw_strip(host,"course_water",scroll)
	var drawables: Array[Dictionary] = [{"hero":true,"y":position.y}]
	for obstacle: Dictionary in course.obstacles:
		var x := float(obstacle.world_x)-scroll
		if x < -150 or x > 1100: continue
		# Water-plane hazards stay below the airborne rider; only tall supports occlude by depth.
		if obstacle.kind != "support":
			art.draw_named(host,str(obstacle.kind),Vector2(x,float(obstacle.y)))
		else:
			drawables.append({"hero":false,"y":float(obstacle.y),"obstacle":obstacle,"x":x})
	drawables.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.y < b.y)
	for drawable: Dictionary in drawables:
		if drawable.hero:
			var falling := events.has("fall")
			if not falling: art.draw_named(host,"shadow",position,Color(1,1,1,1-jump_height/144.0))
			if host.invulnerable <= 0 or int(clock*12)%2 == 0:
				var pose: Dictionary = flush.art.manifest.landing[host.employee.id]["hard" if host.difficulty == "hard" else "normal"]
				var fall_progress := clampf(float(host.death_time),0,1) if falling else 0.0
				host.draw_set_transform(position-Vector2(0,jump_height)+Vector2(0,sin(clock*3)*1.5+fall_progress*90),sin(clock*2.1)*0.025)
				for frame: Dictionary in pose.front: flush.art.draw_frame(host,frame,Vector2.ZERO,Color(1,1,1,1-fall_progress))
				host.draw_set_transform(Vector2.ZERO)
		else:
			art.draw_named(host,str(drawable.obstacle.kind),Vector2(drawable.x,drawable.y))
	draw_strip(host,"course_near",scroll)
	host.box(0,0,960,64,Color("101d29"))
	host.label_at("THE RIDE",Vector2(24,27),22,host.MINT)
	host.label_at("Steer: arrows / stick   Jump: Space / A",Vector2(24,52),14,host.GOLD)
	host.label_at("%s  HP %d/%d  LIVES %d" % [host.employee.name,host.health,host.employee.max_health,host.lives],
		Vector2(550,27),16,host.GOLD)
	host.label_at("%.0f / 45 s" % clock,Vector2(800,52),14,host.MINT)
	draw_preview(host,scroll)
	host.BuildVersion.draw(host)
	if host.paused or host.won:
		host.box(0,0,960,540,Color(0.03,0.07,0.12,0.88))
		if host.life_state in ["death_popup","game_over"]: host.draw_death_popup()
		elif host.won:
			host.label_at("FIRST STRETCH COMPLETE",Vector2(280,195),28,host.GOLD)
			host.label_at("The next stretch is still under construction",Vector2(235,230),21,host.MINT)
			host.draw_pause_plates()
		else: host.draw_pause_panel()

func draw_strip(host: Node2D, id: String, scroll: float) -> void:
	var first := int(floor(scroll/960.0))
	for tile in [first,first+1]:
		var x := float(tile)*960.0-scroll
		var mirrored: bool = posmod(tile,2) == 1
		host.draw_set_transform(Vector2(x+(960.0 if mirrored else 0.0),0),0,Vector2(-1 if mirrored else 1,1))
		art.draw_named(host,id)
	host.draw_set_transform(Vector2.ZERO)

func draw_preview(host: Node2D, scroll: float) -> void:
	var row := 0
	for obstacle: Dictionary in course.obstacles:
		if float(obstacle.world_x)+float(obstacle.width)*0.5 < scroll+position.x-45: continue
		if clock < float(obstacle.warning_at[host.difficulty]): continue
		var message: String = {"support":"STEER AROUND SUPPORT", "low_barrier":"JUMP LOW BARRIER", "gap":"JUMP GAP"}[obstacle.kind]
		if obstacle.kind == "support": message += " — "+("NEAR BANK" if float(obstacle.y) < 330 else "FAR BANK")
		host.label_at(message,Vector2(24,90+row*22),16,host.GOLD)
		var cue: String = {"support":"cue_support","low_barrier":"cue_barrier","gap":"cue_gap"}[obstacle.kind]
		art.draw_named(host,cue,Vector2(910,250+row*48))
		var distance := float(obstacle.world_x)-float(obstacle.width)*0.5-scroll-position.x-45
		if obstacle.kind != "support" and jump_age < 0 and distance > 0 and distance < 55:
			art.draw_named(host,"jump_ready",position+Vector2(0,-110))
		row += 1
