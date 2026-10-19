extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
var failures := 0
var last_hit_state := ""

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for hero_id in [0,1]:
		var game = Game.new()
		game.employee = game.Crew.EMPLOYEES[hero_id]
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.dispenser.cancel()
		var speed := 270.0 if hero_id == 0 else 235.0
		for move in ["pounce","rush"]:
			for x in [120.0,450.0,814.0]:
				if move == "rush":
					route(game,move,x,speed,0,-1)
					if last_hit_state not in ["rat_rush", "rat_rush_recovery"]:
						failures += 1
						push_error("Crouched rush must reach stationary hero: "+str([hero_id,x,last_hit_state]))
				var escaped := false
				for direction in [-1.0,1.0]:
					if escaped: break
					for jump_at in [-1.0,-80.0,-110.0,-140.0,-170.0,-200.0,.2,.5,.8,1.1,1.4,1.7,2.0]:
						if route(game,move,x,speed,direction,jump_at):
							escaped = true
							print("Escape ", [hero_id,move,x,direction,jump_at])
							break
				if not escaped:
					failures += 1
					push_error("No visible-contact dodge route: "+str([hero_id,move,x]))
		game.queue_free()
		await process_frame
	if failures == 0: print("PASS: actual room pounce/rush contact evasion through recovery, both heroes and both corners/center")
	quit(1 if failures else 0)

func route(game: Node2D, move: String, x: float, speed: float, direction: float, jump_at: float) -> bool:
	last_hit_state = ""
	var room = game.skitterling
	room.reset(77)
	room.entered = true
	game.player = room.ORIGIN+Vector2(x,394)
	game.health = game.employee.max_health
	game.invulnerable = 0
	var boss = room.encounter
	boss.start(room.hero_rect(game))
	# Start at a naturally reached, committed tell; pre-attack traversal is outside this route test.
	for tick in range(2400):
		if boss.state == "rat_"+move+"_tell": break
		boss.step(1.0/120,room.hero_rect(game))
	if boss.state != "rat_"+move+"_tell": return false
	boss.drain_events()
	var before: int = game.health
	var jumped := false
	var velocity := 0.0
	var recovered := false
	for tick in range(720):
		var time := tick/120.0
		if time >= .2:
			game.player.x = clampf(game.player.x+direction*speed/120,room.START+120,room.START+814)
		var gap: float = absf(game.player.x+13-room.START-boss.position.x)-141
		var jump_now: bool = time >= jump_at if jump_at >= 0 else (jump_at < -1 and gap <= -jump_at)
		if jump_now and not jumped:
			jumped = true
			velocity = -465
		if jumped:
			velocity += 1250.0/120
			game.player.y = minf(394,game.player.y+velocity/120)
		room.advance(game,1.0/120)
		if game.health != before:
			last_hit_state = boss.state
			return false
		if boss.state == "rat_"+move+"_recovery": recovered = true
		elif recovered: return true
	return false
