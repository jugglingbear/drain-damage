extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	var view = game.flush.world_view
	view.set_process(false)
	if not view.configured: view.configure()
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		for angle in [-18.0,18.0]:
			game.flush.enter_ride(game,0)
			var model = game.flush.ride
			model.jump_age = .2
			model.render_height = 48
			view.yaw = angle
			assert(model.fidget.step(model,true,0).triggered)
			var effect: Dictionary = model.fidget.effects[0]
			view.update_world()
			assert(view.fidget_view.instances.has(effect.id))
			var cloud: MeshInstance3D = view.fidget_view.instances[effect.id]
			assert(cloud.mesh is QuadMesh)
			assert(cloud.material_override.render_priority == 1,"Cloud must sort after transparent water")
			assert(cloud.material_override.get_shader_parameter("uv_region") == Vector4(0,0,1,1))
			assert(cloud.position.is_equal_approx(view.world(Vector2(255,330),56)))
			var release: Vector2 = effect.center
			model.clock += .5
			model.position.y += 20
			model.fidget.step(model,false,.5)
			view.update_world()
			assert(effect.center == release,"Cloud cannot follow steering or board")
			assert(model.fidget.effects.size() == 1,"Partly onscreen puff remains")
			assert(cloud.position.is_equal_approx(view.world(Vector2(255-280,330),60)))
			model.clock += 4
			model.fidget.step(model,false,4)
			view.update_world()
			assert(model.fidget.effects.is_empty() and view.fidget_view.instances.is_empty(),"Full projected offscreen retirement")
	game.free()
	print("PASS: both heroes/angles airborne release, fixed world anchor, buoyant rise, full-silhouette offscreen cleanup")
	quit()
