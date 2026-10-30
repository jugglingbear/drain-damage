extends RefCounted
## Deterministic showcase physics. Rendering/audio remain in the ride wrapper.
const SOURCE := "res://levels/level-two-ride-showcase.json"
const STEP := 1.0/120.0
const HALF := Vector2(45,14)
const EPS := 0.000001
const PIT_FALL_FRACTION := 0.65
var definition: Dictionary = {}
var course: Dictionary = {"obstacles":[]}
var encounter: Dictionary = {}
var encounter_index := 0
var checkpoint_index := 0
var phase := "encounter"
var rest_remaining := 0.0
var encounter_clock := 0.0
var encounter_started_at := 0.0
var encounter_scroll := 0.0
var clock := 0.0
var scroll_speed := 560.0
var x_speed := 400.0
var bank_speed := 350.0
var position := Vector2(300,330)
var jump_age := -1.0
var jump_height := 0.0
var ground_height := 0.0
var active_jump_duration := 0.6
var active_jump_apex := 54.0
var jump_duration: float:
	get: return active_jump_duration
var jump_apex: float:
	get: return active_jump_apex
var cooldown := 0.0
var boosted := false
var ballistic := false
var ramp_active := false
var active_ramp: Dictionary = {}
var render_height := 0.0
var render_pitch := 0.0
var launch_height := 0.0
var launch_velocity := 0.0
var launch_gravity := 0.0
var launch_pitch := 0.0
var complete := false
var recovery_clock := 0.0
var events: Dictionary = {}
var contact_latches: Dictionary = {}
var hit_ids: Dictionary = {}
var used_ramps: Dictionary = {}
var last_event: Dictionary = {}
var landing_material := "water"

func emit_event(name: String, id := "") -> void:
	events[name] = int(events.get(name,0))+1
	last_event = {"event":name,"obstacle_id":id,"clock":clock,"encounter":encounter_index}

func begin(host: Node2D, index := 0) -> void:
	if definition.is_empty():
		definition = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	clock = 0
	position = Vector2(300,330)
	jump_age = -1
	jump_height = 0
	ground_height = 0
	launch_height = 0
	cooldown = 0
	recovery_clock = 0
	boosted = false
	ballistic = false
	ramp_active = false
	active_ramp.clear()
	render_height = 0
	render_pitch = 0
	complete = false
	events.clear()
	landing_material = "water"
	host.won = false
	_start_encounter(clampi(index,0,definition.encounters.size()-1))
	sync_hero(host)

func _start_encounter(index: int) -> void:
	encounter_index = index
	checkpoint_index = index
	encounter = definition.encounters[index].duplicate(true)
	course = {"obstacles":encounter.obstacles}
	for i in range(course.obstacles.size()):
		var obstacle: Dictionary = course.obstacles[i]
		if not obstacle.has("id"): obstacle.id = str(encounter.get("id",index))+"-"+str(i)
	phase = "encounter"
	rest_remaining = 0
	encounter_clock = 0
	encounter_started_at = clock
	encounter_scroll = 0
	contact_latches.clear()
	hit_ids.clear()
	used_ramps.clear()
	emit_event("encounter_started")

func sync_hero(_host: Node2D) -> void:
	pass

func height(age: float) -> float:
	if age < 0: return ground_height
	if ballistic: return maxf(0,launch_height+launch_velocity*age-launch_gravity*age*age)
	return maxf(0,launch_height+360*age-600*age*age)

static func deck_surface_height(deck: Dictionary) -> float:
	return float(deck.get("surface_height",12.0))

static func deck_surface_shape(deck: Dictionary) -> String:
	return str(deck.get("surface_shape","ellipse" if str(deck.get("art_id","")).begins_with("cleanout_deck_") else "rect"))

static func _circle_span(a: Vector2, b: Vector2, center: Vector2) -> Vector2:
	var offset := a-center
	var delta := b-a
	var aa := delta.length_squared()
	if aa <= EPS*EPS: return Vector2(0,1) if offset.length_squared() <= 1 else Vector2(-1,-1)
	var bb := offset.dot(delta)
	var discriminant := bb*bb-aa*(offset.length_squared()-1)
	if discriminant < 0: return Vector2(-1,-1)
	var low := maxf(0,(-bb-sqrt(discriminant))/aa)
	var high := minf(1,(-bb+sqrt(discriminant))/aa)
	return Vector2(low,high) if low <= high else Vector2(-1,-1)

func _deck_top_interval(deck: Dictionary, a: Vector2, b: Vector2, time: float, dt: float) -> Vector2:
	var rect := obstacle_rect(deck)
	var start := a-motion_offset(deck,time)
	var finish := b-motion_offset(deck,time+dt)
	var rigid_half := Vector2(55,14)
	if deck_surface_shape(deck) != "ellipse":
		return overlap_interval(start,finish,rect.grow_individual(55,14,55,14))
	# Ellipse versus rigid board rectangle, expressed as two strips and four rounded corners.
	var radii := rect.size*.5
	start = (start-rect.get_center())/radii
	finish = (finish-rect.get_center())/radii
	var half := rigid_half/radii
	var spans: Array[Vector2] = [overlap_interval(start,finish,Rect2(-half-Vector2(1,0),(half+Vector2(1,0))*2)),
		overlap_interval(start,finish,Rect2(-half-Vector2(0,1),(half+Vector2(0,1))*2))]
	for x in [-half.x,half.x]:
		for y in [-half.y,half.y]: spans.append(_circle_span(start,finish,Vector2(x,y)))
	var result := Vector2(INF,-INF)
	for span in spans:
		if span.x < 0: continue
		result.x = minf(result.x,span.x)
		result.y = maxf(result.y,span.y)
	return result if result.x <= result.y else Vector2(-1,-1)

func deck_support(point: Vector2, time: float) -> Dictionary:
	# Submerged mounting plates preserve pit coverage, while water supports the rider at Y0.
	var support := {"height":0.0,"material":"water","id":""}
	for deck: Dictionary in course.obstacles:
		if deck.kind != "deck" or deck_surface_height(deck) <= float(support.height): continue
		if _deck_top_interval(deck,point,point,time,0).x < 0: continue
		support = {"height":deck_surface_height(deck),"material":str(deck.get("landing_material","metal")),"id":deck.id}
	return support

func _land_on(support: Dictionary) -> void:
	ground_height = float(support.height)
	jump_age = -1
	boosted = false
	ballistic = false
	cooldown = .1
	jump_height = ground_height
	render_height = ground_height
	render_pitch = 0
	landing_material = support.material
	emit_event("landed")

