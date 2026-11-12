extends SceneTree
class Probe extends "res://scripts/starter_specials.gd":
	func water_segments(_host: Node2D) -> Array[Dictionary]: return []
class Audio extends RefCounted:
	func advance(_delta: float) -> void: pass
	func stop() -> void: pass
class Art extends RefCounted:
	func spent_variant(_state: Dictionary, _solids: Array[Rect2]) -> String: return "normal"
class Host extends Node2D:
	var special_art := Art.new()
	func special_solids() -> Array[Rect2]: return []
	var life_state := "alive"
	var paused := false
	var special_audio := Audio.new()
	func specials_allowed(_active := false) -> bool: return not paused
const PipeArt = preload("res://scripts/starter_special_art.gd")
func check_geometry() -> void:
	var art := PipeArt.new()
	art.spent = JSON.parse_string(FileAccess.get_file_as_string(art.SPENT))
	for facing in [-1,1]:
		var state := {"anchor":Vector2(500,300),"angle":facing*PI*.5}
		var floor_only: Array[Rect2] = [Rect2(400,300,200,20)]
		assert(art.spent_variant(state,floor_only) == "normal")
		var walls: Array[Rect2] = [Rect2(0,220,468,80),Rect2(532,220,300,80),Rect2(468,300,64,20)]
		assert(art.spent_variant(state,walls) == "compact")
		for frame: Dictionary in art.spent.variants.compact.frames:
			var b: Array = frame.assembly_bounds_ltrb
			assert(b[0] >= -32 and b[2] <= 32)
			assert(absf(b[3]) < .001)
	for variant in ["normal","compact"]:
		assert(art.spent_pose(0,variant).index == -1)
		assert(art.spent_pose(.089,variant).index == -1)
		assert(art.spent_pose(.09,variant).index == 0)
		assert(art.spent_pose(.75,variant).index == 5)
		assert(art.spent_pose(100,variant).index == 5)
		var last := -1
		for tick in range(91):
			var pose := art.spent_pose(tick/120.0,variant)
			assert(pose.index >= last)
			last = pose.index

func _initialize() -> void:
	check_geometry()
	var host := Host.new()
	var probe := Probe.new()
	probe.hero_id = "sean"
	probe.active = true
	probe.elapsed = 7.4
	probe.tick_serial = 74
	probe.step(host,.2)
	assert(not probe.active and probe.spent_pipes.size() == 1)
	assert(is_equal_approx(probe.spent_pipes[0].spent_age,.1))
	probe.step(host,.2)
	assert(is_equal_approx(probe.spent_pipes[0].spent_age,.3))
	host.paused = true
	probe.step(host,1)
	assert(is_equal_approx(probe.spent_pipes[0].spent_age,.3))
	host.paused = false
	probe.step(host,-1)
	assert(is_equal_approx(probe.spent_pipes[0].spent_age,.3))
	host.life_state = "dying"
	probe.step(host,.1)
	assert(probe.spent_pipes.is_empty())
	host.free()
	print("Spent pipe collapse lifecycle and geometry: PASS")
	quit()
