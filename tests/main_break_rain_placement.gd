extends SceneTree
const Art = preload("res://scripts/main_break_rain_art.gd")
func _initialize() -> void:
	var art := Art.new()
	art.prepare()
	var anchor := Vector2(500,300)
	var narrow: Array[Rect2] = [Rect2(453,300,94,16)]
	var wide: Array[Rect2] = [Rect2(300,300,400,16)]
	var too_narrow: Array[Rect2] = [Rect2(468,300,64,16)]
	var roof: Array[Rect2] = [Rect2(300,300,400,16),Rect2(400,100,200,80)]
	assert(art.placement_clear(anchor,narrow))
	assert(art.placement_clear(anchor,wide))
	assert(not art.placement_clear(anchor,too_narrow))
	assert(not art.placement_clear(anchor,roof))
	for facing in [-1.0,1.0]:
		var state := {"anchor":anchor,"facing":facing}
		assert(art.spent_variant(state,narrow) == "rain_compact")
		assert(art.spent_variant(state,wide) == "rain")
		var bounds := art.collapse_bounds(anchor,facing,"collapse_compact")
		assert(bounds.position.x >= 449 and bounds.end.x <= 551)
		assert(is_equal_approx(bounds.end.y,anchor.y))
	print("Main Break rain placement: PASS (support, ceiling, variants and both facings)")
	quit()