func _drop_from_deck() -> void:
	launch_height = ground_height
	launch_velocity = 0
	launch_gravity = 600
	launch_pitch = render_pitch
	active_jump_duration = sqrt(launch_height/launch_gravity)
	active_jump_apex = launch_height
	jump_age = 0
	ballistic = true
	boosted = false
	ground_height = 0

func _deck_transition(a: Vector2, b: Vector2, time: float, dt: float) -> Dictionary:
	var events_at: Array[float] = [0.0,1.0]
	for deck: Dictionary in course.obstacles:
		if deck.kind != "deck": continue
		var span := _deck_top_interval(deck,a,b,time,dt)
		if span.x < 0: continue
		events_at.append(span.x)
		events_at.append(span.y)
		if jump_age >= 0:
			var velocity := launch_velocity if ballistic else 360.0
			var gravity := launch_gravity if ballistic else 600.0
			var discriminant := velocity*velocity+4*gravity*(launch_height-deck_surface_height(deck))
			if discriminant >= 0:
				var at := ((velocity+sqrt(discriminant))/(2*gravity)-jump_age)/dt
				if at >= span.x and at <= span.y: events_at.append(at)
	events_at.sort()
	for at in events_at:
		var probe := minf(1,at+.00001)
		var support := deck_support(a.lerp(b,probe),time+dt*probe)
		if jump_age < 0:
			if absf(float(support.height)-ground_height) > EPS:
				return {"at":at,"support":support}
		elif float(support.height) > 0:
			var age := jump_age+dt*at
			var velocity := (launch_velocity-2*launch_gravity*age) if ballistic else (360-1200*age)
			var elevation := height(age)
			if elevation < float(support.height)-.0001 or (velocity <= 0 and elevation <= float(support.height)+.0001):
				return {"at":at,"support":support}
	return {}

func hero_head_height(host: Node2D) -> float:
	return 84.0 if str(host.employee.id) == "tony" else 72.0

func motion_offset(obstacle: Dictionary, time: float) -> Vector2:
	var motion: Dictionary = obstacle.get("motion",{})
	if motion.is_empty(): return Vector2.ZERO
	var value := float(motion.get("amplitude",0))*sin(TAU*time/maxf(0.01,float(motion.get("period",2)))+float(motion.get("phase",0)))
	return Vector2(value,0) if motion.get("axis","y") == "x" else Vector2(0,value)

func obstacle_position(obstacle: Dictionary) -> Vector2:
	return Vector2(float(obstacle.x)-encounter_scroll,float(obstacle.y))+motion_offset(obstacle,encounter_clock)

func obstacle_rect(obstacle: Dictionary) -> Rect2:
	return Rect2(Vector2(float(obstacle.x),float(obstacle.y))-Vector2(float(obstacle.width),float(obstacle.depth))*0.5,
		Vector2(float(obstacle.width),float(obstacle.depth)))

static func overlap_interval(start: Vector2, finish: Vector2, rect: Rect2) -> Vector2:
	var enter := 0.0
	var leave := 1.0
	var delta := finish-start
	for axis in [0,1]:
		if absf(delta[axis]) < EPS:
			if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]: return Vector2(-1,-1)
		else:
			var a: float = (rect.position[axis]-start[axis])/delta[axis]
			var b: float = (rect.end[axis]-start[axis])/delta[axis]
			enter = maxf(enter,minf(a,b))
			leave = minf(leave,maxf(a,b))
			if enter > leave: return Vector2(-1,-1)
	return Vector2(enter,leave)

static func support_fraction(point: Vector2, rect: Rect2) -> float:
	var overlap := Rect2(point-HALF,HALF*2).intersection(rect)
	return overlap.get_area()/(HALF.x*HALF.y*4) if overlap.has_area() else 0.0

func area_support_interval(a: Vector2, b: Vector2, rect: Rect2, minimum: float) -> Vector2:
	var span := overlap_interval(a,b,rect.grow_individual(HALF.x,HALF.y,HALF.x,HALF.y))
	if span.x < 0: return span
	if support_fraction(a.lerp(b,span.x),rect)+EPS >= minimum and support_fraction(a.lerp(b,span.y),rect)+EPS >= minimum:
		return span
	# Rectangle overlap area along a line has one supported interval; find its peak then both crossings.
	var low := span.x
	var high := span.y
	for iteration in range(32):
		var left := lerpf(low,high,1.0/3)
		var right := lerpf(low,high,2.0/3)
		if support_fraction(a.lerp(b,left),rect) < support_fraction(a.lerp(b,right),rect): low = left
		else: high = right
	var peak := (low+high)*0.5
	if support_fraction(a.lerp(b,peak),rect)+EPS < minimum: return Vector2(-1,-1)
	low = span.x
	high = peak
	for iteration in range(32):
		var middle := (low+high)*0.5
		if support_fraction(a.lerp(b,middle),rect)+EPS >= minimum: high = middle
		else: low = middle
	var enter := high
	low = peak
	high = span.y
	for iteration in range(32):
		var middle := (low+high)*0.5
		if support_fraction(a.lerp(b,middle),rect)+EPS >= minimum: low = middle
		else: high = middle
	return Vector2(enter,low)

static func uncovered_fraction(point: Vector2, pit: Rect2, decks: Array[Rect2]) -> float:
	var clipped := Rect2(point-HALF,HALF*2).intersection(pit)
	if not clipped.has_area(): return 0
	var pieces: Array[Rect2] = [clipped]
	# Sequential subtraction forms the complement of the union, without double-counting shared tops.
	for deck in decks:
		var remaining: Array[Rect2] = []
		for piece in pieces:
			var cut := piece.intersection(deck)
			if not cut.has_area():
				remaining.append(piece)
				continue
			for rect in [Rect2(piece.position,Vector2(cut.position.x-piece.position.x,piece.size.y)),
				Rect2(Vector2(cut.end.x,piece.position.y),Vector2(piece.end.x-cut.end.x,piece.size.y)),
				Rect2(Vector2(cut.position.x,piece.position.y),Vector2(cut.size.x,cut.position.y-piece.position.y)),
				Rect2(Vector2(cut.position.x,cut.end.y),Vector2(cut.size.x,piece.end.y-cut.end.y))]:
				if rect.has_area(): remaining.append(rect)
		pieces = remaining
	var area := 0.0
	for piece in pieces: area += piece.get_area()
	return area/(HALF.x*HALF.y*4)

