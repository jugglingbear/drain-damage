extends SceneTree
const Debris = preload("res://scripts/devil_spider_debris.gd")
class Model extends RefCounted:
	var position := Vector2(200,20)
	var direction := 1.0
class Host extends Node:
	const FLOOR_Y := 440.0
	var paused := false
	var solids: Array[Rect2] = []
	func actor_solids() -> Array[Rect2]: return solids
var checks_run := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("checks")

func check(ok: bool, message: String) -> void:
	checks_run += 1
	if not ok:
		failures.append(message)
		push_error(message)

func manifest() -> Dictionary:
	return {"anchor":[64,12],"head_release_seconds":0.5,"head_props":[
		{"id":"left","release_socket":[44,92],"contact_anchor":[8,16],"velocity":[-36,0]},
		{"id":"middle","release_socket":[64,92],"contact_anchor":[8,16],"velocity":[0,0]},
		{"id":"right","release_socket":[84,92],"contact_anchor":[8,16],"velocity":[36,0]}]}

func checks() -> void:
	var positions: Array = []
	for hz in [30,60,120,144]:
		var host := Host.new()
		var model := Model.new()
		var actor := {"devil":model}
		var debris = Debris.new()
		check(debris.begin(actor,manifest()),"First lethal notification creates corpse")
		check(not debris.begin(actor,manifest()) and debris.deaths.size() == 1,"Duplicate death is idempotent")
		model.position = Vector2(999,999)
		actor.clear()
		check(debris.deaths[0].origin == Vector2(200,20),"Corpse snapshots survive actor mutation/removal")
		for tick in range(hz/2): debris.step(host,1.0/hz)
		check(debris.props.size() == 3,"Exactly three heads at authored break time")
		check(debris.props[0].pos.is_equal_approx(Vector2(180,100)),"Release socket matches source anchor")
		var before: Array = debris.props.duplicate(true)
		host.paused = true
		debris.step(host,40)
		check(debris.props == before and is_equal_approx(debris.deaths[0].age,0.5),"Pause freezes every timeline")
		host.paused = false
		for tick in range(hz*3): debris.step(host,1.0/hz)
		for prop in debris.props:
			check(prop.landed and is_equal_approx(prop.pos.y,430),"Head settles on floor")
		positions.append(debris.props.map(func(p: Dictionary) -> Vector2: return p.pos))
		before = debris.props.duplicate(true)
		debris.step(host,20)
		check(debris.props.size() == 3 and debris.deaths.size() == 1,"No finite TTL removes heads or ash corpse")
		for i in range(3):
			check(debris.props[i].pos == before[i].pos and debris.props[i].angle == before[i].angle,
				"Settled props stay at rest")
		debris.reset()
		debris.reset()
		check(debris.props.is_empty() and debris.deaths.is_empty(),"Retry/title reset clears all")
		host.free()
	for result in positions:
		for i in range(3): check(result[i].distance_to(positions[0][i]) < 0.001,"Frame-rate independent resting points")
	var host := Host.new()
	host.solids = [Rect2(100,220,200,2)]
	var model := Model.new()
	model.direction = -1
	var debris = Debris.new()
	debris.begin({"devil":model},manifest())
	debris.step(host,0.5)
	check(debris.props[0].pos == Vector2(220,100) and debris.props[0].velocity.x == 36,"Mirrored release and velocity")
	debris.step(host,3)
	for prop in debris.props: check(prop.landed and is_equal_approx(prop.pos.y,210),"Thin solid catches swept heads")
	debris.reset()
	var fast := manifest()
	for head in fast.head_props: head.velocity = [0,100000]
	debris.begin({"devil":model},fast)
	debris.step(host,1)
	for prop in debris.props: check(prop.landed and is_equal_approx(prop.pos.y,210),"Fast fall cannot tunnel platform")
	debris.reset()
	host.solids = [Rect2(240,0,2,440)]
	debris.begin({"devil":model},manifest())
	debris.step(host,3)
	for prop in debris.props: check(prop.pos.x <= 231.001,"Wall stops full head footprint")
	debris.reset()
	host.solids.clear()
	var authored: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/bestiary/devil-spider-v1/death-manifest-v2.json"))
	model.direction = 1
	debris.begin({"devil":model},authored)
	debris.step(host,0.4)
	check(debris.props.size() == 3,"Authored manifest releases exactly three heads at .4 seconds")
	check(debris.props[0].pos.is_equal_approx(Vector2(197,47.5)),"Authored logical socket is not scaled twice")
	debris.step(host,0.4)
	check(debris.props.size() == 4 and debris.props[3].kind == "ash","Authored ash releases once at .8 seconds")
	check(debris.props[3].pos.is_equal_approx(Vector2(206,83.75)),"Ash uses center-origin socket")
	debris.step(host,3)
	check(debris.props[3].landed and is_equal_approx(debris.props[3].pos.y,412),"Ash settles using authored bottom contact")
	check(debris.props.size() == 4,"No repeated head or ash release")
	host.free()
	print("Devil spider debris: %d checks, %d failures" % [checks_run,failures.size()])
	quit(0 if failures.is_empty() else 1)
