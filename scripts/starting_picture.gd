extends RefCounted
## Imported-resource discovery preserves original names inside exported packages.
const DIRECTORY := "res://assets/title/starting-pictures"
const FALLBACK = preload("res://assets/title/drain-damage-v2.png")
static var session_texture: Texture2D

static func candidates(directory := DIRECTORY) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	for filename in ResourceLoader.list_directory(directory):
		if not filename.begins_with("start-") or not filename.ends_with(".png"): continue
		var resource := ResourceLoader.load(directory.path_join(filename),"Texture2D")
		if resource is Texture2D and resource.get_width() > 0 and resource.get_height() > 0:
			result.append(resource)
	return result

static func choose(available: Array[Texture2D]) -> Texture2D:
	return FALLBACK if available.is_empty() else available.pick_random()

static func for_session() -> Texture2D:
	# A static strong reference survives title scene replacement and returning from gameplay.
	if session_texture == null: session_texture = choose(candidates())
	return session_texture
