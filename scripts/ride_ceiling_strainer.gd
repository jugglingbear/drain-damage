extends RefCounted
## One visible ceiling traveller carries the real basket to the fixed floor target.

static func assembly(manifest: Dictionary, point: Vector2, depth: float, age: float) -> Dictionary:
	var spec: Dictionary = manifest.strainer_parts
	var timeline: Dictionary = manifest.strainer_timeline
	var parts: Array[Dictionary] = []
	if age < 1.0: return {"parts":parts}
	var impact := float(timeline.impact)
	var clear := float(timeline.clear)
	var x := point.x
	if age < 1.25:
		x = lerpf(1100,800,smoothstep(1.0,1.25,age))
	elif age < 2.95:
		x = 800
	elif age < impact:
		var u := (age-2.95)/(impact-2.95)
		# Hermite meets the scrolling target with its velocity, not a position snap.
		var target := point.x+560*(age-impact)
		x = (2*u*u*u-3*u*u+1)*800+(-2*u*u*u+3*u*u)*target+(u*u*u-u*u)*(-560)*(impact-2.95)
	var down := 1.0-smoothstep(impact,clear,age) if age >= impact else 1.0
	var bottom_y := 210.0
	if age >= impact:
		bottom_y = lerpf(float(spec.clear_basket_bottom_world_y),point.y+depth*0.5,down)
	elif age >= 2.75:
		bottom_y = lerpf(180,point.y+depth*0.5,smoothstep(2.75,impact,age))
	elif age >= 2.15:
		bottom_y = lerpf(210,180,smoothstep(2.15,2.75,age))
	var bottom := Vector2(x,bottom_y)
	var winch := Vector2(x,float(spec.winch_world_y))
	if manifest.frames.has("strainer_rail"):
		# Continuous fixed overhead rail; the trolley, not the target, changes position.
		var rail_offset := point.x-780 if age >= clear else 0.0
		for rail_x in [0.0,325.0,650.0]:
			parts.append({"id":"strainer_rail","transform":Transform2D(0,Vector2(rail_x+rail_offset,53)),"alpha":1.0})
	parts.append({"id":str(spec.winch),"transform":Transform2D(0,winch),"alpha":1.0})
	for pose in [{"id":spec.basket,"alpha":down,"eyes":spec.impact_eye_offsets},
		{"id":spec.clear_basket,"alpha":1-down,"eyes":spec.clear_eye_offsets}]:
		if float(pose.alpha) <= 0: continue
		for index in range(2):
			var pulley: Array = spec.pulley_offsets[index]
			var eye: Array = pose.eyes[index]
			var start := winch+Vector2(pulley[0],pulley[1])
			var end := bottom+Vector2(eye[0],eye[1])
			var delta := end-start
			parts.append({"id":str(spec.chain),"alpha":float(pose.alpha),"start":start,"end":end,
				"transform":Transform2D(delta.angle()-PI*0.5,Vector2(1,delta.length()/100),0,start)})
		parts.append({"id":str(pose.id),"transform":Transform2D(0,bottom),"alpha":float(pose.alpha)})
	return {"parts":parts}
