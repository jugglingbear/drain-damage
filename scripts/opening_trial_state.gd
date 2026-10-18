extends RefCounted
## Finite trial scheduler; no nodes, input, rendering, damage application or life changes.
## configure(layout, balance) validates/deep-copies data; false sets configuration_error.
## advance(delta, frozen) drives a 20-second gameplay clock; callers must freeze for UI/death.
## next_eligible() returns a copy. reserve(id) starts one warning and claims a visible/shooter
## slot; activate(id) requires warning + settle + role emergence time. Caller checks placement
## safety before both calls. cancel(id, reason) requeues without issuing or killing anything.
## mark_unavailable(id, reason) removes a pending role honestly; death/retire require active ID.
## begin_pattern(token, owner_id)/end_pattern(token) account independent threat patterns;
## callers explicitly group contact threats and keep actors harmless if begin_pattern fails.
## Activation alone does not grant an attack-pattern slot. add_bullet/remove_bullet track shots,
## including projectiles whose emitter has died. Geometry/visibility remain caller-owned.
## record_shot(id)/resolve_shot(id, hit) track friendly shots once; unresolved is not a miss.
## record_damage(amount, to_player=true) records actual applied damage, not attempted damage.
## results() returns a deep snapshot. At 20s every mutation freezes until reset().
## Issued = activated, active = live activated entities, reserved = harmless warnings.
## Deferred = eligible pending/canceled warnings; unavailable and retired are NOT kills.

const DURATION_SECONDS := 20.0
const WARNING_START_INTERVAL := 0.6
const EPSILON := 0.000001
const ROLE_ALIASES := {
	"rear_runner": "runner", "perched_shooter": "shooter",
	"floor_emerger": "emerger", "aggressive_flyer": "flyer",
}
const BUDGET_KEYS := {
	"visible": "visible_hostiles_including_entry_telegraphs",
	"shooters": "simultaneous_shooters",
	"bullets": "hostile_projectiles",
	"patterns": "simultaneous_independent_threat_patterns",
}
const HARD_CAPS := {"visible": 6, "shooters": 3, "bullets": 6, "patterns": 3}

var continuous_mode := false
var elapsed: float = 0.0
var finished: bool = false
var configuration_error: String = ""
var _configured: bool = false
var _frozen: bool = false
var _templates: Array[Dictionary] = []
var _events: Dictionary = {}
var _order: Array[String] = []
var _caps: Dictionary = {}
var _patterns: Dictionary = {}
var _bullets: Dictionary = {}
var _shots: Dictionary = {}
var _last_warning_start: float = -INF
var _last_activation: float = -1.0
var _damage_received: float = 0.0
var _damage_dealt: float = 0.0

func configure(layout: Dictionary, balance: Dictionary, continuous := false) -> bool:
	continuous_mode = continuous
	_configured = false
	configuration_error = ""
	_templates.clear()
	_caps.clear()
	var timeline: Variant = layout.get("timeline")
	var roles: Variant = balance.get("roles")
	var budgets: Variant = balance.get("budgets")
	if not timeline is Array or (not continuous and timeline.size() != 12) \
		or (continuous and (timeline.size() < 12 or timeline.size() > 256)):
		return _invalid("Trial requires 12 events; continuous routes support 12 to 256 finite events")
	if not roles is Dictionary or not budgets is Dictionary:
		return _invalid("Missing roles or budgets")
	for key: String in BUDGET_KEYS:
		var value: Variant = budgets.get(BUDGET_KEYS[key])
		if not _number(value) or value < 1 or value > HARD_CAPS[key] or value != floor(value):
			return _invalid("Invalid budget: " + key)
		_caps[key] = int(value)
	var ids: Dictionary = {}
	for raw: Variant in timeline:
		if not raw is Dictionary:
			return _invalid("Timeline event must be a dictionary")
		var id: Variant = raw.get("id")
		var role: Variant = raw.get("role")
		if not id is String or id.is_empty() or ids.has(id) or not role is String:
			return _invalid("Missing/duplicate event ID or invalid role")
		var canonical_role: String = ROLE_ALIASES.get(role, role)
		if not roles.has(canonical_role) or not roles[canonical_role] is Dictionary:
			return _invalid("Unknown role: " + role)
		var eligibility: Variant = raw.get("eligible_gameplay_second")
		var warning: Variant = raw.get("warning_seconds")
		var settle: Variant = raw.get("settle_seconds", 0.0)
		var emerge: Variant = roles[canonical_role].get("emerge_seconds", 0.0)
		if not _number(eligibility) or eligibility < 0 or eligibility >= DURATION_SECONDS:
			return _invalid("Invalid eligibility: " + id)
		for duration: Variant in [warning, settle, emerge]:
			if not _number(duration) or duration < 0:
				return _invalid("Invalid warning/settle/emergence: " + id)
		var event: Dictionary = raw.duplicate(true)
		event.canonical_role = canonical_role
		event.activation_delay = float(warning) + float(settle) + float(emerge)
		_templates.append(event)
		ids[id] = true
	_templates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.eligible_gameplay_second < b.eligible_gameplay_second)
	_configured = true
	reset()
	return true

