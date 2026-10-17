extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	for person in game.Crew.EMPLOYEES:
		game.employee = person
		game.reset_game()
		game.dialogue.release_guard = 0
		Input.action_press("shoot")
		game.step_player(0.0)
		assert(game.shots.size() == 1)
		var shot: Dictionary = game.shots[0].duplicate()
		game.step_player(game.weapon.attack_interval_seconds / 2)
		assert(game.shots.size() == 1, "Cannot fire before weapon is ready")
		game.step_player(game.weapon.attack_interval_seconds / 2 + 0.001)
		assert(game.shots.size() == 2, "Weapon should fire again when reloaded")
		Input.action_release("shoot")
		game.shots.clear()
		game.enemies.append(game.Data.spawn("toilet",Vector2(700,404)))
		shot.pos = game.enemies[0].pos + Vector2(16, 18)
		game.shots.append(shot)
		game.step_combat(0)
		if person.id == "tony":
			assert(game.enemies.size() == 1 and game.enemies[0].hp == 34)
		else:
			assert(game.enemies.size() == 1 and game.enemies[0].hp == 16)
		game.health = 1
		game.invulnerable = 0
		game.hurt_player()
		for frame in range(180): game.step_death(1.0 / 60)
		game.update_death_popup_guard(0.4)
		game.resume_or_retry()
		assert(game.employee == person and game.health == person.max_health, "Respawn preserves chosen employee")
	var frames: Array[Rect2] = game.world_art.tony_frames
	for index in range(8):
		assert(frames[index].size.x > 0 and frames[index].size.y > 0)
	for index in range(1, 5):
		assert(absf(frames[index].size.y / frames[0].size.y * 72 - 72) < 3,
			"Tony's run poses should stay the same height")
	print("PASS: actual weapon cadence, distinct hit damage, respawn identity, Tony sprite alignment")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
