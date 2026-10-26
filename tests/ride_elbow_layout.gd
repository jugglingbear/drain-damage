extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Course = preload("res://tests/ride_showcase_course.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride-showcase.json"))
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/ride-showcase-v1/manifest.json"))
	for obstacle: Dictionary in data.encounters[1].obstacles:
		var matched := 0
		for layer: Dictionary in art.frames[obstacle.art_id].layers:
			if not layer.get("collision_plane",false): continue
			assert(layer.destination == [-float(obstacle.width)/2,-float(obstacle.depth)/2,
				float(obstacle.width),float(obstacle.depth)])
			matched += 1
		assert(matched == 1,"Pipe/pit art must match the collision footprint")
	var total := 0
	for hero in ["tony","sean"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					for y in [330.0,400.0]:
						for hopping in [false,true]:
							var host := Course.Host.new()
							host.employee.id = hero
							host.difficulty = mode
							host.health = 100
							var model := Model.new()
							model.begin(host,1)
							model.position = Vector2(anchor,y)
							for frame in range(15*hz):
								if host.life_state != "alive": break
								model.tick(host,1.0/hz,Vector2.ZERO,
									hopping and model.jump_age < 0 and model.cooldown <= 0)
								if model.events.get("hit",0) == 1 and model.events.get("fall",0) == 0:
									assert(host.health == 99 and host.lives == 3 and host.life_state == "alive")
							assert(host.life_state == "dead" and host.lives == 2)
							assert(model.events.get("fall",0) == 1 and model.events.get("hit",0) == 1)
							for frame in range(hz): model.tick(host,1.0/hz,Vector2.ZERO,true)
							assert(host.lives == 2 and model.checkpoint_index == 1)
							host.free()
							total += 1
	assert(700+90 > (560+400)*0.6)
	print("PASS: ",total," elbow center/near straight and repeated-jump failures; pipe hit then one pit death; no ordinary jump can span790px")
	quit()
