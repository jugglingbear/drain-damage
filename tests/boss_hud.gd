extends SceneTree
const HUD = preload("res://scripts/boss_hud.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var hud := HUD.new()
	root.add_child(hud)
	for id in ["cockroach-swarm","clogfather"]:
		hud.begin_encounter(id)
		for part: Dictionary in hud.definition.skins[id].values():
			if part.has("texture_key"):
				assert(Rect2(Vector2.ZERO,hud.textures[part.texture_key].get_size()).encloses(hud.rect(part.source_rect)))
			assert(Rect2(864,82,96,458).encloses(hud.rect(part.destination)))
		var fill: Dictionary = hud.definition.skins[id]["fill" if id == "cockroach-swarm" else "fill_green"]
		var whole := hud.fill_regions(fill,1)
		var quarter := hud.fill_regions(fill,.25)
		assert(is_equal_approx(quarter[1].end.y,whole[1].end.y),"Remaining HP stays anchored at bottom")
		assert(is_equal_approx(quarter[1].size.y,whole[1].size.y*.25))
		assert(is_equal_approx(quarter[0].size.y,whole[0].size.y*.25),"Crop rather than squeeze")
		assert(not hud.fill_regions(fill,0)[1].has_area())
	hud.begin_encounter("cockroach-swarm")
	assert(hud.active and hud.maximum == 1440 and hud.hp == 1440)
	assert(hud.boss_id == "cockroach-swarm" and hud.reserved_height() == 0)
	hud.player_status = "Tony   HP 5 / 5   LIVES 3"
	await process_frame
	hud.update_hp(900)
	assert(hud.hp == 900 and hud.trail == 1)
	hud.tick(.1)
	assert(hud.trail == 1)
	hud.tick(.4)
	assert(is_equal_approx(hud.trail, 900.0 / 1440))
	# A phase transition cannot refill the shared encounter bar.
	hud.update_hp(1440)
	assert(hud.hp == 900)
	for value in [540, 360, 144, 1]:
		hud.update_hp(value)
		await process_frame
		assert(hud.hp == value)
	hud.update_hp(NAN)
	assert(hud.hp == 1)
	hud.update_hp(0)
	assert(hud.trail == 0 and hud.active)
	hud.tick(1)
	assert(hud.opacity == 1)
	hud.tick(.175)
	assert(is_equal_approx(hud.opacity, .5))
	hud.tick(.175)
	assert(not hud.active and hud.reserved_height() == 0)
	hud.begin_encounter("cockroach-swarm")
	assert(hud.hp == 1440 and hud.trail == 1 and hud.opacity == 1)
	await process_frame
	hud.end_encounter()
	assert(not hud.active and hud.hp == 0 and hud.trail == 0)
	hud.begin_encounter("clogfather")
	assert(hud.active and hud.boss_id == "clogfather")
	await process_frame
	hud.queue_free()
	await process_frame
	print("PASS: boss HUD damage trail, phase continuity, low HP, death fade, retry and vertical skins, fixed header without persistent names")
	quit()
