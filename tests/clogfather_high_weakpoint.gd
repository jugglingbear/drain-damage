extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("run_checks")

func open_window(game: Node, index: int) -> void:
	for tick in range(120*30):
		if game.clogfather.encounter.recovery_index == index and game.clogfather.encounter.damageable(): return
		game.clogfather.advance(game,1.0/120)
	assert(false,"Missing recovery window")

func run_checks() -> void:
	create_timer(50).timeout.connect(func() -> void: quit(1))
	for hero in [0,1]:
		var game = Game.new()
		game.employee = game.Crew.EMPLOYEES[hero]
		root.add_child(game)
		game.boss_intro.seen = {"cockroach-swarm": true, "clogfather": true}
		game.hide()
		game.set_process(false)
		game.set_physics_process(false)
		game.dispenser.cancel()
		game.dispenser.actions_locked = false
		game.dispenser.just_finished = false
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.restart_guard_device = -1
		game.checkpoint_index = 1
		game.skitterling.restore_completed()
		game.player = Vector2(14150+500,394)
		game.invulnerable = 1000
		game.clogfather.advance(game,0)
		var boss = game.clogfather.encounter
		open_window(game,1)
		assert(boss.snapshot().weak_point_level == "low" and boss.weak_point_rect() == Rect2(626,377,48,42))
		open_window(game,2)
		assert(boss.snapshot().weak_point_level == "high" and boss.weak_point_rect() == Rect2(692,304,48,42))
		# Both trajectories are actual weapon projectiles. An otherwise valid ground-fired high hit is armored.
		var previous: int = boss.hp
		game.player = Vector2(14150+500,394)
		game.velocity = Vector2.ZERO
		game.grounded = true
		game.facing = 1
		game.current_aim = Vector2(1,-1).normalized()
		var muzzle: Vector2 = game.world_art.hero_aim_art.muzzle(game)
		var offset: float = muzzle.x-game.player.x
		game.player.x = 14150+716-(muzzle.y-325)-offset
		Input.action_press("right")
		Input.action_press("aim_up")
		Input.action_press("shoot")
		game.fire_timer = 0
		game._physics_process(1.0/120)
		Input.action_release("shoot")
		Input.action_release("right")
		Input.action_release("aim_up")
		for tick in range(100):
			game._physics_process(1.0/120)
			if game.shots.is_empty(): break
		assert(game.shots.is_empty() and boss.hp == previous,"Ground diagonals must not bypass jump requirement")
		for lane in [400.0,610.0]:
			previous = boss.hp
			game.player = Vector2(14150+lane,394)
			game.velocity = Vector2.ZERO
			game.grounded = true
			game.facing = 1
			game.jump_buffer = 0.14
			for tick in range(43): game._physics_process(1.0/120)
			assert(not game.grounded and game.player.y < 315,"Both heroes must reach real jump apex")
			game.current_aim = Vector2.RIGHT
			Input.action_press("right")
			Input.action_press("shoot")
			game.fire_timer = 0
			game._physics_process(1.0/120)
			Input.action_release("shoot")
			Input.action_release("right")
			assert((game.shots.size() == 1 and game.shots[0].fired_airborne) or boss.hp == previous-int(game.weapon.damage))
			for tick in range(100):
				game._physics_process(1.0/120)
				if game.shots.is_empty(): break
			assert(boss.hp == previous-int(game.weapon.damage),"Actual jump shot must reach high mouth before shell")
		open_window(game,3)
		assert(boss.snapshot().weak_point_level == "low" and boss.weak_point_rect() == Rect2(626,377,48,42))
		boss.reset(42)
		assert(boss.recovery_index == 0 and boss.snapshot().weak_point_level == "low")
		game.queue_free()
		await process_frame
	print("PASS: both heroes actual horizontal jump high hits, ground rejection, low/high/low order and retry reset")
	quit()
