extends SceneTree
## Headless: Godot --headless --path . --script tests/opening_trial_state.gd
const State = preload("res://scripts/opening_trial_state.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func fixture(role: String = "runner") -> Dictionary:
	var events: Array = []
	for index in range(12):
		events.append({"id": "e%d" % index, "role": role,
			"eligible_gameplay_second": 0.0, "warning_seconds": 0.1, "settle_seconds": 0.0})
	return {"timeline": events}

func balance() -> Dictionary:
	return {"roles": {"runner": {}, "shooter": {}, "emerger": {"emerge_seconds": 0.35}, "flyer": {}},
		"budgets": {"visible_hostiles_including_entry_telegraphs": 6,
		"simultaneous_shooters": 3, "hostile_projectiles": 6,
		"simultaneous_independent_threat_patterns": 3}}

func spawn_actor(state: RefCounted, id: String) -> void:
	assert(state.reserve(id))
	state.advance(0.1)
	assert(state.activate(id))
	state.advance(0.5)

func run_checks() -> void:
	var state := State.new()
	assert(state.next_eligible().is_empty())
	assert(not state.reserve("missing"))
	assert(state.configure(fixture(), balance()))
	var copy: Dictionary = state.next_eligible()
	copy.id = "mutated"
	assert(state.next_eligible().id == "e0", "Inspection cannot mutate scheduler")
	assert(state.reserve("e0"))
	assert(state.results().visible == 1 and state.results().issued == 0)
	assert(not state.activate("e0"), "Warnings must finish")
	assert(not state.reserve("e1"), "Only one warning at a time")
	state.advance(5.0, true)
	assert(state.elapsed == 0 and not state.activate("e0"))
	assert(not state.cancel("e0") and not state.record_shot("paused"))
	state.advance(0.1, false)
	assert(state.activate("e0"))
	assert(not state.activate("e0"), "Activation is idempotent")
	assert(not state.reserve("e1"), "Warning start spacing applies after activation")
	state.advance(0.5)
	assert(state.reserve("e1"))
	assert(state.cancel("e1", "Occupied landing"))
	assert(not state.reserve("e1"), "Cancel cannot cause immediate warning spam")
	state.advance(0.6)
	assert(state.reserve("e1"))
	state.advance(0.1)
	assert(state.activate("e1"))
	assert(state.results().issued == 2)
	assert(state.retire("e1"))
	assert(not state.death("e1"))
	assert(state.results().retired == 1 and state.results().killed == 0)
	assert(state.begin_pattern("p0", "e0"))
	assert(not state.begin_pattern("p0", "e0"))
	assert(state.begin_pattern("p1", "e0") and state.begin_pattern("p2", "e0"))
	assert(not state.begin_pattern("p3", "e0"))
	for index in range(6): assert(state.add_bullet("b%d" % index))
	assert(not state.add_bullet("overflow") and not state.add_bullet("b0"))
	assert(state.death("e0"))
	assert(not state.death("e0"))
	assert(state.results().patterns == 0 and state.results().bullets == 6,
		"Emitter death releases patterns, not its live bullets")
	assert(state.remove_bullet("b0") and not state.remove_bullet("b0"))
	assert(state.add_bullet("replacement"))
	assert(state.record_shot("hit") and state.resolve_shot("hit", true))
	assert(not state.resolve_shot("hit", false))
	assert(state.record_shot("miss") and state.resolve_shot("miss", false))
	assert(state.record_shot("inflight"))
	assert(state.record_damage(1) and state.record_damage(24, false))
	assert(not state.record_damage(-1) and not state.record_damage(NAN))
	assert(state.mark_unavailable("e2", "Missing art"))
	assert(not state.mark_unavailable("e3", ""))
	state.advance(100)
	var report: Dictionary = state.results()
	assert(report.elapsed == 20 and report.finished)
	assert(report.issued == 2 and report.killed == 1 and report.retired == 1)
	assert(report.unavailable == 1 and report.deferred == 9)
	assert(report.shots == 3 and report.hits == 1 and report.misses == 1 and report.unresolved_shots == 1)
	assert(report.damage == 1 and report.damage_dealt == 24)
	assert(not state.remove_bullet("b1") and not state.record_damage(10))
	assert(not state.resolve_shot("inflight", false))
	state.advance(1)
	assert(state.results() == report, "Results freeze at observation end")
	report.events.clear()
	assert(state.results().events.size() == 12, "Reports are detached copies")
	state.reset()
	assert(state.elapsed == 0 and state.results().issued == 0 and state.results().shots == 0)
	assert(state.results().bullets == 0 and state.results().damage == 0)
	for index in range(6): spawn_actor(state, "e%d" % index)
	assert(state.results().visible == 6 and state.next_eligible().is_empty())
	assert(not state.reserve("e6"))
	assert(state.death("e2") and state.reserve("e6"))
	assert(state.results().visible == 6, "Warnings consume population slots")
	state.advance(100)
	assert(state.results().reserved == 0 and state.results().deferred == 6)
	assert(state.results().active == 5 and state.results().issued == 6)
	assert(state.configure(fixture("perched_shooter"), balance()))
	spawn_actor(state, "e0")
	spawn_actor(state, "e1")
	assert(state.reserve("e2") and state.results().shooters == 3)
	state.advance(0.6)
	assert(not state.reserve("e3"), "Warning shooter consumes the third slot")
	assert(state.activate("e2"))
	assert(not state.reserve("e3"), "Three live shooters fill the cap")
	assert(state.retire("e0") and state.reserve("e3"))
	var emerger := fixture("floor_emerger")
	emerger.timeline[0].warning_seconds = 0.8
	emerger.timeline[0].settle_seconds = 0.3
	assert(state.configure(emerger, balance()))
	assert(state.reserve("e0"))
	state.advance(1.44)
	assert(not state.activate("e0"))
	state.advance(0.01)
	assert(state.activate("e0"), "Emerger activation includes emergence and harmless settling")
	assert(state.begin_pattern("active-at-end", "e0"))
	state.advance(100)
	assert(state.results().patterns == 1, "Snapshot retains active threats")
	var original := fixture()
	assert(state.configure(original, balance()))
	original.timeline[0].eligible_gameplay_second = 19
	assert(state.next_eligible().id == "e0", "Configuration is deep copied")
	assert(state.reserve("e0") and state.begin_pattern("warning", "e0"))
	assert(state.cancel("e0"))
	assert(state.results().patterns == 0)
	assert(state.mark_unavailable("e0", "No safe route"))
	state.advance(0.6)
	assert(state.next_eligible().id == "e1", "Unavailable event does not block later roles")
	var bad := fixture()
	bad.timeline[1].id = "e0"
	assert(not state.configure(bad, balance()))
	assert(not state.configuration_error.is_empty() and not state.reserve("e0"))
	bad = fixture()
	bad.timeline[0].eligible_gameplay_second = NAN
	assert(not state.configure(bad, balance()))
	var bad_budget := balance()
	bad_budget.budgets.hostile_projectiles = 7
	assert(not state.configure(fixture(), bad_budget))
	bad_budget = balance()
	bad_budget.budgets.simultaneous_shooters = 4
	assert(not state.configure(fixture(), bad_budget))
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://handoffs/opening-trial-level-layout.json"))
	var tuning: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://design/first-call-action/opening-trial-balance.json"))
	assert(state.configure(layout, tuning))
	assert(state.next_eligible().is_empty())
	state.advance(-1)
	state.advance(NAN)
	assert(state.elapsed == 0)
	# Exercise the real twelve-event timeline without unsafe instant activations.
	for step in range(1200):
		state.advance(1.0 / 60.0)
		for event: Dictionary in state.results().events:
			if event.state == "warning" and state.activate(event.id):
				assert(state.death(event.id))
		var next: Dictionary = state.next_eligible()
		if not next.is_empty(): assert(state.reserve(next.id))
	state.advance(0.001)
	assert(state.finished and state.results().issued == 12 and state.results().killed == 12)
	assert(state.results().deferred == 0)
	print("PASS: trial timing, freeze/reset, warning spacing, all budgets, lifecycle, honest results, real 12-event schedule")
	quit()
