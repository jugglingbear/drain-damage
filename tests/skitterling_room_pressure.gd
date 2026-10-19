extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var cases := 0
	for mode in ["easy", "normal", "hard"]:
		for hero in [0, 1]:
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
			var room = game.skitterling
			for x in [120.0, 450.0, 814.0]:
				room.entered = true
				room.released = false
				room.encounter.configure(42)
				game.player = room.ORIGIN + Vector2(x, 394)
				room.encounter.start(room.hero_rect(game))
				game.boss_hud.begin_encounter("cockroach-swarm")
				game.invulnerable = 0
				var hits := 0
				for tick in range(60 * 60):
					# Heal only to measure repeated exposure; preserve the normal 1.5-second immunity.
					game.player = room.ORIGIN + Vector2(x, 394)
					game.health = game.employee.max_health
					game.invulnerable = maxf(0, game.invulnerable - 1.0 / 60)
					room.advance(game, 1.0 / 60)
					if game.health < game.employee.max_health: hits += 1
				assert(hits >= 5, "Passive safe spot: %s hero%d x%d hits%d" % [mode, hero, x, hits])
				print("PRESSURE: ", mode, " hero", hero, " x", x, " hits", hits)
				cases += 1
			var boss = room.encounter
			boss.position = Vector2(480, 440)
			boss._enter("rat_pipe_retreat")
			for elapsed in [0.0, .2, .4, .6, .7]:
				boss.elapsed = elapsed
				var baseline: Rect2 = room.target_rect()
				var first: Array[Rect2] = room.target_regions()
				assert(first == room.target_regions(), "Retreat targeting must be draw-independent")
				for region: Rect2 in first: assert(baseline.encloses(region))
				if elapsed == .7: assert(first.is_empty(), "Concealed insects cannot be shot")
			var started := Time.get_ticks_usec()
			for sample in range(30):
				boss.elapsed = sample * .7 / 30
				room.target_regions()
			print("Retreat target query mean ms: ", (Time.get_ticks_usec() - started) / 30000.0)
			game.queue_free()
			await process_frame
	print("PASS: ", cases, " real-room stationary cases, both heroes/all modes/corners/center; retreat targets")
	quit()
