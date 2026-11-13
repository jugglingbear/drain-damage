extends RefCounted
## Compose immutable showcase geometry into a fixed course; only simple reversal spacing changes by mode.
const SOURCE := "res://levels/level-two-ride-continuous.json"

static func build(showcase: Dictionary, difficulty: String) -> Dictionary:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var result := showcase.duplicate(true)
	var obstacles: Array[Dictionary] = []
	var modules: Array[Dictionary] = []
	var spacing := float(layout.spacing.get(difficulty,650))
	var downstream := 2*(spacing-650)
	for instance: Dictionary in layout.instances:
		var source: Dictionary = {}
		for candidate: Dictionary in showcase.encounters:
			if candidate.id == instance.source: source = candidate
		assert(not source.is_empty())
		var translation := float(instance.get("translate_x",0))+downstream
		if instance.has("centers"): translation = 0
		var module := {"id":instance.id,"source":source.id,"source_version":showcase.schema_version,
			"origin":translation,"title":source.title,"warning_seconds":source.warning_seconds}
		var timeline: Dictionary = source.get("strainer_timeline",source.get("hand_timeline",{}))
		module["timeline"] = timeline.duplicate(true)
		modules.append(module)
		for index in range(source.obstacles.size()):
			var obstacle: Dictionary = source.obstacles[index].duplicate(true)
			if instance.has("obstacle_ids") and obstacle.id not in instance.obstacle_ids: continue
			obstacle["source_id"] = obstacle.id
			obstacle["instance_id"] = instance.id
			obstacle["source_family"] = source.id
			obstacle.id = str(instance.id)+"/"+str(obstacle.id)
			obstacle.x = 2600+index*spacing if instance.has("centers") else float(obstacle.x)+translation
			obstacle.x += float(instance.get("obstacle_x_offsets",{}).get(obstacle.source_id,0))
			obstacle["timeline_origin"] = translation/float(showcase.scroll_speed)
			if obstacle.has("activates_at"):
				obstacle.activates_at = float(obstacle.activates_at)+float(obstacle.timeline_origin)
				obstacle["warning_at"] = float(timeline.warning_at)+float(obstacle.timeline_origin)
			obstacles.append(obstacle)
	result["continuous"] = true
	result["retry_world_x"] = [300,6000+downstream,9000+downstream]
	result["world_finish"] = float(layout.world_finish)+downstream
	result["modules"] = modules
	result.encounters = [{"id":layout.id,"title":"Service Channel","obstacles":obstacles,
		"rest_after_seconds":0,"end_x":result.world_finish}]
	return result
