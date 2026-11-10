extends SceneTree
const Trial = preload("res://scripts/three_screen_trial_game.gd")

func _initialize() -> void:
	var game := Trial.new()
	game.run_seed = 42
	var actor := {"event_id":"opening-single"}
	var seen := {}
	var sequence: Array[int] = []
	for index in range(120):
		var count := game.next_volley_size(actor)
		assert(count >= 1 and count <= 3)
		seen[count] = true
		sequence.append(count)
	assert(seen.size() == 3,"All three volley sizes must occur")
	var retry := {"event_id":"opening-single"}
	for expected in sequence: assert(game.next_volley_size(retry) == expected)
	game.free()
	print("PASS: 1/2/3 shot volleys, all outcomes, deterministic retry sequence")
	quit()
