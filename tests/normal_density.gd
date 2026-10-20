extends SceneTree
const Plan = preload("res://scripts/difficulty_plan.gd")
const Game = preload("res://scripts/integrated_first_call.gd")
const SIGNATURES := {
	"easy":"5b4ea38c6b2d30421cfa83c4af0ccc67fa80af382e12bdea4054ff7416ab6537",
	"hard":"25cd8e95a8563cdb97b2f1f8954705bffb5dc412a76260fe6d3f55a4f9c87fe2",
	"normal":"5a0f833255738e9a5f8d776f5bde5fbf73ced3ebbafd4c9a4fe4d944e8dc698d"}

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for mode in SIGNATURES:
		var values: Array = []
		for seed_value in range(100):
			var plan := Plan.resolve(mode,seed_value)
			var opening_added: int = plan.opening.filter(func(e: Dictionary) -> bool: return e.id.ends_with("-extra")).size()
			var later_added: int = plan.later.filter(func(e: Dictionary) -> bool: return e.id.ends_with("-extra")).size()
			assert(opening_added == (0 if mode == "easy" else 3))
			assert(later_added == (0 if mode == "easy" else 4 if mode == "normal" else 7))
			for event in plan.later:
				if event.id.ends_with("-extra"):
					assert(event.trigger < 5610 or event.trigger >= 7530)
			plan.opening = plan.opening.filter(func(e: Dictionary) -> bool: return not e.id.ends_with("-extra"))
			plan.later = plan.later.filter(func(e: Dictionary) -> bool: return not e.id.ends_with("-extra"))
			if mode != "easy":
				var baseline: int = plan.opening.size()+9
				for event in plan.later:
					if event.trigger < 5610 or event.trigger >= 7530: baseline += 1
				assert(opening_added+later_added+(4 if mode == "normal" else 2) == ceili(baseline*0.25))
			values.append(plan.opening if mode == "normal" else plan)
		assert(JSON.stringify(values).sha256_text() == SIGNATURES[mode], "Preserve approved plans")
	var game = Game.new()
	game.seed_override = 42
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	assert(game.trial_state.results().total == 49)
	assert(game.actor_world_limit() == 9600)
	# Remaining route roles have safe homes; replaced entries stay unavailable.
	for slot in game.run_plan.later:
		game.reset_observation()
		game.swarms.actors.clear()
		game.skitterling.released = true
		if slot.trigger >= 5610 and slot.trigger < 7530:
			assert(game.encounter_states[slot.id] == "excluded")
			for item in game.trial_state.results().events:
				if item.id == slot.id: assert(item.state == "unavailable")
			continue
		game.player = Vector2(slot.trigger,394)
		game.camera_x = game.player.x-320
		game.velocity = Vector2.ZERO
		var event: Dictionary = {}
		for item in game.trial_state.results().events:
			if item.id == slot.id: event = item
		var home: Vector2 = game.route_home(event)
		if slot.role in ["perched_shooter","floor_emerger"]:
			assert(home != Vector2.INF, "Authored habitat must support " + slot.id)
		if home != Vector2.INF:
			assert(game.position_safe(home,event.role) and game.route_clearance(home,event.role))
	# Moving heroes retain the full landing exclusion; farther safe floor stays visibly warned.
	for speed in [235.0,270.0]:
		game.reset_observation()
		game.swarms.actors.clear()
		game.skitterling.released = true
		game.player = Vector2(7900,394)
		game.camera_x = 7580
		game.velocity = Vector2(speed,0)
		var home: Vector2 = game.route_home({"role":"floor_emerger"})
		assert(home != Vector2.INF and absf(home.x-(7900+speed*1.45)) >= 160)
	# Warning safety survives a stop, reversal or jump onto the chosen home; no underfoot activation.
	for role_id in ["normal-route-01","normal-route-03"]:
		for motion in [Vector2.ZERO,Vector2(-270,0),Vector2(0,-465)]:
			game.reset_observation()
			game.swarms.actors.clear()
			game.player = Vector2(3250 if role_id.ends_with("01") else 3650,394)
			game.camera_x = game.player.x-320
			game.velocity = Vector2(270,0)
			var event: Dictionary = {}
			for item in game.trial_state.results().events:
				if item.id == role_id: event = item
			var home: Vector2 = game.route_home(event)
			assert(home != Vector2.INF)
			assert(game.trial_state.reserve(event.id))
			game.create_actor(event,home)
			var actor: Dictionary = game.actors[0]
			game.player = home-Vector2(13,46)
			game.camera_x = home.x-600
			game.velocity = motion
			for tick in range(100):
				game.trial_state.advance(0.02)
				game.step_trial_actors(0.02)
				assert(not actor.active, "Live safety must hold an occupied warning marker")
			game.player.x = home.x-300
			game.trial_state.advance(0.02)
			game.step_trial_actors(0.02)
			assert(actor.active, "A cleared marker may activate after its full warning")
	# Pending/canceled warnings expire without kills, and never reserve after their window.
	game.reset_observation()
	game.swarms.actors.clear()
	game.player = Vector2(3300,394)
	game.camera_x = 2980
	game.step_encounters(2)
	assert(game.actors.size() == 1 and game.actors[0].role == "perched_shooter")
	var id: String = game.actors[0].event_id
	assert(game.trial_state.cancel(id,"test cancellation"))
	game.actors.clear()
	game.player.x = 3900
	game.camera_x = 3580
	game.step_encounters(0)
	assert(game.encounter_states[id] == "bypassed" and game.trial_state.results().killed == 0)
	# Authored approach/room replaces scenery and ordinary admission, even with overdue events.
	for position in [5610.0,6000.0,6570.0,7000.0,7529.0]:
		game.reset_observation()
		game.skitterling.released = false
		game.swarms.actors.clear()
		game.player = Vector2(position,394)
		game.camera_x = position-320
		game.step_encounters(10)
		assert(game.actors.is_empty() and game.enemies.is_empty())
		assert(game.wave_spawned == [0,0,0,0])
	for solid: Rect2 in game.trial_level.plinths:
		assert(solid.end.x <= 5610 or solid.position.x >= 7530)
	# Fallback borrows validated runner timing and cannot rewrite a warning or active actor.
	game.reset_observation()
	assert(game.trial_state.use_runner_fallback("normal-route-01"))
	assert(game.trial_state.reserve("normal-route-01"))
	assert(not game.trial_state.use_runner_fallback("normal-route-01"))
	for item in game.trial_state.results().events:
		if item.id == "normal-route-01":
			assert(item.role == "runner" and item.original_role == "perched_shooter")
	# Pacing target counts visible/incoming bodies, independently of the safety cap.
	game.reset_observation()
	game.swarms.actors.clear()
	game.skitterling.released = true
	game.player = Vector2(7900,394)
	game.camera_x = 7580
	for item in game.trial_state.results().events:
		if item.id in ["opening-01","opening-02"]:
			game.create_actor(item,Vector2(8100+game.actors.size()*60,440))
	assert(game.route_pressure() == 2)
	game.step_encounters(2)
	assert(game.wave_spawned == [0,0,0,0])
	game.reset_observation()
	game.swarms.actors.clear()
	game.player = Vector2(3500,394)
	game.camera_x = 3180
	for item in game.trial_state.results().events:
		if item.id in ["opening-01","opening-02"]:
			game.create_actor(item,Vector2(3000+game.actors.size()*60,440))
	assert(game.route_pressure() == 2)
	game.step_encounters(2)
	assert(game.crowd_population() == 3, "First continuation may admit a third committed threat")
	game.step_encounters(2)
	assert(game.crowd_population() == 3, "Early target does not create an unbounded backlog")
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("PASS:100seed immutable plans,49event route,habitats/world bounds,canceled expiry,fallback and density backpressure")
	quit()
