extends SceneTree
const Opening = preload("res://scripts/opening_trial_game.gd")
const Three = preload("res://scripts/three_screen_trial_game.gd")
const Section = preload("res://scripts/section_one_two_game.gd")
const Campaign = preload("res://scripts/integrated_first_call.gd")
var checks := 0
var failures: Array[String] = []

class Arena extends Opening:
	var terrain: Array[Rect2] = [Rect2(0,440,2000,80)]
	func actor_solids() -> Array[Rect2]: return terrain
	func player_shot_solids() -> Array[Rect2]: return terrain

func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func prepare(game: Node2D) -> void:
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.life_state = "alive"
	game.invulnerable = 0
	game.camera_x = 0
	game.player = Vector2(500,394)
	game.grounded = true
	game.actors.clear()

func spawn(game: Node2D, x := 500.0) -> Dictionary:
	game.create_actor({"id":"opening-09","role":"aggressive_flyer","warning_seconds":0.8,
		"variant":"devil","devil_limits":Vector2(x-50,x+50)},Vector2(x,110))
	var actor: Dictionary = game.actors.back()
	actor.feet = Vector2(x,110)
	actor.active = true
	actor.entry = {}
	actor.devil.start(actor.feet,actor.devil_limits,1)
	actor.devil.drain_events()
	return actor

func web(game: Node2D, actor: Dictionary, start: Vector2, velocity: Vector2, id: int) -> void:
	actor.devil.projectiles[id] = true
	actor.devil_webs.append({"id":id,"pos":start,"previous":start,"velocity":velocity})

func press(game: Node2D) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_J
	event.pressed = true
	game.devil_spiders.input_event(game,event)
	game.devil_spiders.sampled_frame = -1
	game.devil_spiders.step(game,1.0/120)

