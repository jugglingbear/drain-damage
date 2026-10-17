extends RefCounted
## Spatial scenery values: neither player progress nor combat changes the pipe.
var points: Array[Dictionary] = []
var terminal_x := 8570.0

func configure(sections: Array) -> void:
	points.clear()
	for section in sections:
		points.append({"x":float(section.world_x[0]+section.world_x[1])*0.5,
			"water":float(section.water_depth_fraction),"flow":float(section.flow_pixels_per_second),
			"coverage":float(section.lodged_debris_coverage_fraction)})
	terminal_x = sections[-1].world_x[0]
	points[-1].x = terminal_x

func sample(world_x: float, opening_trial := false) -> Dictionary:
	var x := minf(world_x,1440) if opening_trial else world_x
	if x >= terminal_x: return {"water":0.0,"flow":0.0,"coverage":1.0}
	if x <= points[0].x: return points[0].duplicate()
	for index in range(1,points.size()):
		if x <= points[index].x:
			var a: Dictionary = points[index-1]
			var b: Dictionary = points[index]
			var t := smoothstep(a.x,b.x,x)
			return {"water":lerpf(a.water,b.water,t),"flow":lerpf(a.flow,b.flow,t),
				"coverage":lerpf(a.coverage,b.coverage,t)}
	return {"water":0.0,"flow":0.0,"coverage":1.0}
