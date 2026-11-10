extends SceneTree
const Section = preload("res://scripts/section_one_two_game.gd")
const Campaign = preload("res://scripts/integrated_first_call.gd")
const LEFT := "aim_up_left_stationary"
const RIGHT := "aim_up_right_stationary"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func release_inputs() -> void:
	for action in [LEFT,RIGHT,"left","right","shoot"]: Input.action_release(action)

func run_checks() -> void:
	for Type in [Section,Campaign]:
		for hero in ["tony","sean"]:
			var game = Type.new()
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
			for binding in [{"action":LEFT,"button":JOY_BUTTON_LEFT_SHOULDER},
				{"action":RIGHT,"button":JOY_BUTTON_RIGHT_SHOULDER}]:
				var found := false
				for event in InputMap.action_get_events(binding.action):
					if event is InputEventJoypadButton and event.button_index == binding.button: found = true
				check(found,"Physical bumper binding exists")
				var key_found := false
				for event in InputMap.action_get_events(binding.action):
					if event is InputEventKey and event.physical_keycode == (KEY_Z if binding.action == LEFT else KEY_V): key_found = true
				check(key_found,"Conflict-free keyboard equivalent bound")
			for hz in [30,60,120]:
				for side in [-1.0,1.0]:
					release_inputs()
					game.player = Vector2(120,394)
					game.grounded = true
					game.velocity = Vector2(180,0)
					game.fire_timer = 0
					game.shots.clear()
					Input.action_press("right" if side < 0 else "left")
					Input.action_press(LEFT if side < 0 else RIGHT)
					Input.action_press("shoot")
					var start_x: float = game.player.x
					game.step_player(1.0/hz)
					check(is_equal_approx(game.player.x,start_x) and game.velocity.x == 0,"Bumper stops running and residual motion")
					check(game.facing == side and game.aim_direction().is_equal_approx(Vector2(side,-1).normalized()),"Bumper sets facing and diagonal aim")
					check(not game.shots.is_empty() and game.shots[-1].dir.is_equal_approx(Vector2(side,-1).normalized()),"Real shot follows stationary diagonal")
					Input.action_release(LEFT if side < 0 else RIGHT)
					game.step_player(1.0/hz)
					check(game.velocity.x*side < 0,"Release restores held stick/directional movement")
					release_inputs()
					game.grounded = false
					Input.action_press(LEFT if side < 0 else RIGHT)
					check(game.aim_direction().is_equal_approx(Vector2(side,-1).normalized()),"Airborne bumper aim supported")
				release_inputs()
			Input.action_press(LEFT)
			Input.action_press(RIGHT)
			var event := InputEventJoypadButton.new()
			event.button_index = JOY_BUTTON_LEFT_SHOULDER
			event.pressed = true
			game._input(event)
			check(game.stationary_aim_direction() == -1,"Both bumpers honor latest pressed facing")
			event.button_index = JOY_BUTTON_RIGHT_SHOULDER
			game._input(event)
			check(game.stationary_aim_direction() == 1,"Both bumpers can select other diagonal")
			var key := InputEventKey.new()
			key.physical_keycode = KEY_Z
			key.pressed = true
			game._input(key)
			check(game.stationary_aim_direction() == -1,"Keyboard Z selects same up-left action")
			key.physical_keycode = KEY_V
			game._input(key)
			check(game.stationary_aim_direction() == 1,"Keyboard V selects same up-right action")
			release_inputs()
			if hero == "tony":
				game.player = Vector2(120,394)
				game.grounded = true
				check(game.specials.begin(game),"Tony special activates through production API")
				game.specials.elapsed = 1.0
				Input.action_press(LEFT)
				game.step_player(1.0/60)
				check(game.current_aim.is_equal_approx(Vector2(-1,-1).normalized()),"Tony special follows bumper aim")
				check(game.velocity.x > 0,"Tony water recoil remains physical while aiming")
				game.specials.cancel("test")
				release_inputs()
			check_escape_bumper(game)
			game.free()
	release_inputs()
	print("Stationary bumper aim: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

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
