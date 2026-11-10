extends SceneTree
const Opening = preload("res://scripts/opening_trial_game.gd")
const Three = preload("res://scripts/three_screen_trial_game.gd")
const Campaign = preload("res://scripts/integrated_first_call.gd")
const Platforms = preload("res://scripts/basement_platforms.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value and message not in failures:
		failures.append(message)
		push_error(message)

func spawn(host: Node2D) -> Dictionary:
	host.devil_spiders.clear(host,"test_reset")
	host.actors.clear()
	host.create_actor({"id":"capture-collision","role":"aggressive_flyer","warning_seconds":0,
		"variant":"devil","devil_limits":Vector2(480,550)},Vector2(513,110))
	var actor: Dictionary = host.actors.back()
	actor.active = true
	actor.entry = {}
	actor.feet = actor.home
	actor.devil.start(actor.feet,actor.devil_limits,1)
	actor.devil.drain_events()
	actor.devil.projectiles[1] = true
	actor.devil.projectile_hit_player(1,host.player+host.PLAYER_SIZE*0.5)
	host.devil_spiders.consume_events(host,actor)
	return actor

func escape(host: Node2D, actor: Dictionary) -> void:
	for press in range(6): actor.devil.escape_press()
	host.devil_spiders.consume_events(host,actor)

func clear_body(host: Node2D) -> bool:
	for solid: Rect2 in host.trial_level.plinths:
		if Rect2(host.player,host.PLAYER_SIZE).grow(-0.001).intersects(solid): return false
	return true

func run_checks() -> void:
	for Type in [Opening,Three,Campaign]:
		for hero in [0,1]:
			var host = Type.new()
			host.employee = host.Crew.EMPLOYEES[hero]
			root.add_child(host)
			host.hide()
			host.set_process(false)
			host.set_physics_process(false)
			host.dispenser.cancel()
			host.dialogue.finish()
			host.dialogue.release_guard = 0
			host.dialogue.awaiting_release = false
			host.life_state = "alive"
			host.paused = false
			host.camera_x = 0
			for hz in [30,60,120]:
				var dt: float = 1.0/hz
				for solid in [false,true]:
					host.trial_level.plinths.clear()
					host.trial_level.decks.clear()
					var obstacle := Rect2(450,300,200,120 if solid else 16)
					if solid: host.trial_level.plinths.append(obstacle)
					else: host.trial_level.decks.append(obstacle)
					host.player = Vector2(500,394)
					var actor := spawn(host)
					var crossed := false
					for tick in range(hz*5):
						host.devil_spiders.step(host,dt)
						if host.player.y+host.PLAYER_SIZE.y < obstacle.position.y:
							crossed = true
							break
					check(crossed,"Cocoon crosses platform continuously at "+str(hz))
					# Escape inside the material through the actual production event consumer.
					host.player = Vector2(500,290)
					escape(host,actor)
					check(not host.devil_spiders.locked(),"Escape releases movement immediately")
					if solid:
						check(host.player == Vector2(500,254) and clear_body(host),"Solid release raises to clear top")
						var hit: Dictionary = host.move_player_body(host.player,Vector2(0,50),host.PLAYER_SIZE,dt)
						check(hit.grounded and hit.pos == host.player,"Solid collision restored on release frame")
					else:
						check(host.player == Vector2(500,290),"Deck release preserves position")
						var original: Array[Rect2] = host.trial_level.decks.duplicate()
						host.move_player_body(host.player,Vector2.ZERO,host.PLAYER_SIZE,0)
						check(host.trial_level.decks == original,"Zero delta restores shared deck geometry")
						for tick in range(hz):
							var moved: Dictionary = host.move_player_body(host.player,Vector2(0,100),host.PLAYER_SIZE,dt)
							host.player = moved.pos
							check(host.trial_level.decks == original,"Deck filtering never leaks into shared geometry")
						check(host.devil_spiders.release_decks.is_empty(),"Deck exemption expires after clearance")
						var landing: Dictionary = host.move_player_body(Vector2(500,250),Vector2(0,100),host.PLAYER_SIZE,1)
						check(landing.grounded and landing.pos.y == 254,"Cleared deck catches a later landing")
				# Real multi-piece registered props, with a taller adjacent obstruction over the release footprint.
				var platforms := Platforms.new()
				for id in platforms.placements:
					host.trial_level.plinths = platforms.colliders(id)
					host.trial_level.decks.clear()
					for rect: Rect2 in host.trial_level.plinths.duplicate():
						host.player = rect.get_center()-host.PLAYER_SIZE*0.5
						var x: float = host.player.x
						var actor := spawn(host)
						escape(host,actor)
						check(clear_body(host) and host.player.x == x,"Registered multipart release clear: "+str(id))
				host.trial_level.plinths.assign([Rect2(450,300,120,140),Rect2(490,260,80,20)])
				host.player = Vector2(500,320)
				var multipart := spawn(host)
				escape(host,multipart)
				check(host.player == Vector2(500,214) and clear_body(host),"Release rechecks upper lip after first upward resolution")
				host.trial_level.plinths.assign([Rect2(450,300,120,140),Rect2(510,270,120,170)])
				host.player = Vector2(500,320)
				var actor := spawn(host)
				escape(host,actor)
				check(host.player == Vector2(500,224),"Adjacent taller solid determines nearest clear top")
				host.player = Vector2(500,320)
				actor = spawn(host)
				actor.hp = 0
				host.devil_spiders.owner_killed(host,actor)
				check(clear_body(host) and not host.devil_spiders.locked(),"Owner death resolves embedded captive")
				for reason in ["retry","hero_inactive","title","level_transition"]:
					host.player = Vector2(500,320)
					spawn(host)
					host.devil_spiders.clear(host,reason)
					check(clear_body(host) and not host.devil_spiders.locked() \
						and host.devil_spiders.release_decks.is_empty(),"Cleanup removes capture collision state: "+reason)
			host.free()
	print("Devil capture collision: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
