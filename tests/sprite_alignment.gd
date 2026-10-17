extends SceneTree

func _initialize() -> void:
	var art = load("res://scripts/world_art.gd").new()
	var idle: Rect2 = art.sean_frames[0]
	assert(art.SEAN_HEIGHT == 72.0)
	for frame in [1, 2, 3, 4]:
		var height: float = art.sean_frames[frame].size.y * art.SEAN_HEIGHT / idle.size.y
		assert(absf(height - art.SEAN_HEIGHT) < 2, "Run poses must not change Sean's height abruptly")
	var jump: Rect2 = art.sean_frames[5]
	assert(jump.end.y < 1040, "Jump crop must exclude the neighboring firing pose's boot")
	assert(jump.size.y < idle.size.y, "Tucked jumping pose should be shorter than standing pose")
	assert(art.sean_frames[6].position.x < 626, "Firing pose must preserve its left boot")
	print("PASS: larger Sean, stable running height, isolated jump pose, complete firing pose")
	quit()
