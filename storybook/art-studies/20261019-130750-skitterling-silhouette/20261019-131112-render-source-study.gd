extends SceneTree
const Art = preload("res://scripts/skitterling_art.gd")
func _initialize() -> void:
	var art := Art.new()
	assert(art.prepare())
	var result := Image.create(768, 256, false, Image.FORMAT_RGBA8)
	result.fill(Color("10262b"))
	var keys := ["rat-source-v2:1", "alligator-source-v2:3"]
	for panel in range(2):
		var key: String = keys[panel]
		for phase in range(4):
			var sprite: Image = art.roach_body.insect_images[posmod(16 + phase, 4)]
			for index in range(phase, Art.RoachBody.COUNT, 4):
				var point: Vector2 = art.roach_body.insect_position(key,key,0,index,2)
				var shape: Dictionary = art.roach_body.insect_shape(key,key,0,index,2)
				var size: Vector2 = shape.size
				for y in range(-22, 23):
					for x in range(-22, 23):
						var uv := Vector2(x,y).rotated(-float(shape.angle)) / size + Vector2(.5,.5)
						if uv.x < 0 or uv.x >= 1 or uv.y < 0 or uv.y >= 1: continue
						var color := sprite.get_pixelv(Vector2i(uv * Vector2(sprite.get_size())))
						if color.a < .5: continue
						var at := Vector2i(point) + Vector2i(x + panel*384,y)
						if at.x >=0 and at.x <768 and at.y>=0 and at.y<256:
							result.set_pixelv(at, color * art.roach_body.targets[key].colors[index])
	result.resize(1536,512,Image.INTERPOLATE_NEAREST)
	result.save_png("/tmp/skitterling-shape-preview.png")
	quit()
