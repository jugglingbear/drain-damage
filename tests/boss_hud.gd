extends SceneTree
const HUD = preload("res://scripts/boss_hud.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var hud := HUD.new()
	root.add_child(hud)
	assert(hud.swarm_frame != null and hud.swarm_fill != null)
	assert(hud.swarm_frame.get_size() == Vector2(1728, 112))
	assert(hud.swarm_fill.get_size() == Vector2(1536, 40))
	var frame_image := hud.swarm_frame.get_image()
	for y in range(36, 76):
		for x in range(96, 1632):
			assert(frame_image.get_pixel(x, y).a == 0, "Frame must not obscure the HP boundary")
	hud.begin_encounter("cockroach-swarm")
	assert(hud.active and hud.maximum == 1440 and hud.hp == 1440)
	assert(hud.boss_id == "cockroach-swarm" and hud.reserved_height() == 110)
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
	print("PASS: boss HUD damage trail, phase continuity, low HP, death fade, retry and default boss style")
	quit()
