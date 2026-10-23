extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			var game = Game.new()
			game.difficulty = mode
			game.employee = game.Crew.EMPLOYEES[hero]
			game.seed_override = 42
			root.add_child(game)
			game.boss_intro.seen = {"cockroach-swarm": true, "clogfather": true}
			game.set_process(false)
			game.set_physics_process(false)
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.dispenser.cancel()
			var room = game.skitterling
			assert(room.art.ready)
			for rect in game.trial_level.plinths:
				assert(rect.end.x <= room.QUIET or rect.position.x >= room.END)
			game.player = Vector2(6690,394)
			game.invulnerable = 1000
			for tick in range(60): room.advance(game,1.0/120)
			assert(room.locked() and game.camera_x == 6570 and room.encounter.state == "entry_skitter")
			assert(game.actors.is_empty() and game.enemies.is_empty() and game.hostile_shots.is_empty())
			assert(game.boss_hud.active and game.crowd_population() == 1)
			var before_pause: Dictionary = room.encounter.snapshot()
			game.set_paused(true)
			room.advance(game,1)
			assert(room.encounter.elapsed == before_pause.elapsed and room.audio.paused)
			assert(room.damage(game,9999) == 0 and game.camera_x == 6570)
			game.set_paused(false)
			game.dialogue.release_guard = 0
			var left: Dictionary = game.move_player_body(Vector2(6690,394),Vector2(-1000,0),game.PLAYER_SIZE,1)
			var right: Dictionary = game.move_player_body(Vector2(7360,394),Vector2(1000,0),game.PLAYER_SIZE,1)
			assert(left.pos.x == 6690 and right.pos.x+game.PLAYER_SIZE.x == 7410)
			var entry_hp: int = room.encounter.hp
			assert(room.damage(game,9999) == 0 and room.encounter.hp == entry_hp)
			var states: Dictionary = {}
			var rat_defeated := false
			var gator_defeated := false
			for tick in range(120*45):
				room.advance(game,1.0/120)
				states[room.encounter.state] = true
				assert(game.camera_x == 6570)
				if room.encounter.damageable():
					var phase: String = room.encounter.phase
					var before: int = room.encounter.hp
					var rect: Rect2 = room.target_rect()
					assert(rect.has_area(),"Visible damageable body must accept shots")
					game.shots.append({"pos":Vector2(rect.position.x-2,rect.get_center().y),
						"dir":Vector2.RIGHT,"speed":1000.0,"range":480.0,"distance":0.0,"damage":9999})
					game.step_trial_shots(.01)
					assert(room.encounter.hp < before and game.shots.is_empty())
					if phase == "rat":
						rat_defeated = true
						assert(room.encounter.hp == room.encounter.PHASE_HP and not room.encounter.exit_open)
					else: gator_defeated = true
				if room.encounter.exit_open: break
			assert(rat_defeated and gator_defeated and room.encounter.exit_open)
			for state in ["rat_assembly","rat_collapse","reskitter","alligator_assembly","terminal_death"]:
				assert(states.has(state),"Required two-form sequence cannot be skipped")
			assert(game.kills == 1 and game.player_kills == 1)
			assert(room.audio.event_starts.get("terminal_death",0) == 1)
			game.player.x = 7650
			room.advance(game,.01)
			assert(room.released and not room.locked())
			# The checkpoint restores the encounter without altering the already-consumed life.
			game.checkpoint_active = true
			game.checkpoint_index = 0
			game.respawn_point = Vector2(4650,394)
			game.lives = 3
			game.health = 1
			game.invulnerable = 0
			game.hurt_player()
			assert(game.life_state == "dying" and game.lives == 2)
			game.respawn_after_death()
			assert(game.lives == 2 and room.encounter.hp == room.Encounter.MAX_HP and not room.entered)
			assert(room.encounter.hazards.is_empty() and room.audio.target == -1)
			game.queue_free()
			await process_frame
	await check_midfight_retry()
	print("PASS: integrated Skitterling all modes/heroes, authored geometry,camera,shared shots,both forms,exit,one kill,audio and checkpoint reset")
	quit()

func check_midfight_retry() -> void:
	var game = Game.new()
	root.add_child(game)
	game.boss_intro.seen = {"cockroach-swarm": true, "clogfather": true}
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.checkpoint_active = true
	game.checkpoint_index = 0
	game.respawn_point = Vector2(4650,394)
	game.dispenser.checkpoint = 0
	game.dispenser.consume_stock()
	game.player = Vector2(6690,394)
	game.invulnerable = 100
	var room = game.skitterling
	for tick in range(120*45):
		room.advance(game,1.0/120)
		if room.encounter.phase == "rat" and room.encounter.damageable(): room.damage(game,9999)
		if room.encounter.state == "alligator_debris": break
	assert(room.encounter.state == "alligator_debris" and not room.encounter.hazards.is_empty())
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	var state: Dictionary = room.encounter.snapshot()
	room.process_audio(game,.1)
	for tick in range(30): game._physics_process(1.0/120)
	assert(game.camera_x == 6570 and room.encounter.snapshot() == state and room.audio.paused)
	game.respawn_after_death()
	assert(game.player == Vector2(4650,394) and game.lives == 2 and not game.dispenser.stocked)
	assert(room.encounter.hp == room.Encounter.MAX_HP and room.encounter.hazards.is_empty() and not room.locked())
	assert(game.kills == 0 and game.camera_x == 4330)
	game.queue_free()
	await process_frame