func _opening_motion(obstacle: Dictionary, time: float, dt: float, deck := false) -> Array[Rect2]:
	var motion: Dictionary = obstacle.get("motion",{})
	var pad := 0.0
	if not motion.is_empty():
		pad = absf(float(motion.get("amplitude",0)))*pow(TAU/maxf(.01,float(motion.get("period",2))),2)*dt*dt/8
	if deck and deck_surface_shape(obstacle) == "ellipse":
		var size := obstacle_rect(obstacle).size
		pad *= sqrt(2.0)*maxf(size.x,size.y)/minf(size.x,size.y)
	# Chord uncertainty can delay a fall, never enlarge the actual uncovered opening.
	var rect := obstacle_rect(obstacle).grow(pad if deck else -pad)
	return [Rect2(rect.position+motion_offset(obstacle,time),rect.size),
		Rect2(rect.position+motion_offset(obstacle,time+dt),rect.size)]

func _opening_sample(a: Vector2, b: Vector2, pit: Array[Rect2], decks: Array, fraction: float) -> float:
	var tops: Array[Rect2] = []
	for pair in decks: tops.append(Rect2(pair[0].position.lerp(pair[1].position,fraction),pair[0].size))
	return uncovered_fraction(a.lerp(b,fraction),Rect2(pit[0].position.lerp(pit[1].position,fraction),pit[0].size),tops)

static func _interval_union_length(intervals: Array[Vector2], bottom: float, top: float) -> float:
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var end := bottom
	var length := 0.0
	for interval in intervals:
		var start := maxf(bottom,interval.x)
		var finish := minf(top,interval.y)
		if finish > maxf(end,start): length += finish-maxf(end,start)
		end = maxf(end,finish)
	return length

static func _strip_support_bounds(left: float, right: float, clip: Rect2, tops: Array) -> Vector2:
	var inner: Array[Vector2] = []
	var outer: Array[Vector2] = []
	for top: Dictionary in tops:
		var rect: Rect2 = top.rect
		if left >= rect.end.x or right <= rect.position.x: continue
		if top.shape != "ellipse":
			inner.append(Vector2(rect.position.y,rect.end.y))
			outer.append(Vector2(rect.position.y,rect.end.y))
			continue
		var center := rect.get_center()
		var radii := rect.size*.5
		var near_x := 0.0 if left <= center.x and right >= center.x else minf(absf(left-center.x),absf(right-center.x))
		var far_x := maxf(absf(left-center.x),absf(right-center.x))
		var minimum := radii.y*sqrt(maxf(0,1-pow(far_x/radii.x,2)))
		var maximum := radii.y*sqrt(maxf(0,1-pow(near_x/radii.x,2)))
		inner.append(Vector2(center.y-minimum,center.y+minimum))
		outer.append(Vector2(center.y-maximum,center.y+maximum))
	return Vector2(_interval_union_length(inner,clip.position.y,clip.end.y),
		_interval_union_length(outer,clip.position.y,clip.end.y))

static func _ellipse_rect_area(ellipse: Rect2, rect: Rect2) -> float:
	var radii := ellipse.size*.5
	var lo := (rect.position-ellipse.get_center())/radii
	var hi := (rect.end-ellipse.get_center())/radii
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
		var integral := .5*(b*sqrt(maxf(0,1-b*b))+asin(b)-a*sqrt(maxf(0,1-a*a))-asin(a))
		var top := hi.y*(b-a) if hi.y < height else integral
		var bottom := lo.y*(b-a) if lo.y > -height else -integral
		area += top-bottom
	return maxf(0,area*radii.x*radii.y)

static func _disjoint_ellipse_bounds(clip: Rect2, tops: Array) -> Vector2:
	var ellipses: Array[Rect2] = []
	var pieces: Array[Rect2] = [clip]
	for top: Dictionary in tops:
		var rect: Rect2 = top.rect
		if top.shape == "ellipse":
			if not ellipses.has(rect): ellipses.append(rect)
			continue
		var remaining: Array[Rect2] = []
		for piece in pieces:
			var cut := piece.intersection(rect)
			if not cut.has_area():
				remaining.append(piece)
				continue
			for part in [Rect2(piece.position,Vector2(cut.position.x-piece.position.x,piece.size.y)),
				Rect2(Vector2(cut.end.x,piece.position.y),Vector2(piece.end.x-cut.end.x,piece.size.y)),
				Rect2(Vector2(cut.position.x,piece.position.y),Vector2(cut.size.x,cut.position.y-piece.position.y)),
				Rect2(Vector2(cut.position.x,cut.end.y),Vector2(cut.size.x,piece.end.y-cut.end.y))]:
				if part.has_area(): remaining.append(part)
		pieces = remaining
	for first in range(ellipses.size()):
		for second in range(first+1,ellipses.size()):
			if ellipses[first].intersection(ellipses[second]).has_area(): return Vector2(-1,-1)
	# Current caps are disjoint: analytic ellipse integrals avoid adaptive work in live collision.
	var area := 0.0
	for piece in pieces:
		area += piece.get_area()
		for ellipse in ellipses: area -= _ellipse_rect_area(ellipse,piece)
	var fraction := clampf(area/(HALF.x*HALF.y*4),0,1)
	return Vector2(maxf(0,fraction-EPS),minf(1,fraction+EPS))

static func uncovered_shape_bounds(point: Vector2, pit: Rect2, tops: Array) -> Vector2:
	var clip := Rect2(point-HALF,HALF*2).intersection(pit)
	if not clip.has_area(): return Vector2.ZERO
	var exact := _disjoint_ellipse_bounds(clip,tops)
	if exact.x >= 0: return exact
	var cuts: Array[float] = [clip.position.x,clip.end.x]
	for top: Dictionary in tops:
		var rect: Rect2 = top.rect
		for x in [rect.position.x,rect.end.x]:
			if x > clip.position.x and x < clip.end.x: cuts.append(x)
	cuts.sort()
	var stack: Array[Vector3] = []
	for index in range(cuts.size()-1): stack.append(Vector3(cuts[index],cuts[index+1],0))
	var covered := Vector2.ZERO
	var footprint := HALF.x*HALF.y*4
	while not stack.is_empty():
		var strip: Vector3 = stack.pop_back()
		var width := strip.y-strip.x
		if width <= 0: continue
		var bounds := _strip_support_bounds(strip.x,strip.y,clip,tops)
		# Certified inner/outer ellipse strips bound the actual UNION, including overlapping shapes.
		# Any unresolved area is counted as support, so numerical uncertainty cannot cause an early fall.
		if (bounds.y-bounds.x)*clip.size.x > footprint*.00002 and strip.z < 16:
			var middle := (strip.x+strip.y)*.5
			if middle > strip.x and middle < strip.y:
				stack.append(Vector3(strip.x,middle,strip.z+1))
				stack.append(Vector3(middle,strip.y,strip.z+1))
				continue
		covered += bounds*width
	return Vector2(maxf(0,clip.get_area()-covered.y),maxf(0,clip.get_area()-covered.x))/footprint

