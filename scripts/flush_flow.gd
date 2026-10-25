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

static func swim(point: Vector2, input: Vector2, speed: float, time: float, delta: float, flow: Dictionary) -> Vector2:
	point += (input.limit_length()*speed+velocity(point,time,flow))*delta
	if point == Vector2.ZERO: point = Vector2.RIGHT*162.0
	return point.normalized()*clampf(point.length(),162.0,316.8)
