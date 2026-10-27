extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Fixture = preload("res://tests/ride_showcase_physics.gd")

func _initialize() -> void: call_deferred("checks")

func gap(x := 2600.0, activation := 2.90) -> Dictionary:
	return {"id":"hand-pit","kind":"gap","x":x,"y":330,"width":140,"depth":200,"activates_at":activation}

func setup(obstacle: Dictionary) -> Array:
	var host := Fixture.Host.new()
	var model := Model.new()
	model.definition = {"encounters":[{"id":"hand","obstacles":[obstacle]}]}
	model.begin(host)
	return [host,model]

func checks() -> void:
	# Activation inside a simulation step is exact: intact floor first, one fatal fall at impact.
	var pair := setup(gap(300,.005))
	var host = pair[0]
	var model = pair[1]
	model.tick(host,.004,Vector2.ZERO,false)
	assert(host.health == 5 and host.life_state == "alive")
	model.tick(host,.01,Vector2.ZERO,false)
	assert(host.life_state == "dead" and host.lives == 2 and model.events.fall == 1)
	assert(absf(model.clock-.005) < .000001)
	host.free()
	# Moving completely off the future hole before impact cannot trigger a deferred hit.
	pair = setup(gap(300,1.0))
	host = pair[0]; model = pair[1]
	model.tick(host,1.1,Vector2.ZERO,false)
	assert(host.health == 5 and host.lives == 3)
	host.free()
	var cases := 0
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180,300,650]:
				for hz in [30,60,120]:
					for bank in [260,330,400]:
						for should_jump in [false,true]:
							pair = setup(gap())
							host = pair[0]; model = pair[1]
							host.employee.id = hero
							host.difficulty = mode
							model.position = Vector2(anchor,bank)
							var jumped := false
							for frame in range(12*hz):
								if model.phase != "encounter" or host.life_state != "alive": break
								var dt: float = 1.0/hz
								var jump: bool = should_jump and not jumped and model.position.x+model.encounter_scroll+560*dt >= 2432
								model.tick(host,dt,Vector2.ZERO,jump)
								jumped = jumped or jump
							if should_jump:
								assert(host.health == 5 and host.lives == 3 and model.phase == "rest")
								assert(model.events.jump == 1 and model.events.landed == 1)
							else:
								assert(host.life_state == "dead" and host.lives == 2 and model.events.fall == 1)
							cases += 1
							host.free()
	# Rightward and diagonal travel use the real clamp-aware distance, not an assumed960px/s at x650.
	for anchor in [180.0,300.0,650.0]:
		for direction in [Vector2.RIGHT,Vector2(1,1)]:
			pair = setup(gap())
			host = pair[0]; model = pair[1]
			var displacement := minf(.6*400*direction.normalized().x,650-anchor)
			var takeoff := 2600-(336+displacement)*.5
			model.position = Vector2(anchor,330)
			model.encounter_scroll = takeoff-anchor
			model.encounter_clock = model.encounter_scroll/560
			model.clock = model.encounter_clock
			model.tick(host,.6,direction,true)
			assert(host.health == 5 and model.events.landed == 1)
			assert(model.position.x+model.encounter_scroll-45 > 2670)
			host.free()
	# Holding left from the forward anchor shortens the hop; no automatic speed lock rescues it.
	pair = setup(gap())
	host = pair[0]; model = pair[1]
	model.position = Vector2(650,330)
	model.encounter_scroll = 2432-650
	model.encounter_clock = model.encounter_scroll/560
	model.tick(host,1,Vector2.LEFT,true)
	assert(host.life_state == "dead" and host.lives == 2)
	host.free()
	# A floor breaking beneath an already airborne rider does not collide until unsupported landing.
	pair = setup(gap(300,.1))
	host = pair[0]; model = pair[1]
	model.scroll_speed = 0
	model.tick(host,.2,Vector2.ZERO,true)
	assert(host.health == 5 and model.jump_height > 0)
	model.tick(host,.5,Vector2.ZERO,false)
	assert(host.life_state == "dead" and host.lives == 2)
	host.free()
	print("PASS: dynamic pit exact activation, no pre-impact/deferred damage,",cases," jump-required routes across heroes/modes/anchors/fps/banks")
	quit()
