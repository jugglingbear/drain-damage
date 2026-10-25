extends SceneTree
const Flow = preload("res://scripts/flush_flow.gd")
const TOLERANCE := 0.001

func _initialize() -> void:
	for sample in [[0.0,162.0,316.8],[8.0,162.0,316.8],[21.5,126.0,263.4],
			[35.0,90.0,210.0],[43.0,90.0,210.0]]:
		var bounds := Flow.annulus(sample[0])
		assert(bounds.distance_to(Vector2(sample[1],sample[2])) < TOLERANCE,"Timed annulus contract")
	var cases := 0
	for hz in [60,120]:
		for speed in [235.0,270.0]:
			for limits in [[40.0,105.0,8.0,45.0],[50.0,125.0,10.0,55.0],[60.0,145.0,12.0,65.0]]:
				var flow := {"total_speed_start":limits[0],"total_speed_end":limits[1],
					"inward_speed_start":limits[2],"inward_speed_end":limits[3]}
				for angle in [0.0,PI/4,PI,PI*1.5]:
					var point := Vector2.from_angle(angle)*316.8
					var previous := Flow.annulus(0)
					for frame in range(1,35*hz+1):
						var time: float = float(frame)/hz
						var bounds := Flow.annulus(time)
						# Radial outward steering is stronger than holding any fixed keyboard direction.
						point = Flow.swim(point,point.normalized(),speed,time,1.0/hz,flow)
						assert(absf(point.length()-bounds.y) < TOLERANCE,"Outward input cannot resist contraction")
						assert(bounds.x <= previous.x+TOLERANCE and bounds.y <= previous.y+TOLERANCE)
						assert(bounds.y-bounds.x >= 120-TOLERANCE,"Keep room to dodge")
						previous = bounds
					assert(absf(316.8-point.length()-106.8) < TOLERANCE,"Forced inward displacement")
					cases += 1
				for time in [0.0,8.0,21.5,35.0]:
					var bounds := Flow.annulus(time)
					var inner := Flow.swim(Vector2.RIGHT*bounds.x,Vector2.LEFT,speed,time,1.0/hz,flow)
					assert(absf(inner.length()-bounds.x) < TOLERANCE,"Inward input respects current inner bound")
					var origin := Flow.swim(Vector2.ZERO,Vector2.ZERO,speed,time,1.0/hz,flow)
					assert(origin.is_finite() and absf(origin.length()-bounds.x) < TOLERANCE)
					var start := Vector2.RIGHT*((bounds.x+bounds.y)*0.5)
					var diagonal := Flow.swim(start,Vector2.ONE,speed,time,1.0/hz,flow)
					var normalized := Flow.swim(start,Vector2.ONE.normalized(),speed,time,1.0/hz,flow)
					assert(diagonal.distance_to(normalized) < TOLERANCE,"No diagonal speed boost")
	print("PASS: flush timed bounds, %d outward-held runs, both hero speeds/all modes at 60/120Hz, inner/origin/diagonal checks" % cases)
	quit()
