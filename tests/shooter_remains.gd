extends SceneTree
const Remains = preload("res://scripts/shooter_remains.gd")
const Ceiling = preload("res://scripts/ceiling_shooter_art.gd")
class Host extends Node:
	const FLOOR_Y := 440.0
	var paused := false
	var ceiling_shooter_art := Ceiling.new()
	var solids: Array[Rect2] = [Rect2(0,440,1000,100)]
	func actor_solids() -> Array[Rect2]: return solids
	func role_scale(_role: String) -> float: return 1.0
	func ceiling_direction(_actor: Dictionary) -> Vector2: return Vector2(1,1).normalized()
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func actor(id: String, ceiling := false, point := Vector2(300,440)) -> Dictionary:
	return {"event_id":id,"feet":point,"facing":1,"mount":"ceiling" if ceiling else "floor"}
func run_checks() -> void:
	for hz in [30,60,120,144]:
		var host := Host.new()
		var remains := Remains.new()
		var source := actor("floor")
		remains.begin(host,source)
		remains.begin(host,source)
		check(remains.entries.size() == 1,"Duplicate defeat cannot duplicate wreck")
		source.feet = Vector2(999,999)
		check(remains.entries[0].origin == Vector2(300,440),"Death snapshots survive actor mutation")
		for tick in range(hz): remains.step(host,1.0/hz)
		check(remains.entries[0].frame == 5 and not remains.entries[0].falling,"Floor sequence settles")
		remains.step(host,60)
		check(remains.entries.size() == 1 and remains.entries[0].frame == 5,"Floor wreck has no TTL")
		remains.reset()
		host.solids.append(Rect2(200,300,200,16))
		remains.begin(host,actor("ceiling",true,Vector2(300,120)))
		var before: Array = remains.entries.duplicate(true)
		host.paused = true
		remains.step(host,5)
		check(remains.entries == before,"Pause freezes fall and timeline")
		host.paused = false
		for tick in range(hz*3): remains.step(host,1.0/hz)
		var entry: Dictionary = remains.entries[0]
		check(not entry.falling and not entry.lost and entry.origin.y == 300,"Ceiling lands on nearest actual platform")
		check(entry.mount == Vector2(300,120) and entry.frame == 5,"Mount stays attached and pile settles")
		remains.reset()
		host.solids = [Rect2(0,440,250,100),Rect2(350,440,650,100)]
		remains.begin(host,actor("pit",true,Vector2(300,120)))
		for tick in range(hz*4): remains.step(host,1.0/hz)
		check(remains.entries[0].lost and remains.entries[0].falling,"Pit creates no floating pile")
		remains.reset()
		host.solids = [Rect2(0,440,1000,100)]
		remains.begin(host,actor("fast",true,Vector2(300,120)))
		remains.entries[0].velocity = 100000
		remains.step(host,2.0/hz)
		check(not remains.entries[0].falling and remains.entries[0].origin.y == 440,"Swept fall cannot tunnel floor")
		remains.reset()
		host.solids = [Rect2(0,440,250,100),Rect2(350,440,650,100)]
		remains.begin(host,actor("unsupported"))
		remains.step(host,4)
		check(remains.entries[0].lost,"Unsupported floor death cannot leave a floating wreck")
		remains.reset()
		remains.reset()
		check(remains.entries.is_empty() and remains.seen.is_empty(),"Retry/reset clears all identities and wrecks")
		host.free()
	var remains := Remains.new()
	for pair in [[0.0,0],[0.08,1],[0.18,2],[0.28,3],[0.4,4],[0.54,5],[100.0,5]]:
		check(remains.select_frame(pair[0]) == pair[1],"Authored frame boundary "+str(pair))
	await integration_checks()
	print("Shooter remains: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func integration_checks() -> void:
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	var path: String = game.shooter_remains.definition.frames[0].path
	var prepared: bool = game.trial_textures.has(path) and game.trial_textures[path] != null
	check(prepared,"Death atlas prepared at startup")
	if not prepared:
		game.free()
		return
	var pixels: Image = game.trial_textures[path].get_image()
	var bytes := pixels.get_data()
	var clean := true
	for index in range(3,bytes.size(),4):
		if bytes[index] > 0 and bytes[index] < 240: clean = false
	check(clean,"Prepared death texture removes alpha haze")
	for ceiling in [false,true]:
		game.create_actor({"id":"test-remains-"+str(ceiling),"role":"perched_shooter","warning_seconds":0.0},
			Vector2(600,120 if ceiling else 440))
		var source: Dictionary = game.actors.back()
		source.mount = "ceiling" if ceiling else "floor"
		source.active = true
		source.feet = source.home
		source.erase("entry")
		source.winding = true
		source.volley_left = 3
		source.contact_live = true
		var kills: int = game.kills
		game.damage_trial_actor(source,10000)
		check(not source.winding and not source.contact_live and source.volley_left == 0,"Lethal hit disables attacks immediately")
		game.finish_trial_defeat(source)
		check(game.kills == kills+1,"Repeated defeat cannot duplicate kill")
	for tick in range(360):
		game.step_trial_actors(1.0/120)
		game.step_player(1.0/120)
	check(game.actors.is_empty() and game.shooter_remains.entries.size() == 2,"Remains outlive retired combat actors")
	check(game.shooter_remains.entries.all(func(e: Dictionary) -> bool: return e.frame == 5 and not e.falling),
		"Integrated floor and ceiling wrecks settle")
	game.reset_observation()
	check(game.shooter_remains.entries.is_empty(),"Host reset clears remains")
	game.queue_free()
	await process_frame