func run_checks() -> void:
	var game := Arena.new()
	prepare(game)
	for hz in [30,60,120]:
		var dt: float = 1.0/hz
		game.devil_spiders.clear(game,"test")
		game.actors.clear()
		game.player = Vector2(500,394)
		game.invulnerable = 0
		game.grounded = true
		var actor := spawn(game)
		check(actor.hp == 135 and game.actor_rect(actor).size == Vector2(96,108),"Devil HP/body registered")
		web(game,actor,Vector2(513,390),Vector2(0,240),10)
		game.devil_spiders.pending_press = true
		game.devil_spiders.step(game,dt)
		check(game.devil_spiders.locked() and actor.devil.presses == 0,"Web captures; triggering press excluded")
		var captured: Vector2 = game.player
		game.step_player(dt)
		check(game.player.y < captured.y and game.velocity == Vector2.ZERO,"Cocoon hauls and locks movement")
		var before: Vector2 = game.player
		game.paused = true
		game.devil_spiders.step(game,1)
		check(game.player == before,"Pause freezes haul")
		game.paused = false
		for index in range(5): press(game)
		check(game.devil_spiders.locked() and actor.devil.presses == 5,"Five fresh presses do not prematurely escape")
		press(game)
		check(not game.devil_spiders.locked() and game.devil_spiders.release_immunity > 0,"Six presses release with immunity")
		var other := spawn(game,600)
		web(game,other,game.player+Vector2(13,-2),Vector2(0,240),11)
		game.devil_spiders.step(game,dt)
		check(not game.devil_spiders.locked(),"Cross-owner immediate recapture prevented")
		game.devil_spiders.clear(game,"test")
		game.actors.clear()
		actor = spawn(game)
		game.player = Vector2(500,394)
		game.grounded = true
		web(game,actor,Vector2(513,430),Vector2(0,240),12)
		game.player.x = 700
		for tick in range(hz/2): game.devil_spiders.step(game,dt)
		check(actor.devil.traps.size() == 1,"Missed web sticks to actual floor")
		game.player.x = 500
		game.devil_spiders.step(game,dt)
		check(actor.devil.capture_kind == "snare","Walking onto floor web snares")
		var snared: Vector2 = game.player
		game.step_player(dt)
		check(game.player == snared,"Snare holds floor position")
		for index in range(3): press(game)
		check(not game.devil_spiders.locked() and actor.devil.traps.is_empty(),"Three presses consume snare")
		game.devil_spiders.release_immunity = 0
		actor.devil.release_immunity = 0
		web(game,actor,game.player+Vector2(13,-2),Vector2(0,240),13)
		game.devil_spiders.step(game,dt)
		game.damage_trial_actor(actor,999)
		check(not game.devil_spiders.locked() and actor.devil_webs.is_empty(),"Owner death releases capture and webs")
	check_inputs(game)
	check_obstacle(game)
	game.free()
	for Type in [Three,Section,Campaign]: check_host(Type.new())
	print("Devil runtime: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func check_obstacle(game: Node2D) -> void:
	game.devil_spiders.clear(game,"test")
	game.actors.clear()
	game.terrain.assign([Rect2(0,440,2000,80),Rect2(450,300,200,16)])
	game.player = Vector2(500,394)
	game.invulnerable = 0
	var actor := spawn(game)
	web(game,actor,Vector2(513,250),Vector2(0,240),50)
	for tick in range(120): game.devil_spiders.step(game,1.0/120)
	check(not game.devil_spiders.locked() and actor.devil.traps.size() == 1,"Platform blocks incoming web")
	actor.devil.projectiles[51] = true
	actor.devil.projectile_hit_player(51,game.player+game.PLAYER_SIZE*0.5)
	game.devil_spiders.consume_events(game,actor)
	var crossed := false
	for tick in range(600):
		game.devil_spiders.step(game,1.0/120)
		if game.player.y+game.PLAYER_SIZE.y < game.terrain[1].position.y:
			crossed = true
			break
	check(crossed,"Cocoon hauling passes through terrain instead of stalling")
	game.player = Vector2(500,290)
	for index in range(6): actor.devil.escape_press()
	game.devil_spiders.consume_events(game,actor)
	check(not game.devil_spiders.locked() and not Rect2(game.player,game.PLAYER_SIZE).grow(-0.001).intersects(game.terrain[1]),
		"Escape restores collision and resolves captive above solid terrain")
	game.life_state = "dying"
	game.devil_spiders.sync_lifecycle(game)
	check(not game.devil_spiders.locked() and actor.devil.traps.is_empty(),"Hero death clears capture/traps")

func check_host(game: Node2D) -> void:
	prepare(game)
	var actor := spawn(game)
	check(actor.variant == "devil" and actor.hp == 135,"Shared variant works in each Level1 host")
	game.shots.append({"pos":actor.feet+Vector2(-90,45),"dir":Vector2.RIGHT,"damage":12,
		"speed":760,"range":320,"distance":0.0,"trial_id":"test"})
	game.step_trial_shots(0.15)
	check(actor.hp == 123,"Real host projectile damages devil")
	var segment := {"origin":actor.feet+Vector2(-90,45),"end":actor.feet+Vector2(90,45),"width":52.0}
	# Ordinary projectile coverage above is paired with the production special damage overlap API.
	var segments: Array[Dictionary] = [segment]
	game.special_damage(segments,12,1,{})
	check(actor.hp == 111,"Real host special damages devil")
	actor.devil.projectiles[91] = true
	var trap_id: int = actor.devil.projectile_hit_solid(91,game.player+Vector2(13,46),true)
	actor.devil.trigger_floor_trap(trap_id,game.player+game.PLAYER_SIZE*0.5)
	game.devil_spiders.consume_events(game,actor)
	var stopped: Dictionary = game.move_player_body(game.player,Vector2(1000,1000),game.PLAYER_SIZE,1)
	check(stopped.pos == game.player and not stopped.falling,"Snare movement cannot trigger pit side effects")
	game.devil_spiders.clear(game,"test")
	if game.has_method("event_specs"):
		var selected: Array = game.event_specs().filter(func(spec: Dictionary) -> bool: return spec.get("variant","") == "devil")
		check(selected.size() == 1,"Exactly one authored flyer replaced")
		check(selected[0].feet.y == 110 and selected[0].entry.mode == "top","Authored socket and continuous top entry")
		check(game.devil_spiders.placements(game).size() == 1,"Support available before admission")
	else:
		check(game.route_home({"id":"clog-approach-06"}) == Vector2(10920,110),"Campaign fixed socket")
	game.reset_observation()
	check(game.actors.is_empty() and not game.devil_spiders.locked(),"Retry clears runtime")
	if game.has_method("event_specs"):
		var selected: Array = game.event_specs().filter(func(spec: Dictionary) -> bool: return spec.get("variant","") == "devil")
		var spec: Dictionary = selected[0]
		game.dispenser.cancel()
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.player = Vector2(float(spec.trigger),394)
		game.grounded = true
		game.velocity = Vector2.ZERO
		game.camera_x = maxf(0,game.player.x-320)
		game.next_warning = 0
		for id in game.ledger: game.ledger[id] = "retired"
		game.ledger[spec.id] = "pending"
		game.issue_event()
		check(game.actors.size() == 1 and game.actors[0].get("variant","") == "devil","Actual section admission replaces selected flyer")
		if not game.actors.is_empty():
			var entering: Dictionary = game.actors[0]
			check(not entering.active and entering.feet.y < 0,"Devil starts continuously above viewport")
			for tick in range(120*4):
				game.step_trial_actors(1.0/120)
				if entering.active: break
			check(entering.active and is_equal_approx(entering.feet.y,110),"Entry reaches ceiling socket before combat")
	actor = spawn(game)
	actor.devil.projectiles[92] = true
	actor.devil.projectile_hit_player(92,game.player+game.PLAYER_SIZE*0.5)
	game.devil_spiders.consume_events(game,actor)
	game.request_title()
	check(not game.devil_spiders.locked() and actor.devil.projectiles.is_empty(),"Title clears capture/projectiles")
	game.free()

func check_inputs(game: Node2D) -> void:
	game.devil_spiders.clear(game,"input-test")
	game.actors.clear()
	game.player = Vector2(500,394)
	game.invulnerable = 0
	var actor := spawn(game)
	actor.devil.projectiles[70] = true
	actor.devil.projectile_hit_player(70,game.player+game.PLAYER_SIZE*0.5)
	game.devil_spiders.consume_events(game,actor)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	key.pressed = true
	key.echo = true
	game._input(key)
	game.devil_spiders.sampled_frame = -1
	game.devil_spiders.step(game,1.0/120)
	check(actor.devil.presses == 0,"OS key-repeat does not tear silk")
	key.echo = false
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_X
	pad.pressed = true
	game._input(key)
	game._input(pad)
	game.devil_spiders.sampled_frame = -1
	game.devil_spiders.step(game,1.0/120)
	check(actor.devil.presses == 1,"Simultaneous keyboard/controller buttons count once")
	for tick in range(12): game.devil_spiders.step(game,1.0/120)
	check(actor.devil.presses == 1,"Held input/substeps never repeatedly tear")
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 0.8
	game._input(trigger)
	game.devil_spiders.sampled_frame = -1
	game.devil_spiders.step(game,1.0/120)
	check(actor.devil.presses == 2,"Fresh shooting trigger counts")
	trigger.axis_value = 0.9
	game._input(trigger)
	game.devil_spiders.sampled_frame = -1
	game.devil_spiders.step(game,1.0/120)
	check(actor.devil.presses == 2,"Held trigger motion does not count again")
	pad.button_index = JOY_BUTTON_START
	game.devil_spiders.input_event(game,pad)
	game.devil_spiders.sampled_frame = -1
	game.devil_spiders.step(game,1.0/120)
	check(actor.devil.presses == 2,"Pause/menu button excluded")
	game.devil_spiders.clear(game,"input-test")
