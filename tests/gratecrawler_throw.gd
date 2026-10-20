extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("run_checks")

func prepare(game: Node, patrol: float, side: float) -> Dictionary:
	game.reset_observation()
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.paused = false
	game.trial_level.plinths.clear()
	game.trial_level.decks.clear()
	game.player = Vector2(600+side*250,394)
	game.camera_x = 150
	game.invulnerable = 1000
	game.trial_state.advance(2)
	var event: Dictionary = {}
	for item in game.trial_state.results().events:
		if item.role == "floor_emerger": event = item; break
	assert(not event.is_empty() and game.trial_state.reserve(event.id))
	game.trial_state.advance(2)
	assert(game.trial_state.activate(event.id))
	game.create_actor(event,Vector2(600,440))
	var actor: Dictionary = game.actors[0]
	actor.active = true
	actor.facing = patrol
	return actor

func step(game: Node, dt: float) -> void:
	game.trial_state.advance(dt)
	game.step_trial_actors(dt)

func begin_throw(game: Node, actor: Dictionary, dt: float) -> void:
	for tick in range(1200):
		step(game,dt)
		if actor.get("throw_state","") == "windup": return
	assert(false,"Visible Gratecrawler must start its throw")

func clear_projectiles(game: Node) -> void:
	for shot in game.hostile_shots: game.trial_state.remove_bullet(shot.id)
	game.hostile_shots.clear()

func check_sequence(game: Node, dt: float, patrol: float, side: float) -> void:
	var actor := prepare(game,patrol,side)
	begin_throw(game,actor,dt)
	var feet: Vector2 = actor.feet
	var target: Vector2 = game.player+game.PLAYER_SIZE*0.5
	assert(actor.throw_target == target and actor.facing == side and actor.patrol_facing == patrol)
	var started: float = actor.age-actor.throw_clock
	# Crossing after commitment cannot reverse the windup or redirect its projectile.
	game.player.x = 600-side*250
	var releases := 0
	var recovered := false
	var release_seconds: float = game.muck_throw_art.release_seconds
	var duration: float = game.muck_throw_art.duration_seconds
	for tick in range(240):
		step(game,dt)
		assert(actor.feet.distance_to(feet) < 0.001,"Throw must plant the feet")
		if not game.hostile_shots.is_empty():
			assert(game.hostile_shots.size() == 1 and releases == 0,"One projectile per throw")
			var shot: Dictionary = game.hostile_shots[0]
			assert(absf(actor.age-started-release_seconds) <= dt*2)
			assert(shot.target == target and actor.facing == side)
			assert(shot.pos.distance_to(game.muck_hand(actor)) < 0.001,"Release from authored hand")
			var frame: Dictionary = game.muck_throw_frame(actor)
			var offset := Vector2(frame.hand[0],frame.hand[1])-Vector2(
				game.muck_throw_art.anchor[0],game.muck_throw_art.anchor[1])
			offset *= game.role_scale("floor_emerger")
			offset.x *= -side
			assert(shot.pos.distance_to(actor.feet+offset) < 0.001,"Mirror hand around feet anchor")
			releases += 1
			clear_projectiles(game)
		if actor.throw_state == "":
			assert(absf(actor.age-started-duration) <= dt*2)
			assert(actor.facing == patrol,"Restore original patrol heading")
			recovered = true
			break
	assert(recovered and releases == 1)
	step(game,dt)
	assert((actor.feet.x-feet.x)*patrol > 0,"Resume the saved patrol after recovery")

func check_repeats(game: Node, dt: float) -> void:
	var actor := prepare(game,-1,1)
	var times: Array[float] = []
	for tick in range(int(8/dt)):
		step(game,dt)
		if not game.hostile_shots.is_empty():
			assert(game.hostile_shots.size() == 1)
			times.append(actor.age)
			clear_projectiles(game)
	assert(times.size() >= 3)
	for index in range(1,times.size()):
		assert(absf(times[index]-times[index-1]-2.5) <= dt*2,"Recovery is included in repeat cadence")

