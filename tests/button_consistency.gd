extends SceneTree
const Buttons = preload("res://scripts/plumbing_buttons.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func send_pair(event: InputEvent) -> void:
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)

func run_checks() -> void:
	var disabled := Buttons.appearance(true,true,true,true)
	assert(not disabled.highlight and disabled.offset == 0 and disabled.label == Buttons.MUTED)
	assert(Buttons.appearance(false,false,true,false).offset == 1)
	for fixture in [[65,26,"<",20],[100,35,"BACK",16],[110,34,"BACK",17],
		[140,42,"Back",20],[180,42,"Start Job",20],[195,40,"KEYBOARD",17],
		[446,34,"Music  OFF  ·  M / click (menus)",14],
		[430,34,"Enemy bars  OFF  ·  View / click (here)",14]]:
		var area := Rect2(0,0,fixture[0],fixture[1])
		var parts := Buttons.slices(area,true)
		assert(is_equal_approx(parts[0].target.end.x,parts[1].target.position.x))
		assert(is_equal_approx(parts[1].target.end.x,parts[2].target.position.x))
		assert(is_equal_approx(parts[2].target.end.x,area.end.x))
		var size := Buttons.label_size(fixture[2],area,fixture[3])
		var width := ThemeDB.fallback_font.get_string_size(fixture[2],HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		assert(width <= area.size.x-Buttons.CAP_WIDTH*area.size.y/Buttons.SOURCE_HEIGHT*1.2-4,
			"Label overlaps bolt cores: "+fixture[2])
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	for mode in ["keyboard","controller","mouse"]:
		title.start_game()
		var game = title.game
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.finish()
		game.complete_job()
		game.update_completion_button()
		assert(not game.pause_menu.visible,"Dialogue must retain the screen until finished")
		game.dialogue.finish()
		game.dialogue.awaiting_release = true
		game.update_completion_button()
		assert(game.title_button.disabled and not game.resume_button.visible)
		game.dialogue.awaiting_release = false
		game.dialogue.release_guard = 0
		game.update_completion_button()
		await process_frame
		assert(game.pause_menu.visible and game.title_button.has_focus() and not game.title_button.disabled)
		if mode == "keyboard":
			var key := InputEventKey.new()
			key.keycode = KEY_ENTER
			key.physical_keycode = KEY_ENTER
			send_pair(key)
		elif mode == "controller":
			var pad := InputEventJoypadButton.new()
			pad.button_index = JOY_BUTTON_A
			send_pair(pad)
		else:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = game.title_button.get_global_rect().get_center()
			click.global_position = click.position
			send_pair(click)
		await process_frame
		assert(title.game == null,"Completion return failed: "+mode)
	title.start_game()
	var game = title.game
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.lives = 1
	game.health = 1
	game.invulnerable = 0
	game.hurt_player()
	for frame in range(180): game.step_death(1.0/60)
	assert(game.life_state == "game_over" and game.resume_button.text == "Retry")
	var upper := Rect2(game.resume_button.position-Vector2(20,13),Vector2(510,85))
	var lower := Rect2(game.title_button.position-Vector2(20,13),Vector2(510,85))
	assert(not upper.intersects(lower) and lower.end.y < 510)
	assert(Rect2(0,0,960,540).encloses(lower))
	game.update_death_popup_guard(1)
	game.resume_button.pressed.emit()
	assert(game.life_state == "alive" and game.resume_button.visible and game.title_button.visible)
	assert(game.resume_button.text == "Resume" and game.resume_button.position.y == 255)
	title.return_to_title()
	title.queue_free()
	await process_frame
	var trial = load("res://scripts/opening_trial_game.gd").new()
	root.add_child(trial)
	trial.set_process(false)
	trial.set_physics_process(false)
	trial.show_results()
	assert(trial.resume_button.text == "Retry Opening Trial" and trial.resume_button.disabled)
	assert(trial.title_button.position.y+72 <= 540)
	trial.update_death_popup_guard(1)
	trial.resume_button.pressed.emit()
	assert(not trial.result_shown and not trial.paused)
	trial.queue_free()
	await process_frame
	print("PASS: plate state/label fit, completion keyboard/controller/mouse, game-over retry, trial results and reset")
	quit()
