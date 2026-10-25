extends SceneTree
const Flush = preload("res://scripts/level_two_flush.gd")
const Art = preload("res://scripts/flush_art.gd")
const Flow = preload("res://scripts/flush_flow.gd")

class RecordingArt extends Art:
	var calls: Array[String] = []
	func shadows(_host: Node2D, _model: RefCounted, _item: Dictionary) -> void: calls.append("shadow")
	func debris(_host: Node2D, _model: RefCounted, _item: Dictionary) -> void: calls.append("debris")
	func swimmer(_host: Node2D, _model: RefCounted) -> void: calls.append("hero")
	func draw_named(_host: Node2D, id: String, _offset := Vector2.ZERO, _tint := Color.WHITE) -> void:
		calls.append(id)
	func draw_frame(_host: Node2D, _frame: Dictionary, _offset := Vector2.ZERO, _tint := Color.WHITE,
			_clip_bottom := INF) -> void:
		calls.append("burble")

class Host extends Node2D:
	var invulnerable := 0.0

func _initialize() -> void:
	var model := Flush.new()
	model.definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-flush.json"))
	var art := RecordingArt.new()
	art.manifest = model.definition.art
	model.art = art
	var host := Host.new()
	var cases := 0
	var foreground: Dictionary = art.manifest.frames.drain_front
	var patch: Rect2 = art.clipped_region(foreground).target
	patch.position += model.project(Vector2.ZERO)
	var front_position := Vector2(0,Flow.annulus(20).y)
	var sean_frame: Dictionary = art.manifest.animations.sean_normal.frames[0]
	var upper_body: Rect2 = art.clipped_region(sean_frame,Vector2.ZERO,0.0).target
	upper_body.position += model.project(front_position)
	assert(patch.intersects(upper_body),"Regression fixture must reproduce the foreground overlap at20s")
	for hero in ["tony","sean"]:
		for costume in ["normal","hard"]:
			for frame: Dictionary in art.manifest.animations[hero+"_"+costume].frames:
				var visible := art.clipped_region(frame,Vector2.ZERO,0.0)
				assert(not visible.is_empty() and visible.target.size.y > 40)
				assert(is_zero_approx(visible.target.end.y),"Only the body below the chest is clipped")
				assert(is_equal_approx(visible.source.size.y/float(frame.source_rect[3]),
					visible.target.size.y/float(frame.destination[3])),"Clip preserves texture proportions")
				var previous_height: float = visible.target.size.y
				for depth in [0.0,16.0,32.0,48.0,64.0]:
					var sinking := art.clipped_region(frame,Vector2(0,depth),0.0)
					var height := 0.0 if sinking.is_empty() else float(sinking.target.size.y)
					assert(height <= previous_height)
					if not sinking.is_empty(): assert(sinking.target.end.y <= 0.0001)
					previous_height = height
				assert(art.clipped_region(frame,Vector2(0,64),0.0).is_empty())
				for time in [0.0,20.0,34.99,35.0,39.99,40.0,41.5,42.99]:
					model.clock = time
					model.state = "bowl" if time < 35 else "drain"
					var bounds := Flow.annulus(time)
					for radius in [bounds.x,(bounds.x+bounds.y)*0.5,bounds.y]:
						for angle in range(16):
							model.position = Vector2.from_angle(angle*TAU/16)*float(radius)
							model.hazards = [{"pos":model.position+Vector2(0,-5)},
								{"pos":model.position+Vector2(0,5)}]
							art.calls.clear()
							model.draw_bowl_actors(host)
							if time < 40:
								assert(art.calls == ["shadow","shadow","debris","debris","drain_front","hero"])
							else:
								assert(art.calls == ["shadow","shadow","debris","debris","hero","drain_front","burble"])
							cases += 1
	host.free()
	model.radio.free()
	print("PASS: %d stroke/costume/annulus draw-order cases, chest clip and complete scripted submersion" % cases)
	quit()
