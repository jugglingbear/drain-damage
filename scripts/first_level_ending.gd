extends RefCounted
## The portal preserves its departure presentation, then hands the selected hero to Level 2.
const MANIFEST := "res://assets/world/first-call/portal-manifest-v1.json"
const DEPARTURE_MANIFEST := "res://assets/world/first-call/portal-departure-manifest-v1.json"
const PORTAL_PLANE := 14970.0
const TARGET := Vector2(15050,332)
const PULL_SECONDS := 2.5
var state := "idle"
var clock := 0.0
var pull_clock := 0.0
var start_position := Vector2.ZERO
var definition: Dictionary = {}
var departure: Dictionary = {}
var textures: Dictionary = {}
var panic_text := ""

func prepare() -> bool:
	if not FileAccess.file_exists(MANIFEST): return false
	definition = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for frame: Dictionary in definition.frames:
		if not textures.has(frame.path): textures[frame.path] = load("res://"+frame.path)
	if not FileAccess.file_exists(DEPARTURE_MANIFEST): return false
	departure = JSON.parse_string(FileAccess.get_file_as_string(DEPARTURE_MANIFEST))
	load_frames(departure)
	return not definition.frames.is_empty() and not textures.values().has(null)

func load_frames(value: Variant) -> void:
	if value is Dictionary:
		if value.has("path") and value.has("source_rect"):
			if not textures.has(value.path): textures[value.path] = load("res://"+value.path)
		for child in value.values(): load_frames(child)
	elif value is Array:
		for child in value: load_frames(child)

func reset() -> void:
	state = "idle"
	clock = 0
	pull_clock = 0
	start_position = Vector2.ZERO
	panic_text = ""

func active() -> bool:
	return state != "idle"

func begin(host: Node2D) -> void:
	if active(): return
	state = "dialogue"
	host.velocity = Vector2.ZERO
	host.shots.clear()
	for shot: Dictionary in host.hostile_shots: host.trial_state.remove_bullet(shot.id)
	host.hostile_shots.clear()
	host.boss_hud.end_encounter()
	host.camera_x = host.ClogfatherRoom.START
	var lines: Array[Dictionary] = host.Story.completion(host.employee.id).duplicate(true)
	panic_text = str(lines.pop_back().text)
	host.dialogue.start(lines)

func step(host: Node2D, delta: float) -> void:
	if not active() or state == "complete" or host.paused: return
	clock += delta
	if state == "dialogue":
		if host.dialogue.active or host.dialogue.awaiting_release or host.dialogue.release_guard > 0: return
		state = "pull"
		start_position = host.player
		host.grounded = false
		host.animation_state = "rising"
		host.animation_time = 0
		return
	pull_clock = minf(PULL_SECONDS,pull_clock+delta)
	var progress := pull_clock/PULL_SECONDS
	# Acceleration makes the involuntary pull visible before the final disappearance.
	host.player = start_position.lerp(TARGET-host.PLAYER_SIZE*0.5,progress*progress)
	host.animation_time += delta
	if pull_clock >= PULL_SECONDS:
		state = "complete"
		host.begin_level_two()
		host.dialogue.awaiting_release = true
		host.dialogue.release_guard = 0.2

func hero_scale() -> float:
	return 1.0

func hero_frame(host: Node2D) -> Dictionary:
	return departure.heroes["hard" if host.difficulty == "hard" else "normal"][host.employee.id]

func clipped_hero(frame: Dictionary, feet: Vector2) -> Dictionary:
	var destination: Array = frame.destination
	var anchor := Vector2(frame.anchor[0],frame.anchor[1])
	var target := Rect2(feet-anchor+Vector2(destination[0],destination[1]),Vector2(destination[2],destination[3]))
	var source: Array = frame.source_rect
	var crop := Rect2(source[0],source[1],source[2],source[3])
	# Occlude pixels at the aperture while retaining the original scale and body height.
	var visible_width := clampf(PORTAL_PLANE-target.position.x,0,target.size.x)
	crop.size.x *= visible_width/target.size.x
	target.size.x = visible_width
	return {"target":target,"source":crop}

func draw_hero(host: Node2D) -> void:
	if state != "pull": return
	var frame := hero_frame(host)
	var visible := clipped_hero(frame,host.player+Vector2(13,46))
	if visible.target.has_area():
		host.draw_texture_rect_region(textures[frame.path],visible.target,visible.source)

func draw_surge(host: Node2D, foreground: bool) -> void:
	if state != "pull": return
	var frames: Array = departure.surge_front if foreground else departure.surge_back
	if frames.is_empty(): return
	var position := pull_clock*float(departure.get("fps",12))
	var index := int(position)%frames.size()
	var entrance := smoothstep(0,0.18,pull_clock)
	draw_frame(host,frames[index],entrance*(1-fposmod(position,1)))
	draw_frame(host,frames[(index+1)%frames.size()],entrance*fposmod(position,1))

func draw_shout(host: Node2D) -> void:
	if state != "pull": return
	var x := clampf(host.player.x-host.camera_x-90,20,700)
	var y := clampf(host.player.y-45,135,360)
	host.label_at(panic_text,Vector2(x+1,y+1),20,Color("08141c"))
	host.label_at(panic_text,Vector2(x,y),20,Color("fff6d5"))

func draw_portal(host: Node2D) -> void:
	if not active() or definition.is_empty(): return
	var frames: Array = definition.frames
	var position := clock*float(definition.get("fps",12))
	var index := int(position)%frames.size()
	draw_frame(host,frames[index],1-fposmod(position,1))
	draw_frame(host,frames[(index+1)%frames.size()],fposmod(position,1))

func draw_frame(host: Node2D, frame: Dictionary, alpha: float) -> void:
	var destination: Array = frame.destination
	var source: Array = frame.source_rect
	host.draw_texture_rect_region(textures[frame.path],
		Rect2(host.ClogfatherRoom.START+destination[0],destination[1],destination[2],destination[3]),
		Rect2(source[0],source[1],source[2],source[3]),Color(1,1,1,alpha))
