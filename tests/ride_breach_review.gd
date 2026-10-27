extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Fixture = preload("res://tests/ride_showcase_physics.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var cases := 0
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180,300,650]:
				for bank in [260.0,270.0,285.99,286.0,286.01,330.0,400.0]:
					var host := Fixture.Host.new()
					host.employee.id = hero
					host.difficulty = mode
					var model := Model.new()
					model.begin(host,1)
					model.position = Vector2(anchor,bank)
					for frame in range(1200):
						if model.encounter_index != 1 or host.life_state != "alive": break
						model.tick(host,1.0/60,Vector2.ZERO,false)
					if bank < 286:
						assert(host.health == 5 and host.lives == 3 and model.encounter_index == 2)
					else:
						assert(host.life_state == "dead" and host.lives == 2 and model.events.fall == 1)
						model.tick(host,1,Vector2.RIGHT,true)
						assert(host.lives == 2)
					cases += 1
					host.free()
	# A pipe collision consumes one HP; the following pit still kills through fresh impact immunity.
	var host := Fixture.Host.new()
	var model := Model.new()
	model.begin(host,1)
	model.position = Vector2(300,375)
	while model.events.get("hit",0) == 0: model.tick(host,.005,Vector2.ZERO,false)
	assert(host.health == 4 and host.lives == 3 and host.life_state == "alive" and host.invulnerable > 0)
	while host.life_state == "alive": model.tick(host,.005,Vector2.ZERO,false)
	assert(model.events.fall == 1 and host.lives == 2)
	host.free()
	# Granting an ideal takeoff after the pipe still cannot jump the700px unsupported footprint.
	for takeoff in range(2275,2476,20):
		host = Fixture.Host.new()
		model = Model.new()
		model.begin(host,1)
		model.position = Vector2(180,300)
		model.encounter_scroll = takeoff-180
		model.tick(host,.001,Vector2.RIGHT,true)
		model.tick(host,2,Vector2.RIGHT,false)
		assert(host.life_state == "dead" and host.lives == 2)
		host.free()
	print("PASS: ",cases," breach bank-boundary routes, nonlethal pipe then fatal immune pit,11 fastest jump bypass attempts")
	quit()
