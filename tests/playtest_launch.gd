extends SceneTree
const Launch = preload("res://scripts/playtest_launch.gd")
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	assert(Launch.parse([]).is_empty())
	assert(Launch.parse(["--agent-test"]).is_empty())
	assert(Launch.parse(["--list-playtest-targets"]).list)
	for arguments in [["--level=3"],["--boss=clogfather"],["--miniboss=none"],
		["--level=1","--boss=clogfather"],["--level=1","--level=1"],["--level="],
		["--hero=sean"],["--level=1","--hero=unknown"],["--level=1","--difficulty=unknown"],
		["--level=1","--seed=-1"],["--level=1","--seed=2147483648"],["--unknown"],
		["--verify-playtest-launch"],["--list-playtest-targets","--level=1"]]:
		assert(Launch.parse(PackedStringArray(arguments)).has("error"),"Invalid launch must fail clearly")
	for target in Launch.registry().targets:
		for hero in [0,1]:
			for mode in ["easy","normal","hard"]:
				var options := Launch.parse(PackedStringArray(["--%s=%s" % [target.kind,target.id],
					"--hero="+["tony","sean"][hero],"--difficulty="+mode,"--seed=913"]))
				assert(not options.has("error"))
				var game = Game.new()
				game.employee = game.Crew.EMPLOYEES[hero]
				game.difficulty = mode
				game.seed_override = options.seed
				root.add_child(game)
				game.hide()
				game.set_process(false)
				game.set_physics_process(false)
				Launch.initialize(game,target)
				assert(game.employee.id == options.hero and game.run_seed == 913 and game.difficulty == mode)
				assert(game.weapon.damage == (12 if hero == 0 else 18))
				assert(game.health == game.employee.max_health and game.lives == 3 and game.dispenser.stocked)
				assert(not game.dialogue.active and not game.dispenser.active and game.dialogue.release_guard == 0)
				assert(game.skitterling.encounter.hp == game.skitterling.Encounter.MAX_HP and not game.skitterling.entered)
				if target.id == "2":
					assert(game.flush.active and game.flush.clock == 0 and game.checkpoint_index == 3)
				elif target.id == "2-landing":
					assert(game.flush.active and game.flush.state == "landing" and game.flush.clock == 45)
					assert(game.flush.checkpoint_saved and game.flush.hazards.is_empty() and not game.won)
					assert(game.flush.project(game.flush.position).is_equal_approx(Vector2(480,385)))
					assert(not game.flush.radio.current.is_empty() and game.flush.landing_clock == 0)
				elif target.kind == "level":
					assert(game.player.x == 85 and game.checkpoint_index == -1 and game.respawn_origin == 85)
				else:
					assert(game.player.x == 6410 and game.checkpoint_index == 0 and game.respawn_origin == 4650)
					assert(game.enemies.is_empty() and game.actors.is_empty() and game.swarms.actors.is_empty())
					game.respawn_after_death()
					assert(game.player.x == 4650 and not game.skitterling.entered and game.run_seed == 913)
					assert(game.swarm_schedule.report().excluded == {"easy":5,"normal":8,"hard":6}[mode] and not game.dispenser.stocked)
				game.queue_free()
				await process_frame
	print("PASS: launch registry, invalid/conflicting/unimplemented targets, both heroes/all difficulties and checkpoint reset")
	quit()
