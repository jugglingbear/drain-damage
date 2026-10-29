extends SceneTree
const Model = preload("res://scripts/camera_test_model.gd")

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func run_path(hz: int) -> RefCounted:
	var model := Model.new()
	for frame in range(3*hz):
		var time := frame/float(hz)
		var steer := Vector2.RIGHT if time < 1 else Vector2(1,.4)
		model.tick(1.0/hz,steer,time >= 1 and time < 1.5)
	return model

func _initialize() -> void:
	var model := Model.new()
	var basin: Dictionary = Model.LAYOUT.basin
	var rect := Rect2(basin.center-basin.size*.5,basin.size)
	if not require(is_equal_approx(Model.rectangle_support(Vector2(rect.position.x,0),rect),.5),"Basin edge half support"): return
	if not require(model.support_at(Vector2(rect.position.x,0)).surface == "basin","Exact half support selects basin"): return
	if not require(model.support_at(rect.position).surface == "track","Quarter-supported corner cannot select basin top"): return
	if not require(is_equal_approx(Model.ellipse_support(Vector2(10,0),Vector2(10,0),Vector2(1.8,1.4)),1),"Ellipse center full support"): return
	if not require(model.support_at(Vector2(10.8,.6)).surface == "track","Ellipse bounding-box corner is not brass support"): return
	if not require(model.hole_entry(Vector2(12,.78),Vector2(13.05,.78)) == INF,"Round hole rectangular corner must pass"): return
	# At Z0, 65% overlap is 15% of the board width past the mean left circular boundary.
	var radius := .65
	var half_depth := .14
	var mean_radius := (half_depth*sqrt(radius*radius-half_depth*half_depth)+radius*radius*asin(half_depth/radius))/(2*half_depth)
	var threshold_x := 14-mean_radius+.9*.15
	var expected_time := (threshold_x-12)/4
	if not require(model.hole_entry(Vector2(12.9,0),Vector2(13.1,0)) == INF,"Initial edge overlap must remain safe"): return
	if not require(absf(model.hole_fraction(Vector2(threshold_x-.009,0))-.64) < .00001,
		"Circle overlap below 65% is measured as actual area"): return
	if not require(model.hole_entry(Vector2(threshold_x-.009,0),Vector2(threshold_x-.009,0)) == INF,
		"Stationary 64 percent overlap stays safe"): return
	if not require(model.hole_entry(Vector2(threshold_x+.009,0),Vector2(threshold_x+.009,0)) == 0,
		"Stationary 66 percent overlap falls"): return
	if not require(model.hole_entry(Vector2(12,.7),Vector2(16,.7)) == INF,
		"Swept shallow rim overlap never reaches 65%"): return
	var entry: float = model.hole_entry(Vector2(12,0),Vector2(16,0))
	if not require(absf(entry-expected_time) < .0001,"Swept threshold must find 65%-area crossing with safe endpoints"): return
	for bank in [-.4,-.2,0.0,.2,.4]:
		var start := Vector2(12,bank)
		var finish := Vector2(16,-bank)
		var forward: float = model.hole_entry(start,finish)
		var reverse: float = model.hole_entry(finish,start)
		if not require(forward != INF and absf(forward-reverse) < .0001,"Symmetric diagonal sweeps find same 65%-area entry"): return
		if not require(model.hole_fraction(start.lerp(finish,forward-.0001)) < .65 and
			model.hole_fraction(start.lerp(finish,forward+.0001)) > .65,
			"Swept first crossing separates safe and lethal overlap"): return
	model.position = Vector2(12,0)
	model.tick(1,Vector2.RIGHT,false)
	if not require(model.dead and absf(model.position.x-threshold_x) < .0001,"Ground crossing freezes at exact contact"): return
	var death_clock: float = model.clock
	model.tick(5,Vector2.RIGHT,true)
	if not require(model.clock == death_clock and absf(model.position.x-threshold_x) < .0001,"Death freezes simulation"): return
	model.reset()
	model.position = Vector2(12.85,0)
	model.tick(.6,Vector2.RIGHT,true)
	if not require(not model.dead and model.position.x > 15.1 and model.grounded,"Jump clears actual hole plus board footprint"): return
	model.reset()
	model.tick(.3,Vector2.ZERO,true)
	if not require(absf(model.elevation-.54) < .0001,"Jump apex .54 at .3 seconds"): return
	model.tick(.3,Vector2.ZERO,true)
	if not require(model.grounded and model.elevation == 0,"Jump duration .6 without held retrigger"): return
	model.reset()
	model.position = Vector2(18,0)
	model.tick(.5,Vector2.RIGHT,false)
	if not require(model.grounded and absf(model.elevation-.4) < .0001 and model.surface == "ramp","Continuous ramp ascent"): return
	model.tick(.3,Vector2.RIGHT,false)
	if not require(model.grounded and model.elevation > .6,"Ramp lip supports rigid overhang until rear clears"): return
	model.tick(.1,Vector2.RIGHT,false)
	if not require(not model.grounded and model.elevation > .6,"Rear clearance releases smoothly into flight"): return
	model.tick(.6,Vector2.ZERO,false)
	if not require(model.grounded and model.elevation == 0,"Ramp exit lands on water"): return
	model.reset()
	model.position = Vector2(18,0)
	model.tick(.5,Vector2.RIGHT,true)
	if not require(model.grounded and model.surface == "ramp" and absf(model.elevation-.4) < .0001,"Jump lands on rising ramp"): return
	model.tick(.25,Vector2.LEFT,false)
	if not require(model.grounded and absf(model.elevation-.2) < .0001,"Ramp descent follows surface continuously"): return
	model.reset()
	model.position = Vector2(17,0)
	var previous_height := 0.0
	var previous_pitch := 0.0
	for frame in range(180):
		model.tick(Model.STEP,Vector2.RIGHT,false)
		var pose: Dictionary = model.board_pose()
		if not require(absf(pose.rear.distance_to(pose.front)-Model.BOARD_LENGTH) < .00001,"Rotated board must retain rigid length"): return
		if not require(absf(model.elevation-previous_height) < .05 and absf(model.board_pitch-previous_pitch) < .03,
			"Ramp toe and lip pose must remain continuous"): return
		for sample in range(25):
			var edge: Vector3 = pose.rear.lerp(pose.front,sample/24.0)
			var top := (edge.x-18)*.2 if edge.x >= 18 and edge.x <= 21 else 0.0
			if not require(edge.y >= top-.00001,"Rigid board underside penetrates ramp/water"): return
		if model.position.x > 19 and model.position.x < 20:
			if not require(absf(model.board_pitch-atan(.2)) < .00001,"Full slope must be atan(rise/run)"): return
		previous_height = model.elevation
		previous_pitch = model.board_pitch
	model.reset()
	model.position = Vector2(20,0)
	model.elevation = .4
	model.board_pitch = atan(.2)
	for frame in range(80):
		model.tick(Model.STEP,Vector2(0,1),false)
		var pose: Dictionary = model.board_pose()
		if model.position.y-Model.HALF.y < .8:
			for edge in [pose.rear,pose.front]:
				if not require(edge.y >= (edge.x-18)*.2-.00001,"Bank exit cannot sink through remaining ramp"): return
	model.reset()
	model.position = Vector2(20,0)
	model.elevation = .4
	model.board_pitch = atan(.2)
	previous_height = model.elevation
	previous_pitch = model.board_pitch
	for frame in range(90):
		model.tick(Model.STEP,Vector2.LEFT,false)
		var pose: Dictionary = model.board_pose()
		if not require(absf(model.elevation-previous_height) < .05 and absf(model.board_pitch-previous_pitch) < .03,
			"Descending toe follows the same continuous rigid chord"): return
		for sample in range(25):
			var edge: Vector3 = pose.rear.lerp(pose.front,sample/24.0)
			var top := (edge.x-18)*.2 if edge.x >= 18 and edge.x <= 21 else 0.0
			if not require(edge.y >= top-.00001,"Descending board cannot penetrate ramp"): return
		previous_height = model.elevation
		previous_pitch = model.board_pitch
	var ramp_reference := Model.new()
	ramp_reference.position = Vector2(17,0)
	for frame in range(180): ramp_reference.tick(Model.STEP,Vector2.RIGHT,false)
	for hz in [30,60,144]:
		var other := Model.new()
		other.position = Vector2(17,0)
		for frame in range(hz*3/2): other.tick(1.0/hz,Vector2.RIGHT,false)
		if not require(other.position.distance_to(ramp_reference.position) < .0001 and
			absf(other.elevation-ramp_reference.elevation) < .0001 and absf(other.board_pitch-ramp_reference.board_pitch) < .0001,
			"Ramp pose and flight must remain FPS independent"): return
	var reference = run_path(120)
	for hz in [30,60,144]:
		var other = run_path(hz)
		if not require(reference.position.distance_to(other.position) < .0001 and absf(reference.elevation-other.elevation) < .0001,
			"Fixed-step trajectory must be FPS independent"): return
	model.reset()
	model.position = Vector2(14,0)
	model.elevation = .54
	model.grounded = false
	model.tick(.4,Vector2.ZERO,false)
	if not require(model.dead and absf(model.clock-.3) < .0001,"Airborne hole landing dies at floor contact"): return
	for hz in [30,60,120,144]:
		model.reset()
		model.position = Vector2(12,0)
		for frame in range(hz): model.tick(1.0/hz,Vector2.RIGHT,false)
		if not require(model.dead and absf(model.position.x-threshold_x) < .0001 and absf(model.clock-expected_time) < .0001,
			"Swept death position/time must be FPS independent"): return
	model.reset()
	if not require(not model.dead and model.clock == 0 and model.position == Model.LAYOUT.start,
		"Reset clears death and fractional time"): return
	print("PASS: surface support, swept 65%-footprint circular hole, jump, ramp contact/exit, death freeze and FPS-independent world replay")
	quit()
