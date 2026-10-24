extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			var game = Game.new()
			game.difficulty = mode
			game.employee = game.Crew.EMPLOYEES[hero]
			game.seed_override = 42
			root.add_child(game)
			game.set_process(false)
			game.set_physics_process(false)
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.dispenser.cancel()
			var actor: Dictionary = game.swarms.actors[0]
			var bank = game.creature_audio["sewer-fly-swarm"]
			var hits: int = bank.hit_starts
			var deaths: int = bank.death_starts
			assert(actor.hp == 24)
			assert(game.weapon.damage == (12 if hero == 0 else 18))
			for shot in range(2):
				game.shots.append({"pos":actor.pos-Vector2(70,0),"dir":Vector2.RIGHT,"damage":game.weapon.damage,
					"speed":1000.0,"distance":0.0,"range":game.weapon.projectile.max_travel_distance_pixels})
				game.step_trial_shots(.1)
				assert(game.shots.is_empty())
				if shot == 0:
					assert(actor.hp == (12 if hero == 0 else 6))
					assert(bank.hit_starts == hits+1 and bank.death_starts == deaths)
				else:
					assert(actor.hp == 0)
					assert(bank.hit_starts == hits+1 and bank.death_starts == deaths+1)
			game.swarms.damage(0,100)
			assert(bank.death_starts == deaths+1, "One shared swarm death, never one per fly or repeated corpse hit")
			game.reset_game()
			assert(game.swarms.actors[0].hp == 24)
			game.checkpoint_active = true
			game.checkpoint_index = 0
			game.respawn_point = Vector2(4650,394)
			game.lives = 2
			game.respawn_after_death()
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.dispenser.cancel()
			game.wave_clock = 1.25
			game.swarm_schedule.step(game)
			assert(game.swarms.actors.size() == 1 and game.swarms.actors[0].hp == 24)
			assert(game.swarms.actors[0].schedule_id == "pump-overhead" and game.lives == 2)
			game.queue_free()
			await process_frame
	print("PASS: Gnatastrophe two active-weapon hits, both heroes/all modes, one hit/death cue, full reset and checkpoint spawn")
	quit()
