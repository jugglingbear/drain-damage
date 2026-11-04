extends SceneTree
## Exercise the trial's actual collision model without scene, art or combat substitutes.
const CONTRACT := "res://levels/first-call/three-screen-trial.json"
const MODEL := "res://scripts/three_screen_trial_level.gd"
const SIZE := Vector2(26,46)
var failures: Array[String] = []
var cases := 0

func _initialize() -> void: call_deferred("checks")

func check(condition: bool, message: String) -> void:
	cases += 1
	if not condition:
		failures.append(message)
		push_error(message)

func jump(level: RefCounted, start: Vector2, speed: float, hz: int, moving: bool,
		hold: float) -> Dictionary:
	var pos := start
	var velocity := Vector2(speed if moving else 0.0,-465)
	var released := false
	for tick in range(hz*2):
		if not released and float(tick)/hz >= hold:
			velocity.y = maxf(velocity.y,-170)
			released = true
		velocity.x = move_toward(velocity.x,speed,1900.0/hz)
		velocity.y += 1250.0/hz
		var result: Dictionary = level.move_body(pos,velocity,SIZE,1.0/hz)
		pos = result.pos
		velocity = result.velocity
		if result.get("falling",false) or result.grounded: return result
	return {"pos":pos,"grounded":false,"falling":false}

func checks() -> void:
	if not FileAccess.file_exists(MODEL):
		push_error("Pending Engineering trial collision model: "+MODEL)
		quit(1)
		return
	var level = load(MODEL).new()
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	check(level.configure(contract),"Contract configuration")
	for x in [2214.0,2230.9,2240.0,2343.1,2360.0]:
		var expected := maxf(0,minf(x+26,2360)-maxf(x,2240))/26
		check(is_equal_approx(level.pit_overlap_fraction(Rect2(Vector2(x,394),SIZE)),expected),"Footprint fraction")
	for speed in [235.0,270.0]:
		for hz in [30,60,120,144]:
			check_route(level,speed,hz)
			for moving in [false,true]:
				for start in [Vector2(1054,394),Vector2(1254,334)]:
					for hold in [0.15,0.2,1.0]:
						var landed := jump(level,start,speed,hz,moving,hold)
						check(landed.grounded and not landed.get("falling",false)
							and is_equal_approx(landed.pos.y,start.y-60),
							"60px climb: "+str([speed,hz,moving,hold,start,landed]))
				var crossing := jump(level,Vector2(2214,394),speed,hz,moving,1.0)
				check(crossing.grounded and not crossing.get("falling",false)
					and crossing.pos.x >= 2343.1 and is_equal_approx(crossing.pos.y,394),
					"Full-hold pit jump: "+str([speed,hz,moving,crossing]))
				var short_jump := jump(level,Vector2(2214,394),speed,hz,moving,0.0)
				check(short_jump.get("falling",false),"Released jump cannot clear introductory pit")
			# A rim touch and less than65% overlap must retain support.
			for x in [2214.0,2230.89,2343.11,2360.0]:
				var supported: Dictionary = level.move_body(Vector2(x,394),Vector2(0,10),SIZE,1.0/hz)
				check(supported.grounded and not supported.get("falling",false),"Safe rim "+str([x,hz,supported]))
			for x in [2230.91,2280.0,2343.09]:
				var fall: Dictionary = level.move_body(Vector2(x,394),Vector2(0,10),SIZE,1.0/hz)
				check(fall.get("falling",false) and not fall.grounded,"65% fall "+str([x,hz,fall]))
			var airborne: Dictionary = level.move_body(Vector2(2280,300),Vector2(0,10),SIZE,1.0/hz)
			check(not airborne.get("falling",false),"Airborne pit clearance")
			var landing: Dictionary = level.move_body(Vector2(2280,390),Vector2(0,600),SIZE,1.0/hz)
			check(landing.get("falling",false),"Landing inside pit must fall")
	# A long grounded sweep cannot tunnel across the opening to regain floor support.
	for direction in [-1.0,1.0]:
		var start := Vector2(2380 if direction < 0 else 2180,394)
		var swept: Dictionary = level.move_body(start,Vector2(direction*270,30),SIZE,1.0)
		check(swept.get("falling",false),"Swept pit crossing "+str(direction))
	# Optional route must allow walking beneath both supports.
	var under: Dictionary = level.move_body(Vector2(270,394),Vector2(270,0),SIZE,2.2)
	check(under.pos.x > 840 and under.grounded,"Optional catwalk blocks ground route")
	var blocked: Dictionary = level.move_body(Vector2(1040,394),Vector2(270,0),SIZE,.5)
	check(blocked.pos.x <= 1054.001,"Mandatory climb must block hold-right")
	print("PASS" if failures.is_empty() else "FAIL",": three-screen mechanics ",cases," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func check_route(level: RefCounted, speed: float, hz: int) -> void:
	var pos := Vector2(72,394)
	var velocity := Vector2.ZERO
	var grounded := true
	var summit := false
	var jumps := 0
	var fell := false
	for tick in range(20*hz):
		if grounded:
			var needs_jump := pos.x+26 >= 2210 and pos.x < 2240
			for solid: Rect2 in level.plinths:
				var distance := solid.position.x-(pos.x+26)
				if distance >= 0 and distance <= 30 and solid.position.y < pos.y+46:
					needs_jump = true
			if needs_jump:
				velocity.y = -465
				jumps += 1
		velocity.x = move_toward(velocity.x,speed,1900.0/hz)
		velocity.y += 1250.0/hz
		var result: Dictionary = level.move_body(pos,velocity,SIZE,1.0/hz)
		pos = result.pos
		velocity = result.velocity
		grounded = result.grounded
		summit = summit or (grounded and is_equal_approx(pos.y,274))
		fell = fell or result.falling
		if fell or pos.x >= 2770: break
	check(not fell and pos.x >= 2770 and summit and jumps >= 3,
		"Full grounded route/climb/pit: "+str([speed,hz,pos,summit,jumps,fell]))
