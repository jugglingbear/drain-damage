extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	var view = game.flush.world_view
	view.set_process(false)
	view._process(0)
	game.flush.enter_ride(game,10)
	var ride = game.flush.ride
	var hole: Dictionary = ride.visual_obstacles[0]
	assert(hole.activates_at == 2.9 and ride.encounter.hand_timeline.jump_volume_clear_at == 3.05)
	ride.clock = hole.activates_at
	ride.encounter_clock = ride.clock
	ride.encounter_scroll = ride.clock*ride.scroll_speed
	var errors: Array[String] = []
	var pixels := Rect2()
	var started := false
	for anchor in [180.0,300.0,650.0]:
		ride.position.x = anchor
		for angle in [-18.0,18.0]:
			view.yaw = angle
			view.update_world()
			for x in [-float(hole.width)*.5,float(hole.width)*.5]:
				for bank in [-float(hole.depth)*.5,float(hole.depth)*.5]:
					var point: Vector2 = ride.obstacle_position(hole)+Vector2(x,bank)
					var pixel: Vector2 = view.camera.unproject_position(view.world(point))
					if not Rect2(12,104,936,424).has_point(pixel):
						errors.append("Impact corner outside viewport: anchor%s yaw%s pixel%s" % [anchor,angle,pixel])
					pixels = pixels.expand(pixel) if started else Rect2(pixel,Vector2.ZERO)
					started = true
	# Even at the foremost anchor, the leading board edge cannot reach the fist before it clears.
	var first_contact: float = (float(hole.x)-float(hole.width)*.5-45-650)/ride.scroll_speed
	assert(first_contact > 3.05)
	var witness: float = ride.encounter.witness.jump_press_world_x[0]
	assert((witness-650)/ride.scroll_speed-1.25 >= 1.5)
	var hero_top := INF
	var hero_bottom := -INF
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		for mode in ["normal","hard"]:
			game.difficulty = mode
			for anchor in [180.0,300.0,650.0]:
				for angle in [-18.0,18.0]:
					view.yaw = angle
					for bank in [260.0,400.0]:
						ride.position = Vector2(anchor,bank)
						for height in [0.0,54.0]:
							ride.render_height = height
							for age in [1.25,1.8,2.35,2.9,3.05,3.35,3.65]:
								ride.clock = age
								ride.encounter_clock = age
								view.update_world()
								for sprite: Sprite3D in view.rider.get_children():
									for corner in 8:
										var pixel: Vector2 = view.camera.unproject_position(sprite.to_global(sprite.get_aabb().get_endpoint(corner)))
										hero_top = minf(hero_top,pixel.y)
										hero_bottom = maxf(hero_bottom,pixel.y)
										if not Rect2(12,104,936,424).has_point(pixel) and errors.size() < 20:
											errors.append("Hero clips viewport/HUD: %s %s anchor%s yaw%s bank%s height%s age%s pixel%s" % [hero.id,mode,anchor,angle,bank,height,age,pixel])
	# The heel must descend on screen toward the same track point while the camera holds still.
	ride.position = Vector2(300,330)
	ride.render_height = 0
	for angle in [-18.0,18.0]:
		view.yaw = angle
		var previous := -INF
		var held_camera := Transform3D.IDENTITY
		for sample in range(19):
			ride.clock = 2.72+sample*.01
			ride.encounter_clock = ride.clock
			ride.encounter_scroll = ride.clock*ride.scroll_speed
			view.update_world()
			if sample == 0: held_camera = view.camera.global_transform
			assert(view.camera.global_transform.is_equal_approx(held_camera),"Strike cannot be canceled by camera motion")
			for actor: Node3D in view.actors.values():
				if not actor.has_node("hand"): continue
				var hand = actor.get_node("hand")
				var heel: Vector3 = hand.contact.position+hand.opaque_contact("contact",hand.contact.basis)
				var projected: Vector2 = view.camera.unproject_position(hand.to_global(heel))
				var track: Vector2 = view.camera.unproject_position(hand.to_global(Vector3(0,0,-.35+hand.opaque_contact("contact",hand.contact.basis).z)))
				var separation := projected.y-track.y
				assert(separation >= previous-.01 and separation <= .1,"Projected heel descends toward track without overshoot")
				if sample == 18: assert(absf(separation) < .1,"Gap creation coincides with visible heel contact")
				previous = separation
	print("PROJECTION gap",pixels," hero Y",hero_top,"..",hero_bottom)
	game.free()
	if not errors.is_empty():
		for error in errors: push_error(error)
		quit(1)
		return
	print("PASS: full140px hand opening projected inside both yaw views, pixel bounds",pixels,
		"; earliest footprint contact",first_contact," after3.05 clearance; warning>=1.5s")
	quit()