func _curved_opening_bounds(a: Vector2, b: Vector2, pit: Array[Rect2], decks: Array, at: float) -> Vector2:
	var tops: Array = []
	for deck: Dictionary in decks:
		var pair: Array = deck.pair
		tops.append({"rect":Rect2(pair[0].position.lerp(pair[1].position,at),pair[0].size),"shape":deck.shape})
	return uncovered_shape_bounds(a.lerp(b,at),Rect2(pit[0].position.lerp(pit[1].position,at),pit[0].size),tops)

func _curved_opening_spans(obstacle: Dictionary, a: Vector2, b: Vector2, time: float, dt: float) -> Array[Vector2]:
	var pit := _opening_motion(obstacle,time,dt)
	var decks: Array = []
	var travel := (b-a).abs()+(pit[1].position-pit[0].position).abs()
	for deck: Dictionary in course.obstacles:
		if deck.kind != "deck": continue
		var pair := _opening_motion(deck,time,dt,true)
		decks.append({"pair":pair,"shape":deck_surface_shape(deck)})
		travel += (pair[1].position-pair[0].position).abs()
	# Symmetric-difference area bounds every possible overlap change during a straight sweep.
	var variation := travel.x/HALF.x+travel.y/HALF.y
	var result: Array[Vector2] = []
	var pending: Array[Vector2] = [Vector2(0,1)]
	while not pending.is_empty():
		var span: Vector2 = pending.pop_back()
		var middle := (span.x+span.y)*.5
		var bounds := _curved_opening_bounds(a,b,pit,decks,middle)
		var uncertainty := variation*(span.y-span.x)*.5
		if bounds.x-uncertainty >= PIT_FALL_FRACTION:
			result.append(span)
		elif bounds.y+uncertainty < PIT_FALL_FRACTION:
			continue
		elif uncertainty <= .00002:
			# At the subpixel boundary retain only certified lethal samples; never bridge a safe pocket.
			for at in [span.x,middle,span.y]:
				if _curved_opening_bounds(a,b,pit,decks,at).x >= PIT_FALL_FRACTION: result.append(Vector2(at,at))
		else:
			pending.append(Vector2(middle,span.y))
			pending.append(Vector2(span.x,middle))
	result.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.x < right.x)
	return result

func uncovered_spans(obstacle: Dictionary, a: Vector2, b: Vector2, time: float, dt: float) -> Array[Vector2]:
	if course.obstacles.any(func(deck: Dictionary) -> bool: return deck.kind == "deck" and deck_surface_shape(deck) == "ellipse"):
		return _curved_opening_spans(obstacle,a,b,time,dt)
	var pit := _opening_motion(obstacle,time,dt)
	var decks: Array = []
	var geometry: Array = [[Rect2(a-HALF,HALF*2),Rect2(b-HALF,HALF*2)],pit]
	for deck: Dictionary in course.obstacles:
		if deck.kind != "deck": continue
		var pair := _opening_motion(deck,time,dt,true)
		decks.append(pair)
		geometry.append(pair)
	# All rectangle boundary orderings stay fixed between these crossings. The uncovered area on
	# each interval is therefore quadratic, including disconnected openings between adjacent decks.
	var cuts: Array[float] = [0.0,1.0]
	for axis in [0,1]:
		var edges: Array[Vector2] = []
		for pair in geometry:
			edges.append(Vector2(pair[0].position[axis],pair[1].position[axis]))
			edges.append(Vector2(pair[0].end[axis],pair[1].end[axis]))
		for first in range(edges.size()):
			for second in range(first+1,edges.size()):
				var offset := edges[first].x-edges[second].x
				var change := edges[first].y-edges[second].y-offset
				if absf(change) <= EPS: continue
				var at := -offset/change
				if at > 0 and at < 1: cuts.append(at)
	cuts.sort()
	var result: Array[Vector2] = []
	for index in range(cuts.size()-1):
		var lo := cuts[index]
		var hi := cuts[index+1]
		if hi-lo <= EPS: continue
		var f0 := _opening_sample(a,b,pit,decks,lo)-PIT_FALL_FRACTION
		var fm := _opening_sample(a,b,pit,decks,(lo+hi)*.5)-PIT_FALL_FRACTION
		var f1 := _opening_sample(a,b,pit,decks,hi)-PIT_FALL_FRACTION
		var quadratic := 2*(f1+f0-2*fm)
		var linear := f1-f0-quadratic
		var roots: Array[float] = [0.0,1.0]
		if absf(quadratic) <= EPS:
			if absf(linear) > EPS:
				var root := -f0/linear
				if root > 0 and root < 1: roots.append(root)
		else:
			var discriminant := linear*linear-4*quadratic*f0
			if discriminant >= 0:
				for root in [(-linear-sqrt(discriminant))/(2*quadratic),(-linear+sqrt(discriminant))/(2*quadratic)]:
					if root > 0 and root < 1: roots.append(root)
		roots.sort()
		for root in roots:
			if quadratic*root*root+linear*root+f0 >= -EPS:
				var at := lerpf(lo,hi,root)
				result.append(Vector2(at,at))
		for part in range(roots.size()-1):
			var middle := (roots[part]+roots[part+1])*.5
			if quadratic*middle*middle+linear*middle+f0 >= -EPS:
				result.append(Vector2(lerpf(lo,hi,roots[part]),lerpf(lo,hi,roots[part+1])))
	result.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.x < right.x)
	return result

func _relative_interval(obstacle: Dictionary, a: Vector2, b: Vector2, time: float, dt: float, supported := false) -> Vector2:
	var rect := obstacle_rect(obstacle)
	# Bound sinusoid curvature for both hazard expansion and full-board deck containment.
	var motion: Dictionary = obstacle.get("motion",{})
	var pad := 0.0
	if not motion.is_empty():
		pad = absf(float(motion.get("amplitude",0)))*pow(TAU/maxf(.01,float(motion.get("period",2))),2)*dt*dt/8
	var extent := HALF+Vector2.ONE*pad
	if not supported and obstacle.kind in ["gap","long_pit"]:
		# A rim touch is safe: at least 65% of the ground footprint must cross into the void.
		return area_support_interval(a-motion_offset(obstacle,time),b-motion_offset(obstacle,time+dt),
			rect.grow(-pad),PIT_FALL_FRACTION)
	if supported:
		var minimum := float(obstacle.get("minimum_support_fraction",0.5))
		if minimum < 1.0:
			return area_support_interval(a-motion_offset(obstacle,time),b-motion_offset(obstacle,time+dt),
				rect.grow(-pad),minimum)
		if rect.size.x < extent.x*2 or rect.size.y < extent.y*2: return Vector2(-1,-1)
		rect = rect.grow_individual(-extent.x,-extent.y,-extent.x,-extent.y)
	else:
		rect = rect.grow_individual(extent.x,extent.y,extent.x,extent.y)
	return overlap_interval(a-motion_offset(obstacle,time),b-motion_offset(obstacle,time+dt),rect)

