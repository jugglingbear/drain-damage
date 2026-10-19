extends RefCounted
## Continuous motion of one authored water crop, driven only by the room's pause-aware clock.
const WIDTH := 960.0
const TOP := 456.0
const HEIGHT := 84.0
const STRIP := 8
const PERIOD := 640.0
const FLOW_SPEED := 12.0
static var texture: Texture2D

func prepare(source: Image, crop: Rect2i) -> void:
	if texture != null: return
	var tile := source.get_region(crop)
	tile.resize(320, 84, Image.INTERPOLATE_NEAREST)
	var mirror := tile.duplicate() as Image
	mirror.flip_x()
	# Mirrored joins retain the same crest at every wrap; the extra strip permits seam-crossing samples.
	var ribbon := Image.create(640 + STRIP, 84, false, Image.FORMAT_RGBA8)
	ribbon.blit_rect(tile, Rect2i(0, 0, 320, 84), Vector2i.ZERO)
	ribbon.blit_rect(mirror, Rect2i(0, 0, 320, 84), Vector2i(320, 0))
	ribbon.blit_rect(tile, Rect2i(0, 0, STRIP, 84), Vector2i(640, 0))
	texture = ImageTexture.create_from_image(ribbon)

func sample(x: float, clock: float) -> Dictionary:
	var crest := 2.0 + sin(x * .025 - clock * 1.1) * 1.2 + sin(x * .011 + clock * .7) * .6
	return {"destination":Rect2(x, TOP + crest, STRIP, HEIGHT - crest),
		"source":Rect2(fposmod(x + clock * FLOW_SPEED, PERIOD), 0, STRIP, HEIGHT)}

func draw(host: CanvasItem, origin: Vector2, clock: float) -> void:
	if texture == null: return
	for x in range(0, int(WIDTH), STRIP):
		var piece := sample(x, clock)
		var destination: Rect2 = piece.destination
		destination.position += origin
		host.draw_texture_rect_region(texture, destination, piece.source)
