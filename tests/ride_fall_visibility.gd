extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func coverage(ride: RefCounted, frame: Dictionary, image: Image, transform: Transform2D, elapsed: float) -> int:
	var polygons: Array = ride.falling_polygons(frame,transform,elapsed)
	var d: Array = frame.destination
	var r: Array = frame.source_rect
	var pixels := 0
	# Sample imported opaque texels, not the transparent rectangle around the hero.
	for y in range(0,int(r[3]),6):
		for x in range(0,int(r[2]),6):
			if image.get_pixel(int(r[0])+x,int(r[1])+y).a < 0.5: continue
			var local := Vector2(float(d[0])+x/float(r[2])*float(d[2]),float(d[1])+y/float(r[3])*float(d[3]))
			for polygon: PackedVector2Array in polygons:
				if Geometry2D.is_point_in_polygon(transform*local,polygon):
					pixels += 1
					break
	return pixels

func checks() -> void:
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	var ride = game.flush.ride
	var cases := 0
	for hero in [0,1]:
		game.employee = game.Crew.EMPLOYEES[hero]
		for costume in ["normal","hard"]:
			game.difficulty = costume
			var pose: Dictionary = game.flush.art.manifest.landing[game.employee.id][costume]
			var registration: Array = ride.obstacle_art.manifest.rider_contacts[game.employee.id][costume]
			var frame: Dictionary = pose.front[0]
			var image: Image = game.flush.art.textures[frame.path].get_image()
			for index in [1,6,7,9,10,11,12]:
				game.flush.enter_ride(game,index)
				for gap: Dictionary in ride.course.obstacles:
					if gap.kind not in ["gap","long_pit"]: continue
					for parity in [0,1]:
						ride.clock = 6.0+parity/12.0
						# Place the authored hole at x480; visual clock remains on either blink phase.
						ride.encounter_clock = (float(gap.x)-480)/560
						ride.encounter_scroll = ride.encounter_clock*560
						for edge in [-1,0,1]:
							for bank in [maxf(260,float(gap.y)-float(gap.depth)*0.5-13),float(gap.y),minf(400,float(gap.y)+float(gap.depth)*0.5+13)]:
								ride.position = Vector2(480+edge*(float(gap.width)*0.5+44),bank)
								# Keep edge cases on the viewport; scrolling the hole is independent of screen anchor.
								if ride.position.x < 100 or ride.position.x > 850: continue
								ride.events = {"fall":1}
								ride.last_event = {"obstacle_id":gap.id}
								ride.render_height = 0
								game.life_state = "dying"
								game.invulnerable = 1.5
								assert(ride.rider_visible(game),"Fatal fall must draw on BOTH frozen blink phases")
								var counts: Array[int] = []
								for elapsed in [0.0,0.1,0.3,0.5,0.75,1.0,1.35]:
									game.death_time = elapsed
									var transform: Transform2D = ride.rider_transform(game)*Transform2D(0,-Vector2(registration[0],registration[1]))
									counts.append(coverage(ride,frame,image,transform,elapsed))
								assert(counts[0] > 0 and counts[1] >= counts[0]*0.95,"Initial opaque silhouette cannot vanish")
								assert(counts[2] > 0,"Initial descent must remain readable")
								if ride.fall_opening().size.y >= 60:
									assert(counts[3] > 0,"Deep openings retain visible descent through half a second")
								assert(counts[-1] == 0,"Hero descends fully behind the lip before death UI")
								assert(ride.rider_transform(game).origin.y > 540)
								cases += 1
				for obstacle: Dictionary in ride.course.obstacles:
					if obstacle.kind != "deck": continue
					var art: Dictionary = ride.obstacle_art.manifest.frames[ride.obstacle_frame_id(obstacle)]
					for layer: Dictionary in ride.fall_occluding_frames(art,float(obstacle.depth)*0.5):
						assert(float(layer.destination[1]) >= float(obstacle.depth)*0.5,"No island top may blanket entry")
	game.queue_free()
	await process_frame
	print("PASS: ",cases," imported opaque hero/board silhouette sequences across every ride pit, four poses, entry edges and frozen blink phases; no island-top blanket")
	quit()
