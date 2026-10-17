extends RefCounted
## ProjectSettings is the version source used by both the UI and export preparation.

const BADGE := Rect2(866, 504, 78, 20)

static func text() -> String:
	return "v" + str(ProjectSettings.get_setting("application/config/version"))

static func draw(host: CanvasItem) -> void:
	host.draw_rect(BADGE, Color("101820"))
	host.draw_string(ThemeDB.fallback_font, BADGE.position + Vector2(6, 14), text(),
		HORIZONTAL_ALIGNMENT_CENTER, BADGE.size.x - 12, 11, Color("ffffff"))
