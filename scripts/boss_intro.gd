extends Node2D
## Screen-space entrance title; combat resumes at the first fade-out instant.
const MANIFEST := "res://assets/ui/boss-intro-v1/manifest.json"
const FADE_IN := 0.4
const HOLD := 3.0
const FADE_OUT := 0.25
const RESUME_AT := FADE_IN+HOLD
var definition: Dictionary = {}
var textures: Dictionary = {}
var seen: Dictionary = {}
var boss_id := ""
var clock := 0.0

func _ready() -> void:
	set_as_top_level(true)
	z_index = 15
	definition = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for id: String in definition.frames:
		textures[id] = load("res://"+definition.frames[id].path)
	assert(not textures.values().has(null),"Missing selected boss introduction artwork")

func begin(id: String) -> bool:
	if seen.has(id): return false
	assert(definition.frames.has(id))
	seen[id] = true
	boss_id = id
	clock = 0
	queue_redraw()
	return true

func blocking() -> bool:
	return not boss_id.is_empty() and clock < RESUME_AT-0.000001

func active() -> bool:
	return not boss_id.is_empty()

func advance(delta: float) -> float:
	var blocked_seconds := minf(delta,maxf(0,RESUME_AT-clock)) if blocking() else 0.0
	if active():
		clock += delta
		if clock >= RESUME_AT+FADE_OUT-0.000001: boss_id = ""
		queue_redraw()
	return maxf(0,delta-blocked_seconds)

func reset(new_run := false) -> void:
	boss_id = ""
	clock = 0
	if new_run: seen.clear()
	queue_redraw()

func opacity() -> float:
	if not active(): return 0
	if clock < FADE_IN: return clampf(clock/FADE_IN,0,1)
	if clock < RESUME_AT: return 1
	return clampf(1-(clock-RESUME_AT)/FADE_OUT,0,1)

func region(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])

func _draw() -> void:
	if not active(): return
	var title: Dictionary = definition.frames[boss_id]
	draw_texture_rect_region(textures[boss_id],region(title.destination),region(title.source_rect),
		Color(1,1,1,opacity()))
