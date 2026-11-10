extends SceneTree
const Freeze = preload("res://scripts/screenshot_freeze.gd")
const Game = preload("res://scripts/integrated_first_call.gd")
var count := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	count += 1
	if not value:
		failures.append(message)
		push_error(message)

func run_checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		game.specials.budgets.clear()
		game.begin_level_two()
		game.flush.enter_ride(game,0)
		game.flush.input_guard = false
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.restart_guard_device = -1
		game.life_state = "alive"
		var ride = game.flush.ride
		check(not game.specials_allowed(),"Ride blocks inherited combat super "+hero.id)
		game.specials.sample_input(game,false)
		game.specials.sample_input(game,true)
		check(not game.specials.active and game.specials.remaining() == 2,"Combat sampler cannot spend ride charges")
		var pose: Vector2 = ride.position
		var jump: float = ride.jump_age
		var clock: float = ride.clock
		var health: int = game.health
		var starts: int = ride.audio.starts.get("board_super_fart",0)
		check(ride.sample_super(game,true),"Fresh special emits cloud")
		check(game.specials.remaining() == 1 and ride.fidget.effects.size() == 1,"Exactly one charge and cloud")
		check(ride.audio.starts.get("board_super_fart",0) == starts+1,"Exactly one audio start")
		check(ride.position == pose and ride.jump_age == jump and ride.clock == clock and game.health == health,
			"Activation has no motion, time or health effects")
		var cloud: Dictionary = ride.fidget.effects[0]
		check(cloud.center == pose+Vector2(clock*ride.scroll_speed-45,0),"Cloud anchored behind release in course coordinates")
		check(cloud.get("super",false) and cloud.lifetime == 8.0,"Super lifetime is eight seconds")
		for frame in range(20): check(not ride.sample_super(game,true),"Holding cannot repeat")
		game.paused = true
		ride.sample_super(game,false)
		check(not ride.sample_super(game,true),"Paused edge is consumed")
		Input.action_press("special")
		ride.process_audio(game,.5)
		ride.fidget.step(ride,false,.5,true,true,true)
		check(cloud.age == 0 and ride.audio.voices.fidget.stream_paused,"Pause freezes cloud and audio")
		game.paused = false
		check(not ride.sample_super(game,true),"Resume cannot replay held edge")
		Input.action_release("special")
		ride.sample_super(game,false)
		ride.process_audio(game,0)
		check(not ride.audio.voices.fidget.stream_paused,"Resume restores audio")
		# Ordinary airborne fidget has separate cooldown/edge and cannot consume or truncate the super.
		ride.jump_age = 0
		ride.fidget.step(ride,false,0)
		var ordinary: Dictionary = ride.fidget.step(ride,true,0)
		check(ordinary.triggered and game.specials.remaining() == 1,"Ordinary fidget stays independent")
		ride.audio.play("board_fart")
		check(ride.audio.voices.fidget.stream == ride.audio.cues.board_super_fart.stream,"Ordinary audio cannot cut off super")
		ride.clock += 2
		ride.position += Vector2(50,20)
		ride.fidget.step(ride,false,7.99)
		check(ride.fidget.effects.has(cloud) and cloud.center == ride.position+Vector2(ride.clock*ride.scroll_speed-45,0),"Cloud follows rider throughout lifetime")
		ride.fidget.step(ride,false,.02)
		check(not ride.fidget.effects.has(cloud),"Cloud retires after eight seconds")
		check(ride.fidget.effects.any(func(effect: Dictionary) -> bool: return not effect.get("super",false)),
			"Super expiry does not retire ordinary cloud")
		check(ride.sample_super(game,true),"Second fresh press consumes last charge")
		ride.sample_super(game,false)
		check(not ride.sample_super(game,true) and game.specials.remaining() == 0,"Empty budget cannot emit")
		game.life_state = "dying"
		ride.process_audio(game,0)
		check(ride.fidget.effects.is_empty() and not ride.audio.voices.fidget.playing,"Death clears visual and audio")
		check(not ride.sample_super(game,false) and not ride.sample_super(game,true),"Dead input cannot trigger")
		game.life_state = "alive"
		Input.action_press("special")
		game.flush.enter_ride(game,0)
		game.flush.input_guard = false
		check(ride.fidget.effects.is_empty() and game.specials.remaining() == 0,"Retry clears effects without refund")
		check(not ride.sample_super(game,true),"Retry consumes held input")
		Input.action_release("special")
		game.specials.budgets[game.specials.level_key+":"+hero.id] = 1
		for guard in ["input","swimming","complete","won"]:
			ride.sample_super(game,false)
			game.flush.input_guard = guard == "input"
			game.flush.state = "bowl" if guard == "swimming" else "ride"
			ride.complete = guard == "complete"
			game.won = guard == "won"
			check(not ride.sample_super(game,true),"Blocked state consumes edge: "+guard)
			check(game.specials.remaining() == 1,"Blocked state preserves charge: "+guard)
		game.flush.input_guard = false
		game.flush.state = "ride"
		ride.complete = false
		game.won = false
		ride.sample_super(game,false)
		var freeze := Freeze.new()
		freeze.host = game
		game.add_child(freeze)
		freeze.begin_freeze()
		Input.action_press("special")
		freeze.resume()
		check(not ride.sample_super(game,true) and game.specials.remaining() == 1,
			"Screenshot freeze consumes special without deferred activation")
		check(ride.fidget.effects.is_empty(),"Freeze creates no cloud")
		Input.action_release("special")
		ride.sample_super(game,false)
		Input.action_press("special")
		game._process(0)
		ride.process_audio(game,0)
		check(game.specials.remaining() == 0 and not game.specials.active,
			"Actual host input spends cosmetic charge without Level1 attack")
		check(ride.fidget.effects.size() == 1 and ride.fidget.effects[0].get("super",false),
			"Actual host input creates exactly one super cloud")
		Input.action_release("special")
		game.specials.budgets[game.specials.level_key+":"+hero.id] = 1
		game.paused = true
		ride.process_audio(game,0)
		var resume_starts: int = ride.audio.starts.get("board_super_fart",0)
		game.paused = false
		Input.action_press("special")
		ride.process_audio(game,0)
		check(game.specials.remaining() == 0,"Fresh press on first resume frame spends charge")
		check(ride.audio.starts.get("board_super_fart",0) == resume_starts+1,
			"Fresh press on first resume frame must also play super audio")
		Input.action_release("special")
		game.remove_child(freeze)
		freeze.free()
	game.free()
	print("Ride cosmetic super: ",count," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
