extends SceneTree
## Real staged startup must keep yielding and protect the menu from duplicate launches.
class MissingJob:
	extends "res://scripts/title_screen.gd"
	func create_job() -> Node2D: return null

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	title.starting = true
	title.start_game()
	await process_frame
	assert(title.loading_in_progress and title.game == null)
	title.request_start()
	title.start_game()
	var deadline := Time.get_ticks_msec()+60000
	while title.loading_in_progress and Time.get_ticks_msec() < deadline:
		assert(title.music_director.requested == "title", "Menu music must survive hidden preparation")
		await process_frame
	assert(title.card_ready and title.game == null,"Cold preparation waits for a fresh button")
	var motion := InputEventJoypadMotion.new()
	motion.axis_value = 1
	title._unhandled_input(motion)
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_E
	echo.pressed = true
	echo.echo = true
	title._unhandled_input(echo)
	assert(title.card_ready,"Axis motion and key repeats cannot start a level")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_Y
	pad.pressed = true
	title._unhandled_input(pad)
	assert(not title.loading_in_progress and title.game != null)
	assert(title.loading_frames > 10,"Preparation must yield instead of freezing the menu")
	assert(title.game.startup_complete and title.game.dialogue.active)
	assert(title.game.visible and title.pending_game == null and not title.starting)
	assert(title.music_director.requested == "level", "Reveal must request level music")
	print("PASS: staged startup, duplicate guard, dialogue readiness; frames=",title.loading_frames,
		" max_frame_ms=",title.loading_max_frame_msec)
	title.return_to_title()
	title.selecting = true
	deadline = Time.get_ticks_msec()+60000
	while not title.prepared_for_selection() and Time.get_ticks_msec() < deadline:
		assert(not title.card_visible and title.game == null)
		await process_frame
	assert(title.prepared_for_selection())
	# Change both selections after building the hidden Tony/Normal host.
	title.selected = 1
	title.difficulty_index = 2
	await process_frame
	while (title.preparation_running or not title.prepared_for_selection()) and Time.get_ticks_msec() < deadline:
		await process_frame
	title.starting = true
	title.start_game()
	assert(title.game != null and not title.card_visible and not title.card_ready,"Warm start bypasses the card")
	assert(title.game.employee.id == "sean" and title.game.difficulty == "hard")
	assert(title.game.dispenser.costume == "hard" and title.game.health == title.game.employee.max_health)
	title.queue_free()
	await process_frame
	var missing := MissingJob.new()
	root.add_child(missing)
	missing.starting = true
	await missing.start_game()
	assert(missing.game == null and missing.pending_game == null)
	assert(not missing.starting and not missing.loading_in_progress and not missing.loading_error.is_empty())
	assert(missing.music_director.requested == "title", "Failed loading must retain menu music")
	missing.queue_free()
	await process_frame
	print("PASS: failed preparation returns control to the menu")
	quit()
