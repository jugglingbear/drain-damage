extends SceneTree
## Exercise the formal ride checkpoint through the real game host and selector.
const Launch = preload("res://scripts/playtest_launch.gd")

var failures: Array[String] = []
var cases := 0
var tick_hz := 60

func _initialize() -> void:
	call_deferred("checks")

func require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func snapshot(game: Node2D) -> Dictionary:
	var ride: RefCounted = game.flush.ride
	return {"checkpoint":[ride.checkpoint.phase,ride.checkpoint.age,ride.checkpoint.injured,ride.checkpoint.saved],"clock":ride.clock,
		"scroll":ride.encounter_scroll,"position":ride.position,"velocity":ride.steering_velocity,
		"dispenser_elapsed":game.dispenser.elapsed,"health":game.health,"lives":game.lives,"seed":game.run_seed}

func advance(game: Node2D, dt: float, steering := Vector2.ZERO) -> void:
	game.dispenser.tick(game,dt)
	game.flush.tick(game,dt,steering,false,false)

func check_paused(game: Node2D) -> void:
	var before := snapshot(game)
	game.paused = true
	advance(game,0.5,Vector2.ONE)
	require(snapshot(game) == before,"Pause advanced checkpoint or changed player state")
	game.paused = false

func wait_for_phase(game: Node2D, wanted: String, seconds: float, steering := Vector2.ZERO) -> bool:
	for frame in ceili(seconds*tick_hz):
		if game.flush.ride.checkpoint.phase == wanted: return true
		advance(game,1.0/tick_hz,steering)
	require(false,"Checkpoint did not reach "+wanted+" within "+str(seconds)+" seconds")
	return false

func exercise_arrival(game: Node2D, target: Dictionary, injured: bool, hz: int) -> void:
	print("CHECKPOINT_CASE ",game.employee.id," injured=",injured," hz=",hz)
	tick_hz = hz
	game.flush.active = false
	game.reset_game()
	Launch.initialize(game,target)
	var ride: RefCounted = game.flush.ride
	game.health = int(game.employee.max_health)-2 if injured else int(game.employee.max_health)
	var lives: int = game.lives
	var seed_value: int = game.run_seed
	require(ride.checkpoint.phase == "approach" and not ride.checkpoint.saved,"Selector did not start unsaved approach")
	game.flush.input_guard = false
	ride.sample_super(game,false)
	require(ride.sample_super(game,true),"Approaching rider lost B")
	require(not ride.sample_super(game,true),"Held B repeated")
	check_paused(game)
	if not wait_for_phase(game,"waiting",4): return
	require(ride.position.x <= 320 and not ride.checkpoint.saved,"Approach failed to leave rider before machine")
	check_paused(game)
	ride.sample_super(game,false)
	require(ride.sample_super(game,true) and game.specials.remaining() == 0,"Waiting rider lost second B")
	game.flush.tick(game,1.0/hz,Vector2.ZERO,true,true)
	require(ride.jump_age >= 0 and not ride.fidget.effects.is_empty(),"Waiting rider lost jump or X action")
	# Enter the pickup area during the jump; inspection must wait for water contact.
	ride.position.x = 360
	advance(game,1.0/hz)
	require(ride.jump_age >= 0 and ride.checkpoint.phase == "waiting","Machine grabbed airborne rider")
	ride.position.x = 300
	var scroll: float = ride.encounter_scroll
	for frame in hz:
		advance(game,1.0/hz)
	require(ride.checkpoint.phase == "waiting" and ride.encounter_scroll == scroll,"Idle waiting moved course or activated machine")
	require(game.invulnerable <= 0,"Launch protection persisted into waiting")
	# Riders approaching on either bank can steer straight ahead into the pickup area.
	for frame in hz:
		advance(game,1.0/hz,Vector2.UP if injured else Vector2.DOWN)
	for frame in hz*3:
		if ride.checkpoint.phase == "replacement": break
		advance(game,1.0/hz,Vector2.RIGHT)
	if ride.checkpoint.phase != "replacement":
		require(false,"Returning to machine did not activate replacement")
		return
	for frame in ceili(hz*0.2): advance(game,1.0/hz)
	require(ride.position.distance_to(Vector2(455,330)) < 0.01,"Replacement did not ease rider into dock")
	require(ride.checkpoint.injured == injured,"Checkpoint classified arrival health incorrectly")
	require(not ride.checkpoint.saved,"Checkpoint saved before departure")
	check_paused(game)
	if not wait_for_phase(game,"departure",30): return
	require(game.health == game.employee.max_health and game.lives == lives,"Inspection changed life stock or failed healing")
	check_paused(game)
	if not wait_for_phase(game,"runout",ride.checkpoint.DEPARTURE_SECONDS + 0.5): return
	require(game.specials.remaining() == 2,"Checkpoint failed to recharge both specials")
	ride.sample_super(game,false)
	require(ride.sample_super(game,true),"Refilled special unusable in runout")
	require(ride.checkpoint.saved,"Departure did not save formal checkpoint")
	require(game.run_seed == seed_value,"Checkpoint changed run seed")
	check_paused(game)
	var before_scroll: float = ride.encounter_scroll
	for frame in hz*4:
		advance(game,1.0/hz,Vector2(1,-1))
		require(game.health == game.employee.max_health and game.lives == lives,"Runout damaged hero")
		require(not ride.complete,"Runout completed before five seconds")
	require(ride.encounter_scroll > before_scroll,"Runout failed to move")
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	require(game.lives == lives-1,"Saved checkpoint death did not debit exactly one life")
	game.hurt_player()
	require(game.lives == lives-1,"Repeated damage double-debited death")
	game.respawn_after_death()
	require(game.specials.remaining() == 2,"Respawn failed to recharge both specials")
	require(ride.checkpoint.phase == "runout" and ride.checkpoint.saved,"Saved death did not resume at runout")
	require(game.health == game.employee.max_health and game.lives == lives-1 and game.run_seed == seed_value,
		"Saved respawn changed health, life stock or seed incorrectly")
	require(ride.position == Vector2(455,330) and ride.steering_velocity == Vector2.ZERO,"Respawn retained drift")
	for frame in hz*4+int(hz*0.9): advance(game,1.0/hz,Vector2(-1,1))
	require(not ride.complete,"Restored runout finished before five seconds")
	for frame in ceili(hz*0.2): advance(game,1.0/hz,Vector2.ONE)
	require(ride.complete and game.won and game.health == game.employee.max_health,"Five-second exit did not finish safely")
	cases += 1

