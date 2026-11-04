extends SceneTree

class RecordedHUD extends "res://scripts/vitals_hud.gd":
	var rendered: Array[Dictionary] = []
	var last_origin := Vector2.ZERO
	var last_theme := ""
	func draw(game: Node2D, origin: Vector2, theme := "dispenser") -> void:
		last_origin = origin
		last_theme = theme
		rendered = commands(game,origin,theme)

class RecordedGame extends "res://scripts/integrated_first_call.gd":
	var label_count := 0
	func label_at(_text: String, _position: Vector2, _size: int, _color: Color) -> void:
		label_count += 1

var failures: Array[String] = []
var checks_run := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func verify(game: Node2D, origin: Vector2, theme: String) -> void:
	game.label_count = 0
	game.draw_vitals(origin,theme)
	var hud = game.vitals_hud
	check(game.label_count == 0,"Shared vitals draws no text labels")
	check(hud.last_origin == origin and hud.last_theme == theme,"Shared dispatcher preserves placement and theme")
	var bounds := Rect2(origin,Vector2(160,56))
	var counts := {"housing":0,"health":0,"portrait":0,"socket":0}
	var filled := 0
	var marker_index := 0
	var portraits: Array[Dictionary] = []
	var sockets: Array[Dictionary] = []
	var art: Dictionary = hud.components(theme)
	var hero_art = game.world_art.hero_aim_art
	var icon: Dictionary = hero_art.animations.heroes[game.employee.id].head_icon
	for item: Dictionary in hud.rendered:
		check(counts.has(item.kind),"Only visual indicator command kinds are emitted")
		if not counts.has(item.kind): continue
		counts[item.kind] += 1
		check(item.rect.has_area() and bounds.encloses(item.rect),"Every vitals component fits 160 by 56")
		check(item.texture is Texture2D and item.texture.get_width() > 0 and item.texture.get_height() > 0,
			"Every command references a loaded texture")
		match item.kind:
			"housing": check(item.texture == art.housing,"Selected theme supplies housing")
			"health":
				check(item.filled == (marker_index < game.health),"Filled markers follow current health in order")
				check(item.texture == (art.health_active if item.filled else art.health_depleted),"Health texture matches state")
				if item.filled: filled += 1
				marker_index += 1
			"portrait":
				portraits.append(item)
				check(item.hero == game.employee.id,"Every life uses selected hero")
				check(item.texture == hero_art.textures[icon.path],"Portrait uses current costume renderer texture")
				var source: Array = icon.source_rect
				check(item.source == Rect2(source[0],source[1],source[2],source[3]),"Portrait source matches hero registration")
				check(Rect2(Vector2.ZERO,item.texture.get_size()).encloses(item.source),"Portrait crop stays within texture")
			"socket":
				sockets.append(item)
				check(item.texture == art.portrait_socket,"Selected theme supplies portrait socket")
	check(counts.housing == 1,"Exactly one housing")
	check(counts.health == game.employee.max_health and filled == game.health,"Hero maximum and current HP are visible")
	check(counts.portrait == game.lives and counts.socket == game.lives,"One portrait and socket per remaining life")
	for index in range(mini(portraits.size(),sockets.size())):
		check(portraits[index].rect.get_center().distance_to(sockets[index].rect.get_center()) < 0.01,
			"Life portrait and socket share a center")

func verify_duck_alignment(game: Node2D) -> void:
	var origin := Vector2(550,4)
	var heights: Array[float] = []
	var bottoms: Array[float] = []
	for hp in [game.employee.max_health,0]:
		game.health = hp
		for item: Dictionary in game.vitals_hud.commands(game,origin,"rubber-ducks"):
			if item.kind != "health": continue
			var pixels: Image = item.texture.get_image()
			var top := pixels.get_height()
			var bottom := -1
			# Measure visible pixels, not transparent canvas edges, so floating ducks fail.
			for y in range(pixels.get_height()):
				for x in range(pixels.get_width()):
					if pixels.get_pixel(x,y).a >= 0.5:
						top = mini(top,y)
						bottom = maxi(bottom,y)
			check(bottom >= top,"Both duck states have visible artwork")
			var scale_y: float = item.rect.size.y/pixels.get_height()
			var visible_bottom: float = item.rect.position.y+(bottom+1)*scale_y-origin.y
			check(absf(visible_bottom-24.0) <= 1.0,"Opaque duck feet meet the shelf baseline within one pixel")
			heights.append((bottom+1-top)*scale_y)
			bottoms.append(visible_bottom)
	var count: int = game.employee.max_health
	for index in range(count):
		check(heights[index+count] >= 10.0,"Depleted duck retains a readable body height")
		check(absf(bottoms[index+count]-bottoms[index]) <= 0.5,"Intact and collapsed feet share their baseline")

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
			game.vitals_hud = RecordedHUD.new()
			game.world_art.hero_aim_art.configure(mode)
			var origins := [Vector2(630,8),Vector2(550,4),Vector2(625,4)]
			for hp in range(game.employee.max_health+1):
				for lives in range(4):
					game.health = hp
					game.lives = lives
					for origin in origins:
						for theme in ["dispenser","chain","rubber-ducks"]: verify(game,origin,theme)
			verify_duck_alignment(game)
			game.label_count = 0
			game.draw_vitals()
			check(game.vitals_hud.last_origin == Vector2(630,8) and game.vitals_hud.last_theme == "dispenser",
				"Default gameplay placement and dispenser theme")
			check(game.label_count == 0,"Default vitals call contains no labels")
			game.reset_game()
			game.begin_level_two()
			verify(game,Vector2(550,4),"chain")
			game.health -= 1
			game.flush.enter_landing(game)
			verify(game,Vector2(550,4),"chain")
			game.flush.enter_ride(game)
			verify(game,Vector2(550,4),"rubber-ducks")
			game.health = 1
			game.invulnerable = 0
			game.hurt_player()
			check(game.health == 0 and game.lives == 2,"Real death decrements HP and exactly one life")
			verify(game,Vector2(550,4),"rubber-ducks")
			game.respawn_after_death()
			check(game.health == game.employee.max_health and game.lives == 2,"Retry restores health while preserving lost life")
			verify(game,Vector2(550,4),"rubber-ducks")
			game.reset_game()
			check(game.lives == 3,"Fresh run restores three lives")
			verify(game,Vector2(630,8),"dispenser")
			root.remove_child(game)
			game.free()
	print("Gameplay vitals: %d checks, %d failures" % [checks_run,failures.size()])
	quit(0 if failures.is_empty() else 1)
