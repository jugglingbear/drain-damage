extends RefCounted
## Final authored collision footprints; source concept homes are deliberately not used.
const Finale = preload("res://scripts/clogfather_route.gd")
const WIDTH := Finale.WORLD_WIDTH
const CHECKPOINTS := [4650.0,Finale.CHECKPOINT]
const POST_SKITTERLING_CHECKPOINT := 7650.0
const GATES := [1390.0, 3070.0, 4750.0, 6430.0, 8110.0, 9380.0]
const LANES := [Vector2(690, 1370), Vector2(2370, 3050), Vector2(4050, 4730),
	Vector2(5750, 6410), Vector2(7410, 8090), Vector2(8570, 9360)]
const PROPS: Array[Rect2] = [
	Rect2(300,380,180,60), Rect2(500,380,160,60),
	Rect2(1500,380,160,60), Rect2(1660,320,180,120), Rect2(1840,380,160,60), Rect2(2180,380,160,60),
	Rect2(3500,380,160,60), Rect2(3660,320,180,120), Rect2(3840,380,160,60),
	Rect2(4850,380,160,60), Rect2(5010,320,180,120), Rect2(5190,260,200,180),
	Rect2(5390,320,180,120), Rect2(5570,380,160,60),
	Rect2(6860,380,160,60), Rect2(7020,320,180,120), Rect2(7200,380,160,60),
]
const TEXTURES = [preload("res://assets/world/platform-readability-v3/low-deck-v3.png"),
	preload("res://assets/world/platform-readability-v3/pump-v3.png"),
	preload("res://assets/world/platform-readability-v3/tall-v3.png"),
	preload("res://assets/world/first-call/service-shutter-v1.png")]
const CROPS := [Rect2(71,230,1394,344), Rect2(145,220,1249,626),
	Rect2(87,130,1148,936), Rect2(365,36,244,1534)]

static func solids(stage: int, gate_progress: Array[float] = []) -> Array[Rect2]:
	var result: Array[Rect2] = PROPS.duplicate()
	for index in range(GATES.size()):
		if not gate_progress.is_empty():
			var rect := gate_rect(index, gate_progress[index])
			if rect.size.y > 0: result.append(rect)
		elif index >= stage or (index == 5 and stage == 6):
			result.append(gate_rect(index, 0))
	return result

static func move_body(position: Vector2, velocity: Vector2, size: Vector2,
		delta: float, obstacles: Array[Rect2]) -> Dictionary:
	var pos := position
	var vel := velocity
	var grounded := false
	pos.x += vel.x * delta
	for rect in obstacles:
		if position.y < rect.end.y - 0.01 and position.y + size.y > rect.position.y + 0.01:
			if vel.x > 0 and position.x + size.x <= rect.position.x + 0.01 and pos.x + size.x > rect.position.x:
				pos.x = minf(pos.x, rect.position.x - size.x)
			elif vel.x < 0 and position.x >= rect.end.x - 0.01 and pos.x < rect.end.x:
				pos.x = maxf(pos.x, rect.end.x)
	pos.x = clampf(pos.x, 22, WIDTH - 46)
	pos.y += vel.y * delta
	for rect in obstacles:
		if pos.x + size.x > rect.position.x and pos.x < rect.end.x:
			if vel.y >= 0 and position.y + size.y <= rect.position.y + 0.01 and pos.y + size.y >= rect.position.y:
				pos.y = minf(pos.y, rect.position.y - size.y)
				grounded = true
			elif vel.y < 0 and position.y >= rect.end.y and pos.y < rect.end.y:
				pos.y = maxf(pos.y, rect.end.y)
				vel.y = 0
	if pos.y + size.y >= 440:
		pos.y = 440 - size.y
		grounded = true
	if grounded: vel.y = 0
	return {"pos":pos, "velocity":vel, "grounded":grounded}

static func draw_prop(canvas: Node2D, rect: Rect2, shutter := false) -> void:
	var index := 3 if shutter else 0 if rect.size.y == 60 else 1 if rect.size.y == 120 else 2
	var source: Rect2 = CROPS[index]
	if index == 1 and rect.size.x < 180:
		# Keep the exposed right edge at its authored scale on the shortened approach stair.
		var right := source.end.x
		source.size.x *= rect.size.x / 180.0
		source.position.x = right - source.size.x
	canvas.draw_texture_rect_region(TEXTURES[index], rect, source)

static func gate_rect(index: int, progress: float) -> Rect2:
	var drop := 260.0 * clampf(progress, 0, 1)
	return Rect2(GATES[index], 180 + drop, 48, 260 - drop)

static func draw_gate(canvas: Node2D, index: int, progress: float) -> void:
	var rect := gate_rect(index, progress)
	if rect.size.y <= 0: return
	var source: Rect2 = CROPS[3]
	# Crop the bottom as the panel descends; never squash the shutter texture.
	source.size.y *= rect.size.y / 260.0
	canvas.draw_texture_rect_region(TEXTURES[3], rect, source)
