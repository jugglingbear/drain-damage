extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func jump_input(pressed: bool, controller: bool) -> void:
	var event: InputEvent
	if controller:
		var button := InputEventJoypadButton.new()
		button.button_index = JOY_BUTTON_A
		button.pressed = pressed
		event = button
	else:
		var key := InputEventKey.new()
		key.keycode = KEY_SPACE
		key.physical_keycode = KEY_SPACE
		key.pressed = pressed
		event = key
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func fresh_jump(game: Node2D) -> void:
	jump_input(true,game.employee.id == "sean")
	game._physics_process(1.0/120)
	jump_input(false,game.employee.id == "sean")
	await process_frame
func run() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	var game = Game.new()
	root.add_child(game)
	while not game.startup_complete: await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.restart_guard_device = -1
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		game.flush.reset()
		game.begin_level_two()
		var flush = game.flush
		flush.input_guard = false
		game.dialogue.release_guard = 0
		game.restart_guard_device = -1
		check(not flush.intro_complete and flush.radio.current.at == 0,"Opening is not completed when it starts")
		await fresh_jump(game)
		check(flush.radio.current.at == 0,"Center gag ignores fresh Jump")
		for frame in range(9*120):
			flush.tick(game,1.0/120,flush.position.normalized(),false,false)
		check(flush.radio.presentation().progress < 1,"Reply is still relocating")
		await fresh_jump(game)
		check(flush.radio.current.at == 9,"Sliding window ignores Jump")
		for frame in range(2*120):
			flush.tick(game,1.0/120,flush.position.normalized(),false,false)
		check(flush.radio.presentation().progress == 1,"Reply reached bottom")
		jump_input(true,hero.id == "sean")
		game._physics_process(1.0/120)
		check(flush.radio.current.at == 16,"Fresh bottom Jump advances exactly one line")
		await process_frame
		for frame in range(30): game._physics_process(1.0/120)
		check(flush.radio.current.at == 16,"Held Jump does not skip subsequent lines")
		jump_input(false,hero.id == "sean")
		await process_frame
		check(not flush.intro_complete,"Partially advanced opening remains incomplete")
		flush.position = Vector2.ZERO
		flush.tick(game,1.0/120,Vector2.ZERO,false,false)
		check(game.life_state == "dying","Death during bottom dialogue is real")
		game.respawn_after_death()
		check(flush.radio.current.at == 0 and not flush.intro_complete,"Unfinished retry restarts first line")
		flush.input_guard = false
		game.dialogue.release_guard = 0
		game.restart_guard_device = -1
		for frame in range(11*120):
			flush.tick(game,1.0/120,flush.position.normalized(),false,false)
		var presses := 0
		while not flush.intro_complete and presses < 8:
			await fresh_jump(game)
			presses += 1
		check(flush.intro_complete and flush.radio.current.is_empty(),"Final fresh press completes the conversation")
		var onset: float = flush.definition.layout.difficulty[game.difficulty].waves[0].at
		check(flush.prelude_remaining == 0 and absf(flush.clock-onset) < 0.02,"No invisible wait after accelerated dialogue")
		check(flush.debris.next_wave == 1 and not flush.hazards.is_empty(),"First cohort starts exactly once")
		for item: Dictionary in flush.hazards:
			check(absf(item.impact_at-flush.clock-item.duration) < 0.02,"Accelerated onset retains full warning")
		for attempt in range(2):
			game.lives = 3
			flush.position = Vector2.ZERO
			flush.tick(game,1.0/120,Vector2.ZERO,false,false)
			game.respawn_after_death()
			check(flush.intro_complete and flush.prelude_remaining == 0,"Completed retry skips dialogue")
			check(flush.clock == onset and flush.radio.current.is_empty(),"Completed retry starts at first hazard")
		flush.enter_landing(game)
		flush.input_guard = false
		game.dialogue.release_guard = 0
		game.restart_guard_device = -1
		await fresh_jump(game)
		check(flush.state == "ride","Bottom landing dialogue also advances immediately")
		flush.reset()
		check(not flush.intro_complete,"New run resets conversation completion")
	game.free()
	await process_frame
	print("Flush dialogue controls: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
