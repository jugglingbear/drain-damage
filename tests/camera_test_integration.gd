extends SceneTree
const CameraGame = preload("res://scripts/camera_test_game.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var options := Launch.parse(["--level=2.1","--hero=sean"])
	assert(options.target.initializer == "camera-test")
	assert(Launch.parse(["--level=2-08"]).target.initializer == "ride-encounter")
	for setup in [[0,"normal"],[0,"hard"],[0,"easy"],[1,"normal"],[1,"hard"],[1,"easy"]]:
		var game = CameraGame.new()
		game.employee = game.Crew.EMPLOYEES[setup[0]]
		game.difficulty = setup[1]
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		Launch.initialize(game,options.target)
		assert(Launch.summary(game,options).camera_test)
		assert(not game.flush.active and game.camera_view.ready_art)
		assert(game.health == game.employee.max_health and game.lives == 3)
		var view = game.camera_view
		var model = game.camera_model
		var start: Vector2 = model.position
		assert(view.request_turn(model))
		view.update_view(model,.6,false,0)
		assert(is_equal_approx(view.yaw,0))
		view.update_view(model,1,true,0)
		assert(is_equal_approx(view.yaw,0) and model.position == start and model.clock == 0)
		view.update_view(model,.6,false,0)
		assert(is_equal_approx(view.yaw,view.SECOND_YAW) and not view.turning())
		# The rendered underside must project onto the same contacts as the physical rigid board.
		for angle in [view.FIRST_YAW,view.SECOND_YAW]:
			view.yaw = angle
			view.target_yaw = angle
			for x in [17.6,18.0,19.5,20.9]:
				model.position = Vector2(x,0)
				var support: Dictionary = model.support_at(model.position)
				model.elevation = support.height
				model.board_pitch = support.pitch
				view.update_view(model,0,true,0)
				var pose: Dictionary = model.board_pose()
				for endpoint in [[-1.0,"rear"],[1.0,"front"]]:
					var actual: Vector2 = view.camera.unproject_position(view.rider.to_global(
						Vector3(endpoint[0]*model.BOARD_LENGTH*.5,0,0)))
					var expected: Vector2 = view.camera.unproject_position(pose[endpoint[1]])
					assert(actual.distance_to(expected) < .01,"Billboard must preserve physical slope contacts")
				for sprite: Sprite3D in view.rider.get_children():
					assert(sprite.billboard == BaseMaterial3D.BILLBOARD_DISABLED)
		# Full sprite quads must stay inside the banks and gameplay viewport, including camera turns.
		var track: Rect2 = model.LAYOUT.track.rect
		for angle in [-18.0,-9.0,0.0,9.0,18.0]:
			view.yaw = angle
			view.target_yaw = angle
			for x in [track.position.x+model.WALL_HALF.x,12.0,track.end.x-model.WALL_HALF.x]:
				for z in [track.position.y+model.WALL_HALF.y,track.end.y-model.WALL_HALF.y]:
					for height in [0.0,.54]:
						model.position = Vector2(x,z)
						model.elevation = height
						model.board_pitch = 0
						view.update_view(model,0,true,0)
						for sprite: Sprite3D in view.rider.get_children():
							var bounds := sprite.get_aabb()
							for index in 8:
								var point := sprite.to_global(bounds.get_endpoint(index))
								assert(point.z > track.position.y and point.z < track.end.y,
									"Full rider must clear both walls throughout camera turns")
								var screen: Vector2 = view.camera.unproject_position(point)
								assert(Rect2(8,90,944,380).has_point(screen),
									"Full rider must remain inside gameplay view, outside HUD: %s setup=%s yaw=%s position=%s height=%s" % [screen,setup,angle,model.position,height])
		model.elevation = 0
		model.board_pitch = 0
		model.position = model.LAYOUT.hole.center
		assert(not view.request_turn(model))
		game._physics_process(1.0/60)
		assert(game.life_state == "dying" and game.lives == 2 and model.dead)
		game.set_paused(true)
		var age: float = game.death_time
		game._physics_process(.5)
		assert(game.death_time == age)
		game.set_paused(false)
		for frame in 90: game._physics_process(1.0/60)
		assert(game.life_state == "death_popup" and game.lives == 2)
		game.respawn_after_death()
		assert(not model.dead and model.position == start and game.health == game.employee.max_health)
		assert(game.lives == 2 and game.life_state == "alive")
		game.free()
	print("PASS: isolated entry, authored materials, both heroes, bounded turn/pause, world invariance and one-life retry")
	quit()
