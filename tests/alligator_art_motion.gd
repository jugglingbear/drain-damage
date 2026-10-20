extends SceneTree
const Art = preload("res://scripts/skitterling_art.gd")
const Encounter = preload("res://scripts/skitterling_encounter.gd")

func _initialize() -> void:
	var art := Art.new()
	assert(art.prepare(), art.last_error)
	var boss := Encounter.new()
	boss.configure(42)
	boss.start(Rect2(96,394,26,46))
	var snapshot: Dictionary = boss.snapshot()
	snapshot.phase = "alligator"
	snapshot.state = "alligator_charge"
	snapshot.visible = true
	snapshot.position = Vector2(480,440)
	var stride := float(art.body.alligator_ground_motion.stride_distance_pixels)
	for phase in range(6):
		snapshot.alligator_ground_distance = phase * stride / 6.0
		snapshot.elapsed = .2
		var selected: Dictionary = art._selection(snapshot)
		assert(selected.key == "alligator-run-source-v1:" + str(phase))
		assert(art._selection(snapshot, false).key.begins_with("alligator-source-v2:"))
		var old_bounds: Rect2 = art.collision_bounds(snapshot)
		snapshot.alligator_ground_distance += stride * 2.3
		snapshot.alligator_snap_elapsed = .37
		assert(art.collision_bounds(snapshot) == old_bounds, "Visual gait must preserve legacy combat bounds")
	for key: String in art.roach_body.targets:
		if not key.begins_with("alligator-run") and not key.begins_with("alligator-jaw"): continue
		var target: Dictionary = art.roach_body.targets[key]
		assert(target.groups.size() == 140 and target.points.size() == 140)
		assert(target.groups == art.roach_body.targets["alligator-run-source-v1:0"].groups)
		assert(target.groups.count("upper_jaw") == 18 and target.groups.count("lower_jaw") == 14)
		for shape: Dictionary in target.shapes: assert(shape.mobility <= .35)
	snapshot.alligator_ground_distance = stride * .37
	snapshot.elapsed = .15
	var before: Dictionary = art._selection(snapshot)
	snapshot.elapsed = .39
	var after: Dictionary = art._selection(snapshot)
	assert(before.key == after.key and before.blend == after.blend)
	assert(before.overrides != after.overrides, "Jaw cycle advances independently of planted leg phase")
	for index in range(140):
		var pose: Dictionary = art.roach_body.pose_keys(before.key,before.next_key,before.blend,index,before.overrides)
		var group: String = art.roach_body.targets[before.key].groups[index]
		assert(pose.key.begins_with("alligator-jaw" if group in ["upper_jaw","lower_jaw"] else "alligator-run"))
		if group == "torso_tail":
			assert(pose.key == "alligator-run-source-v1:0" and pose.next_key == pose.key,
				"Torso and tail retain fixed anatomical anchors while the legs cycle")
	for boundary in [["alligator_charge",1.1,"alligator_charge_turn",0.0],
		["alligator_charge_turn",.9,"alligator_charge",0.0],
		["alligator_charge",1.1,"alligator_jaw_recovery",0.0]]:
		snapshot.state = boundary[0]
		snapshot.elapsed = boundary[1]
		snapshot.alligator_snap_elapsed = 1.1
		before = art._selection(snapshot)
		snapshot.state = boundary[2]
		snapshot.elapsed = boundary[3]
		after = art._selection(snapshot)
		for index in range(140):
			assert(point(art,before,index).distance_to(point(art,after,index)) < .001,
				"Charge, turn and recovery must preserve the exact fractional anatomy pose at their boundary")
	snapshot.state = "alligator_charge"
	snapshot.elapsed = .2
	snapshot.alligator_ground_distance = stride - .0001
	before = art._selection(snapshot)
	snapshot.alligator_ground_distance = stride + .0001
	after = art._selection(snapshot)
	for index in range(140):
		assert(point(art,before,index).distance_to(point(art,after,index)) < .02,
			"Last-to-first gait wrap must remain continuous")
	print("PASS: six alligator gait phases, independent anatomical jaws, preserved combat bounds and continuous transitions")
	quit()

func point(art: RefCounted, selection: Dictionary, index: int) -> Vector2:
	var pose: Dictionary = art.roach_body.pose_keys(selection.key,selection.next_key,selection.blend,index,
		selection.get("overrides",{}))
	return art.roach_body.insect_position(pose.key,pose.next_key,pose.blend,index,2.0)
