extends RefCounted
## Collision-only opening geometry. Caller supplies gravity and spawn safety against live actors.

const WIDTH := 6000.0
const FLOOR_Y := 440.0
const VIEW_WIDTH := 960.0
const EPSILON := 0.01
const MAX_STEP := 8.0
var width: float = WIDTH
var floor_y: float = FLOOR_Y
var plinths: Array[Rect2] = []
var decks: Array[Rect2] = []
var grate_x: Array[float] = []

func configure(layout: Dictionary) -> bool:
	## Load the authored handoff atomically; false leaves the previous configuration intact.
	var next_plinths: Array[Rect2] = []
	var next_decks: Array[Rect2] = []
	var next_grates: Array[float] = []
	var world: Dictionary = layout.get("world", {})
	if float(world.get("width", 0)) != WIDTH or float(world.get("floor_y", 0)) != FLOOR_Y:
		return false
	var geometry: Array = layout.get("geometry", [])
	if geometry.is_empty(): return false
	for item: Dictionary in geometry:
		var values: Array = item.get("rect", [])
		if values.size() != 4: return false
		var rect := Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))
		if not rect.position.is_finite() or not rect.size.is_finite(): return false
		if rect.size.x <= 0 or rect.size.y <= 0 or rect.position.x < 0 or rect.end.x > WIDTH:
			return false
		if rect.position.y < 0 or rect.end.y > FLOOR_Y: return false
		match item.get("collision", ""):
			"solid": next_plinths.append(rect)
			"one_way_top": next_decks.append(rect)
			_: return false
	var rules: Dictionary = layout.get("placement_rules", {})
	var grates: Dictionary = rules.get("visible_grate", {})
	for x in grates.get("candidate_x", []):
		var value := float(x)
		if not is_finite(value) or value < 0 or value > WIDTH: return false
		next_grates.append(value)
	plinths = next_plinths
	decks = next_decks
	grate_x = next_grates
	return true

func projectile_solids() -> Array[Rect2]:
	## Both faces of a deck block shots; one-way behavior applies only to moving bodies.
	var result: Array[Rect2] = plinths.duplicate()
	result.append_array(decks)
	return result

func move_body(position: Vector2, velocity: Vector2, size: Vector2, delta: float) -> Dictionary:
	## Return pos, velocity and grounded. Input position must not begin embedded in solid scenery.
	var pos := position
	var vel := velocity
	var grounded := false
	# Bound displacement per sweep so diagonal movement cannot skip a thin deck corner.
	var steps := maxi(1, int(ceil(velocity.length() * maxf(delta, 0.0) / MAX_STEP)))
	var dt := maxf(delta, 0.0) / steps
	var surfaces := projectile_solids()
	for step in range(steps):
		var old := pos
		var target_x := pos.x + vel.x * dt
		for rect in plinths:
			if old.y >= rect.end.y - EPSILON or old.y + size.y <= rect.position.y + EPSILON:
				continue
			if vel.x > 0 and old.x + size.x <= rect.position.x + EPSILON:
				if target_x + size.x > rect.position.x: target_x = minf(target_x, rect.position.x - size.x)
			elif vel.x < 0 and old.x >= rect.end.x - EPSILON:
				if target_x < rect.end.x: target_x = maxf(target_x, rect.end.x)
		pos.x = clampf(target_x, 22.0, width - 20.0 - size.x)
		if not is_equal_approx(pos.x, old.x + vel.x * dt): vel.x = 0
		var target_y := pos.y + vel.y * dt
		grounded = false
		for rect in surfaces:
			if pos.x + size.x <= rect.position.x or pos.x >= rect.end.x: continue
			if vel.y >= 0 and old.y + size.y <= rect.position.y + EPSILON:
				if target_y + size.y >= rect.position.y:
					target_y = minf(target_y, rect.position.y - size.y)
					grounded = true
			elif vel.y < 0 and rect in plinths and old.y >= rect.end.y - EPSILON:
				if target_y < rect.end.y: target_y = maxf(target_y, rect.end.y)
		if target_y + size.y >= floor_y:
			target_y = floor_y - size.y
			grounded = true
		if grounded or not is_equal_approx(target_y, old.y + vel.y * dt): vel.y = 0
		pos.y = target_y
	return {"pos": pos, "velocity": vel, "grounded": grounded}

func visible_deck(camera: float, player: Vector2, size: Vector2) -> Dictionary:
	## size is the proposed enemy collider, player is hero top-left. Empty means defer.
	var best: Dictionary = {}
	for rect in decks:
		if rect.position.x < camera or rect.end.x > camera + VIEW_WIDTH or size.x > rect.size.x: continue
		var feet := Vector2(rect.end.x - maxf(28.0, size.x / 2.0), rect.position.y)
		var gap := feet.x - player.x
		if gap < 220 or gap > 420: continue
		var pos := feet - Vector2(size.x / 2.0, size.y)
		if best.is_empty() or pos.x < best.pos.x:
			best = {"pos": pos, "feet": feet, "surface": rect}
	return best

func visible_grate(camera: float, player: Vector2, size: Vector2) -> Dictionary:
	## Caller additionally checks predicted landing, live actors and warning-time safety.
	for x in grate_x:
		var pos := Vector2(x - size.x / 2.0, floor_y - size.y)
		if pos.x < camera or pos.x + size.x > camera + VIEW_WIDTH: continue
		if x - player.x < 180 or x - player.x > 420: continue
		var blocked := false
		for rect in projectile_solids():
			if Rect2(pos, size).intersects(rect): blocked = true
		if not blocked: return {"pos": pos, "feet": Vector2(x, floor_y)}
	return {}
