extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for hero in [0,1]:
		var game = Game.new()
		game.employee = game.Crew.EMPLOYEES[hero]
		game.seed_override = 42
		root.add_child(game)
		game.boss_intro.seen = {"cockroach-swarm": true, "clogfather": true}
		game.hide()
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.dispenser.cancel()
		game.invulnerable = 1000
		game.checkpoint_active = true
		game.checkpoint_index = 0
		game.respawn_point = Vector2(4650,394)
		game.player = Vector2(6210,394)
		game.camera_x = 5890
		game.grounded = true
		var room = game.skitterling
		# The actor remains physically present; authored foreground pixels provide occlusion.
		var masks: Array[Rect2] = room.art.portal_occlusion_rects(room.ORIGIN,false,false)
		for x in [6550.0,7510.0]:
			var covered := false
			for mask in masks:
				if mask.encloses(Rect2(x,394,26,46)): covered = true
			assert(covered,"Authored shell must cover a full hero in the middle of each tunnel")
		walk(game,1,6560)
		assert(not room.entered)
		Input.action_release("right")
		# Normal movement decelerates rather than snapping velocity to zero.
		for tick in range(30): game._physics_process(1.0/120)
		var stopped: Vector2 = game.player
		for tick in range(30): game._physics_process(1.0/120)
		assert(game.player.distance_to(stopped) < .01,"Stopping inside pipe cannot auto-complete entry")
		var paused_camera: float = game.camera_x
		game.set_paused(true)
		for tick in range(30): game._physics_process(1.0/120)
		assert(game.player == stopped and game.camera_x == paused_camera and not room.entered)
		game.set_paused(false)
		game.dialogue.release_guard = 0
		walk(game,-1,6210)
		assert(not room.entered and not game.boss_hud.active)
		walk(game,1,6700)
		assert(room.entered and room.locked() and game.camera_x == room.START)
		assert(room.encounter.state == "entry_skitter" and game.boss_hud.maximum == room.Encounter.MAX_HP)
		var start_clock: float = room.clock
		walk(game,-1,6690)
		assert(game.player.x == 6690 and room.clock >= start_clock)
		# Both closed gates use collision boundaries, including the false-death interval.
		for state in ["rat_ready","rat_collapse","reskitter","alligator_ready"]:
			room.encounter.state = state
			var right: Dictionary = game.move_player_body(Vector2(7380,394),Vector2(1000,0),game.PLAYER_SIZE,.1)
			var left: Dictionary = game.move_player_body(Vector2(6691,394),Vector2(-1000,0),game.PLAYER_SIZE,.1)
			assert(right.pos.x == 7384 and left.pos.x == 6690)
			assert(room.camera_position(7300) == 6570)
		room.encounter.exit_open = true
		room.encounter.active = false
		room.encounter.state = "complete"
		game.player = Vector2(7370,394)
		walk(game,1,7510)
		assert(not room.released and game.camera_x > 6570)
		walk(game,-1,7370)
		assert(not room.released and game.camera_x == 6570 and room.encounter.exit_open)
		walk(game,1,7660)
		assert(room.released and not room.locked() and not game.boss_hud.active)
		walk(game,-1,7500)
		assert(room.released and room.encounter.state == "complete" and room.encounter.exit_open)
		assert(game.camera_x > 6570 and game.camera_x < game.player.x-320)
		walk(game,-1,7370)
		assert(room.released and game.camera_x == 6570)
		walk(game,1,7660)
		assert(room.released and room.encounter.state == "complete")
		walk(game,-1,7510)
		# A retry from inside the open exit clears portal/camera state using the real checkpoint policy, without refilling stock.
		game.dispenser.checkpoint = 0
		game.dispenser.consume_stock()
		game.health = 1
		game.invulnerable = 0
		game.hurt_player()
		game.respawn_after_death()
		assert(game.player.x == 4650 and game.camera_x == 4330 and not room.entered and not room.released)
		assert(game.lives == 2 and not game.dispenser.stocked and room.encounter.hp == room.Encounter.MAX_HP)
		game.queue_free()
		await process_frame
	print("PASS: both heroes walk/stop/reverse through side portals, continuous camera, masks, gates, release and retry")
	quit()

func walk(game: Node2D, direction: int, destination: float) -> void:
	Input.action_release("left")
	Input.action_release("right")
	Input.action_press("right" if direction > 0 else "left")
	for tick in range(120*10):
		var before: Vector2 = game.player
		var old_camera: float = game.camera_x
		game._physics_process(1.0/120)
		assert(absf(game.player.x-before.x) <= game.employee.move_speed/120+.02,"Portal must never teleport")
		assert(absf(game.camera_x-old_camera) <= 14,"Camera must remain continuous across portal blend boundaries")
		assert(game.player.y == 394,"Tunnel floor stays continuous; no drowning or hidden step")
		if direction*(game.player.x-destination) >= -.01: break
	Input.action_release("left")
	Input.action_release("right")
	assert(direction*(game.player.x-destination) >= -.01,"Walk target must be reachable")
