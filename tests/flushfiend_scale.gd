extends SceneTree
const Geometry = preload("res://scripts/flushfiend_geometry.gd")
const Campaign = preload("res://scripts/integrated_first_call.gd")
const Trial = preload("res://scripts/three_screen_trial_game.gd")
var failures: Array[String] = []
var checks_run := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func checks() -> void:
	check(Geometry.BODY_SIZE.is_equal_approx(Vector2(45.6,43.2)),"Terrain/contact size increases exactly 20 percent")
	check(is_equal_approx(Geometry.RENDER_HEIGHT,51.6),"Visible height increases exactly 20 percent")
	for height in [440.0,380.0,320.0]:
		var feet := Vector2(600,height)
		var body := Geometry.body_at_feet(feet)
		check(is_equal_approx(body.end.y,height),"Larger body preserves supported feet")
		check(Geometry.feet(Geometry.legacy_from_body(body.position)).is_equal_approx(feet),"Legacy storage round trip")
		check(is_equal_approx(Geometry.projectile_rect(feet).end.y,height),"Shot target shares feet with visible body")
	for scene in [Campaign,Trial]:
		for hero in [0,1]:
			var game: Node2D = scene.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			root.add_child(game)
			game.set_process(false)
			game.set_physics_process(false)
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.enemies.clear()
			game.actors.clear()
			game.swarms.actors.clear()
			game.shots.clear()
			game.player = Vector2(400,394)
			game.grounded = true
			game.facing = 1
			game.current_aim = Vector2.RIGHT
			for role in ["runner","rear_runner"]:
				check(game.event_size(role).size.is_equal_approx(Geometry.BODY_SIZE),"Shared actor terrain dimensions")
			var feet := Vector2(600,440)
			game.create_actor({"id":"scale-target","role":"runner","warning_seconds":0.0},feet)
			var actor: Dictionary = game.actors.back()
			actor.active = true
			var hp: float = actor.hp
			var muzzle: Vector2 = game.world_art.hero_aim_art.muzzle(game)
			check(game.projectile_hit(muzzle,muzzle+Vector2(450,0),game.actor_projectile_rect(actor),Vector2.RIGHT) >= 0,
				"Actual grounded muzzle intersects enlarged toilet: "+game.employee.id)
			game.shots.append({"pos":muzzle,"dir":Vector2.RIGHT,"speed":900.0,
				"range":600.0,"distance":0.0,"damage":1.0,"trial_id":"scale-shot"})
			game.step_trial_shots(0.5)
			check(actor.hp < hp,"Grounded straight shot causes damage: "+game.employee.id)
			check(game.actor_rect(actor).end.y == 440,"Damage leaves feet grounded")
			for costume in ["normal","easy","hard"]:
				game.world_art.hero_aim_art.configure(costume)
				game.animation_state = "run"
				game.velocity.x = 270
				for frame in range(6):
					game.animation_time = frame*0.09+0.001
					var running_muzzle: Vector2 = game.world_art.hero_aim_art.muzzle(game)
					var before: float = actor.hp
					game.shots.append({"pos":running_muzzle,"dir":Vector2.RIGHT,"speed":900.0,
						"range":600.0,"distance":0.0,"damage":1.0,"trial_id":"running-scale-shot"})
					game.step_trial_shots(0.5)
					check(actor.hp < before,"Every running muzzle damages same-floor toilet: "+game.employee.id+costume)
			game.actors.clear()
			game.shots.clear()
			var enemy: Dictionary = game.Data.spawn("toilet",feet-Geometry.LEGACY_FEET)
			game.enemies.append(enemy)
			hp = enemy.hp
			game.shots.append({"pos":muzzle,"dir":Vector2.RIGHT,"speed":900.0,
				"range":600.0,"distance":0.0,"damage":1.0})
			game.step_combat(0.5)
			check(enemy.hp < hp,"Campaign dictionary enemy also receives straight shot")
			check(is_equal_approx(Geometry.body(enemy.pos).end.y,440),"Production movement preserves floor contact")
			# Actual navigation sweep must retain both sixty-pixel climbs with the larger body.
			game.trial_level.plinths.assign([Rect2(500,380,180,60),Rect2(680,320,180,120)])
			game.trial_level.decks.clear()
			var walker := {"event_id":"scale-walker","role":"runner","feet":Vector2(440,440),
				"vy":0.0,"facing":1.0}
			var summit := false
			for tick in range(720):
				game.move_ground_actor(walker,100,1.0/120)
				if walker.grounded and is_equal_approx(walker.feet.y,320): summit = true
			check(summit,"Enlarged body climbs successive supported steps")
			game.trial_level.plinths.assign([Rect2(500,300,180,140)])
			walker = {"event_id":"scale-wall","role":"runner","feet":Vector2(500-Geometry.BODY_SIZE.x*0.5-0.1,440),
				"vy":0.0,"facing":1.0}
			for tick in range(120):
				game.move_ground_actor(walker,100,1.0/120)
				check(not game.actor_rect(walker).intersects(Rect2(500,300,180,140)),"Larger body does not enter unjumpable wall")
			check(walker.feet.x < 470,"Unreachable obstacle still causes retreat")
			root.remove_child(game)
			game.free()
	print("Flushfiend scale: %d checks, %d failures" % [checks_run,failures.size()])
	quit(0 if failures.is_empty() else 1)
