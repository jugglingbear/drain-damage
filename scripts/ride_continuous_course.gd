extends RefCounted
## Compose immutable showcase geometry into a fixed course; only simple reversal spacing changes by mode.
const SOURCE := "res://levels/level-two-ride-continuous.json"

static func build(showcase: Dictionary, difficulty: String, run_seed := 42) -> Dictionary:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var result := showcase.duplicate(true)
	var obstacles: Array[Dictionary] = []
	var modules: Array[Dictionary] = []
	var stations: Array = []
	var spacing := float(layout.spacing.get(difficulty,410))
	var slalom_start := float(layout.instances[0].start_x)
	var downstream := 7*(spacing-410)
	for instance: Dictionary in layout.instances:
		if instance.has("stations"): stations = instance.stations
		var source: Dictionary = {}
		for candidate: Dictionary in showcase.encounters:
			if candidate.id == instance.source: source = candidate
		assert(not source.is_empty())
		var translation := float(instance.get("translate_x",0))+downstream
		if instance.has("sequence"): translation = 0
		var module := {"id":instance.id,"source":source.id,"source_version":showcase.schema_version,
			"origin":translation,"title":source.title,"warning_seconds":source.warning_seconds}
		var timeline: Dictionary = source.get("strainer_timeline",source.get("hand_timeline",{}))
		module["timeline"] = timeline.duplicate(true)
		modules.append(module)
		var pieces: Array = source.obstacles
		if instance.has("sequence"):
			var templates := {}
			for piece: Dictionary in pieces: templates[piece.id] = piece
			pieces = []
			for id: String in instance.sequence: pieces.append(templates[id])
		for index in range(pieces.size()):
			var obstacle: Dictionary = pieces[index].duplicate(true)
			if instance.has("obstacle_ids") and obstacle.id not in instance.obstacle_ids: continue
			obstacle.merge(instance.get("obstacle_overrides",{}).get(obstacle.id,{}),true)
			obstacle["source_id"] = obstacle.id
			obstacle["instance_id"] = instance.id
			obstacle["source_family"] = source.id
			obstacle.id = str(instance.id)+"/"+str(obstacle.id)
			if instance.has("sequence"):
				obstacle.id += "-%d" % index
				obstacle.width = 80
				if obstacle.source_id == "valve-c": obstacle.depth = 55
			obstacle.x = float(instance.start_x)+index*spacing if instance.has("sequence") else float(obstacle.x)+translation
			obstacle.x += float(instance.get("obstacle_x_offsets",{}).get(obstacle.source_id,0))
			obstacle["timeline_origin"] = translation/float(showcase.scroll_speed)
			if obstacle.has("activates_at"):
				obstacle.activates_at = float(obstacle.activates_at)+float(obstacle.timeline_origin)
				obstacle["warning_at"] = float(timeline.warning_at)+float(obstacle.timeline_origin)
			obstacles.append(obstacle)
			if obstacle.source_id == "flange-front":
				for beat: Dictionary in instance.get("additional_flange_beats",[]):
					var center := float(beat.get("world_x",0))+downstream
					if beat.has("slalom_index"): center = slalom_start+float(beat.slalom_index)*spacing
					for offset: float in beat.offsets:
						var joint := obstacle.duplicate(true)
						joint.x = center+offset
						joint.id = "flange-at-%d" % int(joint.x)
						obstacles.append(joint)
	# Two waves of three drop stations with bounded timing jitter.
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var prototype: Dictionary
	for i in range(obstacles.size()):
		if obstacles[i].instance_id == "slice-strainer":
			prototype = obstacles.pop_at(i)
			break
	# Mirror the whole bank sequence so each seeded pattern preserves its tested transitions.
	var mirror := -1 if rng.randi_range(0,1) == 0 else 1
	for index in stations.size():
		var station: Dictionary = stations[index]
		var gap := prototype.duplicate(true)
		gap.id = "drop-%d-%d" % [floori(index/3.0),index%3]
		gap["station"] = true
		gap.x = float(station.x)+downstream
		gap.y = 330+mirror*float(station.bank_offset)
		gap.width = station.length
		gap.depth = station.depth
		# Keep the original approach lead measured from the upstream edge, including on long cuts.
		gap.timeline_origin = (float(gap.x)-float(gap.width)*.5-2540)/float(showcase.scroll_speed)+rng.randf_range(-.12,.12)
		gap.activates_at = gap.timeline_origin+3.1
		gap.warning_at = gap.timeline_origin+1.25
		obstacles.append(gap)
		if station.get("opposite_baffle",false):
			var baffle: Dictionary
			for valve in obstacles:
				if valve.source_id == ("valve-b" if gap.y < 330 else "valve-a"):
					baffle = valve.duplicate(true)
					break
			baffle.id = "strainer-side-baffle"
			baffle.x = gap.x
			baffle.depth = 65
			baffle.y = 397.5 if gap.y < 330 else 262.5
			obstacles.append(baffle)
	for obstacle in obstacles:
		if obstacle.instance_id == "slice-exit-baffle": obstacle.x += 1530
	result["continuous"] = true
	result["retry_world_x"] = [300,6000+downstream,9000+downstream]
	result["world_finish"] = float(layout.world_finish)+downstream
	result["modules"] = modules
	result.encounters = [{"id":layout.id,"title":"Service Channel","obstacles":obstacles,
		"rest_after_seconds":0,"end_x":result.world_finish}]
	return result
