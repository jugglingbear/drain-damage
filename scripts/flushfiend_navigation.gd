extends RefCounted
## Local grounded step planning shared by opening actors and later campaign Flushfiends.
const RETREAT_SECONDS := 0.8
const MAX_RISE := 61.0
const PROBE_DT := 1.0/120.0

static func velocity(body: Rect2, requested: Vector2, memory: Dictionary, delta: float,
		solids: Array[Rect2], move_body: Callable, gravity: float, jump_speed: float) -> Vector2:
	var result := requested
	var retreat: float = maxf(0,memory.get("navigation_retreat",0.0)-delta)
	memory.navigation_retreat = retreat
	if retreat > 0:
		result.x = float(memory.navigation_away)*absf(requested.x)
		return result
	if absf(requested.x) < 40 or requested.y < -0.01: return result
	# Probe actual support at the current height; a zero vertical velocity at the apex is not a landing.
	var support: Dictionary = move_body.call(body.position,Vector2(0,1),body.size,PROBE_DT)
	if not support.grounded: return result
	for solid in solids:
		if body.position.y >= solid.end.y or body.end.y <= solid.position.y+0.01: continue
		var edge := solid.position.x-body.end.x if requested.x > 0 else body.position.x-solid.end.x
		if edge < -0.1 or edge > maxf(10,absf(requested.x)*delta): continue
		var rise := body.end.y-solid.position.y
		if rise <= MAX_RISE and _can_land(body,requested.x,solid,move_body,gravity,jump_speed):
			result.y = jump_speed
		else:
			# A blocked jump or tall wall gets a short retreat, rather than perpetual wall-walking.
			memory.navigation_retreat = RETREAT_SECONDS
			memory.navigation_away = -signf(requested.x)
			result.x = -requested.x
		return result
	return result

static func _can_land(body: Rect2, speed: float, step: Rect2, move_body: Callable,
		gravity: float, jump_speed: float) -> bool:
	var position := body.position
	var vertical := jump_speed
	for tick in range(120):
		vertical += gravity*PROBE_DT
		var moved: Dictionary = move_body.call(position,Vector2(speed,vertical),body.size,PROBE_DT)
		position = moved.pos
		# A ceiling collision invalidates the hop before launch, not after repeated head bumps.
		if vertical < 0 and moved.velocity.y == 0: return false
		vertical = moved.velocity.y
		if moved.grounded:
			return absf(position.y+body.size.y-step.position.y) < 0.1 and (
				position.x+body.size.x > step.position.x and position.x < step.end.x)
	return false
