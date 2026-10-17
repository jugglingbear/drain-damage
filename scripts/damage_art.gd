extends RefCounted
## Damage rows use shared scale and measured anchors, never per-pose resizing.

const Data = preload("res://scripts/combat_data.gd")
static var textures: Dictionary = {}
static var regions: Dictionary = {}
static var anchors: Dictionary = {}

func prepare(id: String) -> void:
	if textures.has(id): return
	var spec: Dictionary = Data.monster(id).damage_art
	var source: Texture2D = load("res://" + spec.image)
	var pixels := source.get_image()
	pixels.convert(Image.FORMAT_RGBA8)
	# Remove low-alpha generation haze at render time; preserve the original source atlas.
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			var color := pixels.get_pixel(x, y)
			color.a = 1.0 if color.a >= spec.runtime_preparation.alpha_cutoff else 0.0
			pixels.set_pixel(x, y, color)
	textures[id] = ImageTexture.create_from_image(pixels)
	var frames: Array[Rect2] = []
	var points: Array[Vector2] = []
	for frame: Dictionary in spec.runtime_preparation.frames:
		var r: Array = frame.region
		frames.append(Rect2(r[0], r[1], r[2], r[3]))
		points.append(Vector2(frame.anchor[0], frame.anchor[1]))
	regions[id] = frames
	anchors[id] = points

func frame_for(enemy: Dictionary) -> int:
	var spec: Dictionary = Data.monster(enemy.id).damage_art
	if enemy.hp <= 0:
		var death: Array = spec.death.frames
		return int(death[mini(int(enemy.death_time * spec.death.suggested_fps), death.size() - 1)])
	var state := Data.damage_state(enemy.hp, enemy.max_hp)
	var row := 0
	for entry: Dictionary in spec.states:
		if entry.id == state: row = int(entry.row)
	var loop: Array = spec.living_loop.columns
	var column := int(loop[int(enemy.phase * spec.living_loop.suggested_fps / 4.5) % loop.size()])
	if enemy.id == "toilet":
		if enemy.pos.y < 397: column = 2
		if enemy.flash > 0: column = 3
	return row * int(spec.layout.columns) + column

func draw(canvas: Node2D, enemy: Dictionary, anchor: Vector2, scale: float) -> void:
	prepare(enemy.id)
	var frame := frame_for(enemy)
	var region: Rect2 = regions[enemy.id][frame]
	var pivot: Vector2 = anchors[enemy.id][frame]
	var destination := Rect2(anchor - pivot * scale, region.size * scale)
	if enemy.direction > 0:
		destination.position.x = anchor.x - (region.size.x - pivot.x) * scale
		destination.size.x = -destination.size.x
	var tint := Color(1.6, 1.45, 1.25) if enemy.flash > 0 else Color.WHITE
	canvas.draw_texture_rect_region(textures[enemy.id], destination, region, tint)
