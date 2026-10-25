extends SceneTree
const Flush = preload("res://scripts/level_two_flush.gd")

func _initialize() -> void:
	var model := Flush.new()
	model.definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-flush.json"))
	assert(float(model.definition.art.surface_depth_pixels) == 60.0)
	assert(model.project(Vector2.ZERO).is_equal_approx(Vector2(480,360)))
	assert(model.project(Vector2(0,-360)).is_equal_approx(Vector2(480,160)))
	assert(model.project(Vector2(0,360)).is_equal_approx(Vector2(480,440)))
	for radius in [0.0,40.0,90.0,150.0,210.0,316.8,360.0]:
		for index in range(32):
			var point: Vector2 = Vector2.from_angle(index*TAU/32)*radius
			assert(model.unproject(model.project(point)).distance_to(point) < 0.001)
			var transform: Transform2D = model.surface_transform(point)
			assert(transform.origin.is_equal_approx(model.project(point)))
			assert(transform.determinant() > 0,"Surface projection must not fold or reverse shadows")
			if radius > 0:
				var dx := (model.project(point+Vector2(0.1,0))-model.project(point-Vector2(0.1,0)))/0.2
				var dy := (model.project(point+Vector2(0,0.1))-model.project(point-Vector2(0,0.1)))/0.2
				assert(transform.x.distance_to(dx) < 0.002)
				assert((transform.y*model.projection()).distance_to(dy) < 0.002)
	assert(model.project(model.unproject(Vector2(480,385))).distance_to(Vector2(480,385)) < 0.001)
	model.radio.free()
	print("PASS: recessed surface anchors, inverse projection and local shadow/waterline slopes")
	quit()
