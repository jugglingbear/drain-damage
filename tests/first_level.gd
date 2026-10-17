extends SceneTree
const Level = preload("res://scripts/first_call.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	assert(game.WORLD_WIDTH == 9600 and game.mission.remaining() == 30)
	# Traverse every solid staircase in both directions using the shared body solver.
	for speed in [235.0,270.0,115.0]:
		for direction in [-1.0,1.0]:
			var size := Vector2(38,36) if speed == 115 else Vector2(26,46)
			var pos := Vector2(100 if direction>0 else 9000,440-size.y)
			var vel := Vector2.ZERO
			var grounded := true
			for frame in range(12000):
				vel.x = direction * speed
				if grounded:
					for rect in Level.PROPS:
						var edge: float = rect.position.x-(pos.x+size.x) if direction>0 else pos.x-rect.end.x
						if edge>=-0.1 and edge<8 and pos.y+size.y-rect.position.y>1:
							vel.y = -465
				vel.y += 1250.0/120
				var motion := Level.move_body(pos,vel,size,1.0/120,Level.PROPS)
				pos=motion.pos
				vel=motion.velocity
				grounded=motion.grounded
				if (direction>0 and pos.x>9000) or (direction<0 and pos.x<100): break
			assert((pos.x>9000 if direction>0 else pos.x<100), "Every staircase traversable in both directions")
	# Actual persistent pursuit AI must negotiate the same solids off camera.
	game.mission.current_zone=7
	game.enemies.append(game.Data.spawn("toilet",Vector2(100,404)))
	game.enemies[0].aggro=true
	for target in [9000.0,100.0]:
		game.player=Vector2(target,100)
		for frame in range(14000):
			game.step_combat(1.0/120)
			if absf(game.enemies[0].pos.x-target)<=6.1: break
		assert(absf(game.enemies[0].pos.x-target)<=6.1, "Persistent AI traverses all props")
	game.reset_game()
	# Gate-camping with offscreen entrances must drain all finite queues.
	for stage in range(7):
		var lane: Vector2 = Level.LANES[mini(stage,5)]
		game.player=Vector2(Level.GATES[mini(stage,5)]-26,394)
		game.grounded=true
		game.camera_x=clampf(game.player.x-320,0,8640)
		for cycle in range(20):
			for frame in range(160):
				game.step_encounters(1.0/120)
				assert(game.enemies.size()<=4)
			for enemy in game.enemies:
				var center: float = enemy.pos.x+19
				var radius: float = game.entrance_radius()
				assert(center+radius<=floorf(game.camera_x)-23.99 or center-radius>=floorf(game.camera_x)+983.99)
			while not game.enemies.is_empty(): game.damage_enemy(0,100,Vector2.ZERO)
			if game.mission.current_zone!=stage: break
		assert(game.mission.current_zone==stage+1, "Gate camp cannot lock queue")
	assert(game.kills==30 and game.mission.completed())
	game.player=Vector2(9451,394)
	game.dialogue.release_guard=0
	game._physics_process(0)
	assert(game.won)
	game.reset_game()
	assert(game.mission.remaining()==30 and not game.encounter_triggered[0] and not game.won)
	# Gates physically block player and projectiles, without invisible vertical extensions.
	var wall := Rect2(1390,180,48,260)
	var hit := Level.move_body(Vector2(1350,394),Vector2(270,0),Vector2(26,46),1,[wall])
	assert(hit.pos.x==1364)
	assert(game.segment_hit(Vector2(1300,410),Vector2(1500,410),wall)>=0)
	# Dialogue freezes encounter activation and full restart resets triggers.
	game.player=Vector2(1000,394)
	game.camera_x=680
	game.dialogue.start(game.Story.OPENING)
	game.step_encounters(5)
	assert(game.enemies.is_empty() and not game.encounter_triggered[0])
	game.dialogue.finish()
	# At ground height on descent, a horizontal jump shot can hit a ground target.
	game.enemies.clear()
	game.enemies.append(game.Data.spawn("toilet",Vector2(800,404)))
	game.player=Vector2(700,390)
	game.velocity=Vector2(0,100)
	game.fire_timer=0
	game.facing=1
	Input.action_press("shoot")
	game.step_player(1.0/120)
	Input.action_release("shoot")
	game.step_combat(0.2)
	assert(game.enemies[0].hp<40, "Descending shots can hit ground enemies")
	game.queue_free()
	await process_frame
	print("PASS: both heroes and enemy traversal both directions; seven finite waves, gate camping, cap, exit/reset and solids")
	quit()
