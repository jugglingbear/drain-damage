extends SceneTree
## Snapshot the actual Normal composer, preserving both seeded strainer arrangements.
func _init() -> void:
	var showcase: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride-showcase.json"))
	var variants: Array = []
	for seed_value in [1, 2]:
		var course: Dictionary = load("res://scripts/ride_continuous_course.gd").build(showcase, "normal", seed_value)
		variants.append({"seed": seed_value, "world_finish": course.world_finish,
			"obstacles": course.encounters[0].obstacles})
	var output := {"variants": variants, "geometry": showcase.geometry, "jump": showcase.jump,
		"scroll_speed": showcase.scroll_speed, "x_speed": showcase.x_speed,
		"bank_speed": showcase.bank_speed, "steering": showcase.steering}
	var file := FileAccess.open("res://design/level-two-wave-one-grid/composed.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  ") + "\n")
	quit()
