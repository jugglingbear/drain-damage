extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for mode in ["normal"]:
		for hero in [0,1]:
			for seed_value in [7,42,913]:
				var game = Game.new()
				game.difficulty = mode
				game.seed_override = seed_value
				game.employee = game.Crew.EMPLOYEES[hero]
				root.add_child(game)
				game.hide()
				game.set_process(false)
				game.set_physics_process(false)
				game.dialogue.finish()
				game.dialogue.release_guard = 0
				game.invulnerable = 1000
				Input.action_press("right")
				Input.action_press("shoot")
				var seen: Dictionary = {}
				var bins: Dictionary = {}
				var fine: Dictionary = {}
				var hz := 60 if seed_value == 7 else 120
				for tick in range(120*hz):
					if game.grounded:
						for solid: Rect2 in game.trial_level.plinths:
							var gap: float = solid.position.x-(game.player.x+26)
							if gap >= 0 and gap < 70 and solid.position.y < game.player.y+46:
								game.jump_buffer = 0.14
					Input.action_press("right")
					for actor in game.actors:
						if actor.role == "aggressive_flyer" and actor.hp > 0: Input.action_release("right")
						if actor.role == "aggressive_flyer" and actor.hp > 0 and actor.age >= 4.0:
							game.damage_trial_actor(actor, actor.hp)
					game._physics_process(1.0/hz)
					if game.dispenser.active: game.dispenser.tick(game,0.1)
					var bin_id := int(game.player.x/1900)
					if not bins.has(bin_id): bins[bin_id] = {"ticks":0,"population":0,"visible":0,"empty":0}
					var visible := 0
					for actor in game.actors:
						if actor.hp > 0 and actor.feet.x >= game.camera_x and actor.feet.x <= game.camera_x+960: visible += 1
						if not seen.has(actor.event_id):
							seen[actor.event_id] = true
							if actor.role == "aggressive_flyer": print("WIDOW hero",hero," seed",seed_value," id",actor.event_id," x",game.player.x," t",float(tick)/hz)
					for enemy in game.enemies:
						if enemy.hp > 0 and enemy.pos.x >= game.camera_x and enemy.pos.x <= game.camera_x+960: visible += 1
					bins[bin_id].ticks += 1
					bins[bin_id].population += game.crowd_population()
					bins[bin_id].visible += visible
					if visible == 0: bins[bin_id].empty += 1
					var fine_id := -1
					var edges := [3120,4450,4850,5730,7600,9451]
					for section in range(5):
						if game.player.x >= edges[section] and game.player.x < edges[section+1]: fine_id = section
					if fine_id >= 0:
						if not fine.has(fine_id):
							fine[fine_id] = {"ticks":0,"visible":0,"empty":0,"empty_run":0,"longest_empty":0,"warnings":0,"all_visible":0,"all_empty":0}
						var sample: Dictionary = fine[fine_id]
						sample.ticks += 1
						sample.visible += visible
						var all_visible := visible
						for swarm in game.swarms.actors:
							if swarm.hp > 0 and swarm.pos.x+48 >= game.camera_x and swarm.pos.x-48 <= game.camera_x+960:
								all_visible += 1
						sample.all_visible += all_visible
						if all_visible == 0: sample.all_empty += 1
						sample.warnings += game.trial_state.results().reserved
						if visible == 0:
							sample.empty += 1
							sample.empty_run += 1
							sample.longest_empty = maxi(sample.longest_empty,sample.empty_run)
						else: sample.empty_run = 0
					if game.won: break
					var report: Dictionary = game.trial_state.results()
					assert(report.shooters <= 3 and report.bullets <= 6 and report.patterns <= 3)
					assert(game.crowd_population() <= game.run_plan.crowd_cap)
					var widows := 0
					for actor in game.actors:
						if actor.hp > 0 and actor.role == "aggressive_flyer": widows += 1
					assert(widows <= 1)
					if widows > 0: assert(game.crowd_population() <= 6)
				print("FINE hero",hero," seed",seed_value," ",JSON.stringify(fine))
				print("FALLBACKS ",JSON.stringify(game.get("route_fallbacks")))
				print("BINS hero",hero," seed",seed_value," ",JSON.stringify(bins))
				assert(game.won and game.player.x >= 9450)
				print("MODE ",mode," hero",hero," seed",seed_value," x",game.player.x,
					" issued",game.trial_state.results().issued," waves",game.wave_spawned)
				Input.action_release("right")
				Input.action_release("shoot")
				# Moving checkpoint respawn intentionally bypasses short4700 tail during grace.
				game.checkpoint_active = true
				game.checkpoint_index = 0
				game.respawn_point = Vector2(4650,394)
				game.respawn_after_death()
				game.dispenser.cancel()
				for tick in range(hz*2):
					game.player.x = 4650+game.employee.move_speed*float(tick+1)/hz
					game.camera_x = game.player.x-320
					var before: int = game.crowd_population()
					game.step_encounters(1.0/hz)
					if float(tick+1)/hz < 1.25: assert(game.crowd_population() == 0)
					assert(game.crowd_population()-before <= 1)
				assert(game.encounter_states[game.run_plan.later[7].id] == "bypassed")
				game.queue_free()
				await process_frame
	await create_timer(0.3).timeout
	print("PASS:6Normal/hero/seed traversals60/120Hz,all caps,unique Widow,moving respawn grace and safe tail bypass")
	quit()
