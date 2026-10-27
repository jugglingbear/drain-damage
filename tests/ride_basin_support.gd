extends SceneTree
const Physics = preload("res://tests/ride_showcase_physics.gd")
const Model = preload("res://scripts/ride_showcase_model.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var count := 0
	for hero in ["sean","tony"]:
		for index in [6,7]:
			var model = Model.new()
			var host = Physics.Host.new()
			root.add_child(host)
			host.employee.id = hero
			model.begin(host,index)
			var decks: Array = model.course.obstacles.filter(func(o: Dictionary) -> bool: return o.kind == "deck")
			for deck: Dictionary in decks:
				for offset in [-37.0,-36.0,0.0,36.0,37.0]:
					var bank: float = float(deck.y)+offset
					if bank < 260 or bank > 400: continue
					for landing in [false,true]:
						model.begin(host,index)
						host.life_state = "alive"
						host.health = 5
						host.lives = 3
						model.position = Vector2(300,bank)
						model.encounter_scroll = float(deck.x)-300
						if landing: model.jump_age = model.active_jump_duration-0.0005
						model.tick(host,.001,Vector2.ZERO,false)
						var supported: bool = absf(offset)+Model.HALF.y <= float(deck.depth)*0.5
						assert((host.life_state == "alive") == supported,
							"Support boundary must match full board footprint for grounded AND landing riders")
						count += 1
			host.free()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/ride-showcase-v1/manifest.json"))
	for id in ["basin_deck_360","basin_deck_390"]:
		var layers: Array = manifest.frames[id].layers
		assert(layers[1].tint == "737a80" and not layers[2].has("tint"))
		assert(layers[1].destination[1] == 50 and layers[2].destination[3] == 100)
	var ride_art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/level-two-ride-v1/manifest.json"))
	assert(ride_art.frames.shadow.destination == [-45.0,-14.0,90.0,28.0])
	print("PASS: ",count," island support/landing boundary cases, unchanged top, recessed face and contact footprint")
	quit()
