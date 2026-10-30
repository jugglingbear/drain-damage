extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Course = preload("res://tests/ride_showcase_course.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var safe := 0
	var missed := 0
	for hero in ["tony","sean"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					for air_input in [Vector2.ZERO,Vector2.RIGHT,Vector2(1,1)]:
						for offset in [-0.05,0.0,0.05]:
							var host := Course.Host.new()
							host.employee.id = hero
							host.difficulty = mode
							var model := Model.new()
							model.begin(host,10)
							model.position.x = anchor
							var dt: float = 1.0/hz
							var travel: float = 336+minf(400*air_input.normalized().x*0.6,650-anchor)
							var trigger: float = 2480-travel*0.5+offset*560
							var pressed := false
							for frame in range(15*hz):
								if model.encounter_index != 10 or model.complete: break
								var jump: bool = not pressed and model.position.x+model.encounter_scroll+560*dt >= trigger
								if jump:
									assert(model.encounter_clock >= 1.25+1.5,"Jump has at least1.5 seconds of warning")
									pressed = true
								model.tick(host,dt,air_input if jump or model.jump_age >= 0 else Vector2.ZERO,jump)
								if model.encounter_index == 10 and model.encounter_clock < 3.05:
									assert(model.position.x+model.encounter_scroll+45 < 2480-70,
										"Board cannot reach the hand footprint before physical clearance")
							assert(model.encounter_index == 11 and host.health == 5 and host.lives == 3)
							assert(model.events.get("jump",0) == 1 and model.events.get("fall",0) == 0)
							host.free()
							safe += 1
					for bank in [260.0,330.0,400.0]:
						var host := Course.Host.new()
						host.employee.id = hero
						host.difficulty = mode
						host.health = 100
						var model := Model.new()
						model.begin(host,10)
						model.position = Vector2(anchor,bank)
						for frame in range(15*hz):
							model.tick(host,1.0/hz,Vector2.ZERO,false)
						assert(host.life_state == "dead" and host.lives == 2 and model.events.get("fall",0) == 1)
						host.health = 5
						host.life_state = "alive"
						model.begin(host,model.checkpoint_index)
						assert(model.encounter_index == 10 and model.encounter_clock == 0 and host.lives == 2)
						host.free()
						missed += 1
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride-showcase.json"))
	var hole: Dictionary = data.encounters[10].obstacles[0]
	assert(hole.width == 140 and hole.depth == 200 and hole.y == 330)
	for bank in range(260,401): assert(absf(bank-float(hole.y)) <= float(hole.depth)/2+14)
	print("PASS: ",safe," hand jumps neutral/right/diagonal with +/-50ms offsets; ",missed,
		" no-jump deaths and checkpoint resets; all141 bank coordinates intersect full-channel hole")
	quit()
