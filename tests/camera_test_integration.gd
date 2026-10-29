extends SceneTree
const CameraGame = preload("res://scripts/camera_test_game.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var options := Launch.parse(["--level=2.1","--hero=sean"])
	assert(options.target.initializer == "camera-test")
	assert(Launch.parse(["--level=2-08"]).target.initializer == "ride-encounter")
	for hero in [0,1]:
		var game = CameraGame.new()
		game.employee = game.Crew.EMPLOYEES[hero]
		game.difficulty = "normal" if hero == 0 else "hard"
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
