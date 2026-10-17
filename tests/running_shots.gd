extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var cases := 0
	for person in game.Crew.EMPLOYEES:
		game.employee = person
		game.reset_game()
		game.player = Vector2(800,394)
		game.grounded = true
		for facing in [-1,1]:
			game.facing = facing
			game.current_aim = Vector2(facing,0)
			game.velocity.x = 235 * facing
			game.animation_state = "idle"
			var idle: Vector2 = game.world_art.hero_aim_art.muzzle(game)
			for hop in [0,4,12,24,36,60,90]:
				for distance in [80,160,250]:
					var enemy := Rect2(Vector2(813 + facing * distance - 27,399-hop),Vector2(54,46))
					var idle_hit: float = game.projectile_hit(idle, idle + Vector2(facing*300,0), enemy, game.current_aim)
					game.animation_state = "run"
					for frame in range(6):
						game.animation_time = frame * 0.09 + 0.001
						var muzzle: Vector2 = game.world_art.hero_aim_art.muzzle(game)
						var hit: float = game.projectile_hit(muzzle, muzzle+Vector2(facing*300,0), enemy, game.current_aim)
						if idle_hit >= 0: assert(hit >= 0, "Running must not lose an idle horizontal hit")
						if hop == 90: assert(hit < 0, "High airborne enemies can legitimately clear horizontal shots")
						cases += 1
		for facing in [-1,1]:
			game.facing = facing
			game.current_aim = Vector2(facing,0)
			game.velocity.x = 235 * facing
			game.animation_state = "run"
			for frame in range(6):
				game.animation_time = frame * 0.09 + 0.001
				game.enemies.clear()
				game.shots.clear()
				game.enemies.append(game.Data.spawn("toilet",Vector2(813 + facing * 100 - 19,404)))
				game.shots.append({"pos":game.world_art.hero_aim_art.muzzle(game), "dir":game.current_aim,
					"damage":game.weapon.damage, "speed":10000, "range":game.weapon.projectile.max_travel_distance_pixels,
					"distance":0.0})
				game.step_combat(0.02)
				assert(game.enemies[0].hp == 40-game.weapon.damage)
				assert(game.shots.is_empty())
		# The same visible edge must strike solids, while distant vertical misses remain misses.
		assert(game.projectile_hit(Vector2(0,398),Vector2(100,398),Rect2(50,399,20,40),Vector2.RIGHT) >= 0)
		assert(game.projectile_hit(Vector2(0,380),Vector2(100,380),Rect2(50,399,20,40),Vector2.RIGHT) < 0)
		assert(game.weapon.damage == (24 if person.id == "sean" else 6))
		assert(game.weapon.projectile.max_travel_distance_pixels == (480 if person.id == "sean" else 320))
	print("PASS: ",cases," run frame/facing/distance/hop checks, visible thickness and unchanged damage/range")
	game.queue_free()
	quit()
