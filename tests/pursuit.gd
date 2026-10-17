extends SceneTree
const Data = preload("res://scripts/combat_data.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.enemies.clear()
	game.enemies.append(Data.spawn("toilet", Vector2(1000, 404)))
	game.player = Vector2(0, 100)
	game.step_combat(10)
	assert(not game.enemies[0].aggro and game.enemies[0].pos.x == 850)
	game.player.x = 1000
	game.step_combat(0.1)
	assert(game.enemies[0].aggro)
	game.player.x = 1300
	for frame in range(240): game.step_combat(1.0 / 60)
	assert(game.enemies[0].pos.x > 1150)
	game.player.x = 900
	var before: float = game.enemies[0].pos.x
	for frame in range(90): game.step_combat(1.0 / 60)
	assert(game.enemies[0].pos.x < before)
	game.step_combat(100)
	assert(is_equal_approx(game.enemies[0].pos.x, 906))
	game.activate_checkpoint()
	game.dispenser.tick(game,5.6)
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	assert(game.enemies[0].aggro)
	game.reset_game()
	assert(game.enemies.is_empty() and game.mission.remaining()==30)
	for pair in [["pressure-gun", "tony", 320.0, 7], ["heavy-plunger-launcher", "sean", 480.0, 2]]:
		var weapon: Dictionary = Data.weapon(pair[0], pair[1])
		assert(weapon.projectile.max_travel_distance_pixels == pair[2])
		game.enemies.clear()
		game.enemies.append(Data.spawn("toilet", Vector2(1000, 404)))
		for hit in range(pair[3] - 1):
			game.damage_enemy(0, weapon.damage, Vector2.ZERO)
			assert(game.enemies.size() == 1)
		game.damage_enemy(0, weapon.damage, Vector2.ZERO)
		assert(game.enemies.is_empty() and not game.corpses.back().aggro)
		for direction in [-1.0, 1.0]:
			var shot := {"pos":Vector2(1000, 100), "dir":direction, "damage":weapon.damage,
				"speed":weapon.projectile.speed_pixels_per_second, "range":pair[2], "distance":0.0}
			game.shots.clear()
			game.shots.append(shot)
			game.step_combat(100)
			assert(game.shots.is_empty() and shot.distance == pair[2])
			assert(shot.pos.x == 1000 + direction * pair[2])
	game.queue_free()
	await process_frame
	print("PASS: persistent chase, reversal, patrol, stop distance, checkpoint survival, reset, hit counts and exact ranges")
	quit()
