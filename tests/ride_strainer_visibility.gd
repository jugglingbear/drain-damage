extends SceneTree
## Actual assembly bounds and normal wrapper entry paths, not warning-text timing.
const Game = preload("res://scripts/integrated_first_call.gd")
const Strainer = preload("res://scripts/ride_ceiling_strainer.gd")
const VIEW := Rect2(0,0,960,540)
var minimum_visible_lead := INF
var checked_poses := 0

func inspect_pose(ride: RefCounted, obstacle: Dictionary, age: float) -> void:
	var manifest: Dictionary = ride.obstacle_art.manifest
	var point := Vector2(float(obstacle.x)-560*age,float(obstacle.y))
	var assembly: Dictionary = Strainer.assembly(manifest,point,float(obstacle.depth),age)
	for part: Dictionary in assembly.parts:
		assert(part.id == manifest.strainer_parts.basket,"Only the falling basket warns the rider")
		var bounds: Rect2 = ride.frame_bounds(manifest.frames[part.id],part.transform)
		assert(is_equal_approx(bounds.get_center().x,point.x),"Basket moved away from committed footprint")
		if is_equal_approx(age,3.10):
			assert(VIEW.intersects(bounds),"Impact is outside the screen")
			assert(is_equal_approx(bounds.end.y,point.y+obstacle.depth*.5))
	checked_poses += 1

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var cases := 0
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			game.seed_override = 42
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.begin_level_two()
			var ride = game.flush.ride
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					for entry in [[11,11],[12,12],[10,11],[11,12]]:
						game.health = 5
						game.lives = 3
						game.life_state = "alive"
						game.invulnerable = 0
						game.flush.enter_ride(game,int(entry[0]))
						ride.position.x = anchor
						var jumped := false
						var recognition_seconds := 0.0
						var saw_target := false
						for frame in range(20*hz):
							var dt: float = 1.0/hz
							if ride.encounter_index == int(entry[1]):
								saw_target = true
								var age: float = ride.encounter_clock
								if age >= 1.0: inspect_pose(ride,ride.encounter.obstacles[0],age)
								if age < 3.10:
									var parts: Array = ride.hazard_assembly(ride.encounter.obstacles[0]).parts
									if not parts.is_empty():
										var basket: Dictionary = parts[0]
										var bounds: Rect2 = ride.frame_bounds(ride.obstacle_art.manifest.frames[basket.id],basket.transform)
										if VIEW.intersects(bounds): recognition_seconds += dt
								if age >= 3.40: break
							var next_x: float = ride.position.x+ride.encounter_scroll+560*dt
							var jump: bool = ride.encounter_index == 10 and not jumped and next_x >= 2312
							if jump: jumped = true
							var target := 330.0 if ride.encounter_index == 10 else 270.0
							var steering := Vector2(0,clampf((target-ride.position.y)/(350*dt),-1,1))
							ride.tick(game,dt,steering,jump)
							assert(game.life_state == "alive" and game.health == 5)
							assert(ride.phase != "rest")
						assert(saw_target and recognition_seconds > 0,"Basket must be visible before impact")
						minimum_visible_lead = minf(minimum_visible_lead,recognition_seconds)
						inspect_pose(ride,ride.encounter.obstacles[0],3.10)
						cases += 1
			game.queue_free()
			await process_frame
	print("PASS: ",cases," strainer direct/zero-rest entry cases; ",checked_poses,
		" actual assembly poses, full-size visible recognition and impact; minimum visible lead seconds ",minimum_visible_lead)
	quit()
