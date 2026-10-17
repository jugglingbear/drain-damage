extends RefCounted
## Illustrated field reference: gameplay first, context-specific commands grouped below.
const Crew = preload("res://scripts/crew.gd")
const KEYBOARD = preload("res://assets/controls/keyboard-v1.png")
const GAMEPAD = preload("res://assets/controls/gamepad-salvage-v1.png")
const INK := Color("101c24")
const MINT := Color("93dfc4")
const GOLD := Color("e6c681")
const PAPER := Color("eee9dd")
const MUTED := Color("a7b9be")
const HEALTH_RECT := Rect2(498, 492, 430, 34)
const MUSIC_RECT := Rect2(32, 492, 446, 34)
const PRIMARY := [
	[["MOVE", "A / D   or   Left / Right"], ["JUMP", "Space"],
		["FIRE", "Enter / J / X"], ["PAUSE", "Esc"]],
	[["MOVE", "Left stick / D-pad"], ["JUMP", "A"], ["FIRE", "X / Right trigger"], ["PAUSE", "Menu  ≡"]],
]

static func setting_at_point(point: Vector2) -> String:
	if HEALTH_RECT.has_point(point): return "health"
	if MUSIC_RECT.has_point(point): return "music"
	return ""

static func text(canvas: Node2D, value: String, point: Vector2, size := 15, color := PAPER) -> void:
	canvas.draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

static func panel(canvas: Node2D, area: Rect2, fill: Color, border := Color("33454c"), radius := 10) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	canvas.draw_style_box(style, area)

static func reference_card(canvas: Node2D, x: float, heading: String, lines: Array) -> void:
	panel(canvas, Rect2(x, 385, 288, 96), Color("172730"))
	text(canvas, heading, Vector2(x + 16, 406), 12, GOLD)
	for index in range(lines.size()):
		text(canvas, str(lines[index]), Vector2(x + 16, 427 + index * 18), 13, PAPER)

static func draw(canvas: Node2D, page: int, muted: bool, health_bars := false) -> void:
	canvas.draw_rect(Rect2(0, 0, 960, 540), INK)
	text(canvas, "CONTROLS", Vector2(32, 45), 26, PAPER)
	for index in range(2):
		panel(canvas, Rect2(290 + index * 210, 18, 195, 40),
			Color("29473f") if page == index else Color("172730"), MINT if page == index else Color("33454c"))
		text(canvas, ["KEYBOARD", "GAMEPAD"][index], Vector2(324 + index * 210, 44), 17)
	panel(canvas, Rect2(827, 18, 110, 40), Color("172730"))
	text(canvas, "BACK", Vector2(856, 44), 17, GOLD)
	text(canvas, "FIELD GUIDE  /  " + ("KEYBOARD" if page == 0 else "GAMEPAD"), Vector2(33, 88), 13, GOLD)
	text(canvas, Crew.COMPANY_NAME, Vector2(33, 109), 13, MUTED)
	panel(canvas, Rect2(32, 122, 570, 218), Color("0b151b"))
	if page == 0:
		canvas.draw_texture_rect(KEYBOARD, Rect2(35, 133, 564, 188), false)
	else:
		canvas.draw_texture_rect(GAMEPAD, Rect2(160, 125, 315, 210), false)
	for index in range(4):
		var y := 122.0 + index * 56
		panel(canvas, Rect2(622, y, 306, 48), Color("1c3037"))
		text(canvas, PRIMARY[page][index][0], Vector2(638, y + 19), 11, MINT)
		text(canvas, PRIMARY[page][index][1], Vector2(638, y + 39), 17)
	text(canvas, "Aim: WASD / arrows or stick / D-pad. Only straight down needs a jump.", Vector2(42, 363), 14, MINT)
	if page == 0:
		reference_card(canvas, 32, "DURING A JOB", ["Hold fire for continuous shots", "Q  Title when paused / complete", "Numpad Enter also fires / confirms"])
		reference_card(canvas, 336, "MENUS & PAGES", ["WASD / arrows  Navigate", "Enter / Space  Confirm; mouse works", "Esc  Back (quits on title)"])
		reference_card(canvas, 640, "CONVERSATIONS", ["Enter / Space  Reveal / continue", "Tab  Skip conversation", "Left / Right or A / D  Controls page"])
	else:
		reference_card(canvas, 32, "DURING A JOB", ["Hold fire for continuous shots", "B  Back / resume when paused", "Pause menu includes Return to Main Menu"])
		reference_card(canvas, 336, "MENUS & PAGES", ["Stick / D-pad  Navigate", "A / Menu  Confirm; B  Back", "Left / Right  Controls page"])
		reference_card(canvas, 640, "CONVERSATIONS", ["A  Reveal / continue", "B  Skip conversation", "Guide button belongs to the OS"])
	panel(canvas, MUSIC_RECT, Color("203a35"))
	panel(canvas, HEALTH_RECT, Color("203a35"))
	text(canvas, "Music  %s  ·  %s / click (menus)" % ["OFF" if muted else "ON", "M" if page == 0 else "Y"],
		Vector2(47, 514), 14, MINT)
	text(canvas, "Enemy bars  %s  ·  %s / click (here)" % ["ON" if health_bars else "OFF", "H" if page == 0 else "View"],
		Vector2(513, 514), 14, MINT)
