extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, message: String) -> bool:
	if value: return true
	failed = true
	push_error("Clogfather integration: "+message)
	Input.action_release("shoot")
	quit(1)
	return false

func unlock(game: Node) -> void:
	game.dispenser.cancel()
	game.dispenser.just_finished = false
	game.dispenser.actions_locked = false
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.restart_guard_device = -1
	game.invulnerable = 100

func enter_room(game: Node) -> void:
	unlock(game)
	game.player = Vector2(game.ClogfatherRoom.START+480,394)
	game.velocity = Vector2.ZERO
	game.grounded = true
	game.facing = 1
	game.current_aim = Vector2.RIGHT
	game.clogfather.advance(game,0)

func recovery(game: Node) -> bool:
	for tick in range(120*20):
		if game.clogfather.encounter.damageable(): return true
		game.clogfather.advance(game,1.0/120)
	return check(false,"boss never reached its open window")

func fire(game: Node, duplicate := false) -> bool:
	game.fire_timer = 0
	game.dispenser.actions_locked = false
	Input.action_press("shoot")
	game._physics_process(1.0/120)
	Input.action_release("shoot")
	if not check(game.shots.size() == 1,"real player firing did not create one projectile"): return false
	if duplicate: game.shots.append(game.shots[0].duplicate(true))
	for tick in range(120):
		game._physics_process(1.0/120)
		if game.shots.is_empty(): return true
	return check(false,"projectile did not resolve within one second")

