extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Route = preload("res://scripts/clogfather_route.gd")
const START := 9450.0
const TARGET := 13830.0

func _initialize() -> void:
	call_deferred("run_checks")

func prepare(mode: String, hero: int) -> Node2D:
	var game = Game.new()
	game.difficulty = mode
	game.seed_override = 42
	game.employee = game.Crew.EMPLOYEES[hero]
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	# This fixture starts after the prior fight; it does not claim to defeat Skitterling.
	game.respawn_origin = 4650
	game.reset_observation()
	game.skitterling.restore_completed()
	game.skitterling.clear_prior(game)
	game.checkpoint_active = true
	game.checkpoint_index = 0
	game.respawn_point = Vector2(4650,394)
	game.player = Vector2(START,394)
	game.velocity = Vector2.ZERO
	game.camera_x = START-320
	game.route_progress = START
	game.grounded = true
	return game

func check_boundary(game: Node2D) -> void:
	for actor in game.actors:
		if actor.hp > 0:
			assert(game.actor_rect(actor).end.x <= Route.CONTAINMENT+0.01,"Actor leaked into quiet approach")
	for enemy in game.enemies:
		assert(enemy.pos.x+38 <= Route.CONTAINMENT+0.01)
	for shot in game.hostile_shots:
		assert(shot.pos.x < Route.CONTAINMENT,"Hostile projectile leaked")
	for swarm in game.swarms.actors:
		assert(swarm.pos.x+48 <= Route.CONTAINMENT,"Swarm leaked")

func travel(game: Node2D, direction: int, hz: int) -> int:
	Input.action_release("left" if direction > 0 else "right")
	Input.action_press("right" if direction > 0 else "left")
	var contacts := 0
	for tick in range(90*hz):
		if game.dispenser.active or game.dispenser.actions_locked:
			Input.action_release("shoot")
			game.dispenser.tick(game,1.0/hz)
		else:
			Input.action_press("shoot")
		if game.grounded:
			for solid: Rect2 in game.trial_level.plinths:
				var gap: float = solid.position.x-(game.player.x+26) if direction > 0 else game.player.x-solid.end.x
				if gap >= -0.01 and gap < 70 and solid.position.y < game.player.y+46:
					game.jump_buffer = 0.14
		# Coverage bot: real physics/projectiles/contact, but health restoration prevents route truncation.
		game.health = game.employee.max_health
		game._physics_process(1.0/hz)
		if game.health < game.employee.max_health: contacts += 1
		check_boundary(game)
		assert(game.life_state == "alive" and not game.won)
		assert(not game.clogfather.entered,"Route test must not enter boss")
		if direction > 0 and game.player.x >= TARGET and not game.dispenser.active: return contacts
		if direction < 0 and game.player.x <= START: return contacts
	print("STALLED x=",game.player," direction=",direction," hz=",hz)
	assert(false,"Continuation traversal exceeded 90 simulated seconds")
	return contacts

func run_checks() -> void:
	for mode in ["easy","normal","hard"]:
		for hero in [0,1]:
			for hz in [60,120]:
				var game := prepare(mode,hero)
				for solid in Route.SOLIDS: assert(game.player_shot_solids().has(solid))
				for ledge in Route.LEDGES: assert(not game.player_shot_solids().has(ledge))
				var contacts := travel(game,1,hz)
				assert(game.checkpoint_index == 1 and game.respawn_point.x == Route.CHECKPOINT)
				assert(game.skitterling.released and game.skitterling.encounter.exit_open)
				var admitted := 0
				for id in game.route_admitted:
					if id.begins_with("clog-approach-"): admitted += 1
				assert(admitted > 0 and game.wave_spawned[4] == admitted,"Extension role events did not admit")
				var swarm_count := 0
				for slot in Route.SWARMS:
					var entry: Dictionary = game.swarm_schedule.ledger[slot.id]
					assert(entry.issued and entry.visible,"New swarm was not encountered: "+slot.id)
					swarm_count += 1
				contacts += travel(game,-1,hz)
				assert(game.checkpoint_index == 1,"Reverse traversal regressed checkpoint")
				print("ROUTE ",JSON.stringify({"mode":mode,"hero":hero,"hz":hz,
					"admitted":admitted,"swarms":swarm_count,"contacts":contacts,"reverse_x":game.player.x}))
				for action in ["left","right","shoot"]: Input.action_release(action)
				game.queue_free()
				await process_frame
	print("PASS:12 forward/reverse continuation cases; health-restored coverage, not balance validation")
	quit()
