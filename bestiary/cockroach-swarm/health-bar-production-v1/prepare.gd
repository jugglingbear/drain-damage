extends SceneTree
## Deterministic slicing of authored art; no procedural replacement artwork.
func _initialize() -> void:
	var source := Image.load_from_file("res://bestiary/cockroach-swarm/health-bar-production-v1/source-v2.png")
	var frame := Image.create(1664, 64, false, Image.FORMAT_RGBA8)
	for row in [0, 1]:
		var crop := Rect2i(200, 236 if row == 0 else 374, 1580, 73 if row == 0 else 64)
		var rail := source.get_region(crop)
		rail.resize(roundi(crop.size.x * 12.0 / crop.size.y), 12, Image.INTERPOLATE_LANCZOS)
		for x in range(64, 1600, rail.get_width()):
			frame.blit_rect(rail, Rect2i(0, 0, mini(rail.get_width(), 1600 - x), 12), Vector2i(x, row * 52))
	for side in [0, 1]:
		var cap := source.get_region(Rect2i(49 if side == 0 else 1800, 235, 151 if side == 0 else 171, 203))
		cap.resize(roundi(cap.get_width() * 64.0 / 203), 64, Image.INTERPOLATE_LANCZOS)
		frame.blit_rect(cap, Rect2i(Vector2i.ZERO, cap.get_size()), Vector2i(64 - cap.get_width() if side == 0 else 1600, 0))
	var fill := source.get_region(Rect2i(225, 490, 1570, 72))
	fill.resize(1536, 40, Image.INTERPOLATE_LANCZOS)
	frame.save_png("res://assets/bestiary/cockroach-swarm/health-bar-v1/frame.png")
	fill.save_png("res://assets/bestiary/cockroach-swarm/health-bar-v1/fill.png")
	var preview := Image.create(1920, 320, false, Image.FORMAT_RGBA8)
	preview.fill(Color("101c2a"))
	for i in range(3):
		var y := 20 + i * 100
		preview.fill_rect(Rect2i(192, y + 12, 1536, 40), Color("100d0b"))
		preview.blit_rect(fill, Rect2i(0, 0, roundi(1536 * [1.0, .65, .15][i]), 40), Vector2i(192, y + 12))
		preview.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(128, y))
	preview.save_png("res://bestiary/cockroach-swarm/health-bar-production-v1/layout-preview.png")
	print("Prepared 2x frame1664x64, aperture local64,12,1536,40; fill1536x40")
	quit()
