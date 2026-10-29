extends RefCounted

# Camera-independent metre-scale test course. Vector2 stores world X/Z; elevation stores world Y.
const STEP := 1.0/120.0
const HALF := Vector2(.45,.14)
# Full rider clearance at every supported camera yaw, separate from the smaller pit footprint.
const WALL_HALF := Vector2(.75,.85)
# The painted rigid board is longer than its gameplay hazard footprint.
const BOARD_LENGTH := 1.1
const SPEED := Vector2(4,3.5)
const GRAVITY := 12.0
const JUMP_SPEED := 3.6
const EPS := 0.0000001
const LAYOUT := {
	"track":{"rect":Rect2(0,-2,24,4),"top":0.0},
	"basin":{"center":Vector2(5,0),"size":Vector2(3.6,1),"top":.12,"thickness":.18,"material":"ceramic"},
	"platform":{"center":Vector2(10,0),"size":Vector2(1.8,1.4),"top":.12,"thickness":.18,"material":"brass"},
	"hole":{"center":Vector2(14,0),"radius":.65,"top":0.0},
	"ramp":{"rect":Rect2(18,-.8,3,1.6),"rise":.6,"material":"ceramic"},
	"board_size":Vector2(.9,.28),"start":Vector2(1,0)
}
var position := Vector2(1,0)
var elevation := 0.0
var board_pitch := 0.0
var support_velocity := 0.0
var clock := 0.0
var dead := false
var surface := "track"
var material := "water"
var grounded := true
var vertical_speed := 0.0
var accumulator := 0.0
var jump_held := false
var jump_pending := false

func reset() -> void:
	position = LAYOUT.start
	elevation = 0
	board_pitch = 0
	support_velocity = 0
	clock = 0
	dead = false
	surface = "track"
	material = "water"
	grounded = true
	vertical_speed = 0
	accumulator = 0
	jump_held = false
	jump_pending = false

static func rectangle_support(point: Vector2, rect: Rect2) -> float:
	var overlap := Rect2(point-HALF,HALF*2).intersection(rect)
	return overlap.get_area()/(HALF.x*HALF.y*4) if overlap.has_area() else 0.0

static func ellipse_primitive(x: float) -> float:
	x = clampf(x,-1,1)
	return .5*(x*sqrt(maxf(0,1-x*x))+asin(x))

static func ellipse_support(point: Vector2, center: Vector2, size: Vector2) -> float:
	# Integrate clipped ellipse columns exactly, splitting where the rectangle edges meet the ellipse.
	var radii := size*.5
	var lo := (point-HALF-center)/radii
	var hi := (point+HALF-center)/radii
	var left := maxf(-1,lo.x)
	var right := minf(1,hi.x)
	if left >= right or lo.y >= 1 or hi.y <= -1: return 0
	var cuts: Array[float] = [left,right]
	for y in [lo.y,hi.y]:
		if absf(y) < 1:
			var x := sqrt(1-y*y)
			for cut in [-x,x]:
				if cut > left and cut < right: cuts.append(cut)
	cuts.sort()
	var area := 0.0
	for index in range(cuts.size()-1):
		var a := cuts[index]
		var b := cuts[index+1]
		var height := sqrt(maxf(0,1-pow((a+b)*.5,2)))
		if minf(hi.y,height) <= maxf(lo.y,-height): continue
		var integral := ellipse_primitive(b)-ellipse_primitive(a)
		var top := hi.y*(b-a) if hi.y < height else integral
		var bottom := lo.y*(b-a) if lo.y > -height else -integral
		area += top-bottom
	return clampf(area*radii.x*radii.y/(HALF.x*HALF.y*4),0,1)

