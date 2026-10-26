extends SceneTree

class HeadRecorder extends "res://scripts/hero_aim_art.gd":
	var shown := 0
	var hero := ""
	var position := Vector2.ZERO
	func draw_lives(game: Node2D, origin: Vector2) -> void:
		shown = game.lives
		hero = game.employee.id
		position = origin
		var icon: Dictionary = animations.heroes[hero].head_icon
		assert(textures.has(icon.path), "Selected hero head must be loaded")

class RecordedGame extends "res://scripts/integrated_first_call.gd":
	var markers: Array[Dictionary] = []
	func box(x: float, y: float, width: float, height: float, color: Color) -> void:
		markers.append({"rect":Rect2(x,y,width,height),"color":color})
	func label_at(_text: String, _position: Vector2, _size: int, _color: Color) -> void:
		pass

func _initialize() -> void:
	call_deferred("checks")

func verify(game: Node2D, origin: Vector2, bounds: Rect2) -> void:
	game.markers.clear()
	game.draw_vitals(origin)
	assert(game.markers.size() == game.employee.max_health)
	var filled := 0
	for marker: Dictionary in game.markers:
		assert(bounds.encloses(marker.rect))
		if marker.color == Color("ef9270"): filled += 1
	assert(filled == game.health)
	var heads = game.world_art.hero_aim_art
	assert(heads.shown == game.lives and heads.hero == game.employee.id)
	assert(bounds.encloses(Rect2(heads.position,Vector2(maxi(0,heads.shown-1)*28+24,24))))

func checks() -> void:
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game := RecordedGame.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			game.seed_override = 42
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.world_art.hero_aim_art = HeadRecorder.new()
			game.world_art.hero_aim_art.configure(mode == "hard")
			# Level 1 and both boss encounters retain this identical shared header.
			for hp in range(game.employee.max_health+1):
				for lives in range(4):
					game.health = hp
					game.lives = lives
					verify(game,Vector2(630,17),Rect2(630,0,170,82))
			game.reset_game()
			game.begin_level_two()
			verify(game,Vector2(550,10),Rect2(550,0,240,64))
			game.health -= 1
			game.flush.enter_landing(game)
			verify(game,Vector2(550,10),Rect2(550,0,240,64))
			game.flush.enter_ride(game)
			verify(game,Vector2(550,10),Rect2(550,0,240,64))
			game.health = 1
			game.invulnerable = 0
			game.hurt_player()
			assert(game.health == 0 and game.lives == 2)
			verify(game,Vector2(550,10),Rect2(550,0,240,64))
			game.respawn_after_death()
			assert(game.health == game.employee.max_health and game.lives == 2)
			verify(game,Vector2(550,10),Rect2(550,0,240,64))
			game.reset_game()
			assert(game.lives == 3)
			verify(game,Vector2(550,10),Rect2(550,0,240,64))
			game.queue_free()
			await process_frame
	print("PASS: shared HUD marker counts, selected hero heads, bounds, both heroes/all modes, transition, death and retry")
	quit()
