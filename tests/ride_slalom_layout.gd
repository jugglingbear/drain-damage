extends SceneTree
## Actual trajectories complement geometric coverage; survival is not a clean bypass.
const Model = preload("res://scripts/ride_showcase_model.gd")
const Course = preload("res://tests/ride_showcase_course.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride-showcase.json"))
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/ride-showcase-v1/manifest.json"))
	for obstacle: Dictionary in data.encounters[0].obstacles:
		var matched := 0
		for layer: Dictionary in art.frames[obstacle.art_id].layers:
			if not layer.get("collision_plane",false): continue
			assert(layer.destination == [-float(obstacle.width)/2,-float(obstacle.depth)/2,
				float(obstacle.width),float(obstacle.depth)])
			matched += 1
		assert(matched == 1,"Each visible top must match exactly one collision footprint")
	var total := 0
	for hero in ["tony","sean"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for y in range(260,401):
					for hopping in [false,true]:
						var host := Course.Host.new()
						host.employee.id = hero
						host.difficulty = mode
						host.health = 100
						var model := Model.new()
						model.begin(host)
						model.position = Vector2(anchor,y)
						for frame in range(15*60):
							if model.encounter_index != 0 or model.complete: break
							model.tick(host,1.0/60,Vector2.ZERO,hopping and model.jump_age < 0 and model.cooldown <= 0)
						assert(model.encounter_index == 1)
						assert(host.health < 100 and model.events.get("hit",0) > 0,
							"Clean straight/jump bypass: %s %s x%s y%s jump%s" % [hero,mode,anchor,y,hopping])
						assert(host.lives == 3)
						host.free()
						total += 1
	var safe_routes := 0
	for hero in ["tony","sean"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					for timing_offset in [-0.05,0.0,0.05]:
						var host := Course.Host.new()
						host.employee.id = hero
						host.difficulty = mode
						var model := Model.new()
						model.begin(host)
						model.position.x = anchor
						for frame in range(15*hz):
							if model.encounter_index != 0 or model.complete: break
							var target := 330.0
							var dt: float = 1.0/hz
							var next_x: float = model.position.x+model.encounter_scroll+560*dt
							for waypoint: Dictionary in model.encounter.witness.bank_targets:
								if next_x >= float(waypoint.at_world_x)+timing_offset*560: target = waypoint.target_y
							model.tick(host,dt,Vector2(0,clampf((target-model.position.y)/(350*dt),-1,1)),false)
						assert(model.encounter_index == 1 and host.health == 5 and model.events.get("hit",0) == 0,
							"Weave failed timing offset%s Hz%s" % [timing_offset,hz])
						host.free()
						safe_routes += 1
	print("PASS: ",safe_routes," safe weave routes including +/-50ms input offsets at30/60/120Hz")
	print("PASS: ",total," actual slalom straight/jump routes; all141 integer lanes, both heroes, all modes, three anchors")
	quit()
