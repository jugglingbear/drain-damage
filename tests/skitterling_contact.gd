extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for hero in [0, 1]:
		for mode in ["easy", "normal", "hard"]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			root.add_child(game)
			game.set_process(false)
			game.set_physics_process(false)
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.dispenser.cancel()
			var room = game.skitterling
			var boss = room.encounter
			room.entered = true
			boss.active = true
			boss.phase = "rat"
			boss.position = Vector2(450, 440)
			boss._enter("rat_ready")
			var cells: Array[Rect2] = room.art.visible_contact_regions(boss.snapshot(), room.ORIGIN, room.clock)
			assert(not cells.is_empty())
			var touch := Vector2.ZERO
			for cell: Rect2 in cells:
				var grounded := Rect2(Vector2(cell.get_center().x - 13, 394), game.PLAYER_SIZE)
				if grounded.intersects(cell):
					touch = grounded.position
					break
			assert(touch != Vector2.ZERO, "Formed rat must have visible contact reachable from the floor")
			game.player = touch
			game.invulnerable = 0
			var before: int = game.health
			room.advance(game, .001)
			assert(game.health == before - 1 and game.invulnerable == 1.5)
			game.player = touch
			room.advance(game, .001)
			assert(game.health == before - 1, "Continuous contact must respect normal immunity")
			game.player = touch
			game.invulnerable = 0
			game.set_paused(true)
			room.advance(game, .1)
			assert(game.health == before - 1, "Paused contact cannot damage")
			game.set_paused(false)
			game.dialogue.release_guard = 0
			for state in ["rat_assembly", "rat_collapse", "rat_inside_pipe"]:
				boss._enter(state)
				game.player = touch
				game.invulnerable = 0
				var safe_hp: int = game.health
				room.advance(game, .001)
				assert(game.health == safe_hp, "Hidden or transforming rat cannot cause contact damage")
			game.queue_free()
			await process_frame
	print("PASS: actual visible rat contact, both heroes/all modes, shared immunity, pause and harmless transitions")
	quit()