func _float_distance(obstacle: Dictionary, a: Vector2, b: Vector2, age: float, time: float, dt: float, at: float) -> float:
	var offset := a.lerp(b,at)-Vector2(obstacle.x,obstacle.y)-motion_offset(obstacle,time+dt*at)
	var planar := Vector2(maxf(0,absf(offset.x)-HALF.x)/(float(obstacle.width)*.5),
		maxf(0,absf(offset.y)-HALF.y)/(float(obstacle.depth)*.5))
	var elevation := height(age+dt*at) if age >= 0 else render_height
	return planar.length_squared()+pow(maxf(0,elevation+5)/50,2)

func _float_contact(obstacle: Dictionary, a: Vector2, b: Vector2, age: float, time: float, dt: float, span: Vector2) -> float:
	var pending: Array[Vector2] = [span]
	while not pending.is_empty():
		var part: Vector2 = pending.pop_back()
		if _float_distance(obstacle,a,b,age,time,dt,part.x) <= 1: return part.x
		var from := a.lerp(b,part.x)-Vector2(obstacle.x,obstacle.y)-motion_offset(obstacle,time+dt*part.x)
		var to := a.lerp(b,part.y)-Vector2(obstacle.x,obstacle.y)-motion_offset(obstacle,time+dt*part.y)
		var motion: Dictionary = obstacle.get("motion",{})
		var pad := 0.0
		if not motion.is_empty(): pad = absf(float(motion.get("amplitude",0)))*pow(TAU/float(motion.get("period",2)),2)*pow(dt*(part.y-part.x),2)/8
		var nearest := Vector2.ZERO
		for axis in [0,1]:
			var low := minf(from[axis],to[axis])-pad
			var high := maxf(from[axis],to[axis])+pad
			nearest[axis] = 0 if low <= 0 and high >= 0 else minf(absf(low),absf(high))
		nearest = Vector2(maxf(0,nearest.x-HALF.x)/(float(obstacle.width)*.5),
			maxf(0,nearest.y-HALF.y)/(float(obstacle.depth)*.5))
		var minimum_height := minf(height(age+dt*part.x),height(age+dt*part.y)) if age >= 0 else render_height
		if nearest.length_squared()+pow(maxf(0,minimum_height+5)/50,2) > 1: continue
		var middle := (part.x+part.y)*.5
		if part.y-part.x <= .000001:
			for at in [middle,part.y]:
				if _float_distance(obstacle,a,b,age,time,dt,at) <= 1: return at
		else:
			pending.append(Vector2(middle,part.y))
			pending.append(Vector2(part.x,middle))
	return INF

static var elbow_contact_meshes: Dictionary = {}

static func _contact_triangle(vertices: Array[Vector3]) -> Dictionary:
	var axes: Array[Vector3] = [Vector3.RIGHT,Vector3.UP,Vector3.BACK]
	var edges: Array[Vector3] = [vertices[1]-vertices[0],vertices[2]-vertices[1],vertices[0]-vertices[2]]
	axes.append(edges[0].cross(edges[1]).normalized())
	for edge in edges:
		for axis in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]:
			var cross_axis: Vector3 = edge.cross(axis)
			if cross_axis.length_squared() > EPS: axes.append(cross_axis.normalized())
	var limits: Array[Vector2] = []
	for axis in axes:
		var values := Vector3(axis.dot(vertices[0]),axis.dot(vertices[1]),axis.dot(vertices[2]))
		limits.append(Vector2(minf(values.x,minf(values.y,values.z)),maxf(values.x,maxf(values.y,values.z))))
	var bounds := AABB(vertices[0],Vector3.ZERO)
	for vertex in vertices: bounds = bounds.expand(vertex)
	return {"axes":axes,"limits":limits,"bounds":bounds.grow(EPS)}

static func _contact_quad(mesh: Array, vertices: Array[Vector3]) -> void:
	mesh.append(_contact_triangle([vertices[0],vertices[1],vertices[2]]))
	mesh.append(_contact_triangle([vertices[0],vertices[2],vertices[3]]))

static func _elbow_mesh(width: float) -> Array:
	if elbow_contact_meshes.has(width): return elbow_contact_meshes[width]
	# Same outer loft and outlet torus as ride_world_props. Coordinates use physical centimetres;
	# model bank coordinates are doubled by the production view's BANK_SCALE=2.
	var points: Array[Vector3] = [Vector3(-width*.5+35,-60,0),Vector3(-width*.5+35,30,0)]
	for index in range(1,13):
		var angle := PI-index/12.0*PI*.5
		points.append(Vector3(-width*.5+80+cos(angle)*45,30+sin(angle)*45,0))
	points.append(Vector3(width*.5-35,75,0))
	var mesh: Array = []
	for index in range(points.size()-1):
		var tangent_a := (points[mini(index+1,points.size()-1)]-points[maxi(0,index-1)]).normalized()
		var tangent_b := (points[mini(index+2,points.size()-1)]-points[index]).normalized()
		var side_a := tangent_a.cross(Vector3.BACK).normalized()
		var side_b := tangent_b.cross(Vector3.BACK).normalized()
		for ring in range(24):
			var r0 := TAU*ring/24
			var r1 := TAU*(ring+1)/24
			_contact_quad(mesh,[points[index]+(side_a*cos(r0)+Vector3.BACK*sin(r0))*35,
				points[index+1]+(side_b*cos(r0)+Vector3.BACK*sin(r0))*35,
				points[index+1]+(side_b*cos(r1)+Vector3.BACK*sin(r1))*35,
				points[index]+(side_a*cos(r1)+Vector3.BACK*sin(r1))*35])
	for ring in range(24):
		for section in range(8):
			var vertices: Array[Vector3] = []
			for uv in [Vector2(ring,section),Vector2(ring+1,section),Vector2(ring+1,section+1),Vector2(ring,section+1)]:
				var around: float = TAU*uv.x/24
				var tube: float = TAU*uv.y/8
				var radius := 32.0+3.0*cos(tube)
				vertices.append(Vector3(width*.5-35+3.0*sin(tube),75+radius*cos(around),radius*sin(around)))
			_contact_quad(mesh,vertices)
	elbow_contact_meshes[width] = mesh
	return mesh