func reset() -> void:
	elapsed = 0.0
	finished = false
	_frozen = false
	_events.clear()
	_order.clear()
	_patterns.clear()
	_bullets.clear()
	_shots.clear()
	_last_warning_start = -INF
	_last_activation = -1.0
	_damage_received = 0.0
	_damage_dealt = 0.0
	if not _configured: return
	for template: Dictionary in _templates:
		var event: Dictionary = template.duplicate(true)
		event.state = "pending"
		event.warning_started = -1.0
		event.activated_at = -1.0
		event.reason = ""
		_events[event.id] = event
		_order.append(event.id)

func advance(delta: float, frozen: bool = false) -> void:
	if not _configured or finished: return
	_frozen = frozen
	if frozen or not is_finite(delta) or delta < 0: return
	elapsed = elapsed + delta if continuous_mode else minf(elapsed + delta, DURATION_SECONDS)
	if not continuous_mode and elapsed >= DURATION_SECONDS:
		finished = true
		for event: Dictionary in _events.values():
			if event.state == "warning":
				event.state = "pending"
				event.reason = "Observation window ended during warning"
				_release_owner_patterns(event.id)
		# Owner freezes effects too; retain live actor patterns/bullets in the snapshot.

func next_eligible() -> Dictionary:
	if not _can_mutate() or not _warning_ready(): return {}
	for id: String in _order:
		if _can_reserve(_events[id]): return _events[id].duplicate(true)
	return {}

func reserve(id: String) -> bool:
	if not _can_mutate() or not _events.has(id) or not _warning_ready(): return false
	var event: Dictionary = _events[id]
	if not _can_reserve(event): return false
	event.state = "warning"
	event.warning_started = elapsed
	event.reason = ""
	_last_warning_start = elapsed
	return true

func activate(id: String) -> bool:
	if not _can_mutate() or not _events.has(id): return false
	var event: Dictionary = _events[id]
	if event.state != "warning": return false
	if elapsed + EPSILON < event.warning_started + event.activation_delay: return false
	event.state = "active"
	event.activated_at = elapsed
	_last_activation = elapsed
	return true

func cancel(id: String, reason: String = "Unsafe placement") -> bool:
	if not _can_mutate() or not _events.has(id) or _events[id].state != "warning": return false
	_events[id].state = "pending"
	_events[id].reason = reason
	_release_owner_patterns(id)
	return true

func use_runner_fallback(id: String) -> bool:
	# Only an unreserved continuous-route event may borrow the validated runner template.
	if not continuous_mode or not _can_mutate() or not _events.has(id): return false
	var event: Dictionary = _events[id]
	if event.state != "pending" or event.role not in ["perched_shooter", "floor_emerger"]: return false
	for template in _templates:
		if template.role != "runner": continue
		event.original_role = event.role
		event.role = "runner"
		event.canonical_role = "runner"
		event.warning_seconds = template.warning_seconds
		event.settle_seconds = template.get("settle_seconds",0.0)
		event.activation_delay = template.activation_delay
		event.fallback_reason = "No safe forward habitat before admission"
		return true
	return false

