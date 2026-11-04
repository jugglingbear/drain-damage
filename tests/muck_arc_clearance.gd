extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
var count := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("checks")
func check(value: bool, message: String) -> void:
	count += 1
	if not value:
		failures.append(message)
		push_error(message)
func checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.trial_level.plinths.clear()
	game.trial_level.decks.clear()
	var low := game.muck_trajectory(Vector2(500,370),Vector2(200,417),-1)
	check(not low.is_empty() and is_equal_approx(low.flight,1),"Clear floor throw keeps original one-second flight")
	for height in [60,120]:
		for side in [-1,1]:
			game.trial_level.plinths.assign([Rect2(300,440-height,160,height)])
			var origin := Vector2(480 if side < 0 else 280,370)
			var target := Vector2(350 if side < 0 else 410,440-height-23)
			var path := game.muck_trajectory(origin,target,side)
			check(not path.is_empty(),"Raised platform receives an arc: height%s side%s" % [height,side])
			if path.is_empty(): continue
			for hz in [30,120]:
				game.player = target-game.PLAYER_SIZE*0.5
				game.health = game.employee.max_health
				game.invulnerable = 0
				game.hostile_shots.clear()
				game.hostile_shots.append({"id":"arc-test","kind":"muck","pos":origin,
					"velocity":path.velocity,"dir":path.velocity.normalized(),"gravity":700.0,
					"radius":12.0,"age":0.0,"target":target})
				for tick in range(3*hz):
					game.step_hostile_projectiles(1.0/hz)
					if game.hostile_shots.is_empty(): break
				check(game.health < game.employee.max_health,
					"Real projectile clears ledge and hits stationary hero at%sHz" % hz)
	game.trial_level.plinths.assign([Rect2(300,380,160,60)])
	game.player = Vector2(337,334)
	game.invulnerable = 0
	game.health = game.employee.max_health
	game.hostile_shots.clear()
	game.create_actor({"id":"muck-release-test","role":"floor_emerger","warning_seconds":0},Vector2(580,440))
	var actor: Dictionary = game.actors.back()
	actor.entry.complete = true
	actor.feet = actor.home
	actor.active = true
	actor.contact_live = true
	for tick in range(120):
		actor.age += 1.0/120
		game.step_muck_thrower(actor,1.0/120,true)
		if not game.hostile_shots.is_empty(): break
	check(game.hostile_shots.size() == 1,"Actual animated throw releases a ledge-clearing projectile")
	if not game.hostile_shots.is_empty():
		check(game.hostile_shots[0].pos.is_equal_approx(game.muck_hand(actor)),"Projectile starts at visible release hand")
		for tick in range(360):
			game.step_hostile_projectiles(1.0/120)
			if game.hostile_shots.is_empty(): break
		check(game.health < game.employee.max_health,"Actual release and arc threaten hero atop platform")
	for side in [-1,1]:
		game.hostile_shots.clear()
		game.actors.clear()
		game.trial_level.plinths.assign([Rect2(300,380,160,60)])
		game.player = Vector2(337 if side < 0 else 397,334)
		game.health = game.employee.max_health
		game.invulnerable = 0
		var feet := Vector2(560 if side < 0 else 200,440)
		game.create_actor({"id":"close-release","role":"floor_emerger","warning_seconds":0},feet)
		var close: Dictionary = game.actors.back()
		close.entry.complete = true
		close.feet = close.home
		close.active = true
		close.contact_live = true
		for tick in range(120):
			close.age += 1.0/120
			game.step_muck_thrower(close,1.0/120,true)
			if not game.hostile_shots.is_empty(): break
		check(game.hostile_shots.size() == 1,"Close ledge releases without embedded ball in direction"+str(side))
		if game.hostile_shots.is_empty(): continue
		var shot: Dictionary = game.hostile_shots[0]
		check(shot.pos.is_equal_approx(game.muck_hand(close)),"Raised release remains attached to actual hand")
		check(shot.pos.y+shot.radius < 380,"Full ball begins above60px platform top")
		for tick in range(360):
			game.step_hostile_projectiles(1.0/120)
			if game.hostile_shots.is_empty(): break
		check(game.health < game.employee.max_health,"Close ledge throw threatens stationary hero in direction"+str(side))
	game.trial_level.plinths.assign([Rect2(300,0,160,440)])
	check(game.muck_trajectory(Vector2(500,370),Vector2(200,417),-1).is_empty(),
		"Full-height blocker cannot be bypassed")
	game.trial_level.plinths.assign([Rect2(300,300,160,140),Rect2(250,210,260,30)])
	check(game.muck_trajectory(Vector2(480,370),Vector2(350,277),-1).is_empty(),
		"Overhead obstruction rejects impossible higher throw")
	game.trial_level.plinths.clear()
	check(game.muck_trajectory(Vector2(500,370),Vector2(510,417),-1).is_empty(),
		"Target behind extended hand never reverses through body")
	root.remove_child(game)
	game.free()
	print("Muck arc clearance: %d checks, %d failures" % [count,failures.size()])
	quit(0 if failures.is_empty() else 1)
