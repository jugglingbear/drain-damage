extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Fixture = preload("res://tests/ride_showcase_physics.gd")

func _initialize() -> void: call_deferred("checks")

func setup() -> Array:
	var host := Fixture.Host.new()
	var model := Model.new()
	model.definition = {"rest":{"duration":0},"encounters":[
		{"id":"first","rest_after_seconds":0,"obstacles":[
			{"id":"last","kind":"support","x":200,"y":100,"width":20,"depth":20}]},
		{"id":"next","rest_after_seconds":0,"obstacles":[
			{"id":"next-hazard","kind":"support","x":2600,"y":100,"width":20,"depth":20}]}]}
	model.begin(host)
	return [host,model]

func checks() -> void:
	var cases := 0
	for hero in ["sean","tony"]:
		for hz in [30,60,120]:
			for flight in ["normal","ballistic","cooldown"]:
				var pair := setup()
				var host = pair[0]
				var model = pair[1]
				host.employee.id = hero
				if flight == "normal": model._launch()
				elif flight == "ballistic":
					model.active_ramp = {"x":200,"width":200,"rise":40}
					model._launch(true)
				else: model.cooldown = .4
				var dt: float = 1.0/hz
				while model.encounter_index == 0:
					model.tick(host,dt,Vector2.ZERO,false)
					assert(model.events.get("rest_started",0) == 0)
				assert(model.phase == "encounter" and model.encounter_index == 1)
				# Last edge210 must pass leftmost board anchor135: exactly75/560 plus at most one substep.
				assert(model.encounter_started_at > 75.0/560)
				assert(model.encounter_started_at <= 75.0/560+Model.STEP+.000001)
				assert(model.events.encounter_started == 2)
				if flight == "cooldown":
					assert(absf(model.cooldown-(.4-model.clock)) < .00001)
				else:
					assert(absf(model.jump_age-model.clock) < .00001 and model.render_height > 0)
					assert(model.events.get("landed",0) == 0)
				model.tick(host,1.5,Vector2.ZERO,false)
				assert(host.health == 5 and model.encounter_index == 1)
				host.free()
				cases += 1
	# One jump edge in an outer tick crossing the boundary is accepted once and carried through.
	var pair := setup()
	var host = pair[0]
	var model = pair[1]
	model.tick(host,.2,Vector2.ZERO,true)
	assert(model.encounter_index == 1 and model.events.jump == 1 and absf(model.jump_age-.2) < .00001)
	assert(model.events.get("rest_started",0) == 0)
	host.free()
	# A still-overlapping physical hazard cannot disappear merely because no explicit rest remains.
	pair = setup()
	host = pair[0]; model = pair[1]
	model.course.obstacles[0].x = 500
	model.course.obstacles[0].y = 330
	model.course.obstacles[0].width = 400
	model.tick(host,.5,Vector2.ZERO,false)
	assert(model.encounter_index == 0 and host.health == 4 and not model.contact_latches.is_empty())
	model.tick(host,.6,Vector2.ZERO,false)
	assert(model.encounter_index == 1 and host.health == 4)
	host.free()
	print("PASS: ",cases," zero-rest normal/ballistic/cooldown carry cases, exact physical-clear cadence, single boundary edge and collision guard")
	quit()
