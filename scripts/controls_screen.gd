extends RefCounted
## Illustrated field reference: gameplay first, context-specific commands grouped below.
const Buttons = preload("res://scripts/plumbing_buttons.gd")
const Crew = preload("res://scripts/crew.gd")
const KEYBOARD = preload("res://assets/controls/keyboard-v1.png")
const GAMEPAD = preload("res://assets/controls/callout-v1/controller.png")
const CALLOUT_MANIFEST := "res://assets/controls/callout-v1/manifest.json"
static var callout_texture: Texture2D
static var callout_data: Dictionary = {}
const INK := Color("101c24")
const MINT := Color("93dfc4")
const GOLD := Color("e6c681")
const PAPER := Color("eee9dd")
const MUTED := Color("a7b9be")
const BACK_RECT := Rect2(827,18,110,40)
const HEALTH_RECT := Rect2(498, 492, 430, 34)
const MUSIC_RECT := Rect2(32, 492, 446, 34)
const PRIMARY := [
	[["MOVE", "A / D   or   Left / Right"], ["JUMP", "Space"],
		["FIRE", "Enter / J / X"], ["SPECIAL", "K — two uses / level"], ["PAUSE", "Esc"]],
	[["MOVE", "Left stick / D-pad"], ["JUMP", "A"], ["FIRE", "X / Right trigger"], ["SPECIAL", "B — two uses / level"], ["PAUSE", "Menu  ≡"]],
]

static func tab_rect(index: int) -> Rect2:
	return Rect2(290+index*210,18,195,40)

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

static func draw(canvas: Node2D, page: int, muted: bool, health_bars := false, focus := -1) -> void:
	if focus < 0: focus = page
	canvas.draw_rect(Rect2(0, 0, 960, 540), INK)
	text(canvas, "CONTROLS", Vector2(32, 45), 26, PAPER)
	for index in range(2):
		Buttons.compact(canvas,tab_rect(index),["KEYBOARD","GAMEPAD"][index],focus == index,17)
	Buttons.compact(canvas,BACK_RECT,"BACK",focus == 2,17,false,34)
	if page == 1:
		draw_gamepad(canvas)
		draw_settings(canvas,page,muted,health_bars)
		return
	text(canvas, "FIELD GUIDE  /  " + ("KEYBOARD" if page == 0 else "GAMEPAD"), Vector2(33, 88), 13, GOLD)
	text(canvas, Crew.COMPANY_NAME, Vector2(33, 109), 13, MUTED)
	panel(canvas, Rect2(32, 122, 570, 218), Color("0b151b"))
	if page == 0:
		canvas.draw_texture_rect(KEYBOARD, Rect2(35, 133, 564, 188), false)
	else:
		canvas.draw_texture_rect(GAMEPAD, Rect2(160, 125, 315, 210), false)
	for index in range(PRIMARY[page].size()):
		var y := 122.0 + index * 44
		panel(canvas, Rect2(622, y, 306, 40), Color("1c3037"))
		text(canvas, PRIMARY[page][index][0], Vector2(638, y + 15), 11, MINT)
		text(canvas, PRIMARY[page][index][1], Vector2(638, y + 33), 17)
	text(canvas, "Hold Z / V: aim up-left / up-right, stand still." if page == 0 else "Hold LB / RB: aim up-left / up-right, stand still.", Vector2(42, 363), 14, MINT)
	if page == 0:
		reference_card(canvas, 32, "DURING A JOB", ["K  Special (two uses per level)", "Hold fire for continuous shots", "Q  Title when paused / complete"])
		reference_card(canvas, 336, "MENUS & PAGES", ["WASD / arrows  Navigate", "Enter / Space  Confirm; mouse works", "Esc  Back (quits on title)"])
		reference_card(canvas, 640, "CONVERSATIONS", ["Enter / Space  Reveal / continue", "Tab  Skip conversation", "Left / Right or A / D  Controls page"])
	else:
		reference_card(canvas, 32, "DURING A JOB", ["B  Special (two uses per level)", "Hold fire for continuous shots", "B  Back / resume when paused"])
		reference_card(canvas, 336, "MENUS & PAGES", ["Stick / D-pad  Navigate", "A / Menu  Confirm; B  Back", "Left / Right  Controls page"])
		reference_card(canvas, 640, "CONVERSATIONS", ["A  Reveal / continue", "B  Skip conversation", "Guide button belongs to the OS"])
	draw_settings(canvas,page,muted,health_bars)

static func draw_settings(canvas: Node2D, page: int, muted: bool, health_bars: bool) -> void:
	Buttons.compact(canvas,MUSIC_RECT,"Music  %s  ·  %s / click (menus)" % ["OFF" if muted else "ON",
		"M" if page == 0 else "Y"],not muted,14)
	Buttons.compact(canvas,HEALTH_RECT,"Enemy bars  %s  ·  %s / click (here)" % ["ON" if health_bars else "OFF",
		"H" if page == 0 else "View"],health_bars,14)

static func prepare_callouts() -> void:
	if callout_texture != null: return
	callout_data = JSON.parse_string(FileAccess.get_file_as_string(CALLOUT_MANIFEST))
	var pixels := GAMEPAD.get_image()
	pixels.convert(Image.FORMAT_RGBA8)
	var bytes := pixels.get_data()
	for index in range(3,bytes.size(),4):
		bytes[index] = 255 if bytes[index] >= int(callout_data.controller.alpha_cutoff) else 0
	callout_texture = ImageTexture.create_from_image(
		Image.create_from_data(pixels.get_width(),pixels.get_height(),false,Image.FORMAT_RGBA8,bytes))

static func draw_gamepad(canvas: Node2D) -> void:
	prepare_callouts()
	var dest: Array = callout_data.controller.destination
	var area := Rect2(dest[0],dest[1],dest[2],dest[3])
	canvas.draw_texture_rect(callout_texture,area,false)
	text(canvas,"LB / RB: stand still while aiming diagonally",Vector2(32,83),16,MINT)
	text(canvas,"Hold fire: continuous · Special: two uses per level",Vector2(32,104),16)
	for callout: Dictionary in callout_data.callouts:
		var position := Vector2(callout.label_position[0],callout.label_position[1])
		var label: String = callout.label
		var width := ThemeDB.fallback_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		text(canvas,label,position,16,PAPER)
		canvas.draw_line(position+Vector2(0,6),position+Vector2(width,6),MINT,2,true)
		var start := position+Vector2(width+8,-5) if callout.side == "left" else position+Vector2(-8,-5)
		if callout.side == "top": start = position+Vector2(width*0.5,9)
		for source: Array in callout.button_points:
			var point := area.position+Vector2(source[0],source[1])*0.36
			var bend := Vector2(start.x+24 if callout.side == "left" else start.x-24,start.y)
			if callout.side == "top": bend = Vector2(start.x,point.y-24)
			canvas.draw_polyline(PackedVector2Array([start,bend,point]),PAPER,1.5,true)
			canvas.draw_circle(point,3,PAPER)
	text(canvas,"MENUS: stick / D-pad navigate · Left / Right tabs · A / Menu confirm · B back",Vector2(32,454),16)
	text(canvas,"DIALOGUE: A reveal / continue · B skip     PAUSED: B resume",Vector2(32,478),16)
