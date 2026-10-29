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
	var entry: float = model.hole_entry(Vector2(12,0),Vector2(16,0))
	if not require(absf(entry-.225) < .0001,"Swept board must reach circular hole at X12.9"): return
	model.position = Vector2(12,0)
	model.tick(1,Vector2.RIGHT,false)
	if not require(model.dead and absf(model.position.x-12.9) < .0001,"Ground crossing freezes at exact contact"): return
	var death_clock: float = model.clock
	model.tick(5,Vector2.RIGHT,true)
	if not require(model.clock == death_clock and model.position == Vector2(12.9,0),"Death freezes simulation"): return
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
	if not require(not model.grounded and model.elevation > .5 and model.elevation < .6,"Ramp exit falls smoothly"): return
	model.tick(.5,Vector2.ZERO,false)
	if not require(model.grounded and model.elevation == 0,"Ramp exit lands on water"): return
	model.reset()
	model.position = Vector2(18,0)
	model.tick(.5,Vector2.RIGHT,true)
	if not require(model.grounded and model.surface == "ramp" and absf(model.elevation-.4) < .0001,"Jump lands on rising ramp"): return
	model.tick(.25,Vector2.LEFT,false)
	if not require(model.grounded and absf(model.elevation-.2) < .0001,"Ramp descent follows surface continuously"): return
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
		if not require(model.dead and absf(model.position.x-12.9) < .0001 and absf(model.clock-.225) < .0001,
			"Swept death position/time must be FPS independent"): return
	model.reset()
	if not require(not model.dead and model.clock == 0 and model.position == Model.LAYOUT.start,
		"Reset clears death and fractional time"): return
	print("PASS: surface support, rounded swept hole, jump, ramp contact/exit, death freeze and FPS-independent world replay")
	quit()
