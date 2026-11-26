extends RefCounted
## The isolated ramp and full wave use the same authored launch and catch geometry.
const SOURCE := "res://levels/level-two-wave-three-ramp.json"
const FULL_SOURCE := "res://levels/level-two-wave-three.json"

static func build(showcase: Dictionary, origin := 0.0, full := false, difficulty := "normal") -> Dictionary:
	var ramp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var result := showcase.duplicate(true)
	var obstacles: Array = []
	var ramp_origin := origin
	var finish := float(ramp.world_finish)
	var id := str(ramp.id)
	if full:
		var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FULL_SOURCE))
		finish = float(layout.world_finish)
		ramp_origin += float(layout.ramp_translation)
		id = "wave-three"
		var templates := {}
		for encounter: Dictionary in showcase.encounters:
			for piece: Dictionary in encounter.obstacles: templates[piece.id] = piece
		templates["ordinary_gap"] = {"kind":"gap","art_id":"ordinary_gap"}
		templates["long_pit"] = {"kind":"long_pit","art_id":"long_pit"}
		for beat: Dictionary in layout.beats:
			if beat.get("minimum_mode","") == "hard" and difficulty != "hard": continue
			if beat.has("minimum_mode") and difficulty == "easy": continue
			var piece: Dictionary = templates[beat.template].duplicate(true)
			piece.id = beat.get("id","w3-%s-%d" % [beat.template,int(beat.x)])
			piece.x = float(beat.x)+origin
			for key in ["width","depth","y","target_bank","required_actions"]:
				if beat.has(key): piece[key] = beat[key]
			piece.instance_id = id
			if str(beat.template).begins_with("valve-"):
				piece.width = 80
				if beat.template == "valve-c": piece.depth = 55
			if beat.template == "basin-entry" and difficulty == "easy": piece.width += 40
			if beat.template == "strainer-gap-12":
				piece.station = true
				piece.timeline_origin = (piece.x-piece.width*0.5-2540)/float(showcase.scroll_speed)
				piece.activates_at = piece.timeline_origin+3.1
				piece.warning_at = piece.timeline_origin+1.25
			obstacles.append(piece)
	for obstacle: Dictionary in ramp.obstacles:
		obstacle.x = float(obstacle.x)+ramp_origin
		if obstacle.has("launch_x"): obstacle.launch_x = float(obstacle.launch_x)+ramp_origin
		obstacle["instance_id"] = ramp.id
		obstacles.append(obstacle)
	result["continuous"] = true
	result["world_finish"] = origin+finish
	result["retry_world_x"] = [origin+300]
	result.encounters = [{"id":id,"title":"Service Channel Wave 3" if full else "Broken Channel Launch",
		"obstacles":obstacles,"rest_after_seconds":0,"end_x":result.world_finish}]
	return result
