extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Course = preload("res://tests/ride_showcase_course.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride-showcase.json"))
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/ceiling-strainer-v1/manifest.json"))
	for index in [11,12]:
		var obstacle: Dictionary = data.encounters[index].obstacles[0]
		var expected := [-float(obstacle.width)/2,-float(obstacle.depth)/2,float(obstacle.width),float(obstacle.depth)]
		assert(art.collision_registration[obstacle.art_id].core == expected)
		assert(art.collision_registration[obstacle.art_id].activates_at == obstacle.activates_at)
		var matched := 0
		for layer: Dictionary in art.frames[obstacle.art_id].layers:
			if layer.get("collision_plane",false):
				assert(layer.destination == expected)
				matched += 1
		assert(matched == 1)
	var safe := 0
	var fatal := 0
	for hero in ["tony","sean"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					for index in [11,12]:
						var routes := [
							{"y":270.0,"jump":false,"safe":true},
							{"y":390.0,"jump":false,"safe":index == 11},
							{"y":330.0,"jump":false,"safe":false},
							{"y":285.9,"jump":false,"safe":true},
							{"y":286.0,"jump":false,"safe":false},
							{"y":330.0,"jump":true,"safe":true,"offset":-0.05},
							{"y":330.0,"jump":true,"safe":true,"offset":0.0},
							{"y":330.0,"jump":true,"safe":true,"offset":0.05}]
						for route: Dictionary in routes:
							var host := Course.Host.new()
							host.employee.id = hero
							host.difficulty = mode
							var model := Model.new()
							model.begin(host,index)
							model.position = Vector2(anchor,route.y)
							var pressed := false
							for frame in range(15*hz):
								if model.complete or model.encounter_index != index or host.life_state != "alive": break
								var jump: bool = route.jump and not pressed and model.position.x+model.encounter_scroll+560.0/hz >= 2432+float(route.get("offset",0))*560
								if jump:
									assert(model.encounter_clock >= 3.05,"Cage still occupies jump volume")
									pressed = true
								model.tick(host,1.0/hz,Vector2.ZERO,jump)
							if route.safe:
								assert(host.health == 5 and host.lives == 3 and (model.complete or model.encounter_index != index))
								safe += 1
							else:
								assert(host.life_state == "dead" and host.lives == 2 and model.events.get("fall",0) == 1)
								for frame in range(hz): model.tick(host,1.0/hz,Vector2.ZERO,true)
								assert(host.lives == 2)
								fatal += 1
							host.free()
	print("PASS: ",safe," strainer dodge/jump routes and ",fatal," fatal unsupported routes; both variants/heroes/modes/anchors/frame rates, +/-50ms jump offsets")
	quit()
