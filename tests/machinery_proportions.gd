extends SceneTree
## Proportional art patches must cover authored support without changing collision.
const FirstCall = preload("res://scripts/first_call.gd")
const SIZES := [Vector2(160,60),Vector2(180,60),Vector2(200,60),
	Vector2(60,120),Vector2(180,120),Vector2(220,120),Vector2(200,180)]
const EPSILON := 0.001
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var before: Array = []
	for stage in range(7): before.append(FirstCall.solids(stage).duplicate())
	for size: Vector2 in SIZES:
		for origin in [Vector2.ZERO,Vector2(5010,320),Vector2(-123.5,27.25)]:
			var rect := Rect2(origin,size)
			var patches := FirstCall.prop_patches(rect)
			check(not patches.is_empty(),"Every supported footprint has artwork: "+str(size))
			var top_intervals: Array[Vector2] = []
			for patch: Dictionary in patches:
				var source: Rect2 = patch.source_rect
				var destination: Rect2 = patch.destination
				var index: int = patch.texture_index
				check(index >= 0 and index < 3,"Machinery patch uses a machinery texture")
				if index < 0 or index >= 3: continue
				check(source.size.x > 0 and source.size.y > 0,"Source dimensions are positive")
				if source.size.x <= 0 or source.size.y <= 0: continue
				check(destination.size.x > 0 and destination.size.y > 0,"Destination dimensions are positive")
				var scale := destination.size/source.size
				check(is_equal_approx(scale.x,scale.y),"Patch preserves aspect ratio: "+str(size))
				check(Rect2(Vector2.ZERO,FirstCall.TEXTURES[index].get_size()).grow(EPSILON).encloses(source),
					"Source stays inside native texture")
				check(rect.grow(EPSILON).encloses(destination),"Artwork stays inside authored footprint")
				if absf(destination.position.y-rect.position.y) <= EPSILON:
					top_intervals.append(Vector2(destination.position.x,destination.end.x))
			# Merge intervals rather than sampling pixels, so even narrow support gaps fail.
			top_intervals.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.x < b.x)
			var covered := rect.position.x
			for interval: Vector2 in top_intervals:
				check(interval.x <= covered+EPSILON,"No gap in visible platform top")
				covered = maxf(covered,interval.y)
			check(covered >= rect.end.x-EPSILON,"Artwork covers full collision top")
	for stage in range(7):
		check(FirstCall.solids(stage) == before[stage],"Rendering layout leaves collision unchanged")
	print("Machinery proportions: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
