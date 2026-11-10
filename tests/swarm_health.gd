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
			var actor: Dictionary = admit_swarm(game,"campaign-entry-c-swarm")
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
			assert(game.swarms.actors.is_empty())
			assert(admit_swarm(game,"campaign-entry-c-swarm").hp == 24)
			game.checkpoint_active = true
			game.checkpoint_index = 0
			game.respawn_point = Vector2(4650,394)
			game.lives = 2
			game.respawn_after_death()
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.dispenser.cancel()
			assert(game.swarms.actors.is_empty())
			var restored := admit_swarm(game,"campaign-pump-swarm")
			assert(restored.hp == 24 and game.lives == 2)
			for spec in game.campaign.specs:
				if spec.owner_origin < 4650: assert(game.ledger[spec.id] == "excluded")

			game.queue_free()
			await process_frame
	print("PASS: Gnatastrophe two active-weapon hits, both heroes/all modes, one hit/death cue, full reset and checkpoint spawn")
	quit()

func admit_swarm(game: Node, id: String) -> Dictionary:
	var selected: Dictionary
	for spec in game.campaign.specs:
		if spec.id == id: selected = spec
		elif game.ledger[spec.id] == "pending": game.ledger[spec.id] = "expired"
	assert(not selected.is_empty() and game.ledger[id] == "pending")
	game.player = Vector2(selected.trigger,394)
	game.camera_x = game.player.x-320
	game.issue_event()
	assert(game.swarms.actors.size() == 1 and game.ledger[id] == "active")
	var actor: Dictionary = game.swarms.actors[0]
	for tick in range(240): game.step_campaign_swarms(1.0/120)
	assert(not game.swarms.entry_active(actor))
	return actor