func check_interruptions(game: Node, dt: float) -> void:
	for reason in ["hit","death","offscreen","reset"]:
		var actor := prepare(game,-1,1)
		begin_throw(game,actor,dt)
		match reason:
			"hit": game.damage_trial_actor(actor,1)
			"death": game.damage_trial_actor(actor,actor.hp)
			"offscreen":
				game.camera_x = 2000
				step(game,dt)
			"reset": game.reset_observation()
		if reason in ["hit","offscreen"]:
			assert(actor.throw_state == "" and actor.facing == -1,"Cancel and restore patrol")
		# A cancelled windup must never emit its pending shot on the next tick.
		step(game,dt)
		assert(game.hostile_shots.is_empty(),reason)
		if reason == "hit":
			for tick in range(int(0.7/dt)): step(game,dt)
			assert(game.hostile_shots.is_empty(),"Hit cancellation must not restart the first-shot timer")
		if reason in ["death","reset","offscreen"]:
			for tick in range(int(1/dt)): step(game,dt)
			assert(game.hostile_shots.is_empty(),reason)
	var actor := prepare(game,-1,1)
	begin_throw(game,actor,dt)
	var before: Dictionary = actor.duplicate(true)
	game.paused = true
	game.step_trial_actors(2)
	game.step_muck_thrower(actor,2,true)
	assert(actor == before and game.hostile_shots.is_empty(),"Pause freezes pending throw")
	game.paused = false
	for tick in range(int(1/dt)): step(game,dt)
	assert(game.hostile_shots.size() == 1,"Unpause releases once")

func check_close_target(game: Node, dt: float) -> void:
	for side in [-1.0,1.0]:
		var actor := prepare(game,side,side)
		game.player.x = actor.feet.x+side-game.PLAYER_SIZE.x*0.5
		actor.shot_clock = 0.3
		begin_throw(game,actor,dt)
		var recovered := false
		for tick in range(240):
			step(game,dt)
			assert(game.hostile_shots.is_empty(),"Do not throw backward through the body at a close target")
			if actor.throw_state == "recover":
				assert((actor.throw_target.x-game.muck_hand(actor).x)*actor.facing <= 0)
				recovered = true
				break
		assert(recovered,"Close target must complete windup without a backward projectile")

func check_recovery_interruptions(game: Node, dt: float) -> void:
	for lethal in [false,true]:
		var actor := prepare(game,-1,1)
		begin_throw(game,actor,dt)
		for tick in range(240):
			step(game,dt)
			if actor.throw_state == "recover": break
		assert(actor.throw_state == "recover" and game.hostile_shots.size() == 1)
		clear_projectiles(game)
		game.damage_trial_actor(actor,actor.hp if lethal else 1)
		assert(actor.throw_state == "" and actor.facing == -1)
		for tick in range(int(0.7/dt)): step(game,dt)
		assert(game.hostile_shots.is_empty(),"Recovery interruption cannot duplicate an already released ball")

func run_checks() -> void:
	create_timer(45).timeout.connect(func() -> void: quit(1))
	var game = Game.new()
	game.seed_override = 42
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	var total := 0.0
	for frame in game.muck_throw_art.frames: total += float(frame.duration_seconds)
	assert(is_equal_approx(total,float(game.muck_throw_art.duration_seconds)))
	for hz in [60,120]:
		var dt: float = 1.0/hz
		for patrol in [-1.0,1.0]:
			for side in [-1.0,1.0]: check_sequence(game,dt,patrol,side)
		check_repeats(game,dt)
		check_interruptions(game,dt)
		check_close_target(game,dt)
		check_recovery_interruptions(game,dt)
	game.queue_free()
	await process_frame
	print("PASS: Gratecrawler hand release, locked aim/crossing, planted feet, recovery/patrol, cadence and interruptions60/120Hz")
	quit()
