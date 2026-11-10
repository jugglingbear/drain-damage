extends SceneTree
## Lifecycle boundaries must remove special effects immediately without refunding their uses.
const Section = preload("res://scripts/section_one_two_game.gd")
const Integrated = preload("res://scripts/integrated_first_call.gd")
var failures: Array[String] = []
var checks_run := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func prepare(script: GDScript, hero: String) -> Node2D:
	var game = script.new()
	for employee in game.Crew.EMPLOYEES:
		if employee.id == hero: game.employee = employee
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.awaiting_release = false
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.restart_guard_device = -1
	game.paused = false
	game.life_state = "alive"
	game.grounded = true
	game.player = Vector2(120,394)
	game.camera_x = 0
	game.facing = 1
	game.current_aim = Vector2.RIGHT
	game.invulnerable = 1000
	if script == Integrated:
		game.intro_input_release = false
		game.boss_intro.seen = {"cockroach-swarm":true,"clogfather":true}
	if hero == "sean":
		for x in range(100,6000,100):
			game.player = Vector2(x,394)
			if game.special_pipe_clear(game.player+Vector2(57,46)): break
	return game

func arm(game: Node2D, spent: bool) -> void:
	check(game.specials.begin(game),"Fixture must spend an actual charge")
	game.specials.step(game,7.5 if spent else 1.2)
	if spent:
		check(game.specials.spent_pipes.size() == 1,"Normal expiry keeps Sean's spent pipe")
	else:
		check(game.specials.active and game.special_audio.loop_voice.playing,"Fixture has active effect and loop")
	game.specials.held = true

func clean(game: Node2D, budget: Dictionary, label: String, detached := false) -> void:
	check(not game.specials.active,label+": inactive immediately")
	check(game.specials.spent_pipes.is_empty(),label+": no persistent pipe visuals")
	check(game.specials.water_segments(game).is_empty(),label+": no water visual/damage geometry")
	check(game.specials.budgets == budget,label+": spent charges are not refunded")
	check(not game.special_audio.active,label+": audio timeline stopped")
	if not detached:
		check(not game.special_audio.loop_voice.playing,label+": loop stopped immediately")
		for voice in game.special_audio.voices:
			check(not voice.playing,label+": one-shot voice stopped")
	var serial: int = game.specials.tick_serial
	game.specials.step(game,1)
	check(game.specials.tick_serial == serial,label+": no subsequent damage ticks")

func lifecycle(script: GDScript, hero: String, spent: bool, boundary: String) -> void:
	var game := prepare(script,hero)
	arm(game,spent)
	var budget: Dictionary = game.specials.budgets.duplicate(true)
	var label := hero+"/"+("spent/" if spent else "active/")+boundary
	match boundary:
		"death":
			game.health = 1
			game.invulnerable = 0
			game.hurt_player()
			check(game.life_state == "dying",label+": actual lethal hit")
		"pit":
			game.begin_pit_fall()
			check(game.life_state == "dying",label+": actual pit death")
		"respawn":
			game.life_state = "dying"
			game.respawn_after_death()
		"retry": game.reset_game()
		"title": game.request_title()
		"teardown": root.remove_child(game)
	clean(game,budget,label,boundary == "teardown")
	if boundary in ["death","pit"]:
		game.respawn_after_death()
		clean(game,budget,label+"/checkpoint")
		game.respawn_after_death()
		clean(game,budget,label+"/repeated checkpoint")
	if game.is_inside_tree(): root.remove_child(game)
	game.free()

func skitterling_checkpoint(hero: String) -> void:
	var game := prepare(Integrated,hero)
	game.skitterling.entered = true
	game.skitterling.encounter.hp = 0
	game.save_skitterling_checkpoint()
	check(game.post_skitterling_checkpoint,"Actual Skitterling completion saves checkpoint")
	arm(game,false)
	var budget: Dictionary = game.specials.budgets.duplicate(true)
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	clean(game,budget,hero+" Skitterling death")
	game.respawn_after_death()
	clean(game,budget,hero+" Skitterling respawn")
	check(game.player.x == game.Level.POST_SKITTERLING_CHECKPOINT,"Respawn uses Skitterling checkpoint")
	root.remove_child(game)
	game.free()

func cancellation_reasons() -> void:
	for reason in ["death","retry","title","teardown","inactive","configuration change","level transition"]:
		var game := prepare(Section,"sean")
		arm(game,true)
		game.player.x += 120
		arm(game,false)
		var budget: Dictionary = game.specials.budgets.duplicate(true)
		game.specials.cancel(reason)
		clean(game,budget,reason)
		game.specials.cancel(reason)
		clean(game,budget,"repeated "+reason)
		check(game.specials.held,"Cleanup preserves held-input guard")
		root.remove_child(game)
		game.free()

func checks() -> void:
	for script in [Section,Integrated]:
		for hero in ["tony","sean"]:
			for boundary in ["death","pit","respawn","retry","title","teardown"]:
				if boundary == "pit" and script == Integrated: continue
				lifecycle(script,hero,false,boundary)
				if hero == "sean": lifecycle(script,hero,true,boundary)
	for hero in ["tony","sean"]: skitterling_checkpoint(hero)
	cancellation_reasons()
	print("Special death cleanup: %d checks, %d failures" % [checks_run,failures.size()])
	await create_timer(0.2).timeout
	quit(0 if failures.is_empty() else 1)
