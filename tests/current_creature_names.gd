extends SceneTree
const Data = preload("res://scripts/combat_data.gd")

func _initialize() -> void:
	var swarm: Dictionary = Data.monster("sewer-fly-swarm")
	assert(swarm.name == "Gnatastrophe")
	assert(swarm.health.max_hp == 24)
	assert(not FileAccess.get_file_as_string("res://data/combat.json").contains("Septic Air Force"))
	print("PASS: exported Gnatastrophe name, stable creature ID and health, no stale generated runtime text")
	quit()
