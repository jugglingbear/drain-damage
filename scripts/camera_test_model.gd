extends RefCounted

# Camera-independent metre-scale test course. Vector2 stores world X/Z; elevation stores world Y.
const STEP := 1.0/120.0
const HALF := Vector2(.45,.14)
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

func support_at(point: Vector2) -> Dictionary:
	var basin: Dictionary = LAYOUT.basin
	if rectangle_support(point,Rect2(basin.center-basin.size*.5,basin.size))+EPS >= .5:
		return {"surface":"basin","material":basin.material,"height":basin.top}
	var platform: Dictionary = LAYOUT.platform
	if ellipse_support(point,platform.center,platform.size)+EPS >= .5:
		return {"surface":"platform","material":platform.material,"height":platform.top}
	var ramp: Dictionary = LAYOUT.ramp
	if rectangle_support(point,ramp.rect)+EPS >= .5:
		return {"surface":"ramp","material":ramp.material,
			"height":clampf((point.x-ramp.rect.position.x)/ramp.rect.size.x,0,1)*ramp.rise}
	return {"surface":"track","material":"water","height":0.0}

static func rect_entry(a: Vector2, b: Vector2, rect: Rect2) -> float:
	var start := 0.0
	var finish := 1.0
	for axis in range(2):
		var delta := b[axis]-a[axis]
		if absf(delta) < EPS:
			if a[axis] < rect.position[axis] or a[axis] > rect.end[axis]: return INF
			continue
		var first := (rect.position[axis]-a[axis])/delta
		var last := (rect.end[axis]-a[axis])/delta
		start = maxf(start,minf(first,last))
		finish = minf(finish,maxf(first,last))
	return start if start <= finish else INF

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

func hole_entry(a: Vector2, b: Vector2) -> float:
	# Circle expanded by the board rectangle: two strips plus four rounded corners, never a square.
	var center: Vector2 = LAYOUT.hole.center
	var radius: float = LAYOUT.hole.radius
	var first := rect_entry(a,b,Rect2(center-Vector2(HALF.x+radius,HALF.y),Vector2(2*(HALF.x+radius),2*HALF.y)))
	first = minf(first,rect_entry(a,b,Rect2(center-Vector2(HALF.x,HALF.y+radius),Vector2(2*HALF.x,2*(HALF.y+radius)))))
	for x in [-HALF.x,HALF.x]:
		for z in [-HALF.y,HALF.y]:
			first = minf(first,circle_entry(a,b,center+Vector2(x,z),radius))
	return first

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
	target.x = clampf(target.x,track.position.x+HALF.x,track.end.x-HALF.x)
	target.y = clampf(target.y,track.position.y+HALF.y,track.end.y-HALF.y)
	var support := support_at(target)
	var old_height := elevation
	var initial_velocity := vertical_speed
	if grounded and float(support.height) >= elevation-.05:
		elevation = support.height
	else:
		grounded = false
		elevation += vertical_speed*STEP-.5*GRAVITY*STEP*STEP
		vertical_speed -= GRAVITY*STEP
		if vertical_speed <= 0 and elevation <= float(support.height):
			elevation = support.height
			vertical_speed = 0
			grounded = true
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
