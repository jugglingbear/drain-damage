extends Node2D
## Encounter-owned presentation. No boss AI, phase logic, or independent HP authority.
const Data = preload("res://scripts/combat_data.gd")
var active := false
var boss_name := ""
var hp := 0.0
var maximum := 1.0
var trail := 0.0
var trail_start := 0.0
var since_hit := 0.0
var death_time := 0.0
var opacity := 1.0
var policy: Dictionary

func _ready() -> void:
	Data.load_data()
	policy = Data.bundle.visual_policy.boss_hud
	z_index = 30

func begin_encounter(id: String) -> void:
	var definition := Data.monster(id)
	if definition.is_empty(): return
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
	return float(policy.reserved_band_pixels) if active else 0.0

func _draw() -> void:
	if not active: return
	var width := float(policy.reference_viewport_pixels[0])
	var bar_width: float = width * policy.width_fraction
	var top := float(policy.top_margin_pixels)
	var bar := Rect2((width - bar_width) / 2, top + 25, bar_width, policy.reference_bar_height_pixels)
	modulate.a = opacity
	draw_rect(Rect2(0, 0, width, policy.reserved_band_pixels), Color("101c2a"))
	draw_string(ThemeDB.fallback_font, Vector2(0, top + 16), boss_name.to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER, width, 20, Color("ffe18d"))
	draw_rect(bar.grow(3), Color("71848b"))
	draw_rect(bar, Color("25313b"))
	draw_rect(Rect2(bar.position, Vector2(bar_width * trail, bar.size.y)), Color("f3b597"))
	draw_rect(Rect2(bar.position, Vector2(bar_width * hp / maximum, bar.size.y)), Color("efad47"))
