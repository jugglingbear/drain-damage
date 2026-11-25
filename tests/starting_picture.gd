extends SceneTree
const Pictures = preload("res://scripts/starting_picture.gd")
func _initialize() -> void: call_deferred("run_checks")
func run_checks() -> void:
	var available := Pictures.candidate_paths()
	assert(available.size() == 4,"All four staged imported textures must be discoverable in source and export")
	for path in available:
		var texture: Texture2D = load(path)
		assert(texture.resource_path.get_file().begins_with("start-"))
		assert(texture.get_size() == Vector2(1672,941))
	assert(Pictures.candidate_paths("res://assets/controls").is_empty(),"Unmatched images are excluded")
	var selected := Pictures.for_session()
	assert(selected.resource_path in available)
	for index in range(20): assert(Pictures.for_session() == selected)
	var first = load("res://scripts/title_screen.gd").new()
	root.add_child(first)
	assert(first.starting_picture == selected)
	first.queue_free()
	await process_frame
	var second = load("res://scripts/title_screen.gd").new()
	root.add_child(second)
	assert(second.starting_picture == selected,"Replacing title must not reroll session art")
	second.queue_free()
	await process_frame
	print("PASS: four imported title pictures, valid filtering, fallback and session persistence across title replacement")
	quit()
