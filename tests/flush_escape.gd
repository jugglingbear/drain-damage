extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("checks")

func checks() -> void:
	for hz in [60,120]:
		for hero in [0,1]:
			for mode in ["easy","normal","hard"]:
				var game = Game.new()
				game.employee = game.Crew.EMPLOYEES[hero]
				game.difficulty = mode
				game.seed_override = 913
				root.add_child(game)
				game.hide()
				game.set_process(false)
				game.set_physics_process(false)
				game.begin_level_two()
				var initial: int = game.health
				game.invulnerable = 0
				for frame in range(35*hz+1):
					var steering := Vector2.ZERO
					if not game.flush.debris.ledger.is_empty():
						var wave: Dictionary = game.flush.debris.ledger[-1]
						var index := clampi(roundi((game.flush.clock-float(wave.at))*120),0,wave.witness.size()-1)
						steering = wave.witness[index]
					for substep in range(120/hz): game.flush.tick(game,1.0/120,steering,true,true)
					assert(game.health == initial,"Replayed keyboard escape must not require invulnerability or damage")
				assert(game.flush.debris.safety_failures == 0 and game.flush.damage_taken == 0)
				assert(game.flush.debris.spawned == {"easy":16,"normal":36,"hard":60}[mode])
				assert(game.flush.shots_fired == 0)
				assert(game.flush.debris.ledger.all(func(wave: Dictionary) -> bool: return wave.inherited_contacts.is_empty()))
				game.queue_free()
				await process_frame
	print("PASS: real movement replays eight-way escape commands without damage for both heroes/all modes at 60/120Hz, seed913")
	quit()
