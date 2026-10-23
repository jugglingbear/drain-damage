extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			var game = Game.new()
			game.difficulty = mode
			game.employee = game.Crew.EMPLOYEES[hero]
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.dispenser.cancel()
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.sync_boss_presentation()
			assert(game.transform == Transform2D.IDENTITY)
			game.skitterling.entered = true
			game.skitterling.released = false
			var world_player: Vector2 = game.player
			var camera: float = game.camera_x
			game.sync_boss_presentation()
			assert(game.boss_sidebar and game.player == world_player and game.camera_x == camera)
			assert((game.transform*Vector2(960,540)).is_equal_approx(Vector2(864,540)))
			assert((game.transform*Vector2(912,232)).is_equal_approx(Vector2(820.8,262.8)))
			assert((game.transform*Vector2(928,440)).x < 894)
			for overlay: CanvasItem in [game.boss_hud,game.dialogue,game.pause_menu]:
				assert(overlay.is_set_as_top_level())
				assert(overlay.get_global_transform().is_equal_approx(Transform2D.IDENTITY))
			assert(game.boss_hud.z_index < game.dialogue.z_index)
			assert(game.boss_hud.z_index < game.pause_menu.z_index)
			game.set_paused(true)
			assert(game.resume_button.get_global_rect().position == game.resume_button.position)
			game.set_paused(false)
			game.skitterling.encounter.hp = 0
			game.skitterling.encounter.exit_open = true
			game.boss_hud.end_encounter()
			game.sync_boss_presentation()
			assert(game.boss_sidebar,"Keep framing through terminal exit, after health bar fades")
			game.skitterling.released = true
			game.sync_boss_presentation()
			assert(not game.boss_sidebar)
			game.clogfather.entered = true
			game.sync_boss_presentation()
			for rect in [game.clogfather.encounter.weak_point,game.clogfather.encounter.high_weak_point]:
				assert((game.transform*rect).end.x < 864)
			for state in ["collapse","complete"]:
				game.clogfather.encounter.state = state
				game.clogfather.encounter.hp = 0
				game.sync_boss_presentation()
				assert(game.boss_sidebar,"Keep entire portal pull at stable scale")
			game.reset_game()
			assert(game.transform == Transform2D.IDENTITY and not game.boss_sidebar)
			game.queue_free()
			await process_frame
	print("PASS: sidebar mapping all heroes/modes; complete world, right pipe/body/weakpoints, fixed GUI, death/exit/portal/reset")
	quit()
