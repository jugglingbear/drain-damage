extends RefCounted
## Semantic expressions shared by conversations and employee selection.
const MANIFEST_PATH := "res://assets/portraits/emotions-v1.json"
const TONY = preload("res://assets/portraits/tony-expressions-v3.png")
const SEAN = preload("res://assets/portraits/sean-expressions-v4.png")
const BJ = preload("res://assets/portraits/bj-expressions-v2.png")
const TEXTURES := {"tony": TONY, "sean": SEAN, "bj": BJ}
static var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))

static func has_emotion(emotion: String) -> bool:
	for entry in manifest.emotions:
		if entry.name == emotion: return true
	return false

static func expression(character: String, emotion: String) -> AtlasTexture:
	var id := character.to_lower()
	assert(TEXTURES.has(id), "Unknown portrait character: " + character)
	assert(has_emotion(emotion), "Unknown portrait emotion: " + emotion)
	var index := 0
	for entry in manifest.emotions:
		if entry.name == emotion: index = int(entry.index)
	var atlas: Texture2D = TEXTURES[id]
	var columns := int(manifest.layout.columns)
	var rows := int(manifest.layout.rows)
	var column := index % columns
	var row := index / columns
	# Rounded boundaries avoid fractional sampling across the uneven 1983 x 793 source grid.
	var left := roundi(float(column) * atlas.get_width() / columns)
	var top := roundi(float(row) * atlas.get_height() / rows)
	var right := roundi(float(column + 1) * atlas.get_width() / columns)
	var bottom := roundi(float(row + 1) * atlas.get_height() / rows)
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(left, top, right - left, bottom - top)
	texture.filter_clip = true
	return texture