func ramp_pose(x: float) -> Dictionary:
	var ramp: Dictionary = LAYOUT.ramp
	var slope: float = ramp.rise/ramp.rect.size.x
	var low := 0.0
	var high := BOARD_LENGTH*.5
	# A rigid board's projected width shrinks as it rotates. Solve its chord across the ramp toe;
	# beyond the lip the same tangent supports the overhang until the rear clears the actual surface.
	for iteration in range(24):
		var half_x := (low+high)*.5
		var rear := maxf(0,(x-half_x-ramp.rect.position.x)*slope)
		var front := maxf(0,(x+half_x-ramp.rect.position.x)*slope)
		if 4*half_x*half_x+pow(front-rear,2) > BOARD_LENGTH*BOARD_LENGTH: high = half_x
		else: low = half_x
	var half_x := (low+high)*.5
	var rear := maxf(0,(x-half_x-ramp.rect.position.x)*slope)
	var front := maxf(0,(x+half_x-ramp.rect.position.x)*slope)
	return {"height":(rear+front)*.5,"pitch":atan2(front-rear,2*half_x),"half_x":half_x}

func board_pose() -> Dictionary:
	var center := Vector3(position.x,elevation,position.y)
	var half_edge := Vector3(cos(board_pitch),sin(board_pitch),0)*(BOARD_LENGTH*.5)
	return {"center":center,"rear":center-half_edge,"front":center+half_edge,"pitch":board_pitch}

func ramp_clearance(point: Vector2, pitch: float) -> float:
	var ramp: Dictionary = LAYOUT.ramp
	if point.y+HALF.y <= ramp.rect.position.y or point.y-HALF.y >= ramp.rect.end.y: return 0
	var half_x := BOARD_LENGTH*.5*cos(pitch)
	var left := maxf(point.x-half_x,ramp.rect.position.x)
	var right := minf(point.x+half_x,ramp.rect.end.x)
	if right < left: return 0
	var slope: float = ramp.rise/ramp.rect.size.x
	return maxf((left-ramp.rect.position.x)*slope-(left-point.x)*tan(pitch),
		(right-ramp.rect.position.x)*slope-(right-point.x)*tan(pitch))

func support_at(point: Vector2) -> Dictionary:
	var basin: Dictionary = LAYOUT.basin
	if rectangle_support(point,Rect2(basin.center-basin.size*.5,basin.size))+EPS >= .5:
		return {"surface":"basin","material":basin.material,"height":basin.top,"pitch":0.0}
	var platform: Dictionary = LAYOUT.platform
	if ellipse_support(point,platform.center,platform.size)+EPS >= .5:
		return {"surface":"platform","material":platform.material,"height":platform.top,"pitch":0.0}
	var ramp: Dictionary = LAYOUT.ramp
	var pose := ramp_pose(point.x)
	var bank_overlap := maxf(0,minf(point.y+HALF.y,ramp.rect.end.y)-maxf(point.y-HALF.y,ramp.rect.position.y))
	if bank_overlap+EPS >= HALF.y and point.x+pose.half_x >= ramp.rect.position.x and point.x-pose.half_x <= ramp.rect.end.x:
		return {"surface":"ramp","material":ramp.material,"height":pose.height,"pitch":pose.pitch}
	return {"surface":"track","material":"water","height":0.0,"pitch":0.0}

static func circle_entry(a: Vector2, b: Vector2, center: Vector2, radius: float) -> float:
	var offset := a-center
	if offset.length_squared() <= radius*radius: return 0
	var delta := b-a
	var aa := delta.length_squared()
	if aa < EPS*EPS: return INF
	var bb := offset.dot(delta)
	var cc := offset.length_squared()-radius*radius
	var discriminant := bb*bb-aa*cc
	if discriminant < 0: return INF
	var entry := (-bb-sqrt(discriminant))/aa
	return entry if entry >= 0 and entry <= 1 else INF

func hole_fraction(point: Vector2) -> float:
	var radius: float = LAYOUT.hole.radius
	return ellipse_support(point,LAYOUT.hole.center,Vector2.ONE*radius*2)

