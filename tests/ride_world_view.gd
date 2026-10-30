extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void: call_deferred("checks")

var opaque_hulls: Dictionary = {}

func clip_plane(polygon: Array[Vector3], axis: int, edge: float, keep_above: bool) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if polygon.is_empty(): return result
	var previous := polygon[-1]
	var previous_inside := previous[axis] >= edge if keep_above else previous[axis] <= edge
	for point in polygon:
		var inside := point[axis] >= edge if keep_above else point[axis] <= edge
		if inside != previous_inside:
			result.append(previous.lerp(point,(edge-previous[axis])/(point[axis]-previous[axis])))
		if inside: result.append(point)
		previous = point
		previous_inside = inside
	return result

func opaque_hull(hand: Node3D, id: String) -> PackedVector2Array:
	if opaque_hulls.has(id): return opaque_hulls[id]
	# Match the shader's alpha .5 cutoff, including painted arm pixels absent from registration outlines.
	var texture: Texture2D = load("res://"+str(hand.registration.path))
	var image := texture.get_image()
	var crop: Array = hand.registration.frames[id].source_rect
	var points := PackedVector2Array()
	for y in range(int(crop[1]),int(crop[1]+crop[3])):
		var left := -1
		var right := -1
		for x in range(int(crop[0]),int(crop[0]+crop[2])):
			if image.get_pixel(x,y).a < .5: continue
			if left < 0: left = x
			right = x
		if left >= 0:
			points.append(Vector2(left,y))
			points.append(Vector2(right+1,y))
			points.append(Vector2(left,y+1))
			points.append(Vector2(right+1,y+1))
	opaque_hulls[id] = Geometry2D.convex_hull(points)
	return opaque_hulls[id]

func rider_overlap(hand: Node3D, sprite: Sprite3D, id: String) -> Array[Vector3]:
	var polygon: Array[Vector3] = []
	if not sprite.is_visible_in_tree(): return polygon
	var frame: Dictionary = hand.registration.frames[id]
	var pivot: Array = frame.root_px if id.begins_with("forearm") else frame.wrist_px
	for point in opaque_hull(hand,id):
		polygon.append(sprite.to_global(Vector3(point.x-float(pivot[0]),float(pivot[1])-point.y,0)*hand.PIXEL))
	# Union of all legal board centers plus the90x28 footprint and Tony's84px head at54px apex.
	# Shader-discarded wall pixels are outside this reachable prism (bankZ minimum-1.68).
	for axis in 3:
		polygon = clip_plane(polygon,axis,Vector3(1.35,0,-1.68)[axis],true)
		polygon = clip_plane(polygon,axis,Vector3(6.95,1.38,1.68)[axis],false)
	return polygon

func opaque_witness(hand: Node3D, sprite: Sprite3D, id: String) -> Dictionary:
	var texture: Texture2D = load("res://"+str(hand.registration.path))
	var image := texture.get_image()
	var frame: Dictionary = hand.registration.frames[id]
	var crop: Array = frame.source_rect
	var pivot: Array = frame.root_px if id.begins_with("forearm") else frame.wrist_px
	var reachable := AABB(Vector3(1.35,0,-1.68),Vector3(5.6,1.38,3.36))
	for y in range(int(crop[1]),int(crop[1]+crop[3])):
		for x in range(int(crop[0]),int(crop[0]+crop[2])):
			if image.get_pixel(x,y).a < .5: continue
			var world := sprite.to_global(Vector3(x+.5-float(pivot[0]),float(pivot[1])-y-.5,0)*hand.PIXEL)
			if reachable.has_point(world): return {"atlas":Vector2i(x,y),"world":world}
	return {}

func checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var target: Dictionary = Launch.parse(["--level=2-landing"]).target
	Launch.initialize(game,target)
	var view = game.flush.world_view
	view.set_process(false)
	view._process(0)
	assert(view.configured and view.container.visible)
	assert(game.flush.state == "landing" and game.flush.checkpoint_saved)
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		for difficulty in ["normal","hard"]:
			game.difficulty = difficulty
			for index in range(13):
				game.flush.enter_ride(game,index)
				var model = game.flush.ride
				var saved := [model.position,model.clock,model.encounter_clock,model.checkpoint_index]
				for angle in [-18.0,0.0,18.0]:
					view.yaw = angle
					view.update_world()
					assert(saved == [model.position,model.clock,model.encounter_clock,model.checkpoint_index],
						"Rendering and camera turns must not advance gameplay")
					assert(view.actors.size() == model.visual_obstacles.size())
					for sprite: Sprite3D in view.rider.get_children():
						var bounds := sprite.get_aabb()
						for i in 8:
							var point := sprite.to_global(bounds.get_endpoint(i))
							assert(absf(point.z-view.rider.position.z) < .001,
								"Rider art must not lean through narrow channel banks")
	# Ground cues travel with course distance and remain stable across encounter changes and pause.
	game.flush.enter_ride(game,0)
	var travel_model = game.flush.ride
	travel_model.clock = 1.0
	view.update_world()
	var initial_distance: float = view.far_wall.get_shader_parameter("course_distance")
	travel_model.clock += .5
	view.update_world()
	var moved_distance: float = view.far_wall.get_shader_parameter("course_distance")
	assert(is_equal_approx(moved_distance-initial_distance,travel_model.scroll_speed*.5/view.UNIT))
	travel_model.encounter_scroll = 0
	view.update_world()
	assert(is_equal_approx(view.far_wall.get_shader_parameter("course_distance"),moved_distance))
	game.paused = true
	view._process(.5)
	assert(is_equal_approx(view.far_wall.get_shader_parameter("course_distance"),moved_distance))
	game.paused = false
	assert(is_equal_approx(view.world(Vector2(0,430)).z-view.world(Vector2(0,230)).z,4.0),
		"Production waterway must retain the proof's four-metre span")
	# Exercise activation and moving assemblies, not just their initial hidden state.
	for index in range(13):
		game.flush.enter_ride(game,index)
		var model = game.flush.ride
		for age in [0.0,1.3,2.9,3.05,3.2,3.65,4.0]:
			model.clock = age
			model.encounter_clock = age
			view.update_world()
			var active := 0
			for actor: Node3D in view.actors.values():
				var obstacle: Dictionary = actor.get_meta("obstacle")
				if obstacle.kind == "deck":
					var reaches_floor := false
					var raised_surface := false
					for child in actor.get_children():
						if child is MeshInstance3D:
							var bounds: AABB = child.get_aabb()
							for corner in 8:
								if is_equal_approx(child.to_global(bounds.get_endpoint(corner)).y,.12):
									raised_surface = true
								if child.to_global(bounds.get_endpoint(corner)).y <= -1.99:
									reaches_floor = true
					assert(reaches_floor,"Island supports must reach the shaft floor, not float above it")
					assert(raised_surface,"Island top must have the proof's physical 12cm elevation")
				if obstacle.kind in ["gap","long_pit"]:
					assert(actor.get_node("opening").visible == model.obstacle_active(obstacle))
					if model.obstacle_active(obstacle): active += 1
				if str(obstacle.art_id) == "float_ball":
					assert(is_equal_approx(actor.get_node("pivot").global_position.z,-2))
			assert(view.water.get_shader_parameter("opening_count") == active)
			assert(view.bed.get_shader_parameter("opening_count") == active)
	# The wrist axis must continue along the forearm throughout both approved views.
	game.flush.enter_ride(game,10)
	for angle in [-18.0,18.0]:
		view.yaw = angle
		for age in [2.65,2.8,2.9,3.05,3.2,3.5]:
			game.flush.ride.encounter_clock = age
			game.flush.ride.clock = age
			view.update_world()
			for actor: Node3D in view.actors.values():
				if not actor.has_node("hand"): continue
				var hand = actor.get_node("hand")
				var fist: Sprite3D = hand.contact if hand.contact.visible else hand.curled
				var delta: Vector3 = fist.position-hand.arm.position
				var normal: Vector3 = view.camera.global_basis.z
				var tangent := (delta-normal*delta.dot(normal)).normalized()
				if age <= 3.05:
					assert((-fist.basis.y).dot(tangent) > .999,"Raised/striking wrist must align with forearm")
				assert(hand.arm.position.is_equal_approx(hand.root_point),"Forearm remains rooted in hatch")
				if is_equal_approx(age,2.9):
					assert(absf(fist.position.y+hand.opaque_bottom("contact",fist.basis)) < .02,
						"Opaque impact silhouette must meet water")
	var withdrawal_failures: Dictionary = {}
	# Verify opaque hull separation densely throughout withdrawal, rather than a height/Z shortcut.
	for angle in [-18.0,18.0]:
		view.yaw = angle
		var raised_pose := Basis.IDENTITY
		for sample in range(121):
			var age := 3.05+sample*.005
			game.flush.ride.encounter_scroll = age*game.flush.ride.scroll_speed
			game.flush.ride.clock = age
			game.flush.ride.encounter_clock = age
			view.update_world()
			for actor: Node3D in view.actors.values():
				if not actor.has_node("hand"): continue
				var hand = actor.get_node("hand")
				if sample == 0: raised_pose = hand.curled.basis
				assert(hand.curled.basis.is_equal_approx(raised_pose),"Withdrawal retains stable raised orientation")
				assert(hand.arm.position.is_equal_approx(hand.root_point),"Withdrawal cannot drag root out of hatch")
				var forearm: Dictionary = hand.registration.frames.forearm_a
				var palm: Dictionary = hand.registration.frames.curled
				var arm_end: Vector3 = hand.arm.to_global(Vector3(float(forearm.wrist_px[0])-float(forearm.root_px[0]),
					float(forearm.root_px[1])-float(forearm.wrist_px[1]),0)*hand.PIXEL)
				var palm_join: Vector3 = hand.curled.to_global(Vector3(float(palm.arm_overlap_px[0])-float(palm.wrist_px[0]),
					float(palm.wrist_px[1])-float(palm.arm_overlap_px[1]),0)*hand.PIXEL)
				assert(arm_end.distance_to(palm_join) < .1,"Painted forearm endpoint stays inside palm overlap")
				for entry in [[hand.curled,"curled"],[hand.arm,"forearm_a"]]:
					var overlap := rider_overlap(hand,entry[0],entry[1])
					if not overlap.is_empty():
						var key := str(angle)+":"+str(entry[1])
						if not withdrawal_failures.has(key):
							withdrawal_failures[key] = {"first":age,"last":age,"samples":0,"lowest_y":INF,
								"opaque_pixel":opaque_witness(hand,entry[0],entry[1])}
						if withdrawal_failures[key].opaque_pixel.is_empty():
							withdrawal_failures[key].opaque_pixel = opaque_witness(hand,entry[0],entry[1])
						withdrawal_failures[key].last = age
						withdrawal_failures[key].samples += 1
						for point in overlap: withdrawal_failures[key].lowest_y = minf(withdrawal_failures[key].lowest_y,point.y)
	if not withdrawal_failures.is_empty():
		for key in withdrawal_failures: push_error("Withdrawal hull "+key+": "+str(withdrawal_failures[key]))
		game.free()
		quit(1)
		return
	# The full ride retains its original gameplay bank range mapped to the proof water width and boosted ramp apex.
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		for angle in [-18.0,0.0,18.0]:
			view.yaw = angle
			for x in [180.0,650.0]:
				for bank in [260.0,400.0]:
					for height in [0.0,94.0]:
						game.flush.ride.position = Vector2(x,bank)
						game.flush.ride.render_height = height
						view.update_world()
						for sprite: Sprite3D in view.rider.get_children():
							for i in 8:
								var point: Vector2 = view.camera.unproject_position(sprite.to_global(sprite.get_aabb().get_endpoint(i)))
								assert(Rect2(12,104,936,356).has_point(point),"Ride hero clipped: %s %s %s" % [hero.id,height,point])
	game.free()
	print("PASS: all13 world adapters, both heroes/costumes, camera-independent state;242 opaque withdrawal hull checks, fixed root/basis and palm connection")
	quit()
