extends SceneTree
const STEP := 1.0/120

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for path in ["res://scripts/opening_trial_game.gd","res://scripts/integrated_first_call.gd"]:
		var game = load(path).new()
		root.add_child(game)
		game.hide()
		game.set_process(false)
		game.set_physics_process(false)
		assert(game.role_scale("aggressive_flyer") == 2)
		assert(game.event_size("aggressive_flyer") == Rect2(-30,-24,60,48))
		for person in game.Crew.EMPLOYEES:
			game.employee = person
			for direction in [-1,1]: check_cycle(game,direction)
			check_hits_and_solids(game)
			check_blocked_recovery(game)
			check_offscreen_and_reset(game)
		game.actors.clear()
		game.queue_free()
		await process_frame
	print("PASS: both routes/heroes/headings, repeated dives, stationary1s pause, retarget/tie, freeze/death/reset, bounds and15/10hits")
	quit()

func prepare(game: Node, direction: int = -1) -> Dictionary:
	game.reset_game()
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.paused = false
	game.player = Vector2(950,394)
	game.camera_x = 600
	game.invulnerable = 100
	var event := {"id":"opening-09","role":"aggressive_flyer","warning_seconds":0.8}
	game.trial_state.advance(15)
	assert(game.trial_state.reserve(event.id))
	game.trial_state.advance(1.1)
	assert(game.trial_state.activate(event.id))
	game.create_actor(event,Vector2(1000 if direction < 0 else 900,250))
	var actor: Dictionary = game.actors[0]
	actor.active = true
	actor.facing = direction
	return actor

func until_state(game: Node, actor: Dictionary, state: String) -> void:
	for tick in range(600):
		if actor.attack_state == state: return
		game.step_flyer(actor,STEP)
	assert(false,"Flyer failed to reach "+state)

func check_frozen(game: Node, actor: Dictionary) -> void:
	var before: Dictionary = actor.duplicate(true)
	game.paused = true
	game._physics_process(0.1)
	game.step_flyer(actor,0.1)
	assert(actor == before,"Manual pause must freeze every attack phase")
	game.paused = false
	for state in ["dying","death_popup","game_over"]:
		game.life_state = state
		game.step_flyer(actor,0.1)
		assert(actor == before,"Player death must freeze the attack")
	game.life_state = "alive"
	game.dispenser.active = true
	game.step_flyer(actor,0.1)
	assert(actor == before,"Dispenser presentation must freeze the attack")
	game.dispenser.active = false

func check_cycle(game: Node, direction: int) -> void:
	var actor := prepare(game,direction)
	assert(actor.hp == 180 and actor.max_hp == 180)
	assert(game.choose_home({"id":"opening-10","role":"aggressive_flyer"}) == Vector2.INF)
	for cycle in range(3):
		game.step_flyer(actor,STEP)
		assert(actor.attack_state == "windup","Nearby hero must trigger repeated dives")
		check_frozen(game,actor)
		var origin: Vector2 = actor.feet
		var target: Vector2 = actor.attack_target
		game.player.x = 950 # Moving during the warning cannot change the committed target.
		for tick in range(70):
			game.step_flyer(actor,STEP)
			assert(actor.feet == origin)
		assert(actor.attack_target == target)
		until_state(game,actor,"swoop")
		check_frozen(game,actor)
		until_state(game,actor,"recover")
		assert(actor.feet.y > origin.y+100,"Dive must reach the hero lane")
		check_frozen(game,actor)
		until_state(game,actor,"top_pause")
		assert(is_equal_approx(actor.feet.y,250),"Pause begins only at original altitude")
		check_frozen(game,actor)
		var upper: Vector2 = actor.feet
		var old_facing: float = actor.facing
		var next_direction := -direction if cycle % 2 == 0 else direction
		game.player.x = upper.x+next_direction*50-game.PLAYER_SIZE.x*0.5
		for tick in range(119):
			game.step_flyer(actor,STEP)
			assert(actor.feet == upper and actor.facing == old_facing)
			assert(actor.attack_state == "top_pause","Upper pause must last about one second")
		game.step_flyer(actor,STEP*2)
		assert(actor.attack_state == "approach" and actor.facing == next_direction)
		assert(actor.feet == upper,"Pause end changes heading, not position")
	# A centered hero must not randomly flip facing.
	actor.attack_state = "top_pause"
	actor.attack_clock = 0
	game.player.x = actor.feet.x-game.PLAYER_SIZE.x*0.5+3
	var facing: float = actor.facing
	game.step_flyer(actor,1.01)
	assert(actor.facing == facing and actor.attack_state == "approach")
	# Proximity also works when the hero crossed behind before the next dive.
	game.player.x = actor.feet.x-facing*50-game.PLAYER_SIZE.x*0.5
	game.step_flyer(actor,STEP)
	assert(actor.attack_state == "windup" and actor.facing == -facing)
	actor.hp = 0
	var dead: Dictionary = actor.duplicate(true)
	game.step_flyer(actor,1)
	assert(actor == dead,"Dead Widow cannot start or continue attacks")

func check_hits_and_solids(game: Node) -> void:
	var actor := prepare(game)
	actor.feet = Vector2(1400,250)
	assert(not game.move_flyer_clear(actor,Vector2(1400,410)))
	assert(game.actor_rect(actor).end.y <= 320,"Full enlarged body cannot dive through a deck")
	actor.feet = Vector2(1400,250)
	var required := 15 if game.employee.id == "tony" else 10
	for hit in range(required):
		game.shots.append({"pos":Vector2(1350,250),"dir":Vector2.RIGHT,
			"damage":game.weapon.damage,"speed":760,"range":320,"distance":0.0,"trial_id":"fixture"})
		game.step_trial_shots(0.1)
		assert(actor.hp == maxf(0,180-(hit+1)*game.weapon.damage))
	assert(actor.hp == 0)

func check_offscreen_and_reset(game: Node) -> void:
	var actor := prepare(game)
	actor.feet = Vector2(100,250)
	actor.attack_state = "approach"
	actor.attack_clock = 0
	actor.attack_origin = actor.feet
	actor.attack_target = actor.feet
	actor.facing = 1
	game.step_trial_actors(STEP)
	assert(actor.hp == 180 and game.actors.has(actor),"Living active Widow must not retire behind camera")
	actor.feet = Vector2(31,250)
	actor.facing = -1
	game.step_flyer(actor,1)
	assert(game.actor_rect(actor).position.x >= 0,"Pursuit cannot leave world bounds")
	game.step_flyer(actor,STEP)
	assert(actor.facing == 1,"World edge turns stranded pursuit back toward the hero")
	game.respawn_after_death()
	assert(game.actors.is_empty(),"Attempt reset removes the old pursuing Widow")

func check_blocked_recovery(game: Node) -> void:
	var actor := prepare(game)
	var obstacle := Rect2(1100,270,40,170)
	game.trial_level.plinths.append(obstacle)
	actor.feet = Vector2(1000,390)
	actor.attack_state = "recover"
	actor.attack_clock = 0
	actor.attack_origin = Vector2(1000,250)
	actor.recovery_origin = actor.feet
	actor.recovery_target = Vector2(1200,250)
	for tick in range(600):
		game.step_flyer(actor,STEP)
		assert(not game.actor_rect(actor).intersects(obstacle),"Blocked recovery must never penetrate scenery")
		if actor.attack_state == "top_pause": break
	assert(actor.attack_state == "top_pause" and is_equal_approx(actor.feet.y,250))
	game.trial_level.plinths.erase(obstacle)
