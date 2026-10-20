extends RefCounted
## Art-approved plate reuse and shared interaction states; labels remain live text.
const ART = preload("res://assets/title/dripping-menu-v1.png")
const GOLD := Color("ffe18d")
const IVORY := Color("fff2cf")
const MUTED := Color("acb6b4")
const SOURCE_HEIGHT := 362.0
const SOURCE_WIDTH := 2172.0
const CAP_WIDTH := 420.0

static func appearance(selected: bool, hovered: bool, pressed: bool, disabled: bool) -> Dictionary:
	return {"highlight":not disabled and (selected or hovered or pressed),
		"tint":Color(.48,.48,.48,.82) if disabled else Color(.76,.76,.76,1) if pressed else Color.WHITE,
		"label":MUTED if disabled else IVORY, "offset":1.0 if pressed and not disabled else 0.0}

static func slices(area: Rect2, highlighted: bool) -> Array[Dictionary]:
	var cap := CAP_WIDTH * area.size.y / SOURCE_HEIGHT
	assert(area.size.x > cap * 2, "Compact plate must retain both complete end caps")
	var y := SOURCE_HEIGHT if highlighted else 0.0
	return [
		{"source":Rect2(0,y,CAP_WIDTH,SOURCE_HEIGHT),"target":Rect2(area.position,Vector2(cap,area.size.y))},
		{"source":Rect2(CAP_WIDTH,y,SOURCE_WIDTH-CAP_WIDTH*2,SOURCE_HEIGHT),
			"target":Rect2(area.position+Vector2(cap,0),Vector2(area.size.x-cap*2,area.size.y))},
		{"source":Rect2(SOURCE_WIDTH-CAP_WIDTH,y,CAP_WIDTH,SOURCE_HEIGHT),
			"target":Rect2(Vector2(area.end.x-cap,area.position.y),Vector2(cap,area.size.y))}]

static func plate(host: CanvasItem, area: Rect2, selected := false, hovered := false,
		pressed := false, disabled := false, compact := false) -> void:
	var state := appearance(selected,hovered,pressed,disabled)
	if compact:
		for part: Dictionary in slices(area,state.highlight):
			host.draw_texture_rect_region(ART,part.target,part.source,state.tint)
	else:
		host.draw_texture_rect_region(ART,area,Rect2(0,SOURCE_HEIGHT if state.highlight else 0,
			SOURCE_WIDTH,SOURCE_HEIGHT),state.tint)

static func label_size(value: String, area: Rect2, requested: int) -> int:
	var available := area.size.x - CAP_WIDTH * area.size.y / SOURCE_HEIGHT * 1.2 - 4
	var size := mini(requested, maxi(12, int(area.size.y * .55)))
	while size > 12 and ThemeDB.fallback_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > available:
		size -= 1
	return size

static func compact(host: Node2D, area: Rect2, value: String, selected := false, requested_size := 16,
		disabled := false, art_height := 0.0) -> void:
	var hovered := area.has_point(host.get_local_mouse_position())
	if art_height > 0:
		area = Rect2(Vector2(area.position.x,area.get_center().y-art_height/2),Vector2(area.size.x,art_height))
	var pressed := hovered and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var state := appearance(selected,hovered,pressed,disabled)
	plate(host,area,selected,hovered,pressed,disabled,true)
	var size := label_size(value,area,requested_size)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	var origin := Vector2(area.get_center().x-width/2,
		area.position.y+area.size.y*.44+(font.get_ascent(size)-font.get_descent(size))/2+state.offset)
	host.draw_string(font,origin+Vector2(1,1),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("080e15"))
	host.draw_string(font,origin,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,state.label)
	if selected and not disabled:
		host.draw_rect(Rect2(area.position+Vector2(3,3),area.size-Vector2(6,10)),GOLD,false,2)

static func prop_focus(host: Node2D, area: Rect2, selected: bool, disabled := false) -> void:
	var hovered := area.has_point(host.get_local_mouse_position())
	if disabled:
		host.draw_rect(area,Color(0,0,0,.3))
	elif selected or hovered:
		host.draw_rect(area,GOLD if selected else Color("93dfc4"),false,2)
		if hovered and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): host.draw_rect(area,Color(0,0,0,.16))
