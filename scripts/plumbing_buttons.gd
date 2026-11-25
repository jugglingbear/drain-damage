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

# Extend the painted tips behind the plate. The rounded ends of those same two
# strands supply the falling beads, including the artist's specular highlights.
static func pause_drips(host: CanvasItem, area: Rect2, highlighted: bool, seconds: float) -> void:
	var scale := area.size / Vector2(SOURCE_WIDTH,SOURCE_HEIGHT)
	var row := SOURCE_HEIGHT if highlighted else 0.0
	for side in 2:
		var x := 150.0 if side == 0 else 1952.0
		var end := (351.0 if highlighted else 356.0) if side == 0 else (344.0 if highlighted else 349.0)
		var phase := fposmod(seconds / (3.8 if side == 0 else 4.7) + side * 0.41,1.0)
		var base := area.position + Vector2(x,320) * scale
		var tip := Rect2(x,row+320,40,end-320)
		var stretch := 6.0 * smoothstep(0.18,0.70,phase) * (1.0-smoothstep(0.70,0.79,phase))
		host.draw_texture_rect_region(ART,Rect2(base,tip.size*scale+Vector2(0,stretch)),tip)
		if phase >= 0.70:
			var fall := (phase-0.70)/0.30
			var bead := Rect2(x,row+end-24,40,24)
			var position := base + Vector2(0,(end-320)*scale.y+3+44*fall*fall)
			host.draw_texture_rect_region(ART,Rect2(position,bead.size*scale),bead,
				Color(1,1,1,1.0-smoothstep(0.78,1.0,fall)))

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
