extends SceneTree
## Actual assembly bounds and normal wrapper entry paths, not warning-text timing.
const Game = preload("res://scripts/integrated_first_call.gd")
const Strainer = preload("res://scripts/ride_ceiling_strainer.gd")
const VIEW := Rect2(0,0,960,540)
const HERO_ENVELOPE := Rect2(125,122,580,292)
var minimum_hoist_gap := INF
var checked_poses := 0

func inspect_pose(ride: RefCounted, obstacle: Dictionary, age: float) -> void:
	var manifest: Dictionary = ride.obstacle_art.manifest
	var point := Vector2(float(obstacle.x)-560*age,float(obstacle.y))
	var assembly: Dictionary = Strainer.assembly(manifest,point,float(obstacle.depth),age)
	var found_full := false
	var found_rail := false
	for part: Dictionary in assembly.parts:
		if float(part.get("alpha",1)) <= 0: continue
		var bounds: Rect2 = ride.frame_bounds(manifest.frames[part.id],part.transform)
		assert(not bounds.intersects(HERO_ENVELOPE),"Strainer or mounting part crosses a possible hero/jump envelope")
		if part.id == "strainer_rail": found_rail = true
		if part.id == manifest.strainer_parts.basket:
			found_full = true
			if age >= 1.25 and age <= 3.10+0.000001:
				assert(VIEW.encloses(bounds),"Recognizable basket or impact is outside screen")
				assert(bounds.size.is_equal_approx(Vector2(140,92)))
				assert(float(part.get("alpha",1)) >= 0.9999,"Recognition uses faded or miniature substitute")
			if age >= 1.25 and age <= 2.15:
				assert(absf(bounds.get_center().x-800) < 0.001 and absf(bounds.end.y-210) < 0.001)
			if age >= 3.10 and bounds.end.y >= 122:
				minimum_hoist_gap = minf(minimum_hoist_gap,bounds.position.x-705)
		if part.id == manifest.strainer_parts.winch and age >= 1.25 and age <= 3.10:
			assert(VIEW.encloses(bounds),"Trolley leaves viewport before the visible slam")
	if age >= 1.25 and age < 3.10:
		assert(found_full and found_rail,"Actual basket and connected rail must be present")
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
			assert(ride.obstacle_art.manifest.frames.has("strainer_rail"))
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
								if age >= 1.25 and age < 2.15: recognition_seconds += dt
								if age >= 3.40: break
							var next_x: float = ride.position.x+ride.encounter_scroll+560*dt
							var jump: bool = ride.encounter_index == 10 and not jumped and next_x >= 2312
							if jump: jumped = true
							var target := 330.0 if ride.encounter_index == 10 else 270.0
							var steering := Vector2(0,clampf((target-ride.position.y)/(350*dt),-1,1))
							ride.tick(game,dt,steering,jump)
							assert(game.life_state == "alive" and game.health == 5)
							assert(ride.phase != "rest")
						assert(saw_target and recognition_seconds >= 0.9-1.1/hz)
						inspect_pose(ride,ride.encounter.obstacles[0],3.10)
						cases += 1
			game.queue_free()
			await process_frame
	assert(minimum_hoist_gap >= 14.0)
	print("PASS: ",cases," strainer direct/zero-rest entry cases; ",checked_poses,
		" actual assembly poses, full-size visible recognition and impact; minimum hoist gap ",minimum_hoist_gap)
	quit()
