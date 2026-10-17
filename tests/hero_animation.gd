extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var art = game.world_art.hero_aim_art
	var directions := [Vector2.LEFT, Vector2(-1,-1), Vector2.UP, Vector2(1,-1),
		Vector2.RIGHT, Vector2(1,1), Vector2.DOWN, Vector2(-1,1)]
	var cases := 0
	for person in game.Crew.EMPLOYEES:
		game.employee = person
		game.reset_game()
		for phase in ["idle", "run", "takeoff", "rising", "apex", "falling", "landing", "hurt"]:
			game.animation_state = phase
			game.grounded = phase in ["idle", "run", "landing", "hurt"]
			for direction in directions:
				if game.grounded and direction == Vector2.DOWN: continue
				game.current_aim = direction.normalized()
				game.facing = -1 if direction.x < 0 else 1
				game.velocity.x = 270 * game.facing if phase == "run" else 0
				for firing in [false, true]:
					game.fire_timer = game.weapon.attack_interval_seconds if firing else 0
					var frames: Array = []
					for frame_index in range(6 if phase == "run" else 1):
						game.animation_time = frame_index * 0.09 + 0.001
						var pose: Dictionary = art.selected_pose(game)
						assert(pose.hero == person.id and pose.weapon == person.weapon_id)
						var source_muzzle: Array = pose.muzzle
						var expected: Vector2 = art.world_transform(game) * Vector2(source_muzzle[0], source_muzzle[1])
						assert(art.muzzle(game).is_equal_approx(expected))
						for layer: Dictionary in pose.layers:
							assert(art.textures[layer.path] != null)
							var size: Vector2 = art.textures[layer.path].get_size()
							var rect: Array = layer.source_rect
							assert(rect[0] >= 0 and rect[1] >= 0 and rect[0]+rect[2] <= size.x and rect[1]+rect[3] <= size.y)
						if phase == "run": frames.append(int(pose.body_frame))
					if phase == "run":
						assert(frames == [0,1,2,3,4,5], "Every aim and firing state must advance real run frames")
					cases += 1
		game.life_state = "dying"
		game.grounded = false
		game.death_time = 0
		assert(art.death_frame(game).stage == "recoil")
		game.death_time = 100
		assert(art.death_frame(game).stage == "airborne_fall")
		game.grounded = true
		game.death_ground_time = 0
		assert(art.death_frame(game).stage == "ground_impact")
		game.death_ground_time = 100
		assert(art.death_frame(game).stage == "settled", "Death never loops")
		assert(int(art.animations.heroes[person.id].head_icon.max_size[0]) == 24)
		game.life_state = "alive"
		# Verify grounded diagonal aiming survives actual collision/landing resolution.
		game.player = Vector2(800,394)
		Input.action_press("right")
		Input.action_press("aim_down")
		game.step_player(0)
		assert(game.grounded and game.current_aim.is_equal_approx(Vector2(1,1).normalized()))
		assert(art.selected_pose(game).direction == "down_right")
		Input.action_release("right")
		game.step_player(0)
		assert(game.current_aim == Vector2.RIGHT)
		Input.action_release("aim_down")
	game.queue_free()
	await process_frame
	print("PASS: ", cases, " hero/phase/aim/fire combinations, six run frames, muzzles, death stages, head icons and landing")
	quit()
