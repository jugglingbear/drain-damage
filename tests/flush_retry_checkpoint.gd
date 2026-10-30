extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition,message)

func boundary(game: Node2D) -> void:
	var flush = game.flush
	var wave: Dictionary = flush.definition.layout.difficulty[game.difficulty].waves[0]
	check(flush.clock == float(wave.at) and flush.prelude_remaining == 0,"Retry starts exactly at first cohort")
	check(flush.debris.next_wave == 1 and flush.debris.ledger.size() == 1,"Exactly one cohort, no overdue burst")
	check(flush.hazards.size() == int(wave.count) and not flush.debris.blocked,"Complete first cohort")
	for item in flush.hazards:
		check(not item.impacted and is_equal_approx(item.impact_at-flush.clock,float(wave.duration)),"Full warning interval")
	check(flush.radio.current.is_empty(),"No stale intro on retry")
	check(flush.announced.has("onset") and flush.sink_depth == 0,"Reset capture and onset")
	check(is_equal_approx(45-flush.clock,37),"37 active seconds remain")
	flush.input_guard = false
	flush.process_audio(game,0)
	check(is_equal_approx(flush.music.seek_time,flush.clock),"Music seeks to checkpoint clock")
	var count: int = flush.debris.spawned
	game.set_paused(true)
	flush.tick(game,4,Vector2.ONE,false,false)
	flush.process_audio(game,4)
	check(flush.clock == float(wave.at) and flush.debris.spawned == count,"Pause freezes checkpoint")
	check(flush.music.voice.stream_paused,"Pause freezes checkpoint music")
	game.set_paused(false)

func checks() -> void:
	create_timer(110).timeout.connect(func() -> void: quit(1))
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			game.flush.reset()
			game.difficulty = mode
			game.employee = game.Crew.EMPLOYEES[hero]
			game.seed_override = 42
			game.reset_game()
			game.begin_level_two()
			var flush = game.flush
			check(flush.clock == 0 and flush.prelude_remaining == flush.prelude_duration,"Fresh entry retains intro")
			check(flush.hazards.is_empty() and flush.debris.next_wave == 0,"Fresh entry no hazards")
			# Actual drain deaths exercise retries during the intro and twice during hazards.
			for attempt in 3:
				game.lives = 3
				flush.position = Vector2.ZERO
				flush.tick(game,1.0/120,Vector2.ZERO,false,false)
				check(game.life_state == "dying" and game.lives == 2,"Death debits once")
				game.respawn_after_death()
				boundary(game)
				flush.tick(game,1.0/120,flush.position.normalized(),false,false)
				check(flush.debris.next_wave == 1 and flush.debris.safety_failures == 0,"First live tick does not replay cohort")
			game.lives = 1
			flush.position = Vector2.ZERO
			flush.tick(game,1.0/120,Vector2.ZERO,false,false)
			check(game.lives == 0,"Last-life death")
			game.life_state = "game_over"
			game.death_popup_locked = false
			game.resume_or_retry()
			boundary(game)
			# Follow the scheduler's current verified escape witness through the full remainder.
			var elapsed := 0.0
			while flush.clock < 45 and game.life_state == "alive":
				var command := Vector2.ZERO
				if flush.clock < 35:
					var entry: Dictionary = flush.debris.ledger[-1]
					var index := roundi((flush.clock-float(entry.witness_start))*120)
					if index < entry.witness.size(): command = entry.witness[maxi(0,index)]
				flush.tick(game,1.0/120,command,false,false)
				elapsed += 1.0/120
				if flush.clock >= 35: check(flush.state in ["drain","landing"],"Capture boundary")
			check(game.life_state == "alive" and flush.state == "landing","Retry reaches landing")
			check(absf(elapsed-37) < .02 and flush.checkpoint_saved,"Remaining duration and checkpoint")
			check(flush.debris.safety_failures == 0,"No scheduler boundary skipped")
			print("RETRY PASS ",mode," hero",hero)
	game.queue_free()
	await process_frame
	print("PASS: fresh intro, repeated intro/hazard deaths, game-over retry, warning/music/pause and full remaining route")
	quit()
