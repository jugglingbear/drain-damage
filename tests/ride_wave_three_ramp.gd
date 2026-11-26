extends SceneTree
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
	func hurt_player(_fatal_fall := false) -> void:
		if invulnerable > 0 or life_state != "alive": return
		health -= 1
		invulnerable = 1.5
		if health <= 0:
			lives -= 1
			life_state = "dead"

static func bank_input(model: RefCounted, target: float, dt: float) -> float:
	var speed := float(model.steering_velocity.y)
	var stopping: float = speed*absf(speed)*float(model.steering_config.steering.coast_seconds)/(2*model.bank_speed)
	return clampf((target-float(model.position.y)-stopping)/(model.bank_speed*maxf(dt,0.06)),-1,1)

static func predicted_world_x(model: RefCounted, steering: Vector2, dt: float) -> float:
	var input := steering.limit_length()
	var horizontal := Model.steer_axis(model.steering_velocity.x,input.x,model.x_speed,dt)
	return model.encounter_scroll+model.scroll_speed*dt+clampf(model.position.x+horizontal.x,180,650)

var failures: Array = []
var cases := 0

func _initialize() -> void: call_deferred("checks")

func run_case(hero: String, mode: String, anchor: float, hz: int, bank: float, delay := 0.0) -> void:
	var host := Host.new()
	host.employee.id = hero
	host.difficulty = mode
	var model := Model.new()
	model.continuous = true
	model.wave_three = true
	model.begin(host)
	model.position.x = anchor
	var launch_clock := -1.0
	var landed_fully := false
	for frame in hz*10:
		if model.events.has("ramp") and launch_clock < 0: launch_clock = model.clock
		var target := bank if launch_clock >= 0 and model.clock-launch_clock >= delay else 330.0
		var before_land: int = model.events.get("landed",0)
		var was_boosted: bool = model.boosted
		model.tick(host,1.0/hz,Vector2(0,bank_input(model,target,1.0/hz)),false)
		if was_boosted and model.events.get("landed",0) > before_land:
			var catch: Dictionary = model.course.obstacles[-1]
			landed_fully = absf(model.position.x+model.encounter_scroll-float(catch.x))+55 <= float(catch.width)*0.5 \
				and absf(model.position.y-float(catch.y))+14 <= float(catch.depth)*0.5
		if host.health < 5 or model.complete: break
	var correct := bank in [270.0,299.0]
	if (correct and (not model.complete or (bank == 270.0 and not landed_fully) or host.health != 5 or model.events.get("ramp",0) != 1)) \
		or (not correct and host.health == 5):
		failures.append({"hero":hero,"mode":mode,"anchor":anchor,"hz":hz,"bank":bank,"delay":delay,"event":model.last_event})
	cases += 1
	host.free()

func check_bypass(bank: float, jump_x: float, horizontal: float, hz: int) -> void:
	var host := Host.new()
	var model := Model.new()
	model.continuous = true
	model.wave_three = true
	model.begin(host)
	model.position = Vector2(300,bank)
	var pressed := false
	for frame in hz*10:
		var steering := Vector2(horizontal,0)
		var jump := not pressed and predicted_world_x(model,steering,1.0/hz) >= jump_x
		if jump: pressed = true
		model.tick(host,1.0/hz,steering,jump)
		if host.health < 5 or model.complete: break
	if model.complete and model.events.get("ramp",0) == 0:
		failures.append({"reason":"ordinary jump bypass","bank":bank,"jump_x":jump_x,"input":horizontal,"hz":hz})
	cases += 1
	host.free()

func checks() -> void:
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for anchor in [180.0,300.0,650.0]:
				for hz in [30,60,120]:
					for bank in [270.0,299.0,330.0,390.0]: run_case(hero,mode,anchor,hz,bank)
					for delay in [0.15,0.3]: run_case(hero,mode,anchor,hz,270,delay)
	for hz in [30,60,120]:
		for bank in [270.0,300.0,305.0,330.0,355.0,360.0,390.0]:
			for jump_x in range(1800,2751,50):
				for horizontal in [-1.0,0.0,1.0]: check_bypass(bank,jump_x,horizontal,hz)
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
