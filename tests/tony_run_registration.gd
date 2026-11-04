extends SceneTree
const Game = preload("res://scripts/game.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func run_checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var art = game.world_art.hero_aim_art
	for hero_id in art.RUN_OVERRIDES:
		var overrides: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(art.RUN_OVERRIDES[hero_id]))
		for mode in ["normal","easy","hard"]:
			art.configure(mode)
			var data: Dictionary = overrides.costumes[mode]
			var phase: Dictionary = art.animations.heroes[hero_id].phases.run
			check(phase.frames.size() == 6,"Six distinct registered run phases")
			var contacts := 0
			var passing := 0
			var top := INF
			var bottom := -INF
			for index in range(6):
				var frame: Dictionary = phase.frames[index]
				var registration: Dictionary = data.registration.frames[index]
				var source: Array = frame.source_rect
				var destination: Array = frame.destination
				var scale := float(destination[3])/float(source[3])
				check(is_equal_approx(scale,data.source_scale),"Registered sheet scale is preserved")
				check(is_equal_approx(destination[2]/source[2],scale),"Run body is not stretched")
				var marks: Dictionary = registration.landmarks
				var shoulder := Vector2(destination[0],destination[1])+(
					Vector2(marks.front_shoulder[0],marks.front_shoulder[1])-Vector2(source[0],source[1]))*scale
				check(shoulder.distance_to(Vector2(52,64)+Vector2(frame.attachment_offset[0],frame.attachment_offset[1])) < 0.02,
					"Composed front arm remains attached to the authored socket")
				var feet_y: float = destination[1]+(marks.ground_plane_anchor[1]-source[1])*scale
				check(absf(feet_y-(104-marks.suggested_run_flight_clearance_canvas_px)) < 0.02,
					"Contact and passing phases retain their authored ground clearance")
				if marks.contact_state == "grounded": contacts += 1
				if marks.contact_state == "run-flight": passing += 1
				var head_y: float = destination[1]+registration.opaque_bounds_local[1]*scale
				top = minf(top,head_y)
				bottom = maxf(bottom,head_y)
			check(contacts == 4 and passing == 2,"Both strides include contact and passing phases")
			check(bottom-top < 6,"Head does not bounce excessively between registered poses")
	game.queue_free()
	await process_frame
	print("Hero run registration: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
