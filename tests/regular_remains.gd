extends SceneTree
const Remains = preload("res://scripts/regular_remains.gd")
class Host extends Node:
	const FLOOR_Y := 440.0
	var paused := false
	var solids: Array[Rect2] = [Rect2(0,440,1000,100)]
	func actor_solids() -> Array[Rect2]: return solids
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func run_checks() -> void:
	for hz in [30,60,120,144]:
		var host := Host.new()
		var remains := Remains.new()
		var frame := {"opaque":Rect2(-20,-10,40,10),"duration_seconds":0.12}
		remains.frames = {"angel":[frame.duplicate(),frame.duplicate(),frame.duplicate()],
			"swarm":[frame.duplicate(),frame.duplicate(),frame.duplicate()],
			"grate":[frame.duplicate(),frame.duplicate()]}
		for kind in ["angel","grate","swarm"]:
			remains.add(kind,Vector2(300,100),1,1,0)
		var before := remains.entries.duplicate(true)
		host.paused = true
		remains.step(host,2)
		check(remains.entries == before,"Pause freezes remains")
		host.paused = false
		host.solids.append(Rect2(200,300,200,10))
		for tick in range(hz*3): remains.step(host,1.0/hz)
		for entry in remains.entries:
			check(not entry.falling and is_equal_approx(remains.bounds(entry).end.y,300),"Nearest real support")
		remains.step(host,60)
		check(remains.entries.size() == 3 and remains.entries[0].frame == 2,"Permanent settled corpses")
		host.solids = [Rect2(0,440,1000,100)]
		remains.step(host,2)
		for entry in remains.entries:
			check(not entry.falling and is_equal_approx(remains.bounds(entry).end.y,440),"Support loss falls to floor")
		host.solids.clear()
		remains.step(host,4)
		check(remains.entries.all(func(e: Dictionary) -> bool: return e.lost),"Pit fall clears below view")
		remains.reset()
		check(remains.entries.is_empty(),"Reset clears remains")
		host.free()
	await integration_checks()
	print("Regular remains: ",checks," checks, ",failures.size()," failures")
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
	var remains = game.regular_remains
	if remains.textures.size() != 3:
		check(false,"Missing imported Art textures")
		game.free()
		return
	check(remains.frames.size() == 3 and remains.textures.size() == 3,"All Art atlases prepared")
	for texture: Texture2D in remains.textures.values():
		var bytes := texture.get_image().get_data()
		var clean := true
		for index in range(3,bytes.size(),4):
			if bytes[index] > 0 and bytes[index] < 240: clean = false
		check(clean,"Opaque cutoff removes haze")
	for role in ["aggressive_flyer","floor_emerger"]:
		game.create_actor({"id":"remains-"+role,"role":role,"warning_seconds":0.0},Vector2(600,440))
		var actor: Dictionary = game.actors.back()
		actor.active = true
		actor.feet = actor.home
		actor.erase("entry")
		var kills: int = game.kills
		game.damage_trial_actor(actor,10000)
		game.finish_trial_defeat(actor)
		check(game.kills == kills+1,"Defeat counts once")
		check(not actor.contact_live,"Corpse cannot attack")
	var swarm := {"pos":Vector2(600,200),"event_id":"dead-swarm"}
	game._on_swarm_damaged(swarm,true)
	game._on_swarm_damaged(swarm,true)
	check(remains.entries.size() == 3,"Swarm lethal callback snapshots exactly once")
	game.flush.active = true
	game._on_swarm_damaged({"pos":Vector2(100,100),"event_id":"flush-swarm"},true)
	check(remains.entries.size() == 3,"Flush does not create Level 1 remains")
	game.flush.active = false
	check(remains.entries[2].origin == Vector2(600,200) and remains.entries[2].falling,
		"Dead flies begin at death location, not ground")
	for tick in range(360):
		game.step_trial_actors(1.0/120)
		remains.step(game,1.0/120)
	check(remains.entries.size() == 3 and game.actors.is_empty(),"Corpses survive actor retirement")
	for entry in remains.entries:
		check(not entry.falling and not entry.lost,"Actual atlas settles on actual world")
		var box: Rect2 = remains.bounds(entry)
		check(is_finite(remains.support_at(game,box,box.end.y)),"Opaque pixels meet actual support")
	game.reset_observation()
	check(remains.entries.is_empty(),"Host retry clears corpses")
	game.queue_free()
	await process_frame
