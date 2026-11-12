extends RefCounted
## One viewport-wide pulse; callers own scheduling and cancellation of the rain lifetime.
static var next_target_id := 0

static func target_id(actor: Dictionary) -> String:
	if not actor.has("main_break_rain_id"):
		next_target_id += 1
		actor.main_break_rain_id = next_target_id
	return "actor-%d" % int(actor.main_break_rain_id)

static func apply(host: Node2D, amount: float, activation: int, tick: int, remainders: Dictionary) -> Dictionary:
	var applied := {}
	if amount <= 0 or not is_finite(amount) or tick < 1 or not host.specials_allowed(true): return applied
	if remainders.get("activation",-1) != activation:
		remainders.clear()
		remainders.merge({"activation":activation,"last_tick":0,"fractions":{}})
	if tick <= int(remainders.last_tick): return applied
	remainders.last_tick = tick
	var viewport := Rect2(float(host.camera_x),0,960,540)
	var seen := {}
	var alive := {}
	var fractions: Dictionary = remainders.fractions
	for target: Dictionary in host.main_break_rain_targets(activation,tick):
		var id: String = target.id
		if float(target.hp) <= 0: continue
		alive[id] = true
		if seen.has(id): continue
		var visible := false
		for region: Rect2 in target.regions:
			if region.has_area() and viewport.intersects(region):
				visible = true
				break
		if not visible: continue
		seen[id] = true
		var total := amount+float(fractions.get(id,0)) if target.get("integer",false) else amount
		var requested := floorf(total) if target.get("integer",false) else amount
		var accepted: float = target.damage.call(requested)
		if accepted <= 0: continue
		applied[id] = accepted
		if accepted >= float(target.hp):
			fractions.erase(id)
		elif target.get("integer",false):
			fractions[id] = total-requested
	# Missing/dead targets cannot transfer their credit to a later spawn.
	for id in fractions.keys():
		if not alive.has(id): fractions.erase(id)
	return applied
