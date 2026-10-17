extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var badge = load("res://scripts/build_version.gd")
	var version: String = ProjectSettings.get_setting("application/config/version")
	assert(badge.text() == "v" + version)
	assert(version.split(".").size() == 3)
	var title = load("res://scripts/title_screen.gd").new()
	assert(title.BuildVersion.text() == badge.text())
	var game = load("res://scripts/integrated_first_call.gd").new()
	assert(game.BuildVersion.text() == badge.text())
	assert(Rect2(16,16,928,508).encloses(badge.BADGE))
	assert(ThemeDB.fallback_font.get_string_size(badge.text(),HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		<= badge.BADGE.size.x-12)
	for i in range(title.MENU_LABELS.size()):
		assert(not badge.BADGE.intersects(title.menu_rect(i)))
	assert(not badge.BADGE.intersects(Rect2(0,0,960,82)))
	title.free()
	game.free()
	print("PASS: canonical version shared by title/game, text fit, safe inset, HUD/menu clearance")
	quit()
