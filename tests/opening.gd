extends SceneTree
const Story = preload("res://scripts/story_dialogue.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	assert(title.game == null, "Application launch does not start the opening")
	assert(Story.OPENING.size() == 7)
	for entry in Story.OPENING:
		var paragraph := TextParagraph.new()
		paragraph.width = 520
		paragraph.add_string(entry.text, ThemeDB.fallback_font, 21)
		assert(paragraph.get_size().y <= 95, "Opening text must clear the skip hint")
	for selected in range(2):
		var snapshots: Array[Dictionary] = []
		for skip in [false, true]:
			title.selected = selected
			title.start_game()
			var game = title.game
			game.set_process(false)
			game.set_physics_process(false)
			assert(game.employee.id == ["tony", "sean"][selected])
			assert(game.dialogue.active and game.dialogue.lines == Story.OPENING)
			var position: Vector2 = game.player
			var enemies: Array = game.enemies.duplicate(true)
			game._process(0.5)
			game._physics_process(0.5)
			assert(game.player == position and game.enemies == enemies and game.elapsed == 0)
			game.dialogue.using_controller = false
			assert(game.dialogue.skip_hint() == "Tab · SKIP")
			game.dialogue.using_controller = true
			assert(game.dialogue.skip_hint() == "B · SKIP")
			if skip:
				Input.action_press("dialogue_skip")
				game.dialogue.tick(0.5, false)
				Input.action_release("dialogue_skip")
			else:
				for index in range(7):
					game.dialogue.advance()
					game.dialogue.advance()
			assert(not game.dialogue.active and game.dialogue.release_guard > 0)
			Input.action_press("shoot")
			game.dialogue.tick(1.0, false)
			game._physics_process(0.2)
			assert(game.shots.is_empty(), "Held dismissal cannot leak into firing")
			Input.action_release("shoot")
			game.dialogue.tick(0.3, false)
			game.dialogue.tick(0.3, false)
			snapshots.append({"player":game.player, "health":game.health, "kills":game.kills,
				"checkpoint":game.checkpoint_active, "weapon":game.employee.weapon_id})
			game.health = 1
			game.invulnerable = 0
			game.hurt_player()
			for frame in range(180): game.step_death(1.0 / 60)
			game.update_death_popup_guard(0.4)
			game.resume_or_retry()
			assert(not game.dialogue.active, "Death does not replay")
			game.activate_checkpoint()
			game.dispenser.tick(game,5.6)
			game.health = 1
			game.invulnerable = 0
			game.hurt_player()
			for frame in range(180): game.step_death(1.0 / 60)
			game.update_death_popup_guard(0.4)
			game.resume_or_retry()
			assert(not game.dialogue.active and game.player == game.respawn_point)
			game.reset_game()
			assert(not game.dialogue.active, "Retry does not replay")
			title.return_to_title()
			await process_frame
		assert(snapshots[0] == snapshots[1], "Skip and completion hand off identically")
	title.queue_free()
	await create_timer(0.3).timeout
	print("PASS: both heroes, fresh-run replay, freeze, skip/complete parity, bindings, held-input guard, death/checkpoint/retry")
	quit()
