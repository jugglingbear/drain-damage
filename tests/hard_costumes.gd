extends SceneTree
const Prepared = preload("res://scripts/hard_costume_art.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var original_bundle := JSON.stringify(game.Data.bundle.dispenser.art)
	for mode in ["hard", "normal", "hard", "easy"]:
		game.difficulty = mode
		for employee in game.Crew.EMPLOYEES:
			game.employee = employee
			game.reset_game()
			var art = game.world_art.hero_aim_art
			assert(art.hard_mode == (mode == "hard") and game.dispenser.hard_mode == art.hard_mode)
			for phase in art.animations.heroes[employee.id].phases.values():
				for frame in phase.frames:
					assert(str(frame.path).begins_with(Prepared.PREFIX) == art.hard_mode)
			for frame in art.animations.heroes[employee.id].death:
				assert(str(frame.path).begins_with(Prepared.PREFIX) == art.hard_mode)
			assert(str(art.animations.heroes[employee.id].head_icon.path).begins_with(Prepared.PREFIX) == art.hard_mode)
			for pose in art.poses.values():
				for layer in pose.layers:
					assert(art.textures[layer.path] != null)
					if not str(layer.path).begins_with("assets/weapons/"):
						assert(str(layer.path).begins_with(Prepared.PREFIX) == art.hard_mode)
			for state in game.dispenser.art.heroes[employee.id].states.values():
				assert(str(state.path).begins_with(Prepared.PREFIX) == art.hard_mode)
			for frame in game.dispenser.art.sleeping_heroes.heroes[employee.id]:
				assert(str(frame.path).begins_with(Prepared.PREFIX) == art.hard_mode)
			game.lives = 2
			game.respawn_after_death()
			assert(art.hard_mode == (mode == "hard") and game.dispenser.hard_mode == art.hard_mode)
	assert(JSON.stringify(game.Data.bundle.dispenser.art) == original_bundle)
	assert(Prepared.textures.size() == 12)
	for path in Prepared.textures:
		var texture: Texture2D = Prepared.textures[path]
		assert(Prepared.texture(path) == texture, "Preparation must be cached")
		var bytes := texture.get_image().get_data()
		var opaque := 0
		var clear := 0
		for index in range(3, bytes.size(), 4):
			assert(bytes[index] in [0, 255], "Prepared alpha is binary")
			if bytes[index] == 255: opaque += 1
			else: clear += 1
		assert(opaque > 0 and clear > 0)
	game.queue_free()
	await process_frame
	print("PASS: 12 cached prepared sheets, both heroes, all costume paths, respawn and mode isolation")
	quit()
