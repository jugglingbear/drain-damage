extends SceneTree
## Real host lifecycle: defer until needed, freeze at the descent, and bypass both cards on retry.
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("checks")

func expect(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: ",message)
		quit(1)
		assert(value,message)

func dismiss(game: Node2D, use_pad: bool) -> void:
	var overlay = game.level_loading_overlay
	expect(overlay != null,"Cold entry shows a card")
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	root.push_input(key)
	while not overlay.waiting_for_button: await process_frame
	expect(overlay.progress == 1.0,"Prompt waits for all preparation")
	key.echo = true
	root.push_input(key)
	expect(game.level_load_active(),"Held key repeat cannot accept a ready card")
	key.echo = false
	key.pressed = false
	root.push_input(key)
	expect(game.level_load_active(),"Release cannot accept a ready card")
	if use_pad:
		var button := InputEventJoypadButton.new()
		button.button_index = JOY_BUTTON_B
		button.pressed = true
		root.push_input(button)
	else:
		key.pressed = true
		root.push_input(key)
	expect(not game.level_load_active(),"Fresh button dismisses card")

func checks() -> void:
	create_timer(180).timeout.connect(func() -> void: expect(false,"Timed out during level loading"))
	var game := Game.new()
	game.defer_level_two_loading = true
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var flush = game.flush
	expect(game.startup_complete and not flush.bowl_prepared and not flush.ride_prepared,
		"Level 1 starts without the bowl or ride")
	expect(flush.world_view == null and flush.art.textures.is_empty(),"Ride actors and bowl textures are deferred")
	game.begin_level_two()
	await dismiss(game,true)
	expect(flush.active and flush.state == "bowl" and flush.bowl_prepared and not flush.ride_prepared,
		"Controller press enters only the bowl")
	flush.state = "drain"
	flush.prelude_remaining = 0.0
	flush.clock = 42.999
	flush.tick(game,1.0/60,Vector2.ZERO,false,false)
	expect(game.level_load_active() and flush.clock < 43.0,"Cold ride preparation freezes the descent")
	await dismiss(game,false)
	expect(flush.ride_prepared and flush.world_view.configured,"Keyboard press reveals prepared ride")
	flush.tick(game,1.0/60,Vector2.ZERO,false,false)
	expect(flush.clock >= 43,"Descent resumes after the press")
	var view = flush.world_view
	game.begin_level_two()
	game.prepare_level_two_launch("ride-continuous")
	expect(not game.level_load_active() and flush.world_view == view and flush.clock == 0,
		"Warm entries reuse the same actor pool and skip the card")
	game.free()
	print("PASS: cold bowl and ride cards, fresh keyboard/controller presses, frozen descent, and warm bypass")
	quit()
