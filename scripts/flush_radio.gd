extends Node2D
## Nonblocking radio follows the level clock; pause never consumes a line's reading time.
const Portraits = preload("res://scripts/portrait_library.gd")
var entries: Array = []
var current: Dictionary = {}
var next_index := 0
var line_clock := 0.0
var hard_mode := false
var transmissions := 0
var last_event := ""
signal transmission

func _ready() -> void:
	z_index = 20
	set_as_top_level(true)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func configure(lines: Array, hard: bool, retry: bool) -> void:
	entries = lines.duplicate(true)
	hard_mode = hard
	next_index = 0
	current = {}
	line_clock = 0
	transmissions = 0
	last_event = ""
	if retry:
		entries = entries.filter(func(line: Dictionary) -> bool: return line.get("event","") != "arrival")
	queue_redraw()

func advance(clock: float, delta: float, frozen: bool) -> void:
	if frozen: return
	if not current.is_empty():
		line_clock += delta
		if line_clock >= float(current.get("duration",4.0)): current = {}
	while next_index < entries.size() and float(entries[next_index].at) <= clock:
		var line: Dictionary = entries[next_index]
		next_index += 1
		# Optional late reactions are dropped rather than building a distracting backlog.
		if clock > float(line.at)+float(line.get("duration",4.0)): continue
		current = line
		line_clock = 0
		transmissions += 1
		var event := str(line.get("event","landing"))
		if event != last_event:
			transmission.emit()
			last_event = event
	queue_redraw()

func clear() -> void:
	current = {}
	entries.clear()
	queue_redraw()

func _draw() -> void:
	if current.is_empty(): return
	var destination := Vector2(110,452)
	if current.get("gag",false):
		var progress := 0.0 if current.get("gag_action","") == "hold_center" else smoothstep(1.4,2.2,line_clock)
		destination = Vector2(110,220).lerp(destination,progress)
		var scale := lerpf(1.18,1.0,progress)
		draw_set_transform(Vector2(480,261)*(1-scale),0,Vector2.ONE*scale)
	var panel := Rect2(destination,Vector2(740,82))
	draw_rect(panel,Color("101d29"))
	draw_rect(panel,Color("90d7cb"),false,2)
	var portrait := Portraits.expression(str(current.who),str(current.emotion),hard_mode)
	draw_texture_rect(portrait,Rect2(destination+Vector2(7,6),Vector2(70,70)),false)
	var speaker := str(current.who).capitalize()
	draw_string(ThemeDB.fallback_font,destination+Vector2(90,23),speaker,HORIZONTAL_ALIGNMENT_LEFT,-1,17,
		Color("ffcf7e"))
	var text := str(current.text)
	if hard_mode: text = text.to_upper()
	draw_multiline_string(ThemeDB.fallback_font,destination+Vector2(90,45),text,
		HORIZONTAL_ALIGNMENT_LEFT,630,17,2,Color("edf2f5"))
