extends RefCounted
## A bounded current leaves both swimmers steering authority until the scripted drain phase.
static func strength(time: float, flow: Dictionary) -> Vector2:
	var limits: Array = [flow.total_speed_start,flow.total_speed_end,flow.inward_speed_start,flow.inward_speed_end]
	var progress := smoothstep(0.0,35.0,time)
	var total := lerpf(limits[0],limits[1],progress)
	var inward := lerpf(limits[2],limits[3],progress)
	if time >= 35:
		inward = lerpf(limits[3],230.0,clampf((time-35.0)/5.0,0,1))
		total = lerpf(limits[1],300.0,clampf((time-35.0)/5.0,0,1))
	return Vector2(sqrt(maxf(0,total*total-inward*inward)),inward)

static func velocity(point: Vector2, time: float, flow: Dictionary) -> Vector2:
	var outward := point.normalized()
	var force := strength(time,flow)
	return Vector2(-outward.y,outward.x)*force.x-outward*force.y

static func advect(point: Vector2, time: float, delta: float, flow: Dictionary) -> Vector2:
	var force := strength(time+delta*0.5,flow)
	var radius := point.length()
	var next_radius := maxf(0,radius-force.y*delta)
	if next_radius <= 0: return Vector2.ZERO
	var angle := point.angle()+force.x*delta/maxf(1,(radius+next_radius)*0.5)
	return Vector2.from_angle(angle)*next_radius

static func visual_speed(time: float) -> float:
	return lerpf(0.8,4.0,clampf(time/43.0,0,1))

## Hero-center bounds at the supplied simulation time; the two components are inner and outer radii.
static func annulus(time: float) -> Vector2:
	var progress := smoothstep(8.0,35.0,time)
	return Vector2(lerpf(162.0,90.0,progress),lerpf(316.8,210.0,progress))

static func swim(point: Vector2, input: Vector2, speed: float, time: float, delta: float, flow: Dictionary) -> Vector2:
	point += (input.limit_length()*speed+velocity(point,time,flow))*delta
	var bounds := annulus(time)
	return point.limit_length(bounds.y)

## Map the registered planar swimmer footprint onto the visible concave opening.
static func drain_coordinates(point: Vector2, radii: Vector2, projection_y: float, depth: float) -> Vector2:
	var radius := point.length()
	var surface := depth*pow(1.0-clampf(radius/360.0,0,1),2)
	var local := Vector2(point.x,point.y*projection_y+surface-depth)
	return Vector2(local.x/radii.x,local.y/radii.y)

# Bounds for the normalized squared distance of every point in a world rectangle.
static func drain_rectangle_bounds(center: Vector2, half: float, radii: Vector2,
		projection_y: float, depth: float) -> Vector2:
	var minimum_radius := Vector2(maxf(0,absf(center.x)-half),maxf(0,absf(center.y)-half)).length()
	var maximum_radius := Vector2(absf(center.x)+half,absf(center.y)+half).length()
	var low_y := ((center.y-half)*projection_y+depth*pow(1-clampf(maximum_radius/360,0,1),2)-depth)/radii.y
	var high_y := ((center.y+half)*projection_y+depth*pow(1-clampf(minimum_radius/360,0,1),2)-depth)/radii.y
	var min_y := 0.0 if low_y <= 0 and high_y >= 0 else minf(absf(low_y),absf(high_y))
	var min_x := maxf(0,absf(center.x)-half)/radii.x
	var max_x := (absf(center.x)+half)/radii.x
	return Vector2(min_x*min_x+min_y*min_y,max_x*max_x+maxf(low_y*low_y,high_y*high_y))

static var disk_cell_areas: Dictionary = {}

static func disk_quadrant_area(x: float, y: float) -> float:
	x = clampf(x,0,1)
	y = clampf(y,0,1)
	if x*x+y*y <= 1: return x*y
	var split := sqrt(maxf(0,1-y*y))
	return y*split+.5*(x*sqrt(maxf(0,1-x*x))+asin(x)-split*y-asin(split))

static func disk_cell_area(cell: Vector3, radius: float) -> float:
	var key := cell/radius
	if not disk_cell_areas.has(key):
		if key.z >= 1: disk_cell_areas[key] = PI
		else:
			var x0 := maxf(0,absf(key.x)-key.z)
			var x1 := absf(key.x)+key.z
			var y0 := maxf(0,absf(key.y)-key.z)
			var y1 := absf(key.y)+key.z
			disk_cell_areas[key] = maxf(0,disk_quadrant_area(x1,y1)-disk_quadrant_area(x0,y1)
				-disk_quadrant_area(x1,y0)+disk_quadrant_area(x0,y0))
	return float(disk_cell_areas[key])*radius*radius

static func drain_contact(point: Vector2, radii: Vector2, projection_y: float, depth: float,
		footprint_radius := 14.0) -> bool:
	# Certified area bounds avoid killing on a sampled point or an overestimated overlap. Boundary
	# cells are refined to 1/256 of the footprint width; unresolved slivers remain safe, never lethal.
	var bounds := drain_rectangle_bounds(point,footprint_radius,radii,projection_y,depth)
	if bounds.x > 1: return false
	if bounds.y <= 1: return true
	var half_area := PI*footprint_radius*footprint_radius*.5
	var lower := 0.0
	var upper := PI*footprint_radius*footprint_radius
	var cells: Array[Vector3] = [Vector3(0,0,footprint_radius)]
	while not cells.is_empty():
		var cell: Vector3 = cells.pop_back()
		var offset := Vector2(cell.x,cell.y)
		var half: float = cell.z
		var area := disk_cell_area(cell,footprint_radius)
		if area <= 0: continue
		var opening := drain_rectangle_bounds(point+offset,half,radii,projection_y,depth)
		if opening.x > 1:
			upper -= area
		elif opening.y <= 1:
			lower += area
		elif half > footprint_radius/256.0:
			var child := half*.5
			for x in [-child,child]:
				for y in [-child,child]: cells.append(Vector3(offset.x+x,offset.y+y,child))
		if lower >= half_area: return true
		if upper < half_area: return false
	return false