func hole_entry(a: Vector2, b: Vector2) -> float:
	if hole_fraction(a) >= .65: return 0
	# Half of a centrally symmetric footprint cannot overlap a convex hole while its center is outside.
	# This circle bracket avoids the zero-area plateaus of the expanded bounding rectangle.
	var low := circle_entry(a,b,LAYOUT.hole.center,LAYOUT.hole.radius)
	if low == INF: return INF
	var high := 1-circle_entry(b,a,LAYOUT.hole.center,LAYOUT.hole.radius)
	var begin := low
	# Convex intersection area is unimodal along a straight translation. Locate its peak even when
	# both sweep endpoints are safe, then bisect the first 65%-area crossing.
	for iteration in range(40):
		var left := lerpf(low,high,1.0/3)
		var right := lerpf(low,high,2.0/3)
		if hole_fraction(a.lerp(b,left)) < hole_fraction(a.lerp(b,right)): low = left
		else: high = right
	var peak := (low+high)*.5
	if hole_fraction(a.lerp(b,peak)) < .65: return INF
	low = begin
	high = peak
	for iteration in range(40):
		var middle := (low+high)*.5
		if hole_fraction(a.lerp(b,middle)) >= .65: high = middle
		else: low = middle
	return high

func tick(delta: float, steering: Vector2, jump: bool) -> void:
	if dead or delta <= 0: return
	if jump and not jump_held: jump_pending = true
	jump_held = jump
	accumulator += delta
	while accumulator+EPS >= STEP and not dead:
		accumulator -= STEP
		step(steering.limit_length())

func step(steering: Vector2) -> void:
	if jump_pending:
		if grounded:
			grounded = false
			vertical_speed = JUMP_SPEED
		jump_pending = false
	var before := position
	var target := position+steering*SPEED*STEP
	var track: Rect2 = LAYOUT.track.rect
	target.x = clampf(target.x,track.position.x+WALL_HALF.x,track.end.x-WALL_HALF.x)
	target.y = clampf(target.y,track.position.y+WALL_HALF.y,track.end.y-WALL_HALF.y)
	var support := support_at(target)
	var old_height := elevation
	if grounded and float(support.height) >= elevation-.05:
		elevation = support.height
		board_pitch = support.pitch
		support_velocity = (elevation-old_height)/STEP
	else:
		if grounded: vertical_speed = support_velocity if surface == "ramp" else 0.0
		grounded = false
		var initial_velocity := vertical_speed
		elevation += vertical_speed*STEP-.5*GRAVITY*STEP*STEP
		vertical_speed -= GRAVITY*STEP
		board_pitch = move_toward(board_pitch,0,atan(float(LAYOUT.ramp.rise)/LAYOUT.ramp.rect.size.x)*STEP/.18)
		# Even while leaving a bank edge, the underside cannot sink through the remaining ramp.
		var clearance := ramp_clearance(target,board_pitch)
		if support.surface == "ramp" and vertical_speed <= 0 and elevation <= clearance+EPS:
			elevation = support.height
			board_pitch = support.pitch
			vertical_speed = 0
			grounded = true
		elif elevation < clearance:
			elevation = clearance
			vertical_speed = maxf(0,vertical_speed)
		if vertical_speed <= 0 and elevation <= float(support.height)+EPS:
			elevation = support.height
			board_pitch = support.pitch
			vertical_speed = 0
			grounded = true
		# Preserve pre-gravity velocity for the exact floor-contact split below.
		support_velocity = initial_velocity
	var initial_velocity := support_velocity
	# Split the horizontal sweep at the floor landing; jumping above the hole is safe.
	var floor_start := 0.0
	if old_height > EPS:
		if elevation > EPS: floor_start = INF
		else:
			var landing := (initial_velocity+sqrt(initial_velocity*initial_velocity+2*GRAVITY*old_height))/GRAVITY
			floor_start = clampf(landing/STEP,0,1)
	elif elevation > EPS:
		floor_start = INF
	if floor_start != INF:
		var contact := hole_entry(before.lerp(target,floor_start),target)
		if contact != INF:
			var fraction := lerpf(floor_start,1,contact)
			position = before.lerp(target,fraction)
			elevation = 0
			clock += STEP*fraction
			dead = true
			surface = "hole"
			material = "void"
			return
	position = target
	clock += STEP
	surface = support.surface if grounded else "air"
	material = support.material if grounded else "air"
