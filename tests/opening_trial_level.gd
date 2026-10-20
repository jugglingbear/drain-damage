extends SceneTree

const Level = preload("res://scripts/opening_trial_level.gd")
const SIZE := Vector2(26, 46)
const DT := 1.0 / 120.0
var level = Level.new()

func _initialize() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/combat.json")).opening_trial.layout
	assert(level.configure(layout))
	assert(level.plinths.size() == 12 and level.decks.size() == 6)
	assert(not level.configure({}) and level.decks.size() == 6, "Bad config must be atomic")
	var walls: Array[Rect2] = level.projectile_solids()
	assert(walls.size() == 12)
	walls.clear()
	assert(level.projectile_solids().size() == 12, "Returned list must not alias geometry")
	for deck: Rect2 in level.decks:
		assert(deck not in level.projectile_solids() and deck in level.actor_solids(), "Deck only blocks bodies")
		assert(not deck.intersects(Rect2(deck.position.x + 30, 370, 2, 2)), "Underpass shot stays clear")
		assert(deck.end.y <= 440 - 72, "Visual underdeck clearance")
		var under: Dictionary = level.move_body(Vector2(deck.position.x, 394), Vector2(235, 0), SIZE, 0.5)
		assert(is_equal_approx(under.pos.x, deck.position.x + 117.5) and under.pos.y == 394)
		var up: Dictionary = level.move_body(Vector2(deck.position.x + 30, 345), Vector2(0, -465), SIZE, 0.2)
		assert(up.pos.y < deck.position.y, "Pass through deck underside")
		var down: Dictionary = level.move_body(Vector2(deck.position.x + 30, 200), Vector2(0, 900), SIZE, 0.3)
		assert(down.grounded and down.pos.y == deck.position.y - SIZE.y, "Swept landing")
	for speed: float in [235.0, 270.0]:
		for index in range(6):
			var access: Rect2 = level.plinths[index * 2]
			var deck: Rect2 = level.decks[index]
			var exit_step: Rect2 = level.plinths[index * 2 + 1]
			jump_to(Vector2(access.position.x - 80, 394), access, speed)
			jump_to(Vector2(access.end.x - 55, access.position.y - SIZE.y), deck, speed)
			jump_to(Vector2(deck.end.x - 55, deck.position.y - SIZE.y), exit_step, speed)
	var side: Dictionary = level.move_body(Vector2(100, 394), Vector2(900, 0), SIZE, 0.4)
	assert(side.pos.x == 154 and side.velocity.x == 0, "Solid side sweep")
	var back: Dictionary = level.move_body(Vector2(350, 394), Vector2(-900, 0), SIZE, 0.4)
	assert(back.pos.x == 330, "Reverse solid side sweep")
	assert(level.visible_deck(0, Vector2(250, 394), Vector2(38, 36)).size() > 0)
	assert(level.visible_deck(0, Vector2(900, 394), Vector2(38, 36)).is_empty())
	assert(level.visible_grate(0, Vector2(600, 394), Vector2(38, 36)).feet.x == 880)
	assert(level.visible_grate(0, Vector2(900, 394), Vector2(38, 36)).is_empty())
	print("PASS: trial geometry, both-hero jumps, one-way decks, underpass, swept solids and spawn candidates")
	quit()

func jump_to(start: Vector2, target: Rect2, speed: float) -> void:
	var pos := start
	var velocity := Vector2(0, -465)
	for frame in range(180):
		velocity.x = move_toward(velocity.x, speed, 1900 * DT)
		velocity.y += 1250 * DT
		var result: Dictionary = level.move_body(pos, velocity, SIZE, DT)
		pos = result.pos
		velocity = result.velocity
		if result.grounded:
			assert(is_equal_approx(pos.y + SIZE.y, target.position.y), "Jump landed at wrong height")
			assert(pos.x + SIZE.x > target.position.x and pos.x < target.end.x, "Jump missed target")
			return
	assert(false, "Jump did not land")
