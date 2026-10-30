extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Freeze = preload("res://scripts/screenshot_freeze.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		game.flush.enter_ride(game,0)
		var ride = game.flush.ride
		game.flush.input_guard = false
		game.dialogue.release_guard = 0
		game.restart_guard_device = -1
		var before: int = ride.audio.starts.get("board_fart",0)
		Input.action_press("shoot")
		game._physics_process(1.0/60)
		assert(ride.fidget.effects.size() == 1)
		assert(ride.audio.starts.get("board_fart",0) == before+1)
		for frame in 15: game._physics_process(1.0/60)
		assert(ride.audio.starts.get("board_fart",0) == before+1,"Holding fire cannot repeat")
		Input.action_release("shoot")
		game._physics_process(.01)
		Input.action_press("shoot")
		game._physics_process(.01)
		assert(ride.audio.starts.get("board_fart",0) == before+1,"Cooldown rejects rapid press")
		Input.action_release("shoot")
		game._physics_process(.24)
		Input.action_press("shoot")
		game._physics_process(.01)
		assert(ride.audio.starts.get("board_fart",0) == before+2,"Fresh half-second press restarts fart tail")
		Input.action_release("shoot")
		ride.audio.play("metal_impact")
		assert(ride.audio.voices.contact.playing and ride.audio.voices.fidget.playing)
		game.paused = true
		ride.process_audio(game,.5)
		assert(ride.audio.voices.fidget.stream_paused)
		var age: float = ride.fidget.effects[0].age
		ride.tick(game,.5,Vector2.ZERO,false,true)
		assert(ride.fidget.effects[0].age == age)
		game.paused = false
		ride.process_audio(game,0)
		assert(not ride.audio.voices.fidget.stream_paused)
		AudioServer.set_bus_mute(0,true)
		ride.audio.advance(0,false,true)
		ride.audio.play("board_fart")
		assert(not ride.audio.voices.fidget.playing)
		AudioServer.set_bus_mute(0,false)
		var freeze := Freeze.new()
		freeze.host = game
		game.add_child(freeze)
		freeze.begin_freeze()
		Input.action_press("shoot")
		freeze.resume()
		assert(ride.fidget.held,"Fire during capture freeze is consumed")
		Input.action_release("shoot")
		game.remove_child(freeze)
		freeze.free()
		game.life_state = "dying"
		ride.process_audio(game,0)
		assert(ride.fidget.effects.is_empty() and not ride.audio.voices.fidget.playing)
		game.life_state = "alive"
		game.flush.enter_ride(game,0)
		assert(ride.fidget.effects.is_empty() and not ride.audio.voices.fidget.playing)
		game.flush.state = "bowl"
		game.flush.clock = 0
		game.flush.tick(game,.01,Vector2.ZERO,false,true)
		assert(ride.fidget.effects.is_empty(),"Swimming flush cannot create board fidgets")
	game.free()
	print("PASS: both heroes share fire action, held/cooldown bounded audio, contact independence, pause/mute/freeze/death/retry/flush guards")
	quit()
