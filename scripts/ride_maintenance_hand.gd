extends RefCounted
## Authored articulated hand; the permanent pit alone owns gameplay collision.

static func assembly(manifest: Dictionary, pit: Vector2, age: float) -> Dictionary:
	var spec: Dictionary = manifest.hand_parts
	var timeline: Dictionary = manifest.hand_timeline
	var parts: Array[Dictionary] = []
	if age < float(timeline.warning): return {"parts":parts}
	var root_offset: Array = spec.root_relative_pit
	var clear_offset: Array = spec.clear_wrist_relative_pit
	var contact_offset: Array = spec.contact_wrist_relative_pit
	var pivot := pit+Vector2(root_offset[0],root_offset[1])
	var raised := pit+Vector2(clear_offset[0],clear_offset[1])
	var contact := pit+Vector2(contact_offset[0],contact_offset[1])
	var wrist := raised
	var contact_alpha := 0.0
	var arm_alpha := 1.0
	var impact := float(timeline.impact)
	var clear_at := float(timeline.clear)
	if age < impact:
		var strike := smoothstep(impact-0.25,impact,age)
		wrist = raised.lerp(contact,strike)
		contact_alpha = strike
	elif age < clear_at:
		var lift := smoothstep(impact,clear_at,age)
		wrist = contact.lerp(raised,lift)
		contact_alpha = 1.0-lift
	else:
		var retreat := smoothstep(clear_at,float(timeline.retreat_end),age)
		# Keep the curled fingers above y120 even as the wrist returns to the wall root.
		wrist = raised.lerp(pivot+Vector2(0,-30),retreat)
		arm_alpha = 1.0-retreat
	parts.append({"id":str(spec.hatch),"transform":Transform2D(0,pivot),"alpha":1.0})
	if arm_alpha > 0:
		var delta := wrist-pivot
		parts.append({"id":str(spec.forearm),
			"transform":Transform2D(delta.angle(),Vector2(delta.length()/300.0,1),0,pivot),"alpha":arm_alpha})
		if contact_alpha > 0:
			parts.append({"id":str(spec.contact),"transform":Transform2D(0,wrist),"alpha":contact_alpha})
		if contact_alpha < 1:
			parts.append({"id":str(spec.curled),"transform":Transform2D(0,wrist),"alpha":(1-contact_alpha)*arm_alpha})
	return {"parts":parts,"pivot":pivot,"wrist":wrist}
