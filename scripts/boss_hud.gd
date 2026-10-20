extends Node2D
## Encounter-owned presentation. No boss AI, phase logic, or independent HP authority.
const Data = preload("res://scripts/combat_data.gd")
var active := false
var boss_name := ""
var boss_id := ""
var player_status := ""
var hp := 0.0
var maximum := 1.0
var trail := 0.0
var trail_start := 0.0
var since_hit := 0.0
var death_time := 0.0
var opacity := 1.0
var policy: Dictionary
var swarm_frame: Texture2D
var swarm_fill: Texture2D
var clogfather_skin: Dictionary = {}
var clogfather_textures: Dictionary = {}
const SWARM_FRAME_PATH := "res://assets/bestiary/cockroach-swarm/health-bar-v2/frame.png"
const SWARM_FILL_PATH := "res://assets/bestiary/cockroach-swarm/health-bar-v2/fill.png"

func _ready() -> void:
	Data.load_data()
	policy = Data.bundle.visual_policy.boss_hud
	z_index = 30
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	swarm_frame = load(SWARM_FRAME_PATH)
	swarm_fill = load(SWARM_FILL_PATH)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/bestiary/the-clogfather/runtime-manifest-v2.json"))
	clogfather_skin = manifest.get("hud",{})
	for value: Variant in clogfather_skin.values():
		if value is Dictionary and value.has("path"):
			clogfather_textures[value.path] = load("res://"+value.path)

func begin_encounter(id: String) -> void:
	var definition := Data.monster(id)
	if definition.is_empty(): return
	boss_id = id
	boss_name = definition.name
	maximum = definition.health.max_hp
	hp = definition.health.spawn_hp
	trail = hp / maximum
	trail_start = trail
	since_hit = 0
	death_time = 0
	opacity = 1
	active = true
	queue_redraw()

func update_hp(value: float) -> void:
	if not active or not is_finite(value): return
	# Encounter retries explicitly call begin_encounter; phase changes never refill this bar.
	var next := clampf(value, 0, hp)
	if next == hp: return
	hp = next
	trail_start = trail
	since_hit = 0
	if hp == 0:
		trail = 0
		death_time = 0
	queue_redraw()

func end_encounter() -> void:
	active = false
	hp = 0
	trail = 0
	opacity = 0
	queue_redraw()

func tick(delta: float) -> void:
	if not active: return
	if hp <= 0:
		death_time += delta
		opacity = 1.0 - clampf((death_time - policy.death_hold_seconds) / policy.death_fade_seconds, 0, 1)
		if opacity == 0: active = false
	else:
		since_hit += delta
		var feedback: Dictionary = policy.damage_feedback
		var progress := clampf((since_hit - feedback.trail_delay_seconds) / feedback.trail_catchup_seconds, 0, 1)
		trail = lerpf(trail_start, hp / maximum, progress)
	queue_redraw()

func reserved_height() -> float:
	return (110.0 if boss_id in ["cockroach-swarm","clogfather"] else float(policy.reserved_band_pixels)) if active else 0.0

func _draw() -> void:
	if not active: return
	if boss_id == "clogfather" and not clogfather_skin.is_empty():
		draw_clogfather()
		return
	var width := float(policy.reference_viewport_pixels[0])
	var bar_width: float = width * policy.width_fraction
	var swarm := boss_id == "cockroach-swarm"
	var top := 6.0 if swarm else float(policy.top_margin_pixels)
	var bar := Rect2((width - bar_width) / 2, 46.0 if swarm else top + 25, bar_width, policy.reference_bar_height_pixels)
	modulate.a = opacity
	draw_rect(Rect2(0, 0, width, reserved_height()), Color("101c2a"))
	draw_string(ThemeDB.fallback_font, Vector2(0, top + 16), boss_name.to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER, width, 20, Color("ffe18d"))
	if swarm:
		draw_rect(bar, Color("100d0b"))
		draw_swarm_fill(bar, trail, Color("f3b597"))
		draw_swarm_fill(bar, hp / maximum, Color.WHITE)
		draw_texture_rect(swarm_frame, Rect2(bar.position - Vector2(48, 18), bar.size + Vector2(96, 36)), false)
	else:
		draw_rect(bar.grow(3), Color("71848b"))
		draw_rect(bar, Color("25313b"))
		draw_rect(Rect2(bar.position, Vector2(bar_width * trail, bar.size.y)), Color("f3b597"))
		var fraction := hp / maximum
		var color := Color("58d68d") if fraction > .5 else Color("f4d35e") if fraction > .25 else Color("ef5350")
		draw_rect(Rect2(bar.position, Vector2(bar_width * fraction, bar.size.y)), color)
	if not player_status.is_empty():
		draw_string(ThemeDB.fallback_font,Vector2(0,104 if swarm else 75),player_status,HORIZONTAL_ALIGNMENT_CENTER,width,14,Color("fff6d5"))

func draw_swarm_fill(bar: Rect2, fraction: float, tint: Color) -> void:
	var amount := clampf(fraction, 0, 1)
	if amount <= 0: return
	# Crop both rectangles equally so damage reveals the track without squeezing the artwork.
	var source := Rect2(Vector2.ZERO, swarm_fill.get_size() * Vector2(amount, 1))
	var target := Rect2(bar.position, bar.size * Vector2(amount, 1))
	draw_texture_rect_region(swarm_fill, target, source, tint)

func draw_clogfather() -> void:
	modulate.a = opacity
	draw_rect(Rect2(0,0,960,110),Color("101c2a"))
	draw_clogfather_frame("track")
	var fraction := hp/maximum
	var fill := "fill_green" if fraction > .5 else "fill_yellow" if fraction > .25 else "fill_red"
	draw_clogfather_frame(fill,trail,Color("f3b597"))
	draw_clogfather_frame(fill,fraction)
	draw_clogfather_frame("frame")
	draw_string(ThemeDB.fallback_font,Vector2(0,clogfather_skin.name_baseline_y),boss_name.to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER,960,20,Color("ffe18d"))
	draw_string(ThemeDB.fallback_font,Vector2(0,clogfather_skin.player_status_baseline_y),player_status,
		HORIZONTAL_ALIGNMENT_CENTER,960,14,Color("fff6d5"))

func draw_clogfather_frame(id: String, fraction := 1.0, tint := Color.WHITE) -> void:
	if fraction <= 0 or not clogfather_skin.has(id): return
	var part: Dictionary = clogfather_skin[id]
	var source := Rect2(part.source_rect[0],part.source_rect[1],part.source_rect[2],part.source_rect[3])
	var values: Array = clogfather_skin.aperture if id.begins_with("fill_") else part.destination
	var destination := Rect2(values[0],values[1],values[2],values[3])
	source.size.x *= clampf(fraction,0,1)
	destination.size.x *= clampf(fraction,0,1)
	draw_texture_rect_region(clogfather_textures[part.path],destination,source,tint)
