extends SceneTree
## Input-driven showcase routes, multipart rests and authored-geometry exploit checks.
const Model = preload("res://scripts/ride_showcase_model.gd")

class Host extends Node2D:
	var employee := {"id":"sean"}
	var difficulty := "normal"
	var health := 5
	var lives := 3
	var invulnerable := 0.0
	var paused := false
	var life_state := "alive"
	var won := false
	func hurt_player() -> void:
		if invulnerable > 0 or life_state != "alive": return
		health -= 1
		invulnerable = 1.5
		if health <= 0:
			lives -= 1
			life_state = "dead"

func _initialize() -> void:
	call_deferred("checks")

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func lower_margin(record: Dictionary, key: String, value: float) -> void:
	record[key] = minf(float(record.get(key,INF)),value)

func measure_margin(model: RefCounted, record: Dictionary, start: Vector2, old_age: float,
		old_clock: float, landed_before: int, pressed: bool, dt: float) -> void:
	if model.phase != "encounter": return
	var finish: Vector2 = model.position+Vector2(model.encounter_scroll,0)
	for obstacle: Dictionary in model.course.obstacles:
		if obstacle.kind not in ["support","overhead","low_barrier"]: continue
		var left := float(obstacle.x)-float(obstacle.width)*0.5-45
		var right := float(obstacle.x)+float(obstacle.width)*0.5+45
		var enter := maxf(0,(left-start.x)/(finish.x-start.x))
		var leave := minf(1,(right-start.x)/(finish.x-start.x))
		if enter > leave: continue
		if obstacle.kind == "low_barrier":
			var age := 0.0 if pressed else old_age
			for fraction in [enter,leave]:
				var u: float = (age+fraction*dt)/0.6
				var z: float = 216*u*(1-u) if age >= 0 and u <= 1 else 0
				lower_margin(record,"vertical_clearance",z-float(obstacle.clearance))
		else:
			var y0 := lerpf(start.y,finish.y,enter)
			var y1 := lerpf(start.y,finish.y,leave)
			var amplitude := float(obstacle.get("motion",{}).get("amplitude",0))
			var low := float(obstacle.y)-float(obstacle.depth)*0.5-amplitude
			var high := float(obstacle.y)+float(obstacle.depth)*0.5+amplitude
			lower_margin(record,"bank_clearance",maxf(low-maxf(y0,y1)-14,minf(y0,y1)-14-high))
	if int(model.events.get("landed",0)) > landed_before and model.last_event.event == "landed":
		var fraction := clampf((float(model.last_event.clock)-old_clock)/dt,0,1)
		var land := start.lerp(finish,fraction)
		var best_x := -INF
		var best_y := -INF
		for deck: Dictionary in model.course.obstacles:
			if deck.kind != "deck": continue
			var x_margin := float(deck.width)*0.5-absf(land.x-float(deck.x))-45
			var y_margin := float(deck.depth)*0.5-absf(land.y-float(deck.y))-14
			if x_margin >= 0 and y_margin >= 0:
				best_x = maxf(best_x,x_margin)
				best_y = maxf(best_y,y_margin)
		if best_x >= 0:
			lower_margin(record,"landing_x_clearance",best_x)
			lower_margin(record,"landing_y_clearance",best_y)

func checks() -> void:
	var passed := 0
	for hero in ["tony","sean"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					var host := Host.new()
					host.employee.id = hero
					host.difficulty = mode
					var model := Model.new()
					model.begin(host)
					model.position.x = anchor
					var stage := -1
					var next_jump := 0
					var rest_start := -1.0
					var rest_count := 0
					var margins := {}
					for frame in range(180*hz):
						if model.complete: break
						var dt: float = 1.0/hz
						var target := 330.0
						var jump := false
						if model.encounter_index != stage:
							if stage >= 0:
								if not require(rest_start >= 0 and float(model.last_event.clock)-rest_start >= 3.0-0.000001,
									"Next encounter started before full3s rest"): return
							stage = model.encounter_index
							next_jump = 0
							rest_start = -1
						if model.phase == "encounter":
							var route: Dictionary = model.encounter.witness
							var next_x: float = model.position.x+model.encounter_scroll+model.scroll_speed*dt
							for waypoint: Dictionary in route.bank_targets:
								if next_x >= float(waypoint.at_world_x): target = float(waypoint.target_y)
							if next_jump < route.jump_press_world_x.size() and next_x >= float(route.jump_press_world_x[next_jump]):
								jump = true
								next_jump += 1
						var steering := Vector2(0,clampf((target-model.position.y)/(model.bank_speed*dt),-1,1))
						var before: Vector2 = model.position+Vector2(model.encounter_scroll,0)
						var before_age: float = model.jump_age
						var before_clock: float = model.clock
						var landed_before: int = model.events.get("landed",0)
						model.tick(host,dt,steering,jump)
						if not margins.has(str(stage+1)): margins[str(stage+1)] = {}
						if model.encounter_index == stage and model.clock > before_clock:
							measure_margin(model,margins[str(stage+1)],before,before_age,before_clock,landed_before,jump,dt)
						if not require(host.health == 5 and host.lives == 3 and host.life_state == "alive",
							"Route hit %s/%s/x%s/%sHz encounter%s scroll%s last%s" %
							[hero,mode,anchor,hz,model.encounter_index+1,model.encounter_scroll,model.last_event]): return
						if model.phase == "rest":
							if rest_start < 0:
								rest_start = float(model.last_event.clock)
								rest_count += 1
							if not require(model.course.obstacles.is_empty() and model.jump_age < 0 and not model.ramp_active
								and model.recovery_clock <= 0 and model.contact_latches.is_empty(),"Rest contains active hazard/state"): return
					if not require(model.complete and host.won and rest_count == 10 and model.events.get("jump",0) == 6
						and model.events.get("ramp",0) == 1,"Showcase did not finish10 encounters/10rests/6hops/1boost"): return
					if not require(float(model.last_event.clock)-rest_start >= 3.0-0.000001,"Final rest shorter than3s"): return
					for record: Dictionary in margins.values():
						for value in record.values():
							if not require(float(value) > 0,"Nonpositive measured route clearance"): return
					print("MARGINS ",JSON.stringify({"hero":hero,"mode":mode,"anchor":anchor,"hz":hz,"encounters":margins}))
					print("PASS SHOWCASE ",hero," ",mode," x",anchor," hz",hz," seconds",snappedf(model.clock,0.001))
					passed += 1
					host.free()
	print("PASS: ",passed," complete showcase routes;540 encounter traversals, full3s rests and no damage")
	quit()