func run_checks() -> void:
	# A watchdog also bounds unexpected engine assertions in concurrently integrated dependencies.
	create_timer(60).timeout.connect(func() -> void: push_error("Integration watchdog expired"); quit(1))
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			var game = Game.new()
			game.difficulty = mode
			game.employee = game.Crew.EMPLOYEES[hero]
			game.seed_override = 42
			root.add_child(game)
			game.boss_intro.seen = {"cockroach-swarm": true, "clogfather": true}
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			unlock(game)
			# Each dispenser owns a separate single clone. Check-in never charges a life.
			game.health = 1
			game.activate_checkpoint(0)
			if not check(game.dispenser.mode == "injured" and game.health == game.employee.max_health,
				"first check-in must select injured before healing"): return
			game.dispenser.finish(game,true)
			unlock(game)
			if not check(game.dispenser.spent_checkpoints.has(0) and game.lives == 3,"first clone stock/lives"): return
			game.skitterling.restore_completed()
			game.player = Vector2(13800,394)
			game.health = 1
			game.activate_checkpoint(1)
			if not check(is_equal_approx(game.camera_x,game.clogfather.camera_position(game.player.x)),
				"checkpoint presentation must retain the entry camera blend"): return
			if not check(game.dispenser.mode == "injured" and game.dispenser.stocked,
				"first machine must not consume the second machine stock"): return
			game.dispenser.finish(game,true)
			unlock(game)
			if not check(game.respawn_point == Vector2(13800,394) and game.checkpoint_index == 1
				and game.dispenser.spent_checkpoints.size() == 2 and game.lives == 3,"preboss checkpoint commit"): return
			enter_room(game)
			var boss = game.clogfather.encounter
			if not check(game.clogfather.entered and boss.hp == 1080 and game.camera_x == 14150,"arena entry"): return
			if not fire(game): return
			if not check(boss.hp == 1080,"closed shell accepted real projectile damage"): return
			if not recovery(game): return
			var before: int = boss.hp
			if not fire(game,true): return
			if not check(boss.hp == before-int(game.weapon.damage),"weak point must take one hit per shot ID"): return
			# An airborne horizontal shot above the mouth must hit armor even while the mouth is open.
			game.player = Vector2(game.ClogfatherRoom.START+480,270)
			game.velocity = Vector2.ZERO
			game.grounded = false
			before = boss.hp
			if not fire(game): return
			if not check(boss.hp == before,"open window made the entire shell vulnerable"): return
			game.player = Vector2(game.ClogfatherRoom.START+480,394)
			game.velocity = Vector2.ZERO
			game.grounded = true
			var time: float = boss.elapsed
			game.set_paused(true)
			game._physics_process(1)
			if not check(boss.elapsed == time and boss.hp == before,"pause advanced boss or HP"): return
			game.set_paused(false)
			# Real lethal player damage debits a life once; retry resets this boss, not Skitterling.
			game.health = 1
			game.invulnerable = 0
			game.hurt_player()
			if not check(game.life_state == "dying" and game.lives == 2,"real death did not debit one life"): return
			time = boss.elapsed
			game._physics_process(0.1)
			if not check(boss.elapsed == time,"dead player allowed boss attacks to advance"): return
			for tick in range(600):
				game.step_death(1.0/120)
				if game.life_state == "death_popup": break
			if not check(game.life_state == "death_popup","death never reached Continue popup"): return
			game.update_death_popup_guard(0.4)
			game.resume_or_retry()
			if not check(game.lives == 2 and game.health == game.employee.max_health
				and game.respawn_origin == 13800 and game.dispenser.mode == "empty_arrival","checkpoint retry health/lives/stock"): return
			unlock(game)
			if not check(game.skitterling.encounter.exit_open and game.skitterling.released
				and boss.hp == 1080 and boss.state == "idle" and not game.clogfather.entered,
				"retry resurrected Skitterling or retained damaged Clogfather"): return
			for event in game.run_plan.later:
				if not check(game.encounter_states[event.id] == "excluded","earlier route remains eligible after preboss retry"): return
			for event in game.trial_state.results().events:
				if event.id.begins_with("opening-"):
					if not check(event.state == "unavailable","opening revived after preboss retry"): return
			if not check(game.actors.is_empty() and game.enemies.is_empty() and game.shots.is_empty()
				and game.hostile_shots.is_empty() and game.swarms.actors.is_empty(),"retry retained old actors/projectiles"): return
			enter_room(game)
			game.player.x = game.ClogfatherRoom.FINISH
			game._physics_process(0)
			if not check(not game.won and game.player.x <= 14824,"living boss allowed level completion"): return
			game.player.x = game.ClogfatherRoom.START+480
			if not recovery(game): return
			var kills: int = game.kills
			game.clogfather.damage(game,10000,"terminal-test")
			if not check(not boss.exit_open and not game.won and game.clogfather.shell_rect() == Rect2(),
				"lethal hit must clear shell but wait for collapse before exit"): return
			game.clogfather.advance(game,1.21)
			if not check(boss.exit_open and game.kills == kills+1,"terminal collapse/kill accounting"): return
			game.clogfather.advance(game,2)
			if not check(game.kills == kills+1,"repeated completion granted another kill"): return
			game.player = Vector2(game.ClogfatherRoom.FINISH,394)
			game._physics_process(0)
			if not check(game.ending.state == "dialogue" and not game.won,
				"collapse must start aftermath before completion"): return
			unlock(game)
			game._physics_process(0)
			game._physics_process(2.5)
			if not check(game.flush.active and not game.won and game.ending.state == "complete","portal departure did not start Level 2"): return
			game.flush.reset()
			game.reset_game()
			unlock(game)
			if not check(game.checkpoint_index == -1 and game.respawn_point.x == 85 and game.lives == 3
				and game.dispenser.spent_checkpoints.is_empty() and not game.skitterling.encounter.exit_open
				and not boss.exit_open and boss.hp == 1080 and not game.clogfather.entered,
				"full restart failed to reset both encounters/checkpoints/stock"): return
			game.queue_free()
			await process_frame
			print("PASS integrated Clogfather ",mode," hero",hero)
	if not failed:
		print("PASS: all six mode/hero combinations; real shots, armor/weakpoint/dedup, pause/death/retry, independent stock and terminal gate")
		quit()
