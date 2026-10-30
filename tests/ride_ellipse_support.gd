extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Fixtures = preload("res://tests/ride_showcase_physics.gd")

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func sampled_uncovered(point: Vector2, tops: Array) -> float:
	var uncovered := 0
	for x in range(160):
		for y in range(80):
			var sample := point+Vector2((x+.5)/160*90-45,(y+.5)/80*28-14)
			var supported := false
			for top: Dictionary in tops:
				var rect: Rect2 = top.rect
				if top.shape == "ellipse": supported = supported or ((sample-rect.get_center())/(rect.size*.5)).length_squared() <= 1
				else: supported = supported or rect.has_point(sample)
			if not supported: uncovered += 1
	return uncovered/12800.0

func setup() -> Array:
	var host := Fixtures.Host.new()
	root.add_child(host)
	var model := Model.new()
	model.definition = {"encounters":[{"id":"ellipse-test","obstacles":[
		{"id":"pit","kind":"gap","x":500,"y":330,"width":1000,"depth":200},
		{"id":"cap-a","kind":"deck","x":300,"y":330,"width":330,"depth":160,"art_id":"cleanout_deck_330"},
		{"id":"cap-b","kind":"deck","x":750,"y":330,"width":330,"depth":160,"art_id":"cleanout_deck_330"}]}]}
	model.begin(host)
	model.scroll_speed = 0
	return [host,model]

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var pit := Rect2(0,230,1000,200)
	var cap := {"shape":"ellipse","rect":Rect2(135,250,330,160)}
	var base: Array = [cap]
	if not require(Model.uncovered_shape_bounds(Vector2(465,410),pit,base).x > .999,
		"Square cap corner must be actual opening with no phantom mount"): return
	if not require(Model.uncovered_shape_bounds(Vector2(300,330),pit,base).y < .00001,"Cap center fully supports board"): return
	var combinations: Array = [base,[cap,cap],
		[cap,{"shape":"ellipse","rect":Rect2(235,260,330,160)}],
		[cap,{"shape":"rect","rect":Rect2(390,300,50,40)}]]
	for tops: Array in combinations:
		for point in [Vector2(450,330),Vector2(420,390),Vector2(465,410),Vector2(476,330)]:
			var bounds := Model.uncovered_shape_bounds(point,pit,tops)
			var reference := sampled_uncovered(point,tops)
			if not require(bounds.x <= reference+.002 and bounds.y >= reference-.002 and bounds.y-bounds.x < .00015,
				"Ellipse/rectangle union disagrees with independent grid area"): return
	var pair := setup()
	var model = pair[1]
	var began := Time.get_ticks_usec()
	var spans: Array = model.uncovered_spans(model.course.obstacles[0],Vector2(300,330),Vector2(750,330),0,1)
	var has_middle := false
	for span: Vector2 in spans: has_middle = has_middle or (span.x <= .5 and span.y >= .5)
	if not require(has_middle,"Curved swept opening must be found between safe endpoint caps"): return
	print("ELLIPSE long_sweep_us=",Time.get_ticks_usec()-began)
	began = Time.get_ticks_usec()
	model.uncovered_spans(model.course.obstacles[0],Vector2(474,330),Vector2(482,330),0,Model.STEP)
	print("ELLIPSE boundary_step_us=",Time.get_ticks_usec()-began)
	pair[0].free()
	for landing in [false,true]:
		pair = setup()
		model = pair[1]
		model.position = Vector2(455,400)
		if landing: model.jump_age = .599
		model.tick(pair[0],.01,Vector2.ZERO,false)
		if not require(pair[0].life_state == "dead" and pair[0].lives == 2,
			"Cap rectangular corner cannot save a grounded or landing rider"): return
		pair[0].free()
	var reference_x := -1.0
	for hz in [30,60,120,144]:
		pair = setup()
		var host = pair[0]
		model = pair[1]
		model.position.x = 400
		for frame in range(hz):
			model.tick(host,1.0/hz,Vector2.RIGHT,false)
			if host.life_state == "dead": break
		if reference_x < 0: reference_x = model.position.x
		if not require(host.life_state == "dead" and absf(model.position.x-reference_x) < .01,
			"Curved fall threshold must be FPS independent"): return
		var bounds := Model.uncovered_shape_bounds(model.position,pit,base)
		if not require(bounds.x >= .6499 and bounds.y < .651,"Curved fall must occur at65%, never at a rim touch"): return
		host.free()
		pair = setup()
		host = pair[0]; model = pair[1]
		model.position.x = 400
		for frame in range(hz): model.tick(host,1.0/hz,Vector2.RIGHT,frame == 0)
		if not require(host.life_state == "alive","Raised cap jump must clear true curved opening"): return
		host.free()
	print("PASS: actual ellipse support, empty corners, mixed/overlapping union, swept65%, raised jump and FPS")
	quit()
