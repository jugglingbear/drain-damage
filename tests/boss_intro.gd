extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			for id in ["cockroach-swarm","clogfather"]:
				var game = Game.new()
				game.difficulty = mode
				game.employee = game.Crew.EMPLOYEES[hero]
				root.add_child(game)
				game.hide()
				game.set_process(false)
				game.set_physics_process(false)
				game.dispenser.cancel()
				game.dispenser.just_finished = false
				game.dialogue.finish()
				game.dialogue.release_guard = 0
				game.restart_guard_device = -1
				if id == "clogfather": game.skitterling.restore_completed()
				game.player = Vector2(14240 if id == "clogfather" else 6700,394)
				game.checkpoint_index = 1 if id == "clogfather" else 0
				game.velocity = Vector2.ZERO
				game._physics_process(1.0/120)
				var intro = game.boss_intro
				assert(intro.boss_id == id and intro.blocking())
				var frame: Dictionary = intro.definition.frames[id]
				var destination: Rect2 = intro.region(frame.destination)
				assert(destination.get_center().is_equal_approx(Vector2(480,270)))
				assert(destination.size.x <= 540 and destination.size.y <= 180)
				assert(intro.get_global_transform().is_equal_approx(Transform2D.IDENTITY))
				assert(intro.z_index > game.boss_hud.z_index and intro.z_index < game.dialogue.z_index)
				var position: Vector2 = game.player
				var elapsed: float = game.elapsed
				var encounter = game.clogfather.encounter if id == "clogfather" else game.skitterling.encounter
				var hp: float = encounter.hp
				Input.action_press("shoot")
				Input.action_press("jump")
				game._physics_process(.4)
				assert(is_equal_approx(intro.opacity(),1))
				game.set_paused(true)
				game._physics_process(1)
				assert(is_equal_approx(intro.clock,.4))
				game.set_paused(false)
				game.dialogue.awaiting_release = false
				game._process(.3)
				game._physics_process(2.99)
				game._process(.1)
				assert(game.player == position and game.elapsed == elapsed and encounter.hp == hp)
				assert(intro.blocking() and game.shots.is_empty())
				game._physics_process(.01)
				assert(not intro.blocking() and intro.active())
				game._physics_process(.125)
				assert(is_equal_approx(intro.opacity(),.5))
				assert(game.shots.is_empty() and game.intro_input_release)
				Input.action_release("shoot")
				Input.action_release("jump")
				game._physics_process(.125)
				assert(not intro.active() and not game.intro_input_release)
				assert(not intro.begin(id),"Checkpoint retry skips an already seen title")
				intro.reset()
				assert(not intro.begin(id))
				game.reset_game()
				assert(intro.seen.is_empty() and not intro.active())
				game.queue_free()
				await process_frame
	print("PASS: both boss entrances/all heroes and modes, centering, hold/fade boundary, pause, frozen world, held inputs, retry/new run")
	quit()
