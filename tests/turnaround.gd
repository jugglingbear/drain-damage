extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var pursuit: Dictionary = game.Data.monster("toilet").pursuit
	var enemy: Dictionary = game.Data.spawn("toilet", Vector2(800, 404))
	enemy.aggro = true
	enemy.direction = 1.0
	enemy.horizontal_speed = 115.0
	var first: float = game.pursuit_velocity(enemy, -100, pursuit, 0.05)
	assert(first > 0 and first < 115, "Crossing must brake, not reverse")
	for index in range(6): game.pursuit_velocity(enemy, -100, pursuit, 0.05)
	assert(is_zero_approx(enemy.horizontal_speed))
	# Further crossings do not restart the active timer.
	for index in range(12):
		game.pursuit_velocity(enemy, 100 if index % 2 == 0 else -100, pursuit, 0.05)
	assert(enemy.turn_elapsed > 0.9 and enemy.direction == 1.0)
	game.pursuit_velocity(enemy, -100, pursuit, 0.051)
	assert(enemy.turn_elapsed == -1 and enemy.direction == -1.0)
	assert(game.pursuit_velocity(enemy, -100, pursuit, 0.05) < 0)
	assert(enemy.horizontal_speed > -115, "Reverse pursuit accelerates gradually")
	game.pursuit_velocity(enemy, 100, pursuit, 0.05)
	game.enemies.append(enemy)
	game.set_paused(true)
	var before: Dictionary = enemy.duplicate(true)
	game._physics_process(5)
	assert(enemy == before, "Pause freezes turn state")
	game.pursuit_velocity(enemy, 0, pursuit, 2)
	assert(enemy.horizontal_speed == 0 and enemy.turn_elapsed >= 1)
	game.pursuit_velocity(enemy, 100, pursuit, 0.01)
	assert(enemy.direction == 1 and enemy.turn_elapsed == -1)
	game.damage_enemy(0, 100, Vector2.ZERO)
	assert(game.enemies.is_empty())
	game.reset_game()
	var fresh: Dictionary = game.Data.spawn("toilet", Vector2.ZERO)
	assert(not fresh.has("turn_elapsed") and not fresh.aggro)
	game.queue_free()
	await process_frame
	print("PASS: braking, one-second turn, repeated crossings, dead zone, acceleration, pause and reset")
	quit()
