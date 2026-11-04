extends "res://scripts/three_screen_trial_game.gd"
## Second authored trial section; combat and lifecycle remain shared with section 1.1.
const SECTION_CONTRACT_PATH := "res://levels/first-call/section-1-2.json"

func _init() -> void:
	contract = JSON.parse_string(FileAccess.get_file_as_string(SECTION_CONTRACT_PATH))

func event_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for authored: Dictionary in contract.event_specs:
		var spec := authored.duplicate(true)
		for key in ["feet","bounds","source"]:
			if spec.has(key): spec[key] = Vector2(spec[key][0],spec[key][1])
		specs.append(spec)
	return authored_entries(specs)

func configure_scene_art() -> void:
	# Preserve the approved atlas crops and move their supported geometry as one assembly.
	var pit: Array = contract.geometry.pit.opening_x
	var access: Array = contract.geometry.optional_route.steps[0]
	var catwalk: Array = contract.geometry.optional_route.catwalk
	var destinations := {
		"pit-depth":[pit[0],440,pit[1]-pit[0],100],
		"pit-left-rim":[pit[0]-32,440,32,32],
		"pit-right-rim":[pit[1],440,32,32],
		"access-deck":[access[0],access[1],access[2],16],
		"access-support":[access[0],access[1],access[2],440-access[1]],
		"catwalk-deck":catwalk,
		"catwalk-support":[catwalk[0],catwalk[1],catwalk[2],440-catwalk[1]],
	}
	for index in range(contract.geometry.mandatory_climb.solid_rects.size()):
		destinations["machinery-%d" % index] = contract.geometry.mandatory_climb.solid_rects[index]
	for spec in event_specs():
		if spec.depth == "background":
			destinations["pipe-back"] = [spec.source.x-32,spec.source.y-32,64,64]
			destinations["pipe-front-lip"] = [spec.source.x-32,spec.source.y,64,32]
	for item: Dictionary in scene_art.parts:
		if destinations.has(item.id):
			item.destination = destinations[item.id].duplicate()
			if item.id == "catwalk-support":
				# Art-approved uniform frame: retain brace angles and circular bolt proportions.
				var height: float = 440-float(catwalk[1])
				var width: float = float(item.source_rect[2])*height/float(item.source_rect[3])
				item.destination = [float(catwalk[0])+(float(catwalk[2])-width)*0.5,catwalk[1],width,height]

func in_pressure_dip() -> bool:
	for dip: Dictionary in contract.pacing.dips:
		if player.x >= float(dip.x[0]) and player.x < float(dip.x[1]): return true
	return false

func issue_event() -> void:
	if in_pressure_dip(): return
	var previous_warning := next_warning
	super.issue_event()
	if next_warning > previous_warning:
		next_warning = trial_clock+float(contract.pacing.admission_interval_seconds)

func step_three_shooter(actor: Dictionary, delta: float) -> void:
	# Dips delay fresh charges; already telegraphed attacks and in-flight bolts keep their lifecycle.
	if in_pressure_dip() and not actor.winding and actor.volley_left == 0:
		actor.recovery = maxf(0,actor.recovery-delta)
		return
	super.step_three_shooter(actor,delta)
