extends SceneTree

func _initialize() -> void:
	var profile = load("res://scripts/wastewater_profile.gd").new()
	var source = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat.json"))
	profile.configure(source.wastewater.progression)
	var previous: Dictionary = profile.sample(0)
	for x in range(1,15201):
		var value: Dictionary = profile.sample(x)
		assert(value.water <= previous.water and value.flow <= previous.flow and value.coverage >= previous.coverage)
		if x >= 14150: assert(value.water == 0 and value.flow == 0 and value.coverage == 1)
		previous = value
	for x in [500,2400,4650,7400,9600,12000,13800,14500]:
		var before: Dictionary = profile.sample(x)
		profile.sample(15200)
		assert(profile.sample(x) == before)
	assert(profile.sample(6000,true) == profile.sample(1440,true))
	assert(profile.sample(6000,true).water > 0.5)
	print("PASS: wastewater spatial monotonicity, full clog, backtracking and isolated trial profile")
	quit()