static func _quadratic_band(aa: float, bb: float, cc: float, limits: Vector2, span: Vector2) -> Array[Vector2]:
	var cuts: Array[float] = [span.x,span.y]
	for boundary in [limits.x,limits.y]:
		if absf(aa) <= EPS:
			if absf(bb) > EPS:
				var root: float = (boundary-cc)/bb
				if root > span.x and root < span.y: cuts.append(root)
		else:
			var discriminant: float = bb*bb-4*aa*(cc-boundary)
			if discriminant >= 0:
				for root in [(-bb-sqrt(discriminant))/(2*aa),(-bb+sqrt(discriminant))/(2*aa)]:
					if root > span.x and root < span.y: cuts.append(root)
	cuts.sort()
	var result: Array[Vector2] = []
	for cut in cuts:
		var value := aa*cut*cut+bb*cut+cc
		if value >= limits.x-EPS and value <= limits.y+EPS: result.append(Vector2(cut,cut))
	for index in range(cuts.size()-1):
		var middle := (cuts[index]+cuts[index+1])*.5
		var value := aa*middle*middle+bb*middle+cc
		if value >= limits.x-EPS and value <= limits.y+EPS: result.append(Vector2(cuts[index],cuts[index+1]))
	result.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.x < right.x)
	var merged: Array[Vector2] = []
	for part in result:
		if not merged.is_empty() and part.x <= merged[-1].y:
			merged[-1].y = maxf(merged[-1].y,part.y)
		else:
			merged.append(part)
	return merged

static func _mesh_contact(shape: Dictionary, aa: Vector3, bb: Vector3, cc: Vector3, half: Vector3, span: Vector2) -> float:
	var spans: Array[Vector2] = [span]
	for index in range(shape.axes.size()):
		var axis: Vector3 = shape.axes[index]
		var radius := axis.abs().dot(half)
		var limits: Vector2 = shape.limits[index]+Vector2(-radius,radius)
		var next: Array[Vector2] = []
		for part in spans: next.append_array(_quadratic_band(axis.dot(aa),axis.dot(bb),axis.dot(cc),limits,part))
		spans = next
		if spans.is_empty(): return INF
	var first := INF
	for part in spans: first = minf(first,part.x)
	return first

func _elbow_contact(obstacle: Dictionary, a: Vector2, b: Vector2, age: float, dt: float, head: float, span: Vector2) -> float:
	var half := Vector3(HALF.x,head*.5,HALF.y*2)
	var cc := Vector3(a.x-float(obstacle.x),render_height+head*.5,(a.y-float(obstacle.y))*2)
	var bb := Vector3(b.x-a.x,0,(b.y-a.y)*2)
	var aa := Vector3.ZERO
	if age >= 0:
		var velocity := launch_velocity if ballistic else 360.0
		var gravity := launch_gravity if ballistic else 600.0
		cc.y = launch_height+velocity*age-gravity*age*age+head*.5
		bb.y = (velocity-2*gravity*age)*dt
		aa.y = -gravity*dt*dt
	var paths: Array = [{"a":aa,"b":bb,"c":cc,"span":span}]
	if age >= 0 and age+dt >= active_jump_duration:
		var floor_at := clampf((active_jump_duration-age)/dt,span.x,span.y)
		paths[0].span.y = floor_at
		if age+dt*span.x >= active_jump_duration: paths.clear()
		var floor_c := cc; floor_c.y = head*.5
		var floor_b := bb; floor_b.y = 0
		paths.append({"a":Vector3.ZERO,"b":floor_b,"c":floor_c,"span":Vector2(floor_at,span.y)})
	var first := INF
	var base := {"axes":[Vector3.RIGHT,Vector3.UP,Vector3.BACK],"limits":[
		Vector2(-float(obstacle.width)*.5,float(obstacle.width)*.5),Vector2(-80,5),Vector2(-float(obstacle.depth),float(obstacle.depth))]}
	for path: Dictionary in paths:
		first = minf(first,_mesh_contact(base,path.a,path.b,path.c,half,path.span))
		var start: Vector3 = path.a*path.span.x*path.span.x+path.b*path.span.x+path.c
		var finish: Vector3 = path.a*path.span.y*path.span.y+path.b*path.span.y+path.c
		var bounds := AABB(start-half,half*2).merge(AABB(finish-half,half*2))
		if absf(path.a.y) > EPS:
			var peak: float = -path.b.y/(2*path.a.y)
			if peak > path.span.x and peak < path.span.y:
				var center: Vector3 = path.a*peak*peak+path.b*peak+path.c
				bounds = bounds.merge(AABB(center-half,half*2))
		for triangle: Dictionary in _elbow_mesh(float(obstacle.width)):
			if not bounds.intersects(triangle.bounds): continue
			first = minf(first,_mesh_contact(triangle,path.a,path.b,path.c,half,path.span))
	return first

func _vertical_spans(kind: String, obstacle: Dictionary, age: float, dt: float, overlap: Vector2, head: float) -> Array:
	if kind == "support": return [overlap]
	var threshold := 0.0
	var above := kind == "overhead"
	if kind == "low_barrier": threshold = float(obstacle.get("clearance",28))
	if above: threshold = float(obstacle.get("bottom_z",110))-head
	if ramp_active:
		return [overlap] if (above and render_height >= threshold) or (not above and render_height <= threshold) else []
	if age < 0:
		if kind in ["gap","long_pit"]: return [overlap]
		return [overlap] if (above and render_height >= threshold) or (not above and render_height <= threshold) else []
	if threshold > active_jump_apex: return [] if above else [overlap]
	if threshold < 0: return [overlap] if above else []
	var ascent: float
	var descent: float
	var velocity := launch_velocity if ballistic else 360.0
	var gravity := launch_gravity if ballistic else 600.0
	var discriminant := velocity*velocity+4*gravity*(launch_height-threshold)
	var root := sqrt(maxf(0,discriminant))
	ascent = ((velocity-root)/(2*gravity)-age)/dt
	descent = ((velocity+root)/(2*gravity)-age)/dt
	var spans: Array = [Vector2(ascent,descent)] if above else [Vector2(-INF,ascent),Vector2(descent,INF)]
	var result: Array = []
	for span in spans:
		var lo := maxf(overlap.x,span.x)
		var hi := minf(overlap.y,span.y)
		if hi > lo or (hi == lo and kind in ["gap","long_pit","overhead"]): result.append(Vector2(lo,hi))
	return result

func _surface(x: float) -> float:
	var left := float(active_ramp.x)-float(active_ramp.width)*0.5
	var u := (x-left)/float(active_ramp.width)
	var rise := float(active_ramp.get("rise",40))
	if u <= 0: return 0
	if u > 1: return rise*(2*u-1)
	return rise*u*u

