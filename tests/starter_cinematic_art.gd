extends SceneTree
const Art = preload("res://scripts/starter_cinematic_art.gd")
class Host extends Node2D:
	var cinematic := {"active":true,"elapsed":0.0,"hero_id":"sean"}
	var cinematic_feet := Vector2(480,440)
	var cinematic_facing := 1
	var cinematic_costume := "normal"
	var camera_x := 0.0

var checks := 0
var failures := 0
func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		if failures <= 5: push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var art := Art.new()
	var host := Host.new()
	root.add_child(host)
	for costume: String in art.timeline.sean.poses_by_costume:
		host.cinematic_costume = costume
		for facing in [-1,1]:
			host.cinematic_facing = facing
			for pose: Dictionary in art.timeline.sean.poses_by_costume[costume].values():
				var matrix := art.pose_transform(pose,host.cinematic_feet,facing)
				verify((matrix*art.vector(pose.source_feet_pivot)).is_equal_approx(host.cinematic_feet),
					"Every pose must retain the captured world foot anchor")
				verify(is_equal_approx(matrix.x.length(),matrix.y.length()),"No body stretching")
			for feet in [Vector2(140,200),Vector2(480,440),Vector2(810,390)]:
				host.cinematic_feet = feet+Vector2(300,0)
				host.camera_x = 300
				var previous := Transform2D.IDENTITY
				for index in range(409):
					host.cinematic.elapsed = index/120.0
					var camera := art.camera_transform(host)
					verify(camera.x.x >= 1 and camera.x.x <= 2,"Bounded zoom")
					verify(camera.y.y == camera.x.x and camera.x.y == 0 and camera.y.x == 0,
						"Uniform scale without roll")
					verify(camera.origin.distance_to(previous.origin) < 55,"Continuous framing %s %s at %s" % [camera.origin,previous.origin,host.cinematic.elapsed])
					verify(host.camera_x == 300 and host.cinematic_feet == feet+Vector2(300,0),
						"Rendering must not mutate world registration")
					if index == 0 or index == 408:
						verify(camera == Transform2D.IDENTITY,"Exact baseline at endpoints")
					if index == 120:
						var bounds := camera*art.framing_bounds(costume,feet,facing)
						verify(art.rectangle(art.timeline.safe_rect).encloses(bounds),"Full pose envelope framed %s %s %s" % [costume,facing,bounds])
					previous = camera
	for beat: Dictionary in art.timeline.sean.sequence:
		verify(art.pose_id(beat.start) == beat.pose,"Start-inclusive pose boundaries")
		verify(art.pose_id(float(beat.end)-0.000001) == beat.pose,"End-exclusive pose boundaries")
	host.cinematic.elapsed = 3.4
	var pipe := art.pipe_state(host)
	verify(pipe.elapsed == 1 and pipe.angle == 0,"Exact upright pipe handoff at effect time one")
	verify(pipe.anchor == host.cinematic_feet+Vector2(44*host.cinematic_facing,0),"Fixed pipe socket")
	verify(art.pose_id(3.34) == "gameplay_pose","Gameplay hero restored before control returns")
	host.cinematic.hero_id = "tony"
	verify(art.camera_transform(host) == Transform2D.IDENTITY,"Tony does not zoom")
	verify(art.gauge_state(0).alpha == 0 and art.gauge_state(3.2).alpha == 0,"Gauge fade endpoints")
	verify(is_equal_approx(art.gauge_state(0.55).needle,deg_to_rad(-43)),"Gauge readable start")
	verify(is_equal_approx(art.gauge_state(1.75).needle,deg_to_rad(146)),"Gauge physical maximum")
	verify(is_equal_approx(art.gauge_state(1.75).wheel,TAU),"Whole wheel makes one clockwise turn")
	await art.prepare()
	for costume in art.poses:
		verify(art.poses[costume].size() == art.timeline.sean.poses_by_costume[costume].size(),
			"All registered poses prepared")
	var image: Image = art.components.housing.get_image()
	var bytes := image.get_data()
	var clean := true
	for alpha_index in range(3,bytes.size(),4):
		var alpha: int = bytes[alpha_index]
		if alpha != 0 and alpha < 240: clean = false
	verify(clean,"Art alpha cleanup across the complete housing")
	print("%d checks, %d failures" % [checks,failures])
	host.queue_free()
	await process_frame
	quit(1 if failures else 0)
