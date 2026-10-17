extends SceneTree
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	for person in game.Crew.EMPLOYEES:
		game.employee=person
		game.reset_game()
		for grounded in [true,false]:
			game.grounded=grounded
			for x in [-1,0,1]:
				for y in [-1,0,1]:
					for action in ["left","right","aim_up","aim_down"]: Input.action_release(action)
					if x: Input.action_press("left" if x<0 else "right")
					if y: Input.action_press("aim_up" if y<0 else "aim_down")
					var expected := Vector2(x,y)
					if expected==Vector2.ZERO or (grounded and y>0 and x==0): expected=Vector2(game.facing,0)
					assert(game.aim_direction().is_equal_approx(expected.normalized()))
					assert(not Input.is_action_pressed("jump"))
		for action in ["left","right","aim_up","aim_down"]: Input.action_release(action)
		# Every direction travels the same distance and stops at its path-length cap.
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,
				Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
			var origin := Vector2(1000,-1000)
			game.shots.clear()
			game.shots.append({"pos":origin,"dir":direction.normalized(),"damage":6,"speed":100,
				"range":game.weapon.projectile.max_travel_distance_pixels,"distance":0.0})
			game.step_combat(1)
			assert(game.shots[0].pos.is_equal_approx(origin+direction.normalized()*100))
			game.step_combat(10)
			assert(game.shots.is_empty())
	# A weapon can deny a direction; never silently grant it universal eight-way fire.
	game.weapon=game.weapon.duplicate(true)
	game.weapon.aiming.airborne_directions=["left","right"]
	game.grounded=false
	Input.action_press("aim_up")
	assert(game.aim_direction()==Vector2(game.facing,0))
	Input.action_release("aim_up")
	for event in InputMap.action_get_events("jump"):
		if event is InputEventKey: assert(event.physical_keycode==KEY_SPACE)
	# Actual vertical projectile damages the first target on its swept path.
	game.enemies.clear()
	game.enemies.append(game.Data.spawn("toilet",Vector2(800,404)))
	game.shots.append({"pos":Vector2(819,300),"dir":Vector2.DOWN,"damage":6,"speed":1000,
		"range":320,"distance":0.0})
	game.step_combat(0.15)
	assert(game.enemies[0].hp==34 and game.shots.is_empty())
	assert(game.segment_hit(Vector2(5,0),Vector2(5,20),Rect2(0,10,10,5))==0.5)
	assert(game.segment_hit(Vector2(0,0),Vector2(20,20),Rect2(10,10,5,5))==0.5)
	assert(game.segment_hit(Vector2(0,0),Vector2(20,20),Rect2(15,0,5,5))<0)
	game.reset_game()
	game.player=Vector2(800,394)
	game.camera_x=480
	game.step_encounters(0)
	assert(game.enemies.size()==1 and game.encounter_triggered[0])
	var enemy: Dictionary=game.enemies[0]
	var center: float=enemy.pos.x+19
	assert(center+game.entrance_radius()<=game.camera_x-24 or center-game.entrance_radius()>=game.camera_x+984)
	assert(not enemy.aggro)
	var before: Vector2=enemy.pos
	game.step_combat(0.1)
	assert(enemy.pos.distance_to(game.player)<before.distance_to(game.player), "Immediate entrance motion")
	game.damage_enemy(0,100,Vector2.ZERO)
	game.health=1
	game.invulnerable=0
	game.hurt_player()
	assert(game.mission.defeated[0]==1 and game.encounter_triggered[0])
	for frame in range(100): game.step_encounters(0)
	assert(game.mission.spawned[0]<=3)
	game.reset_game()
	assert(not game.encounter_triggered[0] and game.mission.spawned[0]==0)
	game.queue_free()
	await process_frame
	print("PASS: aim permissions, normalized travel caps, segment collision, offscreen entry, persistence/reset")
	quit()
