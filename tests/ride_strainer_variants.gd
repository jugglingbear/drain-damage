extends SceneTree
## Full forward trajectory and actual footprint overlap, with a reachable positive control.
const Model = preload("res://scripts/ride_showcase_model.gd")
const Host = preload("res://tests/ride_showcase_course.gd").Host
var failures: Array[String] = []

func _initialize() -> void:
	check_patterns()
	check_short_full_width()
	var results := []
	for width in [520.0,568.0,640.0]:
		var passes := 0
		var cases := 0
		for hero in ["tony","sean"]:
			for hz in [30,60,120]:
				for anchor in [180.0,300.0,410.0,650.0]:
					for trigger in range(-30,21,2):
						var host := Host.new()
						host.employee.id = hero
						var model := Model.new()
						model.definition = {"encounters":[{"id":"reach","obstacles":[
							{"id":"pit","kind":"gap","x":2000+width/2,"y":330,"width":width,"depth":200}],
							"rest_after_seconds":0}]}
						model.begin(host)
						model.position = Vector2(anchor,330)
						model.encounter_scroll = 1980-anchor
						var pressed := false
						for frame in range(2*hz):
							var dt: float = 1.0/hz
							var x: float = model.position.x+model.encounter_scroll
							var next: float = model.encounter_scroll+560*dt+minf(650,model.position.x+Model.steer_axis(
								model.steering_velocity.x,1,model.x_speed,dt).x)
							var jump: bool = not pressed and next >= 2000+trigger
							if jump: pressed = true
							model.tick(host,dt,Vector2.RIGHT,jump)
							if host.life_state != "alive" or model.complete: break
							if x > 2000+width+50: break
						if host.life_state == "alive" and model.position.x+model.encounter_scroll > 2000+width: passes += 1
						cases += 1
						host.free()
		results.append({"width":width,"cases":cases,"successful_forward_jumps":passes})
		if width >= 568 and passes != 0: failures.append("Long opening can be jumped")
		if width == 520 and passes == 0: failures.append("Positive reach control failed")
	print(JSON.stringify({"reach":results,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func check_patterns() -> void:
	for mode in ["easy","normal","hard"]:
		for seed_value in 64:
			var host := preload("res://tests/ride_continuous_course.gd").SeededHost.new()
			host.difficulty = mode
			host.run_seed = seed_value
			var model := Model.new()
			model.continuous = true
			model.begin(host)
			var before := JSON.stringify(model.course.obstacles)
			var station_count := 0
			for gap: Dictionary in model.course.obstacles:
				if not gap.get("station",false): continue
				station_count += 1
				var leading_edge := float(gap.x)-float(gap.width)*0.5
				var base_phase := (leading_edge-2540)/560
				var first_contact := (leading_edge-45-650)/560
				if absf(float(gap.timeline_origin)-base_phase) > 0.120001:
					failures.append("Phase jitter exceeds reviewed bound")
				if first_contact-(base_phase+0.12+1.25) < 1.5 or base_phase+0.12+3.1 > first_contact:
					failures.append("Worst-phase warning or activation is too late")
				if float(gap.width) > 567 and float(gap.depth) >= 200:
					failures.append("Long full-width opening has no alternate support")
				if float(gap.depth) >= 200: continue
				var safe_centers := 0
				for bank in range(260,401):
					var body := Rect2(Vector2(float(gap.x)-45,bank-14),Vector2(90,28))
					var safe := true
					for obstacle: Dictionary in model.course.obstacles:
						if obstacle.kind not in ["gap","support"]: continue
						# Require the entire footprint outside every concurrent pit/solid, stronger than65%.
						if body.intersects(model.obstacle_rect(obstacle)): safe = false
					if safe: safe_centers += 1
				if safe_centers < 20: failures.append("Insufficient full-body dodge corridor: "+str(gap.id))
			if station_count != 12: failures.append("Expected six stations in each wave")
			for retry in [1,2]:
				model.begin(host,retry)
				if JSON.stringify(model.course.obstacles) != before: failures.append("Retry reshuffled pattern")
				if model.jump_age >= 0 or model.cooldown > 0: failures.append("Retry is not grounded/jump-ready")
			host.free()

func check_short_full_width() -> void:
	for hero in ["tony","sean"]:
		for hz in [30,60,120]:
			for bank in [260.0,330.0,400.0]:
				for jumping in [false,true]:
					var host := Host.new()
					host.employee.id = hero
					var model := Model.new()
					model.definition = {"encounters":[{"id":"short-full","obstacles":[
						{"id":"pit","kind":"gap","x":2000,"y":330,"width":140,"depth":200}],
						"rest_after_seconds":0}]}
					model.begin(host)
					model.position = Vector2(300,bank)
					model.encounter_scroll = 1500
					var pressed := false
					for frame in range(2*hz):
						var dt: float = 1.0/hz
						var jump: bool = jumping and not pressed and model.position.x+model.encounter_scroll+560*dt >= 1850
						if jump: pressed = true
						model.tick(host,dt,Vector2.ZERO,jump)
						if host.life_state != "alive" or model.complete: break
					if jumping != (host.life_state == "alive"):
						failures.append("Short full-width opening must require and permit jumping")
					host.free()
