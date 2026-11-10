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
			model.fidget.emit_super(model)
			var special: Dictionary = model.fidget.effects[0]
			for age in [.15,4.0,7.5]:
				var delta: float = age-float(special.age)
				model.clock += delta
				model.position.y = 330+age*5
				model.fidget.step(model,false,delta)
				view.update_world()
				assert(model.fidget.effects.has(special),"Sustained cloud cannot scroll away")
				var giant: MeshInstance3D = view.fidget_view.instances[special.id]
				assert(giant.get_child_count() == 2,"Three overlapping brown lobes")
				assert(giant.material_override.get_shader_parameter("opacity") >= .84,"Dense full-duration hold")
				var bounds: Rect2 = view.fidget_view.super_bounds
				var size: Vector2 = giant.mesh.size
				var bottom: Vector2 = view.camera.unproject_position(giant.to_global(
					Vector3((bounds.end.x-.5)*size.x,.5-bounds.end.y,0)))
				var top_lobe: MeshInstance3D = giant.get_child(1)
				var top: Vector2 = view.camera.unproject_position(top_lobe.to_global(
					Vector3(0,.5-bounds.position.y,0)))
				var floor_point: Vector2 = view.camera.unproject_position(view.world(model.position-Vector2(45,0),0))
				assert(absf(bottom.y-floor_point.y) < .1,"Cloud touches water")
				assert(absf(top.y) < .1,"Cloud reaches gameplay ceiling at either yaw")
				assert(bottom.x < floor_point.x,"Leading edge remains behind rider")
	game.free()
	print("PASS: both heroes/angles airborne release, fixed world anchor, buoyant rise, full-silhouette offscreen cleanup")
	quit()