func _ramp_geometry(x: float) -> Array[float]:
	# Solve the chord's projected width so the rotated rigid110px board touches at both ends.
	var low := 0.0
	var high := 55.0
	for iteration in range(32):
		var half_x := (low+high)*0.5
		var rise := _surface(x+half_x)-_surface(x-half_x)
		if 4*half_x*half_x+rise*rise > 110*110:
			high = half_x
		else:
			low = half_x
	var half_x := (low+high)*0.5
	var rear := _surface(x-half_x)
	var front := _surface(x+half_x)
	return [(rear+front)*0.5,-atan2(front-rear,2*half_x),half_x]

func _ramp_pose(x: float) -> void:
	var pose := _ramp_geometry(x)
	render_height = pose[0]
	render_pitch = pose[1]
	jump_height = render_height

func _launch(ramp := false) -> void:
	active_jump_duration = 1.25 if ramp else 0.6
	active_jump_apex = 54
	jump_age = 0
	boosted = ramp
	ballistic = ramp
	if ramp:
		var x := position.x+encounter_scroll
		_ramp_pose(x)
		launch_height = render_height
		launch_pitch = render_pitch
		# Differentiate the solved center path, including its changing projected contact width.
		launch_velocity = scroll_speed*(_ramp_geometry(x+0.01)[0]-_ramp_geometry(x-0.01)[0])/0.02
		launch_gravity = (launch_height+launch_velocity*active_jump_duration)/pow(active_jump_duration,2)
		active_jump_apex = launch_height+launch_velocity*launch_velocity/(4*launch_gravity)
	else:
		launch_height = ground_height
		active_jump_duration = (360+sqrt(360*360+2400*launch_height))/1200
		active_jump_apex = launch_height+54
		render_height = launch_height
		render_pitch = 0
	jump_height = render_height
	ramp_active = false
	emit_event("ramp" if ramp else "jump")

func tick(host: Node2D, delta: float, steering: Vector2, jumping: bool) -> void:
	if complete or host.paused or host.life_state != "alive" or delta <= 0: return
	var remaining := delta
	var pressed := jumping
	while remaining > EPS and not complete and host.life_state == "alive":
		var dt := minf(STEP,remaining)
		if phase == "rest": dt = minf(dt,rest_remaining)
		if phase == "rest":
			clock += dt
			rest_remaining = maxf(0,rest_remaining-dt)
			host.invulnerable = maxf(0,host.invulnerable-dt)
			# Safe rest has no collision/warning actors; movement remains responsive.
			position += steering.limit_length()*Vector2(x_speed,bank_speed)*dt
			position = position.clamp(Vector2(180,260),Vector2(650,400))
			if pressed and jump_age < 0 and cooldown <= 0:
				_launch()
			_advance_air_motion(dt)
			if rest_remaining <= EPS:
				_advance_encounter(host)
		else:
			_step(host,dt,steering,pressed)
		remaining -= dt
		pressed = false
	sync_hero(host)

