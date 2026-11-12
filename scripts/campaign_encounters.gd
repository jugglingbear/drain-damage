extends RefCounted
## Finite campaign admission data; boss encounters retain their own lifecycle and budgets.
const CONTRACT_PATH := "res://levels/first-call/campaign-encounters.json"
var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
var specs: Array[Dictionary] = []
var ledger: Dictionary = {}
var tuning: Dictionary = {}
var level := Geometry.new()
var variant_supports: Array[Dictionary] = []

class Geometry extends "res://scripts/three_screen_trial_level.gd":
	var pits: Array[Vector2] = []
	var platforms := preload("res://scripts/basement_platforms.gd").new()
	var permanent_plinths: Array[Rect2] = []

	func configure(data: Dictionary) -> bool:
		width = float(data.world.width)
		floor_y = float(data.world.floor_y)
		fatal_fraction = 0.65
		plinths.clear()
		permanent_plinths.clear()
		platforms.reset()
		decks.clear()
		pits.clear()
		for section: Dictionary in data.sections:
			for item: Dictionary in section.get("geometry",[]):
				var values: Array = platforms.overrides.get(item.id,item.rect)
				var rect := Rect2(values[0],values[1],values[2],values[3])
				match item.kind:
					"solid":
						if not platforms.placements.has(item.id): permanent_plinths.append(rect)
					"one_way": decks.append(rect)
					"pit": pits.append(Vector2(rect.position.x,rect.end.x))
		for item: Dictionary in platforms.supplemental:
			var values: Array = item.rect
			var rect := Rect2(values[0],values[1],values[2],values[3])
			if item.kind == "solid": permanent_plinths.append(rect)
			elif item.kind == "one_way": decks.append(rect)
		refresh_platforms()
		pits.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.x < b.x)
		return true

	func refresh_platforms() -> void:
		plinths.assign(permanent_plinths)
		for id: String in platforms.placements: plinths.append_array(platforms.colliders(id))

	func pit_overlap_fraction(body: Rect2) -> float:
		var overlap := 0.0
		for opening in pits:
			overlap += maxf(0,minf(body.end.x,opening.y)-maxf(body.position.x,opening.x))
		return overlap/body.size.x

	func floor_solids() -> Array[Rect2]:
		var result: Array[Rect2] = []
		var left := 0.0
		for opening in pits:
			result.append(Rect2(left,floor_y,opening.x-left,100))
			left = opening.y
		result.append(Rect2(left,floor_y,width-left,100))
		return result

func reset(difficulty: String, owner_origin: float, run_seed: int = 0) -> void:
	level.configure(contract)
	tuning = contract.difficulty[difficulty].duplicate(true)
	tuning.shooter_cap = int(tuning.get("shooter_cap",tuning.total_actors_max))
	tuning.flyer_cap = int(tuning.get("flyer_cap",tuning.total_actors_max))
	specs.clear()
	ledger.clear()
	variant_supports.clear()
	var variants := entrance_variants(run_seed)
	for authored: Dictionary in contract.encounters:
		var spec: Dictionary = authored.duplicate(true)
		spec.entry = variants.get(authored.id, authored.arrival).duplicate(true)
		if spec.entry.has("source"): spec.entry.source = vector(spec.entry.source)
		spec.feet = vector(authored.placement.feet)
		spec.bounds = vector(authored.placement.bounds)
		spec.depth = spec.entry.mode if spec.entry.mode in ["background","foreground"] else ""
		spec.devil_limits = vector(authored.placement.get("crawl_range",authored.placement.bounds))
		if spec.entry.has("source"): spec.source = spec.entry.source
		apply_flyer_variant(spec, run_seed)
		specs.append(spec)
		ledger[spec.id] = "pending" if difficulty in spec.enabled_difficulties \
			and float(spec.owner_origin) >= owner_origin else "excluded"

func vector(values: Array) -> Vector2:
	return Vector2(values[0],values[1])

func expire(hero_x: float) -> void:
	for spec in specs:
		if ledger[spec.id] == "pending" and hero_x >= float(spec.end): ledger[spec.id] = "expired"

func pressure_dip(hero_x: float) -> bool:
	for section: Dictionary in contract.sections:
		for key in ["quiet_ranges","relief_ranges"]:
			for interval: Array in section.get(key,[]):
				if hero_x >= float(interval[0]) and hero_x <= float(interval[1]): return true
	return false

func entrance_variants(run_seed: int) -> Dictionary:
	## Select before checkpoint/difficulty filtering, so retries cannot reroll surviving slots.
	var groups: Dictionary = {}
	for authored: Dictionary in contract.encounters:
		if not authored.has("arrival_variation"): continue
		assert(authored.role == "runner")
		var group: String = authored.arrival_variation.group
		if not groups.has(group): groups[group] = []
		groups[group].append(authored)
	var result: Dictionary = {}
	for group: String in groups:
		var candidates: Array = groups[group]
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
		var rng := RandomNumberGenerator.new()
		# Each group owns its stream; unrelated encounter order never consumes its choices.
		rng.seed = (str(run_seed) + ":entrance-v1:" + group).hash()
		var selected: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
		result[selected.id] = selected.arrival_variation.alternative
	return result

func apply_flyer_variant(spec: Dictionary, run_seed: int) -> void:
	## Cuddlebug retains the internal devil ID and requires a clear supported ceiling route.
	if spec.role != "aggressive_flyer" or spec.get("variant", "") != "angel": return
	var socket := Vector2(spec.feet.x, 110)
	var limits := Vector2(maxf(spec.bounds.x, socket.x - 90), minf(spec.bounds.y, socket.x + 90))
	var sweep := Rect2(limits.x - 48, 0, limits.y - limits.x + 96, 218)
	for solid: Rect2 in level.plinths + level.decks:
		if sweep.intersects(solid): return
	for section: Dictionary in contract.sections:
		for item: Dictionary in section.get("geometry", []):
			if item.kind in ["ceiling_fixture", "ceiling_rail"]:
				var values: Array = item.rect
				if sweep.intersects(Rect2(values[0], values[1], values[2], values[3])): return
	var rng := RandomNumberGenerator.new()
	rng.seed = (str(run_seed) + ":flyer-v1:" + str(spec.id)).hash()
	if rng.randi_range(0, 1) == 0: return
	spec.variant = "devil"
	spec.feet = socket
	spec.bounds = limits
	spec.devil_limits = limits
	spec.entry = {"mode":"top"}
	spec.depth = ""
	spec.erase("source")
	variant_supports.append({"id":spec.id, "home":socket, "bounds":limits})
