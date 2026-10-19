extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			for dodge in [false,true]:
				var game = Game.new()
				game.employee = game.Crew.EMPLOYEES[hero]
				game.difficulty = mode
				game.seed_override = 42
				root.add_child(game)
				game.hide()
				game.set_process(false)
				game.set_physics_process(false)
				game.dialogue.finish()
				game.dialogue.release_guard = 0
				game.dispenser.cancel()
				game.player = Vector2(6570+450,394)
				var room = game.skitterling
				room.entered = true
				var boss = room.encounter
				boss.active = true
				boss.phase = "alligator"
				boss.hp = boss.PHASE_HP
				boss.position = Vector2(780,440)
				boss._enter("alligator_water_dive")
				game.boss_hud.begin_encounter("cockroach-swarm")
				var hits := 0
				var kinds := {}
				var locked: Array = []
				var dodge_origin: float = game.player.x
				var dodge_destination: float = game.player.x
				for tick in range(120*15):
					if boss.volley_targets.size() == 6 and locked.is_empty():
						locked = boss.volley_targets.duplicate()
						dodge_origin = game.player.x
						var best_clearance := -1.0
						for offset in [-180.0, 180.0]:
							var clearance := INF
							for target_x: float in locked:
								clearance = minf(clearance, absf(dodge_origin - 6570 + offset - target_x))
							if clearance > best_clearance:
								best_clearance = clearance
								dodge_destination = dodge_origin + offset
					if dodge and not locked.is_empty() and (boss.state == "alligator_debris" and boss.elapsed >= 1.3):
						game.player.x = move_toward(game.player.x, dodge_destination, game.employee.move_speed / 120)
					game.health = game.employee.max_health
					game.invulnerable = 0
					var before_shots: int = boss.snapshot().throw_count
					var fire_target: float = clampf(game.player.x - 6570 + game.PLAYER_SIZE.x / 2, 133, 827)
					room.advance(game,1.0/120)
					assert(boss.hazards.size() <= 6)
					if game.health < game.employee.max_health: hits += 1
					for hazard: Dictionary in boss.hazards:
						kinds[hazard.kind] = true
						if hazard.kind == "aimed_arc":
							assert(hazard.target_x == boss.volley_targets[5])
							if before_shots == 5: assert(is_equal_approx(hazard.target_x, fire_target))
					if boss.state == "alligator_surface_swim": break
				assert(kinds.size() == 2 and locked.size() == 6)
				assert(hits == 0 if dodge else hits > 0, "Committed volley must punish waiting and allow movement")
				# The scene clips damage to the real rendered jaw; stationary floor contact must still hurt.
				boss.position = Vector2(176,440)
				game.player = Vector2(6570+450,394)
				boss._enter("alligator_charge_tell")
				var snapped := false
				for tick in range(120*4):
					game.health = game.employee.max_health
					game.invulnerable = 0
					room.advance(game,1.0/120)
					if game.health < game.employee.max_health: snapped = true
					if boss.state == "alligator_charge_turn": break
				assert(snapped,"Visible charge jaws must hurt through the real art/room adapter")
				game.queue_free()
				await process_frame
	print("PASS: both heroes/all modes scene-adapted six-shot volley, dodges, fire-time aim and visible jaw charges")
	quit()
