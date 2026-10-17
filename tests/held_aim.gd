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
		game.player=Vector2(800,394)
		game.grounded=true
		Input.action_press("right")
		Input.action_press("aim_up")
		game.step_player(0)
		assert(game.current_aim.is_equal_approx(Vector2(1,-1).normalized()))
		assert(game.shots.is_empty())
		var art = game.world_art.hero_aim_art
		assert(art.selected_pose(game).direction == "up_right")
		var held_pose: Dictionary = art.selected_pose(game)
		Input.action_press("shoot")
		game.step_player(0)
		assert(game.shots.size()==1 and game.shots[0].dir==game.current_aim)
		assert(game.shots[0].pos.is_equal_approx(art.muzzle(game)))
		Input.action_release("shoot")
		for timer in [0.0,0.05,0.5]:
			assert(art.selected_pose(game) == held_pose)
			game.fire_timer=timer
			game.step_player(0)
			assert(game.current_aim.is_equal_approx(Vector2(1,-1).normalized()))
		Input.action_release("right")
		game.step_player(0)
		assert(game.current_aim==Vector2.UP)
		Input.action_release("aim_up")
		game.step_player(0)
		assert(game.current_aim==Vector2.RIGHT)
		game.player.y=300
		Input.action_press("aim_down")
		game.step_player(0)
		assert(game.current_aim==Vector2.DOWN)
		assert(art.selected_pose(game).direction == "down")
		assert(art.selected_pose(game).stance == "airborne")
		game.player.y=394
		game.step_player(0)
		assert(game.current_aim==Vector2.RIGHT)
		assert(art.selected_pose(game).direction == "right")
		assert(art.selected_pose(game).stance == "standing")
		Input.action_release("aim_down")
		for direction in [Vector2.RIGHT, Vector2(1,-1), Vector2.UP, Vector2(-1,-1), Vector2.LEFT, Vector2(-1,1), Vector2.DOWN, Vector2(1,1)]:
			game.grounded = false
			game.current_aim = direction.normalized()
			game.facing = -1 if direction.x < 0 else 1
			assert(not art.selected_pose(game).is_empty())
			var anchor: Array = art.selected_pose(game).muzzle
			var local := Vector2(anchor[0]-64, anchor[1]-104)
			local.x *= game.facing
			assert(art.muzzle(game).is_equal_approx(game.player+Vector2(13,46)+local))
		game.facing = 1
		game.player = Vector2(game.Level.GATES[0] - 32, 394)
		game.shots.clear()
		game.fire_timer = 0
		Input.action_press("shoot")
		game.step_player(0)
		assert(game.shots.is_empty(), "Barrel must not shoot through a closed shutter")
		Input.action_release("shoot")
	game.queue_free()
	await process_frame
	print("PASS: both heroes maintain aim without firing, through cooldown, release and landing")
	quit()
