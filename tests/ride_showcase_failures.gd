extends SceneTree
## Failure controls use authored geometry; safe-route coverage lives in ride_showcase_course.gd.
const Model = preload("res://scripts/ride_showcase_model.gd")
const Course = preload("res://tests/ride_showcase_course.gd")

func _initialize() -> void: call_deferred("checks")

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func setup(hero: String, anchor: float, index: int, y: float) -> Array:
	var host := Course.Host.new()
	host.employee.id = hero
	host.health = 100
	var model := Model.new()
	model.begin(host,index)
	model.position = Vector2(anchor,y)
	return [host,model]

func verify_fall_and_retry(host: Node2D, model: RefCounted, index: int, dt: float) -> bool:
	if not require(host.life_state == "dead" and host.lives == 2 and host.health == 0
		and model.events.get("fall",0) == 1 and model.events.get("recovered",0) == 0,
		"Unsupported pit must cause exactly one normal death without recovery"): return false
	for frame in range(120): model.tick(host,dt,Vector2.RIGHT,true)
	if not require(host.lives == 2 and model.events.get("fall",0) == 1,
		"Dead rider was charged a second life"): return false
	if not require(model.checkpoint_index == index,"Fall changed encounter checkpoint"): return false
	host.health = 5
	host.life_state = "alive"
	host.invulnerable = 0
	model.begin(host,model.checkpoint_index)
	model.tick(host,dt,Vector2.ZERO,false)
	return require(model.encounter_index == index and model.phase == "encounter"
		and host.lives == 2 and host.health == 5 and host.life_state == "alive",
		"Retry failed to restart safely at the same encounter")

func checks() -> void:
	var failures_checked := 0
	for hero in ["tony","sean"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					var dt: float = 1.0/hz
					# Every concept punishes its careless approach; unsupported gaps cost one life.
					for index in range(9):
						var y := 285.0 if index == 5 else 280.0 if index == 7 else 330.0
						var pair := setup(hero,anchor,index,y)
						var host = pair[0]
						host.difficulty = mode
						host.invulnerable = 0.75 if index in [6,7] else 0.0
						var model = pair[1]
						for frame in range(20*hz):
							if model.phase != "encounter" or host.life_state != "alive": break
							model.tick(host,dt,Vector2.ZERO,false)
						if index in [6,7]:
							if not verify_fall_and_retry(host,model,index,dt): return
						else:
							if not require(host.health < 100 and host.lives == 3,
								"Careless solid route bypassed encounter%s" % [index+1]): return
							if index in [1,2,4,5,8]:
								if not require(host.health == 99,"Single traversal must debit exactly 1HP"): return
						failures_checked += 1
						host.free()
					# The near and far edges cannot bypass the bank-connected slalom either.
					for y in [260.0,400.0]:
						var pair := setup(hero,anchor,0,y)
						var host = pair[0]
						host.difficulty = mode
						host.invulnerable = 0.0
						var model = pair[1]
						for frame in range(20*hz):
							if model.phase != "encounter" or host.life_state != "alive": break
							model.tick(host,dt,Vector2.ZERO,false)
						if not require(host.health < 100,"Straight slalom bank-edge bypass"): return
						failures_checked += 1
						host.free()
					# A center inside a platform is insufficient when the board overhangs its bank edge.
					for index in [6,7]:
						var pair := setup(hero,anchor,index,260 if index == 6 else 330)
						var host = pair[0]
						host.difficulty = mode
						host.invulnerable = 0.75 if index in [6,7] else 0.0
						var model = pair[1]
						model.encounter_scroll = 2600-anchor
						model.encounter_clock = model.encounter_scroll/560.0
						model.tick(host,dt,Vector2.ZERO,false)
						if not verify_fall_and_retry(host,model,index,dt): return
						failures_checked += 1
						host.free()
					# Best-speed normal hop launched before ramp entry cannot cross the540px pit.
					var pair := setup(hero,anchor,9,330)
					var host = pair[0]
					host.difficulty = mode
					host.invulnerable = 0.75
					var model = pair[1]
					model.encounter_scroll = 2300-anchor
					model.encounter_clock = model.encounter_scroll/560.0
					for frame in range(3*hz):
						if host.life_state != "alive": break
						model.tick(host,dt,Vector2.RIGHT,frame == 0)
					if not require(host.life_state == "dead" and host.lives == 2 and model.events.get("ramp",0) == 0
						and model.events.get("fall",0) == 1,"Ordinary hop bypassed mandatory ramp or fatal pit"): return
					if not verify_fall_and_retry(host,model,9,dt): return
					failures_checked += 1
					host.free()
	# Narrow ramp requires full bank support: even a 1px overhang must not earn a boost.
	for hero in ["tony","sean"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					for y in [260.0,293.0,367.0,400.0]:
						var pair := setup(hero,anchor,9,y)
						var host = pair[0]
						host.difficulty = mode
						var model = pair[1]
						var dt: float = 1.0/hz
						for frame in range(10*hz):
							if host.life_state != "alive": break
							model.tick(host,dt,Vector2.ZERO,false)
						if not require(model.events.get("ramp",0) == 0 and model.position.y == y,
							"Misaligned board earned boost or snapped onto ramp"): return
						if not verify_fall_and_retry(host,model,9,dt): return
						failures_checked += 1
						host.free()
	# Rest cannot begin while a late jump persists after the last multipart shape clears.
	var pair := setup("tony",300,0,330)
	var host = pair[0]
	var model = pair[1]
	model.encounter_scroll = float(model.encounter.end_x)+45-180-1
	model.encounter_clock = model.encounter_scroll/560.0
	model.tick(host,1.0/120,Vector2.ZERO,true)
	if not require(model.phase == "encounter" and model.jump_age >= 0,"Rest skipped lingering jump"): return
	model.tick(host,0.7,Vector2.ZERO,false)
	if not require(model.phase == "rest" and model.course.obstacles.is_empty(),"Rest failed after lingering state cleared"): return
	host.free()
	# Expanded intervals cover every possible constant bank coordinate, not only three examples.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride-showcase.json"))
	for y in range(260,401):
		var blocked := false
		for obstacle: Dictionary in data.encounters[0].obstacles:
			blocked = blocked or absf(y-float(obstacle.y)) <= float(obstacle.depth)*0.5+14
		if not require(blocked,"Uncovered straight slalom lane"): return
	if not require(540+90 > (560+400)*0.6,"Ordinary jump can clear long pit"): return
	print("PASS: ",failures_checked," authored failure/exploit cases;all10 concepts,both heads,all3 modes,3anchors,3frame rates;141 straight slalom lanes blocked;lingering rest checked")
	quit()
