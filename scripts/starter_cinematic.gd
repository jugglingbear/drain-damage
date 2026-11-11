extends RefCounted
## Presentation-only clock; the host owns spending, world freeze and effect handoff.
const DURATIONS := {"tony":3.2,"sean":3.4}
const COMPLETION_EPSILON := 0.0000000001
var active := false
var elapsed := 0.0
var hero_id := ""
var _completion := ""

func begin(hero: String) -> bool:
	if active or not _completion.is_empty() or not DURATIONS.has(hero): return false
	hero_id = hero
	elapsed = 0.0
	active = true
	return true

func advance(delta: float, paused := false) -> void:
	if not active or paused or not is_finite(delta) or delta <= 0: return
	var duration: float = DURATIONS[hero_id]
	# Absorb accumulated floating-point roundoff at an exact frame boundary only.
	if delta+COMPLETION_EPSILON >= duration-elapsed:
		elapsed = duration
		active = false
		_completion = hero_id
	else:
		elapsed += delta

func take_completion() -> String:
	var completed := _completion
	_completion = ""
	return completed

func cancel() -> void:
	active = false
	elapsed = 0.0
	hero_id = ""
	_completion = ""