func _step(host: Node2D, dt: float, steering: Vector2, pressed: bool, check_ramps := true, check_decks := true) -> void:
	var old_age := jump_age
	var start_position := position
	var a := position+Vector2(encounter_scroll,0)
	if jump_age < 0 and not ramp_active:
		var initial_support := deck_support(a,encounter_clock)
		if float(initial_support.height) > ground_height:
			ground_height = initial_support.height
			render_height = ground_height
			jump_height = ground_height
			landing_material = initial_support.material
	var input := steering.limit_length()
	var movement := Vector2(0 if boosted or ramp_active else input.x*x_speed,input.y*bank_speed)*dt
	var next_position := (position+movement).clamp(Vector2(180,260),Vector2(650,400))
	var b := next_position+Vector2(encounter_scroll+scroll_speed*dt,0)
	# Losing full bank support cannot retain or reacquire the automatic ramp launch.
	if ramp_active:
		var bank_min := float(active_ramp.y)-float(active_ramp.depth)*0.5+HALF.y
		var bank_max := float(active_ramp.y)+float(active_ramp.depth)*0.5-HALF.y
		if next_position.y < bank_min or next_position.y > bank_max:
			# Leaving the side drops naturally to the water; it never grants the long-pit boost.
			ramp_active = false
			boosted = false
			launch_height = render_height
			launch_velocity = 0
			launch_gravity = 181.128
			launch_pitch = render_pitch
			active_jump_duration = sqrt(launch_height/launch_gravity)
			active_jump_apex = launch_height
			ballistic = active_jump_duration > EPS
			jump_age = 0 if ballistic else -1
			old_age = jump_age
	# Split entry and lip events exactly, so the entire attached composite follows one surface pose.
	if ramp_active:
		var lip := float(active_ramp.get("launch_x",float(active_ramp.x)+float(active_ramp.width)*0.5))
		if check_ramps and a.x < lip and b.x >= lip:
			var fraction := (lip-a.x)/(b.x-a.x)
			_step(host,dt*fraction,steering,false,false)
			_launch(true)
			_step(host,dt*(1-fraction),steering,false,false)
			return
		if a.x >= lip and check_ramps:
			_launch(true)
			_step(host,dt,steering,false,false)
			return
	elif check_ramps:
		var ramp: Dictionary = {}
		var ramp_at := 2.0
		for obstacle: Dictionary in course.obstacles:
			if obstacle.kind != "ramp" or used_ramps.has(obstacle.id): continue
			var rect := obstacle_rect(obstacle)
			var entry_x := rect.position.x-55
			if a.x > entry_x or b.x < entry_x or b.x <= a.x: continue
			var at := (entry_x-a.x)/(b.x-a.x)
			var bank := lerpf(a.y,b.y,at)
			used_ramps[obstacle.id] = true
			if jump_age >= 0 or rect.size.y < HALF.y*2: continue
			if bank-HALF.y < rect.position.y or bank+HALF.y > rect.end.y: continue
			if at < ramp_at:
				ramp = obstacle
				ramp_at = at
		if not ramp.is_empty():
			if ramp_at > EPS: _step(host,dt*ramp_at,steering,false,false)
			if host.life_state != "alive": return
			used_ramps[ramp.id] = true
			active_ramp = ramp
			ramp_active = true
			_ramp_pose(position.x+encounter_scroll)
			_step(host,dt*(1-ramp_at),steering,false,false)
			return
	if dt <= EPS: return
	if pressed and jump_age < 0 and not ramp_active and cooldown <= 0:
		_launch()
		old_age = 0
	if check_decks and not ramp_active:
		var transition := _deck_transition(a,b,encounter_clock,dt)
		if not transition.is_empty():
			var fraction: float = transition.at
			if fraction > EPS: _step(host,dt*fraction,steering,false,false,false)
			if host.life_state != "alive": return
			if jump_age >= 0:
				_land_on(transition.support)
			elif float(transition.support.height) < ground_height:
				_drop_from_deck()
			else:
				ground_height = transition.support.height
				render_height = ground_height
				jump_height = ground_height
				landing_material = transition.support.material
			_step(host,dt*(1-fraction),steering,false,false,false)
			return
	position = next_position
	clock += dt
	encounter_scroll += scroll_speed*dt
	var contacts: Array[Dictionary] = []
	for obstacle: Dictionary in course.obstacles:
		var kind := str(obstacle.kind)
		if kind in ["deck","ramp"]: continue
		var motion: Dictionary = obstacle.get("motion",{})
		var max_x := absf(float(motion.get("amplitude",0))) if motion.get("axis","") == "x" else 0.0
		if contact_latches.has(obstacle.id):
			if b.x-HALF.x > float(obstacle.x)+float(obstacle.width)*0.5+max_x: contact_latches.erase(obstacle.id)
			continue
		var interval := _relative_interval(obstacle,a,b,encounter_clock,dt)
		if interval.x < 0: continue
		# A destructible floor becomes unsupported at the same timestamp as its visible impact.
		var activation_fraction := (float(obstacle.get("activates_at",0))-encounter_clock)/dt
		if activation_fraction > interval.y: continue
		interval.x = maxf(interval.x,activation_fraction)
		var spans := _vertical_spans(kind,obstacle,old_age,dt,interval,hero_head_height(host))
		if str(obstacle.get("art_id","")) == "float_ball":
			var at := _float_contact(obstacle,a,b,old_age,encounter_clock,dt,interval)
			spans = [Vector2(at,at)] if at != INF else []
		elif str(obstacle.get("art_id","")) == "elbow_pipe_v2":
			var at := _elbow_contact(obstacle,a,b,old_age,dt,hero_head_height(host),interval)
			spans = [Vector2(at,at)] if at != INF else []
		if kind in ["gap","long_pit"] and not spans.is_empty():
			var uncovered := uncovered_spans(obstacle,a,b,encounter_clock,dt)
			var actual: Array = []
			for span in spans:
				for opening in uncovered:
					var lo := maxf(span.x,opening.x)
					var hi := minf(span.y,opening.y)
					if lo <= hi: actual.append(Vector2(lo,hi))
			actual.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.x < right.x)
			spans = actual
		if not spans.is_empty(): contacts.append({"obstacle":obstacle,"at":spans[0].x})
	contacts.sort_custom(func(left: Dictionary,right: Dictionary) -> bool: return left.at < right.at)
	var processed := 0.0
	for contact in contacts:
		var event_time := float(contact.at)*dt
		host.invulnerable = maxf(0,host.invulnerable-(event_time-processed))
		processed = event_time
		var obstacle: Dictionary = contact.obstacle
		if obstacle.kind in ["gap","long_pit"]:
			if host.life_state == "alive":
				# Freeze at the actual unsupported contact, not the end of this simulation substep.
				position = start_position.lerp(next_position,float(contact.at))
				clock -= dt-event_time
				encounter_scroll -= scroll_speed*(dt-event_time)
				encounter_clock += event_time
				render_height = height(old_age+event_time) if old_age >= 0 else ground_height
				jump_height = render_height
				host.health = 1
				host.invulnerable = 0
				host.hurt_player()
				emit_event("fall",str(obstacle.id))
			return
		contact_latches[obstacle.id] = true
		if host.invulnerable <= 0:
			host.hurt_player()
			hit_ids[obstacle.id] = true
			emit_event("hit",str(obstacle.id))
			if host.life_state != "alive": return
	host.invulnerable = maxf(0,host.invulnerable-(dt-processed))
	encounter_clock += dt
	_advance_air_motion(dt)
	if _encounter_clear():
		rest_remaining = _rest_duration()
		if rest_remaining <= EPS:
			_advance_encounter(host)
		else:
			phase = "rest"
			course = {"obstacles":[]}
			emit_event("rest_started")

func _advance_encounter(host: Node2D) -> void:
	if encounter_index+1 >= definition.encounters.size():
		complete = true
		phase = "complete"
		host.won = true
		emit_event("finished")
	else:
		_start_encounter(encounter_index+1)

func _expected_contact_age() -> float:
	var contact_age := active_jump_duration
	var point := position+Vector2(encounter_scroll,0)
	for deck: Dictionary in course.obstacles:
		if deck.kind != "deck": continue
		var discriminant := launch_velocity*launch_velocity+4*launch_gravity*(launch_height-deck_surface_height(deck))
		if discriminant < 0: continue
		var age := (launch_velocity+sqrt(discriminant))/(2*launch_gravity)
		if age < jump_age or age >= contact_age: continue
		var until := age-jump_age
		var landing := point+Vector2(scroll_speed*until,0)
		if _deck_top_interval(deck,landing,landing,encounter_clock+until,0).x >= 0: contact_age = age
	return contact_age

func _advance_air_motion(dt: float) -> void:
	recovery_clock = maxf(0,recovery_clock-dt)
	cooldown = maxf(0,cooldown-dt)
	if jump_age >= 0:
		jump_age += dt
		if jump_age+EPS >= active_jump_duration:
			_land_on(deck_support(position+Vector2(encounter_scroll,0),encounter_clock))
	jump_height = height(jump_age)
	render_height = jump_height
	if ramp_active:
		_ramp_pose(position.x+encounter_scroll)
	elif ballistic:
		var tangent := -atan2(launch_velocity-2*launch_gravity*jump_age,scroll_speed)
		render_pitch = lerpf(launch_pitch,tangent,clampf(jump_age/0.12,0,1))
		# Level the rigid composite before contact instead of snapping its angle on the landing frame.
		var settling := clampf((_expected_contact_age()-jump_age)/0.18,0,1)
		render_pitch *= settling*settling*(3-2*settling)
	else:
		render_pitch = 0

func _rest_duration() -> float:
	var rest: Dictionary = definition.get("rest",{})
	return maxf(0,float(encounter.get("rest_after_seconds",rest.get("duration",3.0))))

func _encounter_clear() -> bool:
	# Legacy positive-rest fixtures retain their quiet landing boundary; zero-rest rides never wait for flight.
	if _rest_duration() > EPS and jump_age >= 0: return false
	if ramp_active or recovery_clock > EPS or not contact_latches.is_empty(): return false
	for obstacle: Dictionary in course.obstacles:
		var motion: Dictionary = obstacle.get("motion",{})
		var max_x := absf(float(motion.get("amplitude",0))) if motion.get("axis","") == "x" else 0.0
		if float(obstacle.x)+float(obstacle.width)*0.5+max_x-encounter_scroll >= 180-HALF.x: return false
	return true
