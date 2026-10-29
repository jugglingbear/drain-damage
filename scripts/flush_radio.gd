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
var dialogue_font: Font
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
		line_clock = maxf(0,clock-float(line.at))
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

func presentation() -> Dictionary:
	return line_presentation(current,line_clock)

func presentations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if current.get("retain_partner",false):
		for line: Dictionary in entries:
			if float(line.at) >= float(current.at): break
			if line.get("gag_action","") == "hold_center" and line.get("radio",false):
				result = [line_presentation(line,0)]
	if not current.is_empty(): result.append(presentation())
	return result

func line_presentation(line: Dictionary, age: float) -> Dictionary:
	if line.is_empty(): return {}
	var destination := Vector2(110,452)
	var scale := 1.0
	var progress := 1.0
	if line.get("gag",false):
		progress = 0.0
		# Only the authored partner response can relocate its own portrait and dialogue.
		if line.get("gag_action","") == "slide_bottom":
			var interval: Array = line.slide_line_seconds
			progress = smoothstep(float(interval[0]),float(interval[1]),age)
		destination = Vector2(110,220).lerp(destination,progress)
		scale = lerpf(1.18,1.0,progress)
	return {"who":line.who,"emotion":line.emotion,"text":line.text,
		"portrait":Portraits.expression(str(line.who),str(line.emotion),hard_mode),
		"destination":destination,"scale":scale,"progress":progress}

func text_font() -> Font:
	if dialogue_font == null:
		var emoji := SystemFont.new()
		emoji.font_names = PackedStringArray(["Apple Color Emoji","Segoe UI Emoji","Noto Color Emoji"])
		dialogue_font = ThemeDB.fallback_font.duplicate()
		dialogue_font.fallbacks = [emoji]
	return dialogue_font

func _draw() -> void:
	for view: Dictionary in presentations(): draw_view(view)
	draw_set_transform(Vector2.ZERO)

func draw_view(view: Dictionary) -> void:
	var destination: Vector2 = view.destination
	var scale: float = view.scale
	draw_set_transform(Vector2(480,261)*(1-scale),0,Vector2.ONE*scale)
	var panel := Rect2(destination,Vector2(740,82))
	draw_rect(panel,Color("101d29"))
	draw_rect(panel,Color("90d7cb"),false,2)
	draw_texture_rect(view.portrait,Rect2(destination+Vector2(7,6),Vector2(70,70)),false)
	var speaker := str(view.who).capitalize()
	draw_string(ThemeDB.fallback_font,destination+Vector2(90,23),speaker,HORIZONTAL_ALIGNMENT_LEFT,-1,17,
		Color("ffcf7e"))
	var text := str(view.text)
	if hard_mode: text = text.to_upper()
	draw_multiline_string(text_font(),destination+Vector2(90,45),text,
		HORIZONTAL_ALIGNMENT_LEFT,630,17,2,Color("edf2f5"))
