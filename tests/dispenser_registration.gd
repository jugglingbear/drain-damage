extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var dispenser = game.dispenser
	var feet := Vector2(3300,440)
	var origin := feet-Vector2(64,104)
	for hero in ["tony","sean"]:
		for state in ["emerge","look_left","look_right","shrug"]:
			var frame: Dictionary = dispenser.art.heroes[hero].states[state].duplicate(true)
			var centers: Array[float] = []
			for mirror in [false,true]:
				frame.mirror_x = mirror
				var geometry: Dictionary = dispenser.frame_geometry(frame,origin)
				var dest: Rect2 = geometry.destination
				# RenderingServer preserves left edge and uses absolute size for UV flips.
				var bounds := Rect2(dest.position,dest.size.abs())
				centers.append(bounds.get_center().x)
				assert(absf(bounds.get_center().x-feet.x) < 1,"Facing must not move hero a sprite width")
				assert(absf(bounds.end.y-feet.y) < 7,"Exit poses stay at registered foot baseline")
			assert(absf(centers[0]+centers[1]-2*feet.x) < 0.01)
		# Actual Sean look states are the same source with opposite facing.
		if hero == "sean":
			var left: Dictionary = dispenser.frame_geometry(dispenser.art.heroes[hero].states.look_left,origin)
			var right: Dictionary = dispenser.frame_geometry(dispenser.art.heroes[hero].states.look_right,origin)
			assert(absf(left.destination.position.x-right.destination.position.x) < 1)
	game.queue_free()
	await process_frame
	print("PASS: both heroes/facings, emerge/look/shrug registration and Sean flip regression")
	quit()
