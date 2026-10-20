extends SceneTree
const Encounter = preload("res://scripts/skitterling_encounter.gd")
const HERO := Rect2(96, 394, 26, 46)

func _initialize() -> void:
	for hz in [30, 60, 120]:
		var boss := Encounter.new()
		boss.configure(42)
		boss.start(HERO)
		boss.phase = "alligator"
		boss.position = Vector2(300, Encounter.FLOOR_Y)
		boss._enter("alligator_charge_tell")
		boss.step(.9, HERO)
		assert(boss.state == "alligator_charge")
		assert(boss.alligator_ground_distance == 0)
		var distance := 0.0
		for tick in range(hz):
			var before: Vector2 = boss.position
			boss.step(1.0 / hz, HERO)
			distance += absf(boss.position.x - before.x)
			assert(is_equal_approx(boss.alligator_ground_distance, distance))
		assert(is_equal_approx(distance, Encounter.CHARGE_SPEED))
		var frozen: Dictionary = boss.snapshot()
		boss.step(2, HERO, true)
		assert(boss.snapshot().alligator_ground_distance == frozen.alligator_ground_distance)
		assert(boss.position == frozen.position and boss.elapsed == frozen.elapsed)
		while boss.state == "alligator_charge": boss.step(1.0 / hz, HERO)
		assert(boss.state == "alligator_charge_turn")
		var stopped: float = boss.alligator_ground_distance
		boss.step(.4, HERO)
		assert(boss.alligator_ground_distance == stopped, "Turn warning must not advance planted feet")
		boss.reset()
		assert(boss.alligator_ground_distance == 0)
	print("PASS: alligator gait distance follows actual travel at30/60/120Hz, freezes at rest/pause and resets")
	quit()
