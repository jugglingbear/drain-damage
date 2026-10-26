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

func checks() -> void:
	var failures_checked := 0
	for hero in ["tony","sean"]:
		for anchor in [180.0,300.0,650.0]:
			for hz in [30,60,120]:
				var dt: float = 1.0/hz
				# Every ordinary concept must punish its careless approach; several slalom pieces may hit.
				for index in range(9):
					var y := 285.0 if index == 5 else 280.0 if index == 7 else 330.0
					var pair := setup(hero,anchor,index,y)
					var host = pair[0]
					var model = pair[1]
					for frame in range(20*hz):
						if model.phase != "encounter": break
						model.tick(host,dt,Vector2.ZERO,false)
					if not require(host.health < 100 and host.lives == 3,
						"Careless route bypassed encounter%s %s x%s hz%s" % [index+1,hero,anchor,hz]): return
					if index in [1,2,4,5,6,7,8]:
						if not require(host.health == 99,"Single traversal must debit exactly1HP"): return
					if index in [6,7]:
						if not require(model.events.get("recovered",0) == 1,"Unsupported island/basin must recover once"): return
					failures_checked += 1
					host.free()
				# The near and far edges cannot bypass the bank-connected slalom either.
				for y in [260.0,400.0]:
					var pair := setup(hero,anchor,0,y)
					var host = pair[0]
					var model = pair[1]
					for frame in range(20*hz):
						if model.phase != "encounter": break
						model.tick(host,dt,Vector2.ZERO,false)
					if not require(host.health < 100,"Straight slalom bank-edge bypass"): return
					failures_checked += 1
					host.free()
				# A center inside a platform is insufficient when the board overhangs its bank edge.
				for index in [6,7]:
					var pair := setup(hero,anchor,index,260 if index == 6 else 330)
					var host = pair[0]
					var model = pair[1]
					model.encounter_scroll = 2600-anchor
					model.encounter_clock = model.encounter_scroll/560.0
					model.tick(host,dt,Vector2.ZERO,false)
					if not require(host.health == 99 and model.events.get("recovered",0) == 1,
						"Center-only platform support bypass"): return
					failures_checked += 1
					host.free()
				# Best-speed normal hop launched before ramp entry cannot cross the540px pit.
				var pair := setup(hero,anchor,9,330)
				var host = pair[0]
				var model = pair[1]
				model.encounter_scroll = 2300-anchor
				model.encounter_clock = model.encounter_scroll/560.0
				for frame in range(3*hz):
					if host.life_state != "alive": break
					model.tick(host,dt,Vector2.RIGHT,frame == 0)
				if not require(host.life_state == "dead" and host.lives == 2 and model.events.get("ramp",0) == 0
					and model.events.get("fall",0) == 1,"Ordinary hop bypassed mandatory ramp or fatal pit"): return
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
	print("PASS: ",failures_checked," authored failure/exploit cases;all10 concepts,both heads,3anchors,3frame rates;141 straight slalom lanes blocked;lingering rest checked")
	quit()
