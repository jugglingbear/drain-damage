extends SceneTree
const Campaign = preload("res://scripts/campaign_encounters.gd")
const Game = preload("res://scripts/integrated_first_call.gd")
var checks := 0
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	checks += 1
	if not value and message not in failures: failures.append(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var campaign := Campaign.new()
	var original := JSON.stringify(campaign.contract)
	var selections := {}
	var covered := {}
	var devil_coverage := {}
	var angel_coverage := {}
	for seed in range(64):
		campaign.reset("normal", 85, seed)
		var chosen := campaign.entrance_variants(seed)
		selections[JSON.stringify(chosen)] = true
		check(chosen.size() == 5, "Exactly five added foreground slots")
		var baseline := campaign.specs.duplicate(true)
		var supports := campaign.variant_supports.duplicate(true)
		var count := 0
		for spec: Dictionary in baseline:
			if spec.entry.mode == "foreground": count += 1
			if chosen.has(spec.id): covered[spec.id] = true
			if spec.role == "aggressive_flyer" and spec.id != "campaign-approach-devil":
				if spec.variant == "devil":
					devil_coverage[spec.id] = true
					check(spec.entry.mode == "top" and spec.feet.y == 110, "Cuddlebug mounted top ingress")
					check(spec.devil_limits.x <= spec.feet.x and spec.devil_limits.y >= spec.feet.x,
						"Cuddlebug socket inside crawl support")
				else: angel_coverage[spec.id] = true
			if spec.role == "perched_shooter":
				check(spec.entry.mode in ["floor", "ceiling"], "Stationary shooter mount")
		check(count == 6, "Six foreground arrivals per run")
		for difficulty in ["easy", "normal", "hard"]:
			for origin in [85.0, 4650.0, 7650.0, 13800.0]:
				campaign.reset(difficulty, origin, seed)
				check(campaign.variant_supports == supports, "Run-owned supports survive checkpoint resets")
				check(campaign.specs == baseline, "Checkpoint/difficulty cannot reroll entrance choices")
		campaign.contract.encounters.reverse()
		check(chosen == campaign.entrance_variants(seed), "Encounter ordering cannot reroll")
		campaign.contract.encounters.reverse()
	check(devil_coverage.size() == 13, "Every authored angel slot eligible across seeds")
	check(angel_coverage.size() == 13, "Every eligible slot retains angel variety")
	check(selections.size() > 8, "Seeds produce varied combinations")
	check(covered.size() == 10, "Every candidate selected across seeds")
	check(original == JSON.stringify(campaign.contract), "Canonical data remains immutable")
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	var initial_seed: int = game.run_seed
	var initial_specs: Array = game.campaign.specs.duplicate(true)
	game.reset_game()
	check(game.run_seed == initial_seed, "Beginning retry retains the run seed")
	check(game.campaign.specs == initial_specs, "Beginning retry retains entrance choices")
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.paused = false
	game.life_state = "alive"
	game.grounded = true
	game.velocity = Vector2.ZERO
	game.campaign.reset("normal", 85, 42)
	# Test BOTH alternatives, not only the currently chosen five.
	for spec: Dictionary in game.campaign.specs:
		if not spec.has("arrival_variation"): continue
		for mode in ["floor", "foreground"]:
			var candidate := spec.duplicate(true)
			candidate.entry = {"mode":mode}
			candidate.depth = "foreground" if mode == "foreground" else ""
			var possible := false
			for hero_x in range(int(spec.trigger), int(spec.end), 5):
				game.player = Vector2(hero_x, 394)
				game.camera_x = clampf(hero_x - 320, 0, 14240)
				if game.in_pressure_dip() or game.crossing_reserved(): continue
				if spec.feet.x < game.camera_x + 40 or spec.feet.x > game.camera_x + 920: continue
				var route: Dictionary = game.entry_route(candidate)
				if route.is_empty(): continue
				var shape: Rect2 = game.actor_shape({"role":"runner"})
				var body := Rect2(spec.feet + shape.position, shape.size)
				if body.grow(45).intersects(Rect2(game.player, game.PLAYER_SIZE)): continue
				var clear := true
				var supported := false
				for solid: Rect2 in game.actor_solids():
					if body.grow(-0.01).intersects(solid): clear = false
					if is_equal_approx(solid.position.y, spec.feet.y) and solid.position.x <= body.position.x and solid.end.x >= body.end.x:
						supported = true
				if not clear or not supported: continue
				check(route.home == spec.feet, "Destination unchanged")
				possible = true
				break
			check(possible, "Safe supported route " + spec.id + " " + mode)
	var route_coverage := {}
	for seed in range(64):
		game.campaign.reset("normal", 85, seed)
		for spec: Dictionary in game.campaign.specs:
			if spec.get("variant", "") != "devil" or route_coverage.has(spec.id): continue
			var possible := false
			for hero_x in range(int(spec.trigger), int(spec.end), 5):
				game.player = Vector2(hero_x, 394)
				game.camera_x = clampf(hero_x - 320, 0, 14240)
				if game.in_pressure_dip() or game.crossing_reserved(): continue
				if spec.feet.x < game.camera_x + 40 or spec.feet.x > game.camera_x + 920: continue
				if not game.entry_route(spec).is_empty():
					possible = true
					break
			check(possible, "Cuddlebug ingress feasible: " + spec.id)
			route_coverage[spec.id] = true
	check(route_coverage.size() == 14, "All thirteen substitutions and original devil tested")
	game.free()
	print("Campaign entrance variants: ", checks, " checks, ", failures.size(), " failures: ", failures)
	quit(0 if failures.is_empty() else 1)
