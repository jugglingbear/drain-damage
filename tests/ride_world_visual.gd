extends SceneTree
## Manual visual fixture: real production renderer and authoritative encounter data, with time frozen.
const Game = preload("res://scripts/integrated_first_call.gd")
const Launch = preload("res://scripts/playtest_launch.gd")
var game: Node2D
var index := -1
var age := 3.6
var held := false
var live := false
var route_stage := -1
var next_jump := 0

func _initialize() -> void: call_deferred("setup")

func setup() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960,540)
	root.position = Vector2i(80,80)
	index = int(OS.get_environment("RIDE_AUDIT_INDEX")) if OS.has_environment("RIDE_AUDIT_INDEX") else -1
	age = float(OS.get_environment("RIDE_AUDIT_AGE")) if OS.has_environment("RIDE_AUDIT_AGE") else 3.7
	game = Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.flush.world_view.set_process(false)
	Launch.initialize(game,Launch.parse(["--level=2-landing"]).target)
	show_scene()

func show_scene() -> void:
	if index < 0:
		Launch.initialize(game,Launch.parse(["--level=2-landing"]).target)
	else:
		game.flush.enter_ride(game,index)
		route_stage = -1
		for frame in int(maxf(0,age)*120): advance_route(1.0/120)
	game.invulnerable = 0
	game.flush.world_view._process(0)
	game.queue_redraw()
	root.title = "Ride visual audit — %s — age %.2f — N/P scene, C angle, H hero, +/- time" % [index+1,age]

func _process(delta: float) -> bool:
	if game == null: return false
	if live and index >= 0:
		advance_route(minf(delta,1.0/30))
		game.flush.world_view.update_world()
		game.queue_redraw()
		if game.flush.ride.complete:
			print("PASS: visual live route complete; health=%s lives=%s" % [game.health,game.lives])
			live = false
	var keys := [KEY_N,KEY_P,KEY_C,KEY_H,KEY_EQUAL,KEY_MINUS,KEY_L]
	var down := false
	for key in keys: down = down or Input.is_physical_key_pressed(key)
	if down and not held:
		if Input.is_physical_key_pressed(KEY_L):
			live = not live
			if live:
				index = maxi(index,0)
				age = 0
				route_stage = -1
				show_scene()
			held = down
			return false
		if Input.is_physical_key_pressed(KEY_N): index = mini(12,index+1)
		if Input.is_physical_key_pressed(KEY_P): index = maxi(-1,index-1)
		if Input.is_physical_key_pressed(KEY_C): game.flush.world_view.yaw *= -1
		if Input.is_physical_key_pressed(KEY_H):
			game.employee = game.Crew.EMPLOYEES[0] if game.employee.id == "sean" else game.Crew.EMPLOYEES[1]
		if Input.is_physical_key_pressed(KEY_EQUAL): age += .1
		if Input.is_physical_key_pressed(KEY_MINUS): age -= .1
		show_scene()
	held = down
	return false

func advance_route(dt: float) -> void:
	var model = game.flush.ride
	if model.encounter_index != route_stage:
		route_stage = model.encounter_index
		next_jump = 0
	var target := 330.0
	var jump := false
	var route: Dictionary = model.encounter.witness
	var next_x: float = model.position.x+model.encounter_scroll+model.scroll_speed*dt
	for waypoint: Dictionary in route.bank_targets:
		if next_x >= float(waypoint.at_world_x): target = float(waypoint.target_y)
	if next_jump < route.jump_press_world_x.size() and next_x >= float(route.jump_press_world_x[next_jump]):
		jump = true
		next_jump += 1
	model.tick(game,dt,Vector2(0,clampf((target-model.position.y)/(model.bank_speed*dt),-1,1)),jump)
