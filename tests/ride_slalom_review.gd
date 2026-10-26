extends SceneTree
## Independent held-horizontal/jump bypass review of the authored slalom.
const Model = preload("res://scripts/ride_showcase_model.gd")
const Fixture = preload("res://tests/ride_showcase_physics.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var template := Model.new()
	var fixture := Fixture.Host.new()
	template.begin(fixture)
	var encounter: Dictionary = template.definition.encounters[0]
	var banks: Array[float] = [260,280,330,380,390,400]
	for obstacle: Dictionary in encounter.obstacles:
		assert(obstacle.kind == "support", "Slalom structures must block at every jump height")
		for edge in [float(obstacle.y)-float(obstacle.depth)*.5-14,float(obstacle.y)+float(obstacle.depth)*.5+14]:
			for offset in [-.01,0.0,.01]:
				if edge+offset >= 260 and edge+offset <= 400: banks.append(edge+offset)
	fixture.free()
	var cases := 0
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180,300,650]:
				for bank in banks:
					for horizontal in [-1,1]:
						for jump in [false,true]:
							var host := Fixture.Host.new()
							host.employee.id = hero
							host.difficulty = mode
							var model := Model.new()
							model.definition = template.definition
							model.begin(host)
							model.position = Vector2(anchor,bank)
							for frame in range(1200):
								if model.phase != "encounter" or host.life_state != "alive": break
								model.tick(host,1.0/60,Vector2(horizontal,0),jump)
							assert(model.events.get("hit",0) > 0 and host.health < 5,
								"Held horizontal/jumping found a clean unsteered slalom route")
							assert(model.events.get("fall",0) == 0 and host.lives == 3,
								"Slalom impacts must retain normal damage, never pit death")
							assert(model.hit_ids.size() == model.events.hit,
								"Repeated traversal damage cannot masquerade as multiple blockers")
							cases += 1
							host.free()
	print("PASS: ",cases," slalom held-left/right and jump attempts at exact collision edges; actual damage, no clean bypass")
	quit()
