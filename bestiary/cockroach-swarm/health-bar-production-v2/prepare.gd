extends SceneTree
## Deterministic slicing of authored art; no procedural replacement artwork.
func _initialize() -> void:
	var source := Image.load_from_file("res://bestiary/cockroach-swarm/health-bar-production-v1/source-v2.png")
	var frame := Image.create(1728, 112, false, Image.FORMAT_RGBA8)
	for row in [0, 1]:
		var crop := Rect2i(200, 236 if row == 0 else 374, 1580, 73 if row == 0 else 64)
		var rail := source.get_region(crop)
		rail.resize(roundi(crop.size.x * 36.0 / crop.size.y), 36, Image.INTERPOLATE_LANCZOS)
		for x in range(96, 1632, rail.get_width()):
			frame.blit_rect(rail, Rect2i(0, 0, mini(rail.get_width(), 1632 - x), 36), Vector2i(x, row * 76))
	for side in [0, 1]:
		var cap := source.get_region(Rect2i(49 if side == 0 else 1800, 235, 151 if side == 0 else 171, 203))
		cap.resize(roundi(cap.get_width() * 112.0 / 203), 112, Image.INTERPOLATE_LANCZOS)
		frame.blit_rect(cap, Rect2i(Vector2i.ZERO, cap.get_size()), Vector2i(96 - cap.get_width() if side == 0 else 1632, 0))
	var fill := source.get_region(Rect2i(225, 490, 1570, 72))
	fill.resize(1536, 40, Image.INTERPOLATE_LANCZOS)
	frame.save_png("res://assets/bestiary/cockroach-swarm/health-bar-v2/frame.png")
	fill.save_png("res://assets/bestiary/cockroach-swarm/health-bar-v2/fill.png")
	var preview := Image.create(960, 330, false, Image.FORMAT_RGBA8)
	preview.fill(Color("101c2a"))
	var native_frame := frame.duplicate()
	native_frame.resize(864, 56, Image.INTERPOLATE_LANCZOS)
	var native_fill := fill.duplicate()
	native_fill.resize(768, 20, Image.INTERPOLATE_LANCZOS)
	for i in range(3):
		var y := 28 + i * 110
		preview.fill_rect(Rect2i(96, y + 18, 768, 20), Color("100d0b"))
		preview.blit_rect(native_fill, Rect2i(0, 0, roundi(768 * [1.0, .65, .15][i]), 20), Vector2i(96, y + 18))
		preview.blend_rect(native_frame, Rect2i(Vector2i.ZERO, native_frame.get_size()), Vector2i(48, y))
	preview.save_png("res://bestiary/cockroach-swarm/health-bar-production-v2/native-size-preview.png")
	print("Prepared 2x frame1728x112, aperture96,36,1536,40; native864x56")
	quit()
