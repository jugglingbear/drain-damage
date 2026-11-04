extends "res://scripts/opening_trial_level.gd"
## Isolated trial collision, including a swept footprint threshold at the real floor opening.

var pit := Vector2(2240, 2360)
var fatal_fraction := 0.65

func configure(contract: Dictionary) -> bool:
	width = float(contract.world.width)
	floor_y = float(contract.world.floor_y)
	plinths.clear()
	decks.clear()
	for values in contract.geometry.mandatory_climb.solid_rects:
		plinths.append(Rect2(values[0], values[1], values[2], values[3]))
	for values in contract.geometry.optional_route.steps:
		decks.append(Rect2(values[0], values[1], values[2], 16))
	var catwalk: Array = contract.geometry.optional_route.catwalk
	decks.append(Rect2(catwalk[0], catwalk[1], catwalk[2], catwalk[3]))
	pit = Vector2(contract.geometry.pit.opening_x[0], contract.geometry.pit.opening_x[1])
	fatal_fraction = float(contract.movement.pit_overlap_fatal_fraction)
	return true

func pit_overlap_fraction(body: Rect2) -> float:
	# The side-view opening spans the entire contact depth; area fraction reduces to width fraction.
	return maxf(0, minf(body.end.x, pit.y) - maxf(body.position.x, pit.x)) / body.size.x

func floor_solids() -> Array[Rect2]:
	return [Rect2(0, floor_y, pit.x, 100), Rect2(pit.y, floor_y, width - pit.y, 100)]

func move_body(position: Vector2, velocity: Vector2, size: Vector2, delta: float) -> Dictionary:
	var pos := position
	var vel := velocity
	var grounded := false
	var falling := position.y + size.y > floor_y + EPSILON
	var steps := maxi(1, ceili(velocity.length() * maxf(delta, 0) / MAX_STEP))
	var dt := maxf(delta, 0) / steps
	for index in range(steps):
		var old := pos
		var target_x := pos.x + vel.x * dt
		for rect in plinths:
			if old.y >= rect.end.y - EPSILON or old.y + size.y <= rect.position.y + EPSILON: continue
			if vel.x > 0 and old.x + size.x <= rect.position.x + EPSILON:
				target_x = minf(target_x, rect.position.x - size.x)
			elif vel.x < 0 and old.x >= rect.end.x - EPSILON:
				target_x = maxf(target_x, rect.end.x)
		pos.x = clampf(target_x, 22, width - 20 - size.x)
		if not is_equal_approx(pos.x, old.x + vel.x * dt): vel.x = 0
		var target_y := pos.y + vel.y * dt
		grounded = false
		for rect in actor_solids():
			if pos.x + size.x <= rect.position.x or pos.x >= rect.end.x: continue
			if vel.y >= 0 and old.y + size.y <= rect.position.y + EPSILON:
				if target_y + size.y >= rect.position.y:
					target_y = minf(target_y, rect.position.y - size.y)
					grounded = true
			elif vel.y < 0 and rect in plinths and old.y >= rect.end.y - EPSILON:
				if target_y < rect.end.y: target_y = maxf(target_y, rect.end.y)
		if not falling and target_y + size.y >= floor_y:
			falling = pit_overlap_fraction(Rect2(pos, size)) + 0.000001 >= fatal_fraction
			if not falling:
				target_y = floor_y - size.y
				grounded = true
		if grounded or not is_equal_approx(target_y, old.y + vel.y * dt): vel.y = 0
		pos.y = target_y
	return {"pos": pos, "velocity": vel, "grounded": grounded, "falling": falling}
