extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var art = load("res://scripts/clogfather_art.gd").new()
	assert(art.prepare())
	for key in ["body","sludge_relaxed","sludge_swell","weak_closed","weak_open","drool",
		"weak_high_closed","weak_high_open","gas_warning_a","gas_warning_b",
		"gas_cloud_a","gas_cloud_b","gas_cloud_c","gas_cloud_d","gas_emit",
		"sludge_projectile_a","sludge_projectile_b","acid_warning","acid_ceiling_warning",
		"acid_drop","acid_puddle","weak_hit","deflect"]:
		assert(art.definition.frames.has(key),"Missing required Clogfather artwork: "+key)
	for stage in ["healthy","mild","moderate","severe","near_death"]:
		assert(art.definition.frames.has("damage_body_"+stage))
	for index in range(6): assert(art.definition.frames.has("collapse_%d" % index))
	for frame: Dictionary in art.definition.frames.values():
		var texture: Texture2D = art.textures[frame.path]
		assert(Rect2(Vector2.ZERO,texture.get_size()).encloses(art.rect(frame.source_rect)))
		assert(art.rect(frame.destination).has_area())
	var hud: Dictionary = art.definition.hud
	assert(Rect2(0,0,960,110).encloses(art.rect(hud.frame.destination)))
	assert(art.rect(hud.frame.destination).encloses(art.rect(hud.aperture)))
	assert(hud.name_baseline_y > 0 and hud.player_status_baseline_y <= 110)
	for key in ["track","frame","fill_green","fill_yellow","fill_red"]:
		var frame: Dictionary = hud[key]
		var texture: Texture2D = load("res://"+frame.path)
		assert(Rect2(Vector2.ZERO,texture.get_size()).encloses(art.rect(frame.source_rect)))
	var inspection: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/spare-employee-dispenser/inspection-contract-v1.json"))
	assert(inspection.release_seconds < inspection.watchdog_seconds)
	assert(inspection.inspection_lens_center[1] < inspection.grip_center[1])
	for frame: Dictionary in inspection.parts.values():
		var texture: Texture2D = load("res://"+frame.path)
		assert(Rect2(Vector2.ZERO,texture.get_size()).encloses(art.rect(frame.source_rect)))
		for pivot: Array in frame.source_pivots.values():
			assert(Rect2(Vector2.ZERO,art.rect(frame.source_rect).size).has_point(Vector2(pivot[0],pivot[1])))
	assert(inspection.diagnosis_art.has("aperture"))
	for mode in ["normal","hard"]:
		for hero in ["tony","sean"]:
			var frame: Dictionary = inspection.hero_states[mode][hero].grab
			var texture: Texture2D = load("res://"+frame.path)
			assert(Rect2(Vector2.ZERO,texture.get_size()).encloses(art.rect(frame.source_rect)))
			assert(is_equal_approx(frame.anchor[0],64) and is_equal_approx(frame.anchor[1],104),
				"Held hero must preserve its registered scale and foot anchor")
	var scenery: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/first-call/background-manifest-v2.json"))
	assert(scenery.world_width == 15200 and not scenery.panels.is_empty())
	var covered := 0.0
	for panel: Dictionary in scenery.panels:
		var destination: Rect2 = art.rect(panel.destination)
		assert(destination.position.x <= covered,"Background gap before "+str(destination.position.x))
		covered = maxf(covered,destination.end.x)
		var texture: Texture2D = load("res://"+panel.path)
		assert(Rect2(Vector2.ZERO,texture.get_size()).encloses(art.rect(panel.source_rect)))
	assert(covered >= 15200)
	print("PASS: complete authored boss/inspection assets, source rectangles, pivots, HUD safe area and terminal frames")
	quit()