func mark_unavailable(id: String, reason: String) -> bool:
	if not _can_mutate() or not _events.has(id) or reason.is_empty(): return false
	if _events[id].state not in ["pending", "warning"]: return false
	_events[id].state = "unavailable"
	_events[id].reason = reason
	_release_owner_patterns(id)
	return true

func death(id: String) -> bool:
	return _finish_actor(id, "killed")

func retire(id: String) -> bool:
	return _finish_actor(id, "retired")

func begin_pattern(token: String, owner_id: String) -> bool:
	if not _can_mutate() or token.is_empty() or _patterns.has(token): return false
	if not _events.has(owner_id) or _events[owner_id].state not in ["warning", "active"]: return false
	if _patterns.size() >= _caps.patterns: return false
	_patterns[token] = owner_id
	return true

func end_pattern(token: String) -> bool:
	if not _can_mutate(): return false
	return _patterns.erase(token)

func add_bullet(token: String) -> bool:
	if not _can_mutate() or token.is_empty() or _bullets.has(token): return false
	if _bullets.size() >= _caps.bullets: return false
	_bullets[token] = true
	return true

func remove_bullet(token: String) -> bool:
	if not _can_mutate(): return false
	return _bullets.erase(token)

func record_shot(id: String) -> bool:
	if not _can_mutate() or id.is_empty() or _shots.has(id): return false
	_shots[id] = "unresolved"
	return true

func resolve_shot(id: String, hit: bool) -> bool:
	if not _can_mutate() or not _shots.has(id) or _shots[id] != "unresolved": return false
	_shots[id] = "hit" if hit else "miss"
	return true

func record_damage(amount: float, to_player: bool = true) -> bool:
	if not _can_mutate() or not is_finite(amount) or amount < 0: return false
	if to_player: _damage_received += amount
	else: _damage_dealt += amount
	return true

func results() -> Dictionary:
	var report := {"elapsed": elapsed, "finished": finished, "configured": _configured,
		"total": _events.size(), "issued": 0, "killed": 0, "retired": 0, "active": 0,
		"reserved": 0, "deferred": 0, "unavailable": 0, "not_yet_eligible": 0,
		"visible": 0, "shooters": 0, "patterns": _patterns.size(), "bullets": _bullets.size(),
		"damage": _damage_received, "damage_dealt": _damage_dealt,
		"shots": _shots.size(), "hits": 0, "misses": 0, "unresolved_shots": 0,
		"last_spawn_time": _last_activation, "events": []}
	for id: String in _order:
		var event: Dictionary = _events[id]
		if event.activated_at >= 0: report.issued += 1
		match event.state:
			"active", "killed", "retired", "unavailable": report[event.state] += 1
			"warning": report.reserved += 1
			"pending":
				if elapsed + EPSILON >= event.eligible_gameplay_second: report.deferred += 1
				else: report.not_yet_eligible += 1
		if event.state in ["warning", "active"]:
			report.visible += 1
			if event.canonical_role == "shooter": report.shooters += 1
		report.events.append(event.duplicate(true))
	for outcome: String in _shots.values():
		if outcome == "hit": report.hits += 1
		elif outcome == "miss": report.misses += 1
		else: report.unresolved_shots += 1
	return report

func _warning_ready() -> bool:
	if elapsed + EPSILON < _last_warning_start + WARNING_START_INTERVAL: return false
	for event: Dictionary in _events.values():
		if event.state == "warning": return false
	return true

func _can_reserve(event: Dictionary) -> bool:
	if event.state != "pending" or elapsed + EPSILON < event.eligible_gameplay_second: return false
	var counts := results()
	if counts.visible >= _caps.visible: return false
	if event.canonical_role == "shooter" and counts.shooters >= _caps.shooters: return false
	return true

func _finish_actor(id: String, state: String) -> bool:
	if not _can_mutate() or not _events.has(id) or _events[id].state != "active": return false
	_events[id].state = state
	_release_owner_patterns(id)
	return true

func _release_owner_patterns(id: String) -> void:
	for token: String in _patterns.keys():
		if _patterns[token] == id: _patterns.erase(token)

func _can_mutate() -> bool:
	return _configured and not finished and not _frozen

func _invalid(message: String) -> bool:
	configuration_error = message
	reset()
	return false

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
