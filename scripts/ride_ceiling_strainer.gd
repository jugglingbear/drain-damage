extends RefCounted
## Authored depth poses and chains share the destructive-floor timeline.

static func assembly(manifest: Dictionary, point: Vector2, depth: float, age: float) -> Dictionary:
	var spec: Dictionary = manifest.strainer_parts
	var timeline: Dictionary = manifest.strainer_timeline
	var parts: Array[Dictionary] = []
	if age < float(timeline.warning): return {"parts":parts}
	var impact := float(timeline.impact)
	var down := smoothstep(impact-0.25,impact,age) if age < impact else 1.0-smoothstep(impact,float(timeline.clear),age)
	var bottom := Vector2(point.x,lerpf(float(spec.clear_basket_bottom_world_y),point.y+depth*0.5,down))
	var winch := Vector2(point.x,float(spec.winch_world_y))
	parts.append({"id":str(spec.winch),"transform":Transform2D(0,winch),"alpha":1.0})
	# Each crossfading authored pose keeps its own exact chain-to-eye registration.
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
