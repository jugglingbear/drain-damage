extends SceneTree
const Portraits = preload("res://scripts/portrait_library.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	assert(Portraits.manifest.emotions.size() == 10)
	assert(not Portraits.has_emotion("unmapped"))
	for character in Portraits.manifest.characters:
		var atlas: Texture2D = Portraits.TEXTURES[character.id]
		assert(atlas.resource_path == "res://" + character.asset)
		assert(atlas.get_width() == character.dimensions.width)
		assert(atlas.get_height() == character.dimensions.height)
		var covered := 0.0
		var rectangles: Array[Rect2] = []
		for emotion in Portraits.manifest.emotions:
			var texture := Portraits.expression(character.id, emotion.name)
			assert(texture.filter_clip)
			var region := texture.region
			assert(Rect2(Vector2.ZERO, atlas.get_size()).encloses(region))
			for previous in rectangles: assert(not previous.intersects(region))
			rectangles.append(region)
			covered += region.get_area()
		assert(covered == atlas.get_width() * atlas.get_height(), "All 10 cells cover the atlas exactly")
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	for employee in load("res://scripts/crew.gd").EMPLOYEES:
		game.employee = employee
		game.reset_game()
		game.complete_job()
		assert(game.dialogue.lines[0].emotion == ("skeptical" if employee.id == "tony" else "worried"))
		assert(game.dialogue.lines[1].who == "BJ" and game.dialogue.lines[1].emotion == "neutral")
		for entry in game.dialogue.lines:
			assert(entry.has("emotion") and not entry.has("face"))
			assert(Portraits.expression(entry.who, entry.emotion) != null)
	game.queue_free()
	await create_timer(0.3).timeout
	print("PASS: all 30 portraits, canonical paths, exact non-overlapping cells, semantic dialogue for both employees")
	quit()
