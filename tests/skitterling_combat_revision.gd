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
				var hits := {}
				var upward_hits := {}
				var committed: Array = []
				var last_column := 0.0
				for tick in range(120*35):
					if dodge and boss.state == "alligator_water_warning":
						var direction := -1 if boss.column_x > 450 else 1
						game.player.x = clampf(game.player.x+direction*game.employee.move_speed/120,6690,7384)
					if boss.state == "alligator_water_warning": last_column = boss.column_x
					var before: String = boss.state
					game.health = game.employee.max_health
					game.invulnerable = 0
					room.advance(game,1.0/120)
					assert(boss.hazards.size() <= 1)
					if before == "alligator_water_warning" and boss.state == "alligator_debris":
						committed.append(last_column)
					if not boss.hazards.is_empty():
						assert(boss.hazards[0].position.x == last_column,"No homing after warning")
						if game.health < game.employee.max_health:
							hits[boss.hazards[0].id] = true
							if not boss.hazards[0].descending: upward_hits[boss.hazards[0].id] = true
					if boss.state == "alligator_surface_swim": break
				assert(committed.size() == 3 and committed[0] != committed[1] and committed[1] != committed[2])
				assert(committed[0] != committed[2])
				assert(hits.is_empty() if dodge else upward_hits.size() == 3)
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
	print("PASS: both heroes/all modes scene-adapted three distinct upward hits, dodges, fixed columns and visible jaw charges")
	quit()
