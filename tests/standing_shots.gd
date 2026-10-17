extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var script_path := "res://scripts/integrated_first_call.gd" if "--integrated" in OS.get_cmdline_user_args() else "res://scripts/opening_trial_game.gd"
	var game = load(script_path).new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	var cases := 0
	for person in game.Crew.EMPLOYEES:
		game.employee = person
		game.reset_game()
		game.dispenser.cancel()
		game.player = Vector2(1387,394)
		game.grounded = true
		game.velocity = Vector2.ZERO
		game.animation_state = "idle"
		for facing in [-1,1]:
			game.facing = facing
			game.current_aim = Vector2(facing,0)
			var muzzle: Vector2 = game.world_art.hero_aim_art.muzzle(game)
			assert(is_equal_approx(muzzle.y,399.0 if person.id == "tony" else 400.5))
			for enemy_direction in [-1,1]:
				for role in ["runner","rear_runner"]:
					game.actors.clear()
					game.shots.clear()
					game.hostile_shots.clear()
					var feet := Vector2(1400+facing*100,440)
					var actor := {"event_id":"fixture", "role":role,"feet":feet,
						"hp":24.0,"max_hp":24.0,"active":true,"flash":0.0}
					game.actors.append(actor)
					# This is the exact old mismatch, not an artificial high projectile.
					if person.id == "tony":
						assert(game.projectile_hit(muzzle,muzzle+Vector2(facing*250,0),
							game.actor_rect(actor),game.current_aim) < 0)
					assert(game.actor_projectile_rect(actor) == game.flushfiend_projectile_rect(feet))
					game.shots.append({"pos":muzzle,"dir":game.current_aim,"damage":game.weapon.damage,
						"speed":game.weapon.projectile.speed_pixels_per_second,
						"range":game.weapon.projectile.max_travel_distance_pixels,"distance":0.0,"trial_id":"fixture"})
					for tick in range(120):
						actor.feet.x += enemy_direction*115.0/120
						game.step_trial_shots(1.0/120)
						if game.shots.is_empty(): break
					assert(actor.hp == 24-game.weapon.damage,"Standing shot missed moving visible Flushfiend body")
					assert(game.shots.is_empty())
					cases += 1
			var target: Rect2 = game.flushfiend_projectile_rect(Vector2(1400+facing*100,440))
			assert(game.projectile_hit(Vector2(muzzle.x,380),Vector2(muzzle.x+facing*250,380),
				target,game.current_aim) < 0,"Shots clearly above body must still miss")
			assert(game.current_aim == Vector2(facing,0))
	print("PASS: ",cases," standing shots, both heroes/facings/enemy directions/runner roles; visible muzzle and high misses")
	game.actors.clear()
	game.queue_free()
	await process_frame
	quit()
