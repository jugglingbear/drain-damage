extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func check(value: bool, message: String) -> bool:
	if value: return true
	push_error(message)
	quit(1)
	return false

func release(game: Node) -> void:
	game.dialogue.finish()
	game.dialogue.awaiting_release = false
	game.dialogue.release_guard = 0

func run_checks() -> void:
	create_timer(45).timeout.connect(func() -> void: quit(1))
	var art = load("res://scripts/first_level_ending.gd").new()
	if not check(art.prepare(),"Portal art failed to load"): return
	for frame: Dictionary in art.definition.frames:
		var source: Array = frame.source_rect
		var texture: Texture2D = art.textures[frame.path]
		if not check(Rect2(Vector2.ZERO,texture.get_size()).encloses(
			Rect2(source[0],source[1],source[2],source[3])),"Portal source outside texture"): return
	for hero in [0,1]:
		for mode in ["normal","hard"]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.dispenser.cancel()
			game.dispenser.just_finished = false
			game.restart_guard_device = -1
			release(game)
			game.player = Vector2(14630,394)
			game.clogfather.encounter.exit_open = true
			game.ending.begin(game)
			if not check(game.dialogue.lines.size() == 5 and game.ending.panic_text == "UUAAAAAAAAAA!!",
				"The selected hero's scream belongs to the moving pull, not a blocking sixth line"): return
			var frame: Dictionary = game.ending.hero_frame(game)
			var full: Dictionary = game.ending.clipped_hero(frame,Vector2(game.ending.PORTAL_PLANE-200,355))
			for offset in [-100,-40,0,40,100]:
				var visible: Dictionary = game.ending.clipped_hero(frame,Vector2(game.ending.PORTAL_PLANE+offset,355))
				if not check(is_equal_approx(visible.target.size.y,full.target.size.y)
					and is_equal_approx(visible.source.size.y,full.source.size.y),"Portal must never shrink hero height"): return
				if visible.target.has_area():
					if not check(is_equal_approx(visible.target.size.x/visible.source.size.x,
						full.target.size.x/full.source.size.x),"Occlusion must crop pixels without rescaling"): return
				if offset == 100 and not check(not visible.target.has_area(),"Hero must fully cross the aperture plane"): return
			var start: Vector2 = game.player
			game._physics_process(3)
			if not check(game.player == start and not game.won,"Dialogue must hold suction and success"): return
			game.ending.begin(game)
			if not check(game.ending.state == "dialogue","Repeated trigger changed ending phase"): return
			game.dialogue.finish()
			game.dialogue.awaiting_release = true
			game.dialogue.release_guard = 0
			game._physics_process(1)
			if not check(game.ending.state == "dialogue","Skip/advance leaked through release guard"): return
			release(game)
			game._physics_process(0)
			game._physics_process(0.8)
			if not check(game.ending.hero_scale() == 1.0,"Full-size departure contract changed"): return
			if not check(game.player.x > start.x and not game.won,"Pull must move selected hero before success"): return
			var held: Vector2 = game.player
			game.set_paused(true)
			game._physics_process(4)
			if not check(game.player == held and not game.won,"Paused portal advanced"): return
			game.set_paused(false)
			release(game)
			game._physics_process(1.7)
			if not check(game.won and game.ending.state == "complete","Departure never completed"): return
			if not check(game.player.is_equal_approx(game.ending.TARGET-game.PLAYER_SIZE*0.5),
				"Departure did not carry the full-size hero beyond the portal plane"): return
			game.update_completion_button()
			if not check(game.title_button.disabled,"Held input can dismiss completion immediately"): return
			game.reset_game()
			if not check(not game.ending.active() and not game.won and game.ending.panic_text.is_empty(),
				"Reset retained portal state or scream"): return
			game.queue_free()
			await process_frame
	print("PASS: all four full-size hero poses, aperture cropping, moving scream, dialogue/skip guard, pause and reset")
	quit()
