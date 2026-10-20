extends SceneTree

class EntranceGame:
	extends "res://scripts/integrated_first_call.gd"
	var selected_entrance := 0.0

	func choose_entrance() -> void:
		for offset in range(0,385,48):
			var x := floorf(camera_x)-24-entrance_radius()-19-offset
			if super.safe_entrance(x):
				selected_entrance = x
				return
		assert(false,"Fixture needs a safe rear entrance")

	func safe_entrance(x: float) -> bool:
		# Isolate one real, safe entrance so an alternate cannot hide a blocked admission.
		return is_equal_approx(x,selected_entrance) and super.safe_entrance(x)

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(1))
	var game = EntranceGame.new()
	game.difficulty = "hard"
	game.seed_override = 7
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.player = Vector2(4100,394)
	game.camera_x = 3780
	game.choose_entrance()
	assert(game.safe_entrance(game.selected_entrance))
	var event: Dictionary = game.run_plan.later[0].duplicate(true)
	event.trigger = 3500
	event.end = 4650
	event.side = -1.0
	game.run_plan.later = [event]
	for scenario in ["high","diving","ground","cap"]:
		game.actors.clear()
		game.enemies.clear()
		game.swarms.actors.clear()
		game.encounter_states[event.id] = "pending"
		game.wave_clock = 10
		game.last_wave_admission = 0
		game.next_wave_spawn = 0
		var role := "runner" if scenario == "ground" else "aggressive_flyer"
		var height := 250.0 if scenario in ["high","cap"] else 440.0
		game.create_actor({"id":"spacing-fixture","role":role,"warning_seconds":0.8},
			Vector2(game.selected_entrance+19,height))
		if scenario == "cap":
			for index in range(5):
				game.create_actor({"id":"cap-%d" % index,"role":"runner","warning_seconds":0.8},
					Vector2(4100+index*50,440))
			assert(game.ordinary_population() == game.crowd_limit())
		game.step_encounters(1.0/60.0)
		assert(game.enemies.size() == (1 if scenario == "high" else 0),scenario)
		assert(game.encounter_states[event.id] == ("spawned" if scenario == "high" else "pending"))
	game.queue_free()
	await process_frame
	print("PASS: actual entrance admission allows high Widow, blocks diving/ground bodies and preserves crowd cap")
	quit()
