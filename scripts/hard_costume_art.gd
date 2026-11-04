extends RefCounted
## Approved alpha preparation is cached before gameplay; source PNGs remain untouched.
const PREFIX := "assets/sprites/hard-mode/"
const ALPHA_CUTOFF := 240
const PREPARED_RUN_SHEETS := [
	"assets/sprites/tony-run-v4/normal-v2.png",
	"assets/sprites/easy-mode/tony-run-v4.png",
	"assets/sprites/sean-run-v4/normal-v1.png",
	"assets/sprites/easy-mode/sean-run-v4.png",
]
static var textures: Dictionary = {}

static func texture(path: String) -> Texture2D:
	if not path.begins_with(PREFIX) and path not in PREPARED_RUN_SHEETS: return load("res://" + path)
	if textures.has(path): return textures[path]
	var source: Texture2D = load("res://" + path)
	var pixels := source.get_image()
	pixels.convert(Image.FORMAT_RGBA8)
	var bytes := pixels.get_data()
	for index in range(3, bytes.size(), 4):
		bytes[index] = 255 if bytes[index] >= ALPHA_CUTOFF else 0
	var prepared := Image.create_from_data(pixels.get_width(), pixels.get_height(), false, Image.FORMAT_RGBA8, bytes)
	textures[path] = ImageTexture.create_from_image(prepared)
	return textures[path]
