extends RefCounted
## Art-approved reuse of title background and menu plates; copy is shipped as data.
const BACK := Rect2(54,470,140,42)
const CONFIRM := Rect2(740,470,180,42)
const HARD_NORMAL := Color("ff9b78")
const HARD_HOVER := Color("ffc09a")
const HARD_SELECTED := Color("ffe1aa")
const LABEL_COLOR := Color("fff6d5")

static func row_rect(index: int) -> Rect2:
	return Rect2(303,150+100*index,355,46)

static func label_rect(index: int) -> Rect2:
	var rect := row_rect(index)
	if index == 2: return Rect2(rect.position+Vector2(40,0),Vector2(300,46))
	return Rect2(rect.position+Vector2(52,0),Vector2(285,46))

static func label_size(index: int) -> int:
	return 22 if index == 2 else 27

static func art_rect(index: int) -> Rect2:
	return Rect2(row_rect(index).position-Vector2(10,8),Vector2(375,64))

static func label_origin(index: int, text: String) -> Vector2:
	var rect := row_rect(index)
	if index != 2: return rect.position+Vector2(52,32)
	var font := ThemeDB.fallback_font
	var bounds := label_rect(index)
	var size := label_size(index)
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	return Vector2(bounds.get_center().x-width/2,
		bounds.get_center().y+(font.get_ascent(size)-font.get_descent(size))/2)

static func hard_tint(chosen: bool, hovered: bool) -> Color:
	return HARD_SELECTED if chosen else HARD_HOVER if hovered else HARD_NORMAL

static func row_at(point: Vector2) -> int:
	for index in range(3):
		if row_rect(index).has_point(point): return index
	return -1

static func draw(host: Node2D) -> void:
	host.draw_texture_rect(host.ART,Rect2(0,0,960,540),false)
	host.draw_rect(Rect2(0,0,960,540),Color(0.05,0.08,0.15,0.90))
	var copy: Dictionary = host.difficulty_copy
	host.caption(copy.title,Vector2(54,73),30,host.GOLD)
	host.caption(copy.prompt,Vector2(54,115),18,host.MINT)
	for index in range(3):
		var chosen: bool = index == host.difficulty_index
		var rect := row_rect(index)
		var source := Rect2(0,362 if chosen else 0,2172,362)
		if index == 2:
			# Art-approved tint reuse keeps the original plate; functional focus cues stay independent of color.
			var hovered: bool = host.difficulty_hover == index
			host.draw_texture_rect_region(host.MENU_ART,art_rect(index),
				source,hard_tint(chosen,hovered))
			var rim: Color = host.GOLD if chosen else HARD_HOVER if hovered else HARD_NORMAL
			host.draw_rect(rect,rim,false,3 if chosen else 2)
			if chosen:
				for corner in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,
					Vector2(rect.position.x,rect.end.y)]:
					var direction: Vector2 = (rect.get_center()-corner).sign()
					host.draw_line(corner,corner+Vector2(direction.x*16,0),rim,4)
					host.draw_line(corner,corner+Vector2(0,direction.y*12),rim,4)
				host.caption(">",rect.position+Vector2(19,32),24,host.GOLD)
		else:
			host.draw_texture_rect_region(host.MENU_ART,art_rect(index),source)
			if chosen:
				host.draw_rect(rect,host.MINT,false,2)
				host.caption(">",rect.position+Vector2(19,32),24,host.MINT)
		host.caption(copy.options[index].label,label_origin(index,copy.options[index].label),label_size(index),LABEL_COLOR)
	for item in [{"rect":BACK,"text":copy.back},{"rect":CONFIRM,"text":copy.confirm}]:
		host.draw_rect(item.rect,host.MINT,false,2)
		host.caption(item.text,item.rect.position+Vector2(15,28),20,host.MINT)
