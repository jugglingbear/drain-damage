extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
var failures := 0

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var game = Game.new()
	game.seed_override = 42
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dispenser.cancel()
	for hz in [60,120]:
		for hero in game.Crew.EMPLOYEES:
			game.employee = hero
			for campaign in [false, true]:
				game.actors.clear()
				game.enemies.clear()
				game.camera_x = 4800
				game.invulnerable = 1000
				game.player = Vector2(5700,394)
				var actor: Dictionary
				if campaign:
					actor = game.Data.spawn("toilet",Vector2(5421,284))
					actor.aggro = true
					actor.direction = 1.0
					game.enemies.append(actor)
				else:
					game.create_actor({"id":"checkpoint-navigation","role":"runner","warning_seconds":.8},Vector2(5440,320))
					actor = game.actors.back()
					actor.active = true
					actor.runner.direction = 1.0
				for tick in range(hz * 6): advance(game,campaign,1.0/hz)
				var feet := Vector2(actor.pos) + Vector2(19,36) if campaign else Vector2(actor.feet)
				check(feet.x <= 5591.01 and is_equal_approx(feet.y,380), "Quiet boundary must retain a reachable lower stair")
				# Hero crosses behind the enemy after it reaches the boss-approach boundary.
				game.player = Vector2(4900,334)
				var highest := feet.y
				for tick in range(hz * 12):
					advance(game,campaign,1.0/hz)
					feet = Vector2(actor.pos) + Vector2(19,36) if campaign else Vector2(actor.feet)
					highest = minf(highest,feet.y)
				check(feet.x < 5100 and highest <= 260.01,"Flushfiend must turn and climb back toward hero")
				print("Checkpoint navigation ",hero.id," campaign=",campaign," feet=",feet," highest=",highest)
	game.queue_free()
	await process_frame
	if failures == 0: print("PASS: actual postcheckpoint geometry, quiet boundary, both hero sides, normal/campaign reacquisition")
	quit(1 if failures else 0)

func advance(game: Node2D, campaign: bool, delta: float) -> void:
	if campaign: game.step_combat(delta)
	else: game.step_trial_actors(delta)
	game.skitterling.contain_prior(game)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
