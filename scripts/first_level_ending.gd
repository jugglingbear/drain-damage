extends RefCounted
## The portal ends this playable level; it never starts the held second-level proposal.
const MANIFEST := "res://assets/world/first-call/portal-manifest-v1.json"
const TARGET := Vector2(14970,320)
const PULL_SECONDS := 2.5
var state := "idle"
var clock := 0.0
var pull_clock := 0.0
var start_position := Vector2.ZERO
var definition: Dictionary = {}
var textures: Dictionary = {}

func prepare() -> bool:
	if not FileAccess.file_exists(MANIFEST): return false
	definition = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for frame: Dictionary in definition.frames:
		if not textures.has(frame.path): textures[frame.path] = load("res://"+frame.path)
	return not definition.frames.is_empty() and not textures.values().has(null)

func reset() -> void:
	state = "idle"
	clock = 0
	pull_clock = 0
	start_position = Vector2.ZERO

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
	host.dialogue.start(host.Story.completion(host.employee.id))

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
		host.won = true
		host.dialogue.awaiting_release = true
		host.dialogue.release_guard = 0.2

func hero_scale() -> float:
	return lerpf(1,0.03,smoothstep(0.4,1,pull_clock/PULL_SECONDS))

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
