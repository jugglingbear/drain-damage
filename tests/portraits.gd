extends SceneTree
const Portraits = preload("res://scripts/portrait_library.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	assert(Portraits.manifest.emotions.size() == 10)
	assert(not Portraits.has_emotion("unmapped"))
	for character in Portraits.manifest.characters:
		var atlas: Texture2D = Portraits.TEXTURES[character.id]
		assert(atlas.resource_path == "res://" + character.asset)
		assert(atlas.get_width() == character.dimensions.width)
		assert(atlas.get_height() == character.dimensions.height)
		var covered := 0.0
		var rectangles: Array[Rect2] = []
		for emotion in Portraits.manifest.emotions:
			var texture := Portraits.expression(character.id, emotion.name)
			assert(texture.filter_clip)
			var region := texture.region
			assert(Rect2(Vector2.ZERO, atlas.get_size()).encloses(region))
			for previous in rectangles: assert(not previous.intersects(region))
			rectangles.append(region)
			covered += region.get_area()
		assert(covered == atlas.get_width() * atlas.get_height(), "All 10 cells cover the atlas exactly")
	for character in ["tony","sean"]:
		var atlas: Texture2D = Portraits.HARD_TEXTURES[character]
		assert(atlas.get_size() == Vector2(1983,793))
		var covered := 0.0
		var rectangles: Array[Rect2] = []
		for emotion in Portraits.manifest.emotions:
			var standard := Portraits.expression(character,emotion.name)
			var hard := Portraits.expression(character,emotion.name,true)
			assert(hard.atlas == atlas and hard.atlas != standard.atlas)
			assert(hard.region == standard.region and hard.filter_clip)
			for previous in rectangles: assert(not previous.intersects(hard.region))
			rectangles.append(hard.region)
			covered += hard.region.get_area()
		assert(covered == atlas.get_width()*atlas.get_height())
	for emotion in Portraits.manifest.emotions:
		assert(Portraits.expression("BJ",emotion.name,true).atlas == Portraits.BJ)
	for mode in ["hard","easy","normal"]:
		var campaign = load("res://scripts/integrated_first_call.gd").new()
		campaign.difficulty = mode
		root.add_child(campaign)
		campaign.set_process(false)
		campaign.set_physics_process(false)
		for employee in campaign.Crew.EMPLOYEES:
			campaign.employee = employee
			campaign.reset_game()
			assert(campaign.dialogue.hard_portraits == (mode == "hard"))
			campaign.dialogue.start(campaign.Story.OPENING)
			for entry in campaign.dialogue.lines:
				var portrait := Portraits.expression(entry.who,entry.emotion,campaign.dialogue.hard_portraits)
				var id: String = entry.who.to_lower()
				assert(portrait.atlas == (Portraits.HARD_TEXTURES[id] if mode == "hard" and id != "bj" else Portraits.TEXTURES[id]))
			campaign.lives = 2
			campaign.respawn_after_death()
			assert(campaign.dialogue.hard_portraits == (mode == "hard"))
		campaign.queue_free()
		await process_frame
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	for employee in load("res://scripts/crew.gd").EMPLOYEES:
		game.employee = employee
		game.reset_game()
		game.complete_job()
		assert(game.dialogue.lines.size() == 9)
		assert(game.dialogue.lines[0].who == employee.id)
		assert(game.dialogue.lines[1].radio and game.dialogue.lines[1].who != employee.id)
		for entry in game.dialogue.lines:
			assert(entry.has("emotion") and not entry.has("face"))
			assert(Portraits.expression(entry.who, entry.emotion) != null)
	game.queue_free()
	await create_timer(0.3).timeout
	print("PASS:30standard+20Hard portraits,exact cells,mode isolation,BJ unchanged,both heroes and respawn")
	quit()
