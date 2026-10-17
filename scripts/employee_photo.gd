extends RefCounted
## Shared selection photo assembly; portraits and first names remain live for every hero.
const FRAME = preload("res://assets/selection/employee-photo-frame-v1.png")
const SOURCE := Rect2(130, 25, 990, 1200)
const DESTINATION := Rect2(247, 230, 173.25, 210)
const WINDOW := Rect2(272.375, 257.125, 126, 126)
const PIVOT := Vector2(333.625, 335)
const ANGLE := -3.0 * PI / 180.0

static func bounds() -> Rect2:
	var transform := Transform2D(ANGLE, PIVOT)
	var result := Rect2(transform * (DESTINATION.position - PIVOT), Vector2.ZERO)
	for point in [DESTINATION.position, Vector2(DESTINATION.end.x, DESTINATION.position.y),
		DESTINATION.end, Vector2(DESTINATION.position.x, DESTINATION.end.y)]:
		result = result.expand(transform * (point - PIVOT))
	return result

static func draw(canvas: Node2D, portrait: Texture2D, first_name: String) -> void:
	canvas.draw_set_transform(PIVOT, ANGLE)
	var window := Rect2(WINDOW.position - PIVOT, WINDOW.size)
	canvas.draw_rect(window, Color("85948c"))
	# Texture drawing maps the complete portrait into the photo window, so it cannot bleed outside it.
	canvas.draw_texture_rect(portrait, window, false)
	canvas.draw_texture_rect_region(FRAME, Rect2(DESTINATION.position - PIVOT, DESTINATION.size), SOURCE)
	var center := DESTINATION.position + (Vector2(627, 1030) - SOURCE.position) * 0.175 - PIVOT
	var font := ThemeDB.fallback_font
	var size := 14
	while size > 8 and font.get_string_size(first_name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > 126:
		size -= 1
	var width := font.get_string_size(first_name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := center.y + (font.get_ascent(size) - font.get_descent(size)) / 2.0
	canvas.draw_string(font, Vector2(center.x - width / 2.0, baseline), first_name,
		HORIZONTAL_ALIGNMENT_LEFT, 126, size, Color("263634"))
	canvas.draw_set_transform(Vector2.ZERO)
