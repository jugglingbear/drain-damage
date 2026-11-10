extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run_checks")
func run_checks() -> void:
	var game = Game.new()
	for hero in game.Crew.EMPLOYEES:
		if hero.id == "sean": game.employee = hero
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.intro_input_release = false
	game.paused = false
	game.life_state = "alive"
	game.camera_x = 6570
	game.player = Vector2(7000,394)
	game.grounded = true
	var room = game.skitterling
	room.entered = true
	var boss = room.encounter
	boss.active = true
	boss.phase = "rat"
	boss.position = Vector2(480,300)
	boss.port = 0
	boss.facing = 1
	game.specials.configure("sean","level-one")
	game.specials.active = true
	game.specials.elapsed = 1.5
	for state in ["rat_pounce","rat_pipe_launch","rat_pipe_abort"]:
		boss.state = state
		boss.elapsed = .1 if state == "rat_pipe_launch" else .2
		boss.hp = boss.MAX_HP
		var regions: Array[Rect2] = room.target_regions()
		check(boss.damageable(),state+" accepts incoming damage while airborne")
		check(not regions.is_empty(),state+" exposes visible targets")
		if regions.is_empty(): continue
		var point := regions[0].get_center()
		game.specials.anchor = Vector2(point.x,440)
		var segments: Array[Dictionary] = game.specials.water_segments(game)
		var before: int = boss.hp
		game.special_damage(segments,24,1,{"skitterling":12,"clogfather":12})
		check(boss.hp == before-12,state+" takes one Sean water tick")
		game.specials.anchor.x = room.ORIGIN.x+900
		before = boss.hp
		game.special_damage(game.specials.water_segments(game),24,1,{"skitterling":12,"clogfather":12})
		check(boss.hp == before,state+" does not take off-target damage")
		if state == "rat_pipe_abort": check(not boss.rat_contact_active(),"Abort stays harmless to hero")
	for state in ["rat_inside_pipe","rat_pipe_warning","rat_collapse","reskitter"]:
		boss.state = state
		check(not boss.damageable() and room.target_regions().is_empty(),state+" stays protected")
	game.specials.active = false
	game.queue_free()
	await process_frame
	print("Airborne Sean special: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
