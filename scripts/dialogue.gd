extends Node2D
## Illustrated conversations freeze gameplay and accept keyboard or gamepad input.

const Portraits = preload("res://scripts/portrait_library.gd")
const REVEAL_SPEED := 42.0
var using_controller := false
var active := false
var lines: Array[Dictionary] = []
var line_index := 0
var revealed := 0.0
var release_guard := 0.0
var awaiting_release := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	z_index = 20
	using_controller = not Input.get_connected_joypads().is_empty()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		using_controller = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.3:
		using_controller = true
	elif event is InputEventKey and event.pressed:
		using_controller = false

func current_text() -> String:
	return str(lines[line_index].text)

func start(conversation: Array[Dictionary]) -> void:
	for entry in conversation:
		assert(entry.has("emotion") and Portraits.has_emotion(str(entry.emotion)),
			"Every dialogue line requires a recognized emotional tone")
		assert(Portraits.TEXTURES.has(str(entry.who).to_lower()), "Unknown dialogue speaker")
	awaiting_release = false
	lines = conversation
	line_index = 0
	revealed = 0.0
	active = not lines.is_empty()
	release_guard = 0.2
	queue_redraw()

func advance() -> void:
	if not active:
		return
	if revealed < current_text().length():
		revealed = current_text().length()
	else:
		line_index += 1
		revealed = 0.0
		if line_index >= lines.size():
			finish()
	queue_redraw()

func finish() -> void:
	active = false
	awaiting_release = true
	# Prevent the final dialogue press from also firing or jumping into gameplay.
	release_guard = 0.2
	queue_redraw()

func tick(delta: float, is_paused: bool) -> void:
	release_guard = maxf(0.0, release_guard - delta)
	if awaiting_release:
		var held := false
		for action in ["dialogue_next", "dialogue_skip", "jump", "shoot"]:
			held = held or Input.is_action_pressed(action)
		if held: release_guard = maxf(release_guard, 0.05)
		else: awaiting_release = false
	visible = not is_paused
	if not active or is_paused:
		return
	revealed = minf(revealed + delta * REVEAL_SPEED, current_text().length())
	if release_guard <= 0:
		if Input.is_action_just_pressed("dialogue_skip"):
			finish()
		elif Input.is_action_just_pressed("dialogue_next"):
			advance()
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	var entry: Dictionary = lines[line_index]
	var is_boss := str(entry.who).to_lower() == "bj"
	var is_tony := str(entry.who).to_lower() == "tony"
	var accent := Color("7ce4bc") if is_tony else Color("ffcf70")
	var portrait := Portraits.expression(str(entry.who), str(entry.emotion))
	draw_rect(Rect2(0, 0, 960, 540), Color(0.02, 0.04, 0.08, 0.55))
	draw_rect(Rect2(22, 334, 916, 188), Color("101c2a"))
	draw_rect(Rect2(22, 334, 916, 3), accent)
	draw_rect(Rect2(22, 519, 916, 3), Color("3c5967"))
	draw_texture_rect(portrait, Rect2(15, 155, 365, 365), false)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(680, 508), skip_hint(), HORIZONTAL_ALIGNMENT_RIGHT, 230, 16, Color("f1eee4"))
	draw_string(font, Vector2(389, 365), ("BJ" if is_boss else "Tony" if is_tony else "Sean"), HORIZONTAL_ALIGNMENT_LEFT, -1, 23, accent)
	var role := "4TH-GENERATION PLUMBER / EMPLOYEE" if is_tony else "APPRENTICE / PROBATIONARY HUMAN"
	if is_boss:
		role = "YOUR ARTIFICIALLY INTELLIGENT LORD AND MASTER"
	if entry.get("radio", false):
		role += " / RADIO SUPPORT"
	draw_string(font, Vector2(390, 385), role, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9aafb8"))
	var text := current_text().substr(0, int(revealed))
	var paragraph := TextParagraph.new()
	paragraph.width = 520
	paragraph.add_string(text, font, 21)
	paragraph.draw(get_canvas_item(), Vector2(390, 397), Color("f1eee4"))
	draw_string(font, Vector2(885, 365), "%d / %d" % [line_index + 1, lines.size()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, accent)

func skip_hint() -> String:
	for event in InputMap.action_get_events("dialogue_skip"):
		if using_controller and event is InputEventJoypadButton:
			var buttons := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y"}
			return str(buttons.get(event.button_index, "Button %d" % event.button_index)) + " · SKIP"
		if not using_controller and event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode if event.physical_keycode else event.keycode) + " · SKIP"
	return "SKIP"
