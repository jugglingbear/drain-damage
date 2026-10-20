extends SceneTree
const Route = preload("res://scripts/clogfather_route.gd")
const Plan = preload("res://scripts/difficulty_plan.gd")
const Level = preload("res://scripts/opening_trial_level.gd")

func _initialize() -> void:
	for mode in Plan.IDS:
		for seed_value in range(100):
			var plan := Plan.resolve(mode,seed_value)
			var baseline: Dictionary = plan.duplicate(true)
			Route.append_plan(plan)
			assert(plan.later.size() == baseline.later.size()+(12 if mode == "easy" else 25))
			for index in range(baseline.later.size()):
				assert(plan.later[index] == baseline.later[index],"Existing event changed")
			for key in baseline:
				if key != "later": assert(plan[key] == baseline[key])
			var ids: Dictionary = {}
			for event in plan.later:
				assert(not ids.has(event.id),"Duplicate encounter")
				ids[event.id] = true
				if not event.id.begins_with("clog-approach-"): continue
				assert(event.enabled and event.wave == 4 and event.owner_origin == 4650)
				assert(event.trigger >= 9500 and event.trigger < event.end)
				assert(event.end <= Route.CONTAINMENT and event.end < Route.CHECKPOINT)
				if event.id.ends_with("-extra"): assert(event.role == "runner")
			var once: Dictionary = plan.duplicate(true)
			Route.append_plan(plan)
			assert(plan == once,"Repeated integration duplicated route")
	var level := Level.new()
	level.width = Route.WORLD_WIDTH
	level.plinths.assign(Route.SOLIDS)
	level.decks.assign(Route.LEDGES)
	for solid in Route.SOLIDS:
		assert(solid.end.y == 440 and solid.end.x < Route.CONTAINMENT)
		assert(level.projectile_solids().has(solid))
	for ledge in Route.LEDGES:
		assert(not level.projectile_solids().has(ledge),"One-way ledge blocks fire")
	for slot in Route.SWARMS:
		assert(slot.bounds.grow(-48).has_point(slot.home))
		assert(slot.bounds.end.x < Route.CONTAINMENT)
		for solid in Route.SOLIDS:
			assert(not solid.grow(48).intersects(slot.bounds.grow(-48)),"Swarm lane clips solid")
	assert(Route.COMPLETION_X > Route.ARENA_END and Route.COMPLETION_X < Route.WORLD_WIDTH)
	print("PASS: Clogfather route; 300 seed/mode plans, idempotence, ownership and geometry")
	quit()
