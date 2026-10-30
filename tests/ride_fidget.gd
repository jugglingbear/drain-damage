extends SceneTree
const Fidget = preload("res://scripts/ride_fidget.gd")
const Model = preload("res://scripts/ride_showcase_model.gd")

func _initialize() -> void: call_deferred("checks")

func model_for(obstacles: Array = []) -> RefCounted:
	var model := Model.new()
	model.course = {"obstacles":obstacles}
	model.position = Vector2(300,330)
	return model

func advance(model: RefCounted, delta: float) -> void:
	model.clock += delta
	model.encounter_clock += delta
	model.encounter_scroll += delta*model.scroll_speed

func checks() -> void:
	var model := model_for()
	var fidget := Fidget.new()
	var before := [model.position,model.jump_age,model.render_height,model.events.duplicate()]
	assert(fidget.step(model,true,.01).triggered)
	assert(before == [model.position,model.jump_age,model.render_height,model.events],"Cosmetic effect cannot mutate physics")
	var effect: Dictionary = fidget.effects[0]
	assert(effect.material == "water" and effect.vertices.size() == effect.uv.size())
	assert(effect.vertices[0] == Vector3(195,0,323.75))
	assert(effect.vertices[-2] == Vector3(255,0,336.25))
	assert(effect.uv[0] == Vector2.ZERO and effect.uv[-2] == Vector2.ONE)
	for hz in [30,60,120,144]:
		fidget.reset()
		var count := 0
		for frame in range(hz*3):
			advance(model,1.0/hz)
			if fidget.step(model,true,1.0/hz).triggered: count += 1
		assert(count == 1 and fidget.effects.is_empty(),"Held fire never repeats; effects expire")
	fidget.reset()
	assert(fidget.step(model,true,0).triggered)
	fidget.step(model,false,.25)
	assert(not fidget.step(model,true,.23).triggered,"Cooldown blocks rising edge before0.5s")
	fidget.step(model,false,.02)
	assert(fidget.step(model,true,0).triggered)
	var age: float = fidget.effects[0].age
	fidget.step(model,false,10,true,true)
	assert(fidget.effects[0].age == age,"Pause freezes effects and cooldown")
	fidget.step(model,true,10,true,true)
	assert(not fidget.step(model,true,1).triggered,"Pause input consumed without deferred fire")
	fidget.sync_input(true)
	assert(not fidget.step(model,true,1).triggered)
	fidget.step(model,false,0,true,false,false)
	assert(fidget.effects.is_empty(),"Death clears deposits")
	model.jump_age = .2
	model.render_height = 42
	assert(fidget.step(model,true,1).triggered)
	var cloud: Dictionary = fidget.effects[0]
	assert(cloud.material == "cloud" and cloud.release_height == 50)
	var release: Vector2 = cloud.center
	model.position += Vector2(120,30)
	advance(model,2)
	fidget.step(model,false,2)
	assert(cloud.center == release and cloud.height > 50 and cloud.height <= 75)
	assert(fidget.effects.size() == 1,"Cloud survives until renderer confirms offscreen")
	fidget.retire_cloud(cloud.id)
	assert(fidget.effects.is_empty())
	fidget.sync_input(true)
	model.jump_age = -1
	assert(not fidget.step(model,true,1).triggered,"Landing with fire held cannot deposit")
	fidget.reset()
	assert(not fidget.step(model,true,1,false).triggered,"Non-ride phases cannot emit")
	assert(not fidget.step(model,true,1).triggered,"Held fire does not carry from flush into ride")
	fidget.reset()
	assert(fidget.step(model,true,0).triggered)
	model.clock = 0
	assert(not fidget.step(model,true,0).triggered and fidget.effects.is_empty(),"Retry clock clears stale effects")
	var deck := {"id":"deck","kind":"deck","x":300,"y":330,"width":160,"depth":80,"surface_height":12,"landing_material":"porcelain"}
	model = model_for([deck])
	model.ground_height = 12
	fidget.reset()
	assert(fidget.step(model,true,0).triggered)
	for vertex: Vector3 in fidget.effects[0].vertices:
		assert(vertex.x >= 220 and vertex.y == 12,"Clip streak at raised deck edge")
	assert(fidget.effects[0].material == "porcelain")
	assert(fidget.effects[0].lifetime == Fidget.DRY_LIFETIME)
	fidget.step(model,false,2.6)
	assert(fidget.effects.size() == 1 and fidget.effects[0].alpha < 1)
	fidget.step(model,false,.91)
	assert(fidget.effects.is_empty(),"Dry stain expires after3.5s")
	deck.surface_shape = "ellipse"
	model.position.y = 363
	fidget.reset()
	fidget.step(model,true,0)
	for item in fidget.effects:
		for vertex: Vector3 in item.vertices:
			assert(pow((vertex.x-300)/80,2)+pow((vertex.z-330)/40,2) <= 1.000001)
	var ramp := {"id":"ramp","kind":"ramp","x":200,"y":330,"width":200,"depth":80,"rise":40}
	model = model_for([ramp])
	model.ramp_active = true
	model.active_ramp = ramp
	fidget.reset()
	assert(fidget.step(model,true,0).triggered)
	for vertex: Vector3 in fidget.effects[0].vertices:
		assert(absf(vertex.y-40*pow((vertex.x-100)/200,2)) < .00001)
	for normal: Vector3 in fidget.effects[0].normals: assert(normal.x < 0 and normal.y > 0)
	model.position.x = 310
	fidget.reset()
	assert(not fidget.step(model,true,0).triggered,"No extension beyond ramp lip")
	var hole := {"id":"hole","kind":"gap","x":225,"y":330,"width":1,"depth":100,"activates_at":.2}
	model = model_for([hole])
	fidget.reset()
	assert(fidget.step(model,true,0).triggered)
	var old_count: int = fidget.effects[0].indices.size()
	advance(model,.3)
	fidget.step(model,false,.3)
	assert(fidget.effects[0].indices.size() < old_count,"Timed fracture removes affected cells immediately")
	for index in range(0,fidget.effects[0].vertices.size(),4):
		var a: Vector3 = fidget.effects[0].vertices[index]
		var b: Vector3 = fidget.effects[0].vertices[index+1]
		assert(b.x < 224.5 or a.x > 225.5,"No cell bridges even a narrow internal hole")
	model = model_for([{"id":"hole","kind":"gap","x":300,"y":330,"width":300,"depth":200}])
	fidget.reset()
	assert(not fidget.step(model,true,0).triggered)
	deck = {"id":"moving","kind":"deck","x":300,"y":330,"width":400,"depth":100,"surface_height":20,
		"motion":{"axis":"y","amplitude":10,"period":2,"phase":0}}
	model = model_for([deck])
	model.ground_height = 20
	fidget.reset()
	assert(fidget.step(model,true,0).triggered)
	var original: Vector3 = fidget.effects[0].vertices[0]
	advance(model,.5)
	fidget.step(model,false,.5)
	assert(fidget.effects[0].vertices[0].is_equal_approx(original+Vector3(0,0,10)),"Deposit follows moving support")
	model = model_for()
	fidget.reset()
	for frame in range(200):
		advance(model,.1)
		fidget.step(model,frame%11 == 0,.1)
		assert(fidget.effects.size() <= Fidget.MAX_EFFECTS)
	fidget.reset()
	assert(fidget.step(model,true,0).triggered)
	fidget.step(model,false,.7)
	assert(fidget.effects.size() == 1 and fidget.effects[0].alpha < 1)
	assert(fidget.effects[0].lifetime == Fidget.WATER_LIFETIME)
	fidget.step(model,false,3)
	assert(fidget.effects.is_empty())
	print("PASS: fidget input edges/cooldown, pause/death/retry/airborne guards, finite lifetime, exact deck/ramp poses and pit clipping")
	quit()
