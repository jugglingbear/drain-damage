extends RefCounted
## Persistent death snapshots and harmless head debris; rendering/audio remain caller-owned.
const STEP := 1.0/120.0
const GRAVITY := 600.0
var deaths: Array[Dictionary] = []
var props: Array[Dictionary] = []
var _seen: Dictionary = {}
var _serial := 0
var _remainder := 0.0

func reset() -> void:
	deaths.clear()
	props.clear()
	_seen.clear()
	_remainder = 0

func begin(actor: Dictionary, manifest: Dictionary) -> bool:
	var model: RefCounted = actor.devil
	var key := model.get_instance_id()
	if _seen.has(key): return false
	_seen[key] = true
	_serial += 1
	deaths.append({"id":_serial,"origin":Vector2(model.position),"age":0.0,
		"facing":float(model.direction),"manifest":manifest.duplicate(true),"heads_spawned":false,"ash_spawned":false})
	return true

func _vector(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(float(value[0]),float(value[1]))

func _release(death: Dictionary, kind: String) -> void:
	death[kind+"_spawned"] = true
	var manifest: Dictionary = death.manifest
	var anchor := _vector(manifest.get("anchor",[64,12]))
	var definitions: Array = manifest.get("head_props",[]) if kind == "heads" else [manifest.ash]
	var index := 0
	for definition: Dictionary in definitions:
		# Authored sockets are already logical canvas coordinates; source_scale is not applicable.
		var socket := _vector(definition.release_socket)-anchor
		socket.x *= death.facing
		var velocity := _vector(definition.get("velocity",[-36+36*index,12] if kind == "heads" else [0,12]))
		velocity.x *= death.facing
		var prop_id: String = str(definition.get("id","ash"))
		props.append({"id":str(death.id)+":"+prop_id,"head_id":prop_id,"kind":"head" if kind == "heads" else "ash",
			"pos":Vector2(death.origin)+socket,"velocity":velocity,"angle":0.0,"landed":false,
			"facing":death.facing,"definition":definition.duplicate(true),
			"radius":float(definition.get("contact_half_width",9)),
			"bottom":float(definition.get("contact_bottom",10)),
			"top":float(definition.get("contact_bottom",10)),
			"spin":float(definition.get("spin",(-1.0 if index%2 == 0 else 1.0)*2.0 if kind == "heads" else 0.0)),
			"age":0.0})
		index += 1

func _sweep(start: Vector2, motion: Vector2, rect: Rect2) -> Dictionary:
	var enter := 0.0
	var leave := 1.0
	var normal := Vector2.ZERO
	for axis in range(2):
		if absf(motion[axis]) < 0.0000001:
			if start[axis] <= rect.position[axis] or start[axis] >= rect.end[axis]: return {}
			continue
		var near: float = (rect.position[axis]-start[axis])/motion[axis]
		var far: float = (rect.end[axis]-start[axis])/motion[axis]
		var sign_normal := -1.0
		if near > far:
			var swap := near
			near = far
			far = swap
			sign_normal = 1.0
		if near >= enter:
			enter = near
			normal = Vector2.ZERO
			normal[axis] = sign_normal
		leave = minf(leave,far)
		if enter > leave: return {}
	if enter < 0 or enter > 1 or normal == Vector2.ZERO: return {}
	return {"at":enter,"normal":normal}

func _move(prop: Dictionary, dt: float, solids: Array[Rect2]) -> void:
	prop.age += dt
	if prop.landed: return
	prop.angle += prop.spin*dt
	prop.velocity.y += GRAVITY*dt
	var remaining := dt
	for iteration in range(3):
		var motion: Vector2 = prop.velocity*remaining
		var nearest: Dictionary = {}
		for solid in solids:
			var expanded := solid.grow_individual(prop.radius,prop.bottom,prop.radius,prop.top)
			var hit := _sweep(prop.pos,motion,expanded)
			if not hit.is_empty() and (nearest.is_empty() or hit.at < nearest.at): nearest = hit
		if nearest.is_empty():
			prop.pos += motion
			return
		prop.pos += motion*nearest.at
		if nearest.normal.y < 0:
			prop.landed = true
			prop.velocity = Vector2.ZERO
			return
		if nearest.normal.x != 0: prop.velocity.x = 0
		if nearest.normal.y > 0: prop.velocity.y = 0
		remaining *= 1.0-nearest.at
		if remaining <= 0.0000001: return

func step(host: Node, delta: float) -> void:
	if host.paused or delta <= 0: return
	var solids: Array[Rect2] = host.actor_solids().duplicate()
	if host.has_method("special_floor_solids"):
		solids.append_array(host.special_floor_solids())
	else:
		solids.append(Rect2(-10000000,float(host.FLOOR_Y),20000000,1000000))
	_remainder += delta
	while _remainder+0.0000001 >= STEP:
		_remainder -= STEP
		for death in deaths:
			var previous: float = death.age
			death.age += STEP
			for kind in ["heads","ash"]:
				if kind == "ash" and not death.manifest.has("ash"): continue
				var release_time: float = float(death.manifest.get("head_release_seconds",0.4)) if kind == "heads" else float(death.manifest.ash.release_seconds)
				if not death[kind+"_spawned"] and death.age+0.0000001 >= release_time:
					var first := props.size()
					_release(death,kind)
					# Integrate only the portion after the authored release boundary.
					for index in range(first,props.size()):
						props[index]["birth_skip"] = clampf(release_time-previous,0,STEP)
		for prop in props:
			var used: float = STEP-float(prop.get("birth_skip",0))
			prop.erase("birth_skip")
			if used > 0: _move(prop,used,solids)
