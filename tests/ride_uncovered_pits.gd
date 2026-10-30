extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Fixtures = preload("res://tests/ride_showcase_physics.gd")

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func obstacle(id: String, kind: String, rect: Rect2) -> Dictionary:
	return {"id":id,"kind":kind,"x":rect.get_center().x,"y":rect.get_center().y,
		"width":rect.size.x,"depth":rect.size.y}

func setup(decks: Array[Rect2], kind := "gap") -> Array:
	var host := Fixtures.Host.new()
	root.add_child(host)
	var model := Model.new()
	var obstacles: Array = [obstacle("pit",kind,Rect2(0,230,800,200))]
	for index in range(decks.size()): obstacles.append(obstacle(str(index),"deck",decks[index]))
	model.definition = {"encounters":[{"id":"union-test","obstacles":obstacles}]}
	model.begin(host)
	model.scroll_speed = 0
	return [host,model]

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var pit := Rect2(0,230,800,200)
	var point := Vector2(300,330)
	for kind in ["gap","long_pit"]:
		for width in [44.1,32.4,31.5,30.6]:
			var decks: Array[Rect2] = [Rect2(255,316,width,28)]
			if not require(absf(Model.uncovered_fraction(point,pit,decks)-(1-width/90)) < .000001,"Exact uncovered area"): return
			for landing in [false,true]:
				var pair := setup(decks,kind)
				var host = pair[0]
				var model = pair[1]
				if landing: model.jump_age = .599
				model.tick(host,.002,Vector2.ZERO,false)
				if not require((host.life_state == "dead") == (width <= 31.5),"Ground and landing use actual65% opening"): return
				host.free()
	var split: Array[Rect2] = [Rect2(255,316,22.05,28),Rect2(322.95,316,22.05,28)]
	var pair := setup(split)
	pair[1].tick(pair[0],.01,Vector2.ZERO,false)
	if not require(pair[0].life_state == "alive" and absf(Model.uncovered_fraction(point,pit,split)-.51) < .000001,
		"Two neighboring tops combine support even when neither supports half"): return
	pair[0].free()
	var duplicate: Array[Rect2] = [Rect2(255,316,20,28),Rect2(255,316,20,28)]
	if not require(absf(Model.uncovered_fraction(point,pit,duplicate)-70.0/90) < .000001,
		"Overlapping decks must not double count support"): return
	var corner: Array[Rect2] = [Rect2(255,316,45,14)]
	if not require(absf(Model.uncovered_fraction(point,pit,corner)-.75) < .000001,"Corner support uses area"): return
	var banks: Array[Rect2] = [Rect2(0,230,285,200),Rect2(375,230,425,200)]
	pair = setup(banks)
	var spans: Array = pair[1].uncovered_spans(pair[1].course.obstacles[0],Vector2(250,330),Vector2(450,330),0,1)
	if not require(not spans.is_empty() and absf(spans[0].x-(298.5-250)/200) < .00001,
		"Swept threshold must detect lethal interior with both endpoints supported"): return
	pair[0].free()
	var islands: Array[Rect2] = [Rect2(0,230,285,200),Rect2(365,230,70,200),Rect2(515,230,285,200)]
	pair = setup(islands)
	spans = pair[1].uncovered_spans(pair[1].course.obstacles[0],Vector2(250,330),Vector2(550,330),0,1)
	var found_first := false
	var found_second := false
	for span: Vector2 in spans:
		if span.x <= .25 and span.y >= .25: found_first = true
		if span.x <= .75 and span.y >= .75: found_second = true
		if not require(not (span.x <= .5 and span.y >= .5),"Supported middle island splits lethal intervals"): return
	if not require(found_first and found_second,"A sweep must retain both disconnected lethal openings"): return
	pair[0].free()
	# Compare the polynomial sweep with direct area samples on corner-crossing diagonal paths.
	var crossed: Array[Rect2] = [Rect2(250,300,80,30),Rect2(300,325,90,35),Rect2(400,290,45,80)]
	pair = setup(crossed)
	for bank in [270.0,310.0,350.0,390.0]:
		var start := Vector2(200,bank)
		var finish := Vector2(500,660-bank)
		spans = pair[1].uncovered_spans(pair[1].course.obstacles[0],start,finish,0,1)
		for sample in range(101):
			var fraction := sample/100.0
			var area := Model.uncovered_fraction(start.lerp(finish,fraction),pit,crossed)
			if absf(area-.65) < .00001: continue
			var lethal := false
			for span: Vector2 in spans: lethal = lethal or (fraction >= span.x and fraction <= span.y)
			if not require(lethal == (area >= .65),"Swept area polynomial disagrees with direct diagonal union area"): return
	pair[0].free()
	for hz in [30,60,120,144]:
		pair = setup(banks)
		pair[1].position.x = 250
		for frame in range(hz):
			pair[1].tick(pair[0],1.0/hz,Vector2.RIGHT,false)
			if pair[0].life_state == "dead": break
		if not require(pair[0].life_state == "dead" and absf(pair[1].position.x-298.5) < .001
			and absf(pair[1].clock-.12125) < .00001,"Swept union threshold and death time are FPS independent"): return
		pair[0].free()
		pair = setup(banks)
		pair[1].position.x = 250
		for frame in range(hz): pair[1].tick(pair[0],1.0/hz,Vector2.RIGHT,frame == 0)
		if not require(pair[0].life_state == "alive","Jump clears uncovered opening at every frame rate"): return
		pair[0].free()
	print("PASS: true65% uncovered pit, union/duplicate/corner tops, swept safe endpoints, grounded/landing/jump and FPS invariance")
	quit()
