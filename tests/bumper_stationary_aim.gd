extends SceneTree
## Exercise the input map, on-foot movement, and emitted projectiles through both real game hosts.
const Section = preload("res://scripts/section_one_two_game.gd")
const Campaign = preload("res://scripts/integrated_first_call.gd")
const LEFT := "aim_up_left_stationary"
const RIGHT := "aim_up_right_stationary"
const DEVICE := 3
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func axis(id: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = DEVICE
	event.axis = id
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func stick(value: Vector2) -> void:
	axis(JOY_AXIS_LEFT_X,value.x)
	axis(JOY_AXIS_LEFT_Y,value.y)

func button(id: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = DEVICE
	event.button_index = id
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run_checks() -> void:
	for Type in [Section,Campaign]:
		for hero in ["tony","sean"]:
			var game = Type.new()
			if Type == Campaign: game.defer_level_two_loading = true
			for employee in game.Crew.EMPLOYEES:
				if employee.id == hero: game.employee = employee
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.dispenser.cancel()
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.dialogue.awaiting_release = false
			game.restart_guard_device = -1
			game.life_state = "alive"
			if Type == Campaign: game.intro_input_release = false
			for hz in [30,60,120]: check_plant(game,1.0/hz)
			for direction in [-1.0,1.0]:
				var id := JOY_BUTTON_LEFT_SHOULDER if direction < 0 else JOY_BUTTON_RIGHT_SHOULDER
				button(id,true)
				check(not game.planted_aim() and game.stationary_aim_direction() == 0,
					"Shoulders no longer select diagonal aim")
				button(id,false)
				var code := KEY_Z if direction < 0 else KEY_V
				key(code,true)
				check(game.aim_direction().is_equal_approx(Vector2(direction,-1).normalized()),
					"Keyboard Z/V retain their diagonal")
				key(code,false)
			if hero == "tony":
				game.player = Vector2(120,394)
				game.grounded = true
				check(game.specials.begin(game),"Tony special activates")
				game.specials.elapsed = 1.0
				key(KEY_Z,true)
				game.step_player(1.0/60)
				check(game.current_aim.is_equal_approx(Vector2(-1,-1).normalized()),"Tony special follows keyboard aim")
				check(game.velocity.x > 0,"Tony water recoil remains physical while aiming")
				game.specials.cancel("test")
				key(KEY_Z,false)
			check_escape_bumper(game)
			game.free()
	print("Planted aim: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func check_plant(game: Node2D, dt: float) -> void:
	game.player = Vector2(120,394)
	game.grounded = true
	game.velocity = Vector2(180,0)
	game.shots.clear()
	var start_x: float = game.player.x
	axis(JOY_AXIS_TRIGGER_LEFT,1.0)
	for vector in [Vector2(-0.84,-0.36),Vector2(0.86,0.43)]:
		stick(vector)
		game.fire_timer = 0
		var count: int = game.shots.size()
		if vector.x < 0:
			axis(JOY_AXIS_TRIGGER_RIGHT,1.0)
			check(game.trigger_state.get(DEVICE,Vector2.ZERO) == Vector2.ONE,
				"Both physical triggers reach the game restart handler")
		else: button(JOY_BUTTON_X,true)
		game.step_player(dt)
		check(game.grounded and is_equal_approx(game.player.x,start_x) and game.velocity.x == 0,
			"LT stops horizontal movement immediately")
		check(game.current_aim.is_equal_approx(vector.normalized()),"Stick aims between compass sectors")
		check(game.shots.size() == count+1 and game.shots[-1].dir.is_equal_approx(vector.normalized()),
			"LT with RT or X fires at the selected angle")
		axis(JOY_AXIS_TRIGGER_RIGHT,0)
		button(JOY_BUTTON_X,false)
		stick(Vector2(0.10,0.07))
		game.step_player(dt)
		check(game.current_aim.is_equal_approx(vector.normalized()),"Centered stick retains last aim")
	stick(Vector2.ZERO)
	button(JOY_BUTTON_DPAD_DOWN,true)
	game.step_player(dt)
	check(game.current_aim.is_equal_approx(Vector2.DOWN) and game.grounded,"Grounded straight-down planted aim")
	button(JOY_BUTTON_DPAD_RIGHT,true)
	game.step_player(dt)
	check(game.current_aim.is_equal_approx(Vector2(1,1).normalized()),"D-pad diagonal selects its sector")
	button(JOY_BUTTON_DPAD_DOWN,false)
	button(JOY_BUTTON_DPAD_RIGHT,false)
	stick(Vector2(0.9,0))
	axis(JOY_AXIS_TRIGGER_LEFT,0)
	game.step_player(dt)
	check(game.velocity.x > 0 and game.player.x > start_x,"LT release restores held stick movement")
	stick(Vector2.ZERO)

func check_escape_bumper(game: Node2D) -> void:
	game.create_actor({"id":"bumper-escape","role":"aggressive_flyer","warning_seconds":0.8,
		"variant":"devil"},Vector2(500,110))
	var actor: Dictionary = game.actors.back()
	actor.active = true
	actor.feet = Vector2(500,110)
	actor.devil.start(actor.feet,Vector2(450,550))
	actor.devil.projectiles[1] = true
	actor.devil.projectile_hit_player(1,game.player+game.PLAYER_SIZE*0.5)
	game.devil_spiders.consume_events(game,actor)
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_LEFT_SHOULDER
	event.pressed = true
	game._input(event)
	game.devil_spiders.sampled_frame = -1
	game.devil_spiders.step(game,1.0/120)
	check(actor.devil.presses == 1,"Fresh bumper press tears cocoon")
	game.devil_spiders.step(game,1.0/120)
	check(actor.devil.presses == 1,"Held bumper does not repeatedly tear")
