extends RefCounted
## Imported-resource discovery preserves original names inside exported packages.
const DIRECTORY := "res://assets/title/starting-pictures"
const FALLBACK = preload("res://assets/title/drain-damage-v2.png")
static var session_texture: Texture2D

static func candidate_paths(directory := DIRECTORY) -> PackedStringArray:
	var paths := PackedStringArray()
	for filename in ResourceLoader.list_directory(directory):
		if filename.begins_with("start-") and filename.ends_with(".png"):
			paths.append(directory.path_join(filename))
	return paths

static func for_session() -> Texture2D:
	if session_texture == null:
		var paths := candidate_paths()
		if not paths.is_empty(): session_texture = load(paths[randi_range(0,paths.size()-1)])
		if session_texture == null: session_texture = FALLBACK
	return session_texture
