extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func press(kind: String, down: bool) -> void:
	if kind == "keyboard":
		var key := InputEventKey.new()
		key.physical_keycode = KEY_SPACE
		key.keycode = KEY_SPACE
		key.pressed = down
		Input.parse_input_event(key)
	else:
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_A
		pad.pressed = down
		Input.parse_input_event(pad)
	Input.flush_buffered_events()

func rest(game: Node2D, remaining: float) -> void:
	game.flush.enter_ride(game,0)
	game.flush.input_guard = false
	game.dialogue.release_guard = 0
	var ride = game.flush.ride
	ride.phase = "rest"
	ride.course = {"obstacles":[]}
	ride.rest_remaining = remaining

func checks() -> void:
	for hero in [0,1]:
		var game = Game.new()
		game.employee = game.Crew.EMPLOYEES[hero]
		root.add_child(game)
		game.hide()
		game.set_process(false)
		game.begin_level_two()
		for kind in ["keyboard","controller"]:
			for remaining in [3.0,0.005]:
				rest(game,remaining)
				var ride = game.flush.ride
				press(kind,true)
				await create_timer(0.05).timeout
				assert(ride.events.get("jump",0) == 1 and ride.jump_age >= 0,
					"Real physics input must launch during rest: "+kind)
				if remaining < 0.01: assert(ride.encounter_index == 1)
				await create_timer(0.8).timeout
				assert(ride.events.jump == 1,"Held key/A must not auto-jump after landing")
				press(kind,false)
				await create_timer(0.04).timeout
				press(kind,true)
				await create_timer(0.05).timeout
				assert(ride.events.jump == 2,"Fresh press must work after landing: "+kind)
				press(kind,false)
				await create_timer(0.04).timeout
			rest(game,3)
			game.set_paused(true)
			press(kind,true)
			await create_timer(0.05).timeout
			assert(game.flush.ride.events.get("jump",0) == 0)
			game.set_paused(false)
			await create_timer(0.05).timeout
			assert(game.flush.ride.events.get("jump",0) == 0,"Resume must not reuse a held press")
			press(kind,false)
			await create_timer(0.04).timeout
		game.queue_free()
		await process_frame
	print("PASS: real keyboard Space/controller A rest and transition physics input for both heroes; held/released and pause guards")
	quit()
