extends SceneTree
const Data = preload("res://scripts/combat_data.gd")
const Pipe = preload("res://scripts/wastewater_art.gd")

class PipeCanvas extends Node2D:
	var renderer: RefCounted
	func _draw() -> void:
		draw_set_transform(Vector2(-100, 0))
		renderer.draw(self, 100, 10, false)

func _initialize() -> void:
	assert(Data.load_data())
	assert(Data.bundle.has("wastewater"), "Engineering must bundle wastewater manifest/profile")
	var renderer = Pipe.new()
	assert(renderer.configure(Data.bundle.wastewater))
	for camera in [0.0, 1600.0, 3600.0, 5600.0, 7400.0, 8200.0, 8570.0]:
		var plan: Array[Dictionary] = renderer.commands(camera, 10)
		assert(not plan.is_empty())
		var count := 0
		for command: Dictionary in plan:
			var rect: Rect2 = command.rect
			assert(rect.position.y >= 456 and rect.end.y <= 528.001)
			assert(command.alpha >= 0 and command.alpha <= 1)
			if command.id in renderer.debris_ids:
				count += 1
				assert(rect.position.y >= 464 and rect.end.y <= 520.001)
			if rect.position.x >= 8570:
				assert(command.id != "water-a" and command.id not in renderer.debris_ids)
		assert(count <= 8)
		renderer.commands(0, 99)
		assert(plan == renderer.commands(camera, 10), "Backtracking/frozen-clock determinism")
	var early: Array = renderer.commands(0, 10)
	assert(early != renderer.commands(0, 11), "Water and debris must animate")
	assert(renderer.commands(8570, 10) == renderer.commands(8570, 11), "Terminal must be motionless")
	var plug_width := 0.0
	for command: Dictionary in renderer.commands(8570, 10):
		if command.id == "plug":
			assert(command.rect.position.y == 464 and command.rect.size.y == 56)
			plug_width += command.rect.size.x
	assert(is_equal_approx(plug_width, 960), "Terminal fills entire visible bore")
	for command: Dictionary in renderer.commands(5000, 10, true):
		assert(command.id != "plug" and command.rect.end.x <= 6000)
	assert(renderer.profile.sample(5500, true).water > 0.5)
	assert(not Pipe.new().configure({}), "Missing art must not produce substitute drawings")
	var canvas := PipeCanvas.new()
	canvas.renderer = renderer
	root.add_child(canvas)
	canvas.queue_redraw()
	await process_frame
	await process_frame
	canvas.queue_free()
	print("PASS: bundled pipe art, clipping, motion, deterministic pause/backtracking, terminal and trial")
	quit()