func exercise_unsaved(game: Node2D, target: Dictionary) -> void:
	for direct in [false,true]:
		print("UNSAVED_CASE ",game.employee.id," direct=",direct)
		game.flush.active = false
		game.reset_game()
		if direct:
			Launch.initialize(game,target)
		else:
			game.begin_level_two()
			game.flush.enter_ride(game)
			var ride: RefCounted = game.flush.ride
			ride.encounter_scroll = float(ride.definition.world_finish)-310
			ride.clock = ride.encounter_scroll/ride.scroll_speed
			ride.encounter_clock = ride.clock
			advance(game,1.0/30)
			require(ride.checkpoint.phase == "approach" and not ride.complete and not game.won,
				"Crossing Wave 2 finish did not enter checkpoint approach")
		var seed_value: int = game.run_seed
		game.health = 1
		game.invulnerable = 0
		game.hurt_player()
		game.respawn_after_death()
		require(game.lives == 2 and game.health == game.employee.max_health and game.run_seed == seed_value,
			"Unsaved death changed life stock, healing or seed")
		require(not game.flush.ride.checkpoint.saved,"Unsaved retry acquired a checkpoint")
		if direct:
			require(game.flush.state == "ride" and game.flush.ride.checkpoint.phase == "approach",
				"Unsaved selector retry did not restart approach")
		else:
			require(game.flush.state == "bowl","Unsaved campaign retry skipped bowl")
		cases += 1

func check_game_over(game: Node2D, title: Node2D) -> void:
	print("CHECKPOINT_GAME_OVER_BEGIN")
	# Use the title owner's actual new-campaign path, not reset_game's retry path.
	game.won = false
	game.paused = false
	game.lives = 1
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	game.step_death(3.0)
	require(game.life_state == "game_over" and game.lives == 0,"Last death did not reach game over")
	var before := snapshot(game)
	game.respawn_after_death()
	require(snapshot(game) == before,"Zero-stock respawn restored checkpoint")
	game.update_death_popup_guard(1.0)
	print("CHECKPOINT_RESTART_REQUEST")
	game.resume_or_retry()
	for frame in 6000:
		if title.card_ready: break
		await process_frame
	require(title.card_ready,"Game-over restart did not prepare new campaign")
	if title.card_ready:
		var press := InputEventJoypadButton.new()
		press.pressed = true
		title._unhandled_input(press)
		var fresh = title.game
		require(fresh != null and not fresh.flush.active and fresh.lives == 3 and fresh.life_state == "alive",
			"Game-over restart did not enter fresh Level 1")
		if fresh != null:
			require(not fresh.flush.ride.checkpoint.saved and fresh.flush.ride.checkpoint.phase == "",
				"Fresh campaign inherited formal ride checkpoint")
			require(fresh.dialogue.active,"Fresh campaign skipped opening")
	title.queue_free()
	await process_frame
	cases += 1

func checks() -> void:
	var options := Launch.parse(PackedStringArray(["--level=2-checkpoint","--seed=17"]))
	if options.has("error"):
		require(false,str(options.error))
		quit(1)
		return
	var title = load("res://main.tscn").instantiate()
	root.add_child(title)
	title.start_game(options)
	for frame in 6000:
		if title.card_ready: break
		await process_frame
	if not title.card_ready:
		require(false,"Checkpoint selector preparation did not finish")
		title.queue_free()
		quit(1)
		return
	var press := InputEventJoypadButton.new()
	press.pressed = true
	title._unhandled_input(press)
	var game = title.game
	if game == null:
		require(false,"Checkpoint selector did not reveal game")
		quit(1)
		return
	game.set_process(false)
	game.set_physics_process(false)
	game.run_seed = 17
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		exercise_unsaved(game,options.target)
		for injured in [false,true]:
			for hz in [30,60,120]: exercise_arrival(game,options.target,injured,hz)
	await check_game_over(game,title)
	await process_frame
	print(JSON.stringify({"cases":cases,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
