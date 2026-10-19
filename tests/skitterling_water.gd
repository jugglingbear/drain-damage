extends SceneTree
const Art = preload("res://scripts/skitterling_art.gd")

class Canvas extends Node2D:
	var water: RefCounted
	func _draw() -> void:
		water.draw(self, Vector2(137, 91), 5.125)

func _initialize() -> void:
	var art := Art.new()
	assert(art.prepare())
	var water = art.water
	assert(water.texture.get_size() == Vector2(648, 84))
	for tick in range(240):
		var clock := tick / 120.0
		for x in range(0, 960, 8):
			var a: Dictionary = water.sample(x, clock)
			var b: Dictionary = water.sample(x, clock + 1.0 / 120)
			assert(a == water.sample(x, clock), "Frozen room clock must freeze water")
			assert(a.destination.position.y >= 456 and is_equal_approx(a.destination.end.y, 540))
			assert(absf(a.destination.position.y - b.destination.position.y) < .02)
			assert(absf(wrapf(b.source.position.x - a.source.position.x, -320, 320) - .1) < .001)
	var pixels: Image = water.texture.get_image()
	for y in range(84):
		assert(pixels.get_pixel(319, y) == pixels.get_pixel(320, y))
		assert(pixels.get_pixel(639, y) == pixels.get_pixel(640, y))
	var second := Art.new()
	assert(second.prepare() and second.water.texture == water.texture)
	var canvas := Canvas.new()
	canvas.water = water
	root.add_child(canvas)
	await process_frame
	await process_frame
	canvas.queue_free()
	print("PASS: continuous water samples, seamless mirrored joins, bounded water band, frozen clock, cached draw")
	quit()
