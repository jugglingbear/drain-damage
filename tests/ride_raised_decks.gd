extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Fixtures = preload("res://tests/ride_showcase_physics.gd")

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func setup(x := 300.0, art_id := "basin_deck_360") -> Array:
	var host := Fixtures.Host.new()
	root.add_child(host)
	var model := Model.new()
	model.definition = {"encounters":[{"id":"raised","obstacles":[{"id":"deck","kind":"deck",
		"x":x,"y":330,"width":330,"depth":160,"art_id":art_id,"landing_material":"metal"}]}]}
	model.begin(host)
	model.scroll_speed = 0
	return [host,model]

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var pair := setup(300,"cleanout_deck_330")
	var host = pair[0]
	var model = pair[1]
	if not require(model.deck_support(Vector2(300,330),0).height == 12,"Cap center is raised12"): return
	if not require(model.deck_support(Vector2(465,410),0).height == 0,"Empty ellipse corner stays at water above submerged surround"): return
	model.course.obstacles[0].art_id = "basin_deck_360"
	if not require(model.deck_support(Vector2(465,410),0).height == 12,"Basin has rectangular raised top"): return
	model.course.obstacles[0].surface_height = 20
	if not require(model.deck_support(Vector2(300,330),0).height == 20,"Explicit physical surface height is authoritative"): return
	host.free()
	pair = setup()
	host = pair[0]; model = pair[1]
	model.tick(host,Model.STEP,Vector2.ZERO,false)
	var ceiling := {"kind":"overhead","bottom_z":84}
	if not require(not model._vertical_spans("overhead",ceiling,-1,.01,Vector2(0,1),72).is_empty(),
		"Raised standing height contributes to ceiling contact"): return
	model._launch()
	var high_ceiling := {"kind":"overhead","bottom_z":132}
	var spans: Array = model._vertical_spans("overhead",high_ceiling,0,.6,Vector2(0,1),72)
	if not require(not spans.is_empty() and absf(spans[0].x-1.0/3) < .00001 and absf(spans[0].y-2.0/3) < .00001,
		"Raised jump hazard intervals use absolute height"): return
	host.free()
	for hz in [30,60,120,144]:
		pair = setup()
		host = pair[0]; model = pair[1]
		model.tick(host,Model.STEP,Vector2.ZERO,false)
		if not require(model.render_height == 12 and model.jump_age < 0,"Standing board contacts top without renderer offset"): return
		for frame in range(hz*3/10): model.tick(host,1.0/hz,Vector2.ZERO,frame == 0)
		#144Hz does not have an exact .3 frame; compare the actual analytic clock.
		if not require(absf(model.render_height-(12+360*model.jump_age-600*model.jump_age*model.jump_age)) < .001,
			"Raised takeoff preserves54px relative jump arc"): return
		while model.jump_age >= 0: model.tick(host,1.0/hz,Vector2.ZERO,false)
		if not require(model.render_height == 12 and model.events.landed == 1,
			"Descending hop lands on raised top exactly once"): return
		if not require(absf(model.last_event.clock-(Model.STEP+.6)) < .00001,"Same-height raised hop lasts.6 seconds"): return
		model.tick(host,1.0,Vector2.RIGHT,false)
		if not require(model.render_height == 0 and model.jump_age < 0 and model.events.landed == 2,
			"Leaving deck falls physically back to water"): return
		host.free()
		pair = setup(500)
		host = pair[0]; model = pair[1]
		model.position.x = 200
		for frame in range(hz): model.tick(host,1.0/hz,Vector2.RIGHT,frame == 0)
		var expected := (360+sqrt(360*360-2400*12))/1200
		if not require(model.events.get("landed",0) == 1 and absf(model.last_event.clock-expected) < .00002,
			"Jump from water hits raised top on descending crossing before water plane"): return
		if not require(model.render_height == 12 and host.life_state == "alive","Raised destination remains supported"): return
		host.free()
	print("PASS: mixed ellipse/rect deck heights, real standing contact, raised takeoff/landing, water drop and FPS timing")
	quit()
