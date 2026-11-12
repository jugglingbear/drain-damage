extends SceneTree
## Authored-level regression: destruction must never expose a pit below a standable prop.
const Campaign = preload("res://scripts/campaign_encounters.gd")
const HERO_SIZE := Vector2(26, 46)
const GRAVITY := 1250.0
const JUMP_SPEED := -465.0
const RATES := [60, 120]
const SPEEDS := [235, 270]
const EXPECTED_PITS := [Vector2(900, 1020), Vector2(13200, 13320)]
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value and message not in failures:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run_checks")

func top_rect(platforms: RefCounted, id: String) -> Rect2:
	# Use current Art geometry, not cached placement coordinates that could become stale.
	var asset: Dictionary = platforms.assets[platforms.placements[id].family]
	var values: Array = asset.top_support_segments[0]
	return Rect2(platforms.anchor(id) + Vector2(values[0], values[1]), Vector2(values[2] - values[0], 1))

func destroy(platforms: RefCounted, id: String) -> void:
	platforms.damage(id, float(platforms.states[id].hp))

func drop(level: RefCounted, position: Vector2, hz: int, advance_break := false) -> Dictionary:
	var vertical := 0.0
	var result: Dictionary = {}
	for tick in range(hz * 2):
		if advance_break and level.platforms.advance(1.0 / hz): level.refresh_platforms()
		vertical += GRAVITY / hz
		result = level.move_body(position, Vector2(0, vertical), HERO_SIZE, 1.0 / hz)
		position = result.pos
		vertical = result.velocity.y
		if result.falling: return result
	return result

func run_checks() -> void:
	var campaign := Campaign.new()
	campaign.reset("normal", 85, 42)
	var level = campaign.level
	var ids: Array[String] = []
	var intact_material: Dictionary = {}
	var families: Array[String] = []
	for id: String in level.platforms.placements:
		var family: String = level.platforms.placements[id].family
		if not level.platforms.assets[family].destructible: continue
		ids.append(id)
		families.append(family)
		intact_material[id] = level.platforms.colliders(id)
	families.sort()
	check(families == ["cast-iron-boiler", "pressure-tank", "water-heater"], "All three approved families loaded")
	check(level.pits == EXPECTED_PITS, "Both authored pits remain unchanged")
	for id in ids:
		for body: Rect2 in intact_material[id]:
			for pit: Vector2 in level.pits:
				check(body.end.x <= pit.x or body.position.x >= pit.y, "No material above pit: " + id)
			for item: Dictionary in level.platforms.supplemental:
				var values: Array = item.rect
				var support := Rect2(values[0], values[1], values[2], values[3])
				check(not body.grow(-0.001).intersects(support), "No material/support overlap: " + id + "/" + item.id)

	# Exercise every destruction combination against real campaign pits and live collision release.
	for mask in range(1 << ids.size()):
		campaign.reset("normal", 85, 42)
		for index in ids.size():
			if mask & (1 << index): destroy(level.platforms, ids[index])
		level.platforms.advance(2.0)
		level.refresh_platforms()
		for id in ids:
			var top := top_rect(level.platforms, id)
			for hz in RATES:
				for x in [top.position.x, top.get_center().x - HERO_SIZE.x / 2, top.end.x - HERO_SIZE.x]:
					var result := drop(level, Vector2(x, top.position.y - HERO_SIZE.y), hz)
					var label := "%s mask=%s hz=%s x=%s" % [id, mask, hz, x]
					check(not result.falling and result.grounded, "Safe supported landing: " + label)
					if level.platforms.colliders(id).is_empty():
						check(is_equal_approx(result.pos.y + HERO_SIZE.y, level.floor_y),
							"Destroyed prop lands on actual floor: " + label)

	# Destruction starts while occupied, rather than removing collision before the test begins.
	for id in ids:
		for hz in RATES:
			campaign.reset("normal", 85, 42)
			var top := top_rect(level.platforms, id)
			destroy(level.platforms, id)
			var result := drop(level, Vector2(top.get_center().x - HERO_SIZE.x / 2,
				top.position.y - HERO_SIZE.y), hz, true)
			check(not result.falling and result.grounded, "Standing destruction is safe: " + id)
			check(is_equal_approx(result.pos.y + HERO_SIZE.y, level.floor_y), "Standing break reaches floor: " + id)

	campaign.reset("normal", 85, 42)
	check_access_routes(level)
	for id in ids: destroy(level.platforms, id)
	level.platforms.advance(2.0)
	level.refresh_platforms()
	# Cover the entire former material footprint, including overhangs, rather than just the anchor.
	for id in ids:
		for body: Rect2 in intact_material[id]:
			for x in range(floori(body.position.x) - int(HERO_SIZE.x), ceili(body.end.x) + 1, 2):
				var result: Dictionary = level.move_body(Vector2(x, level.floor_y - HERO_SIZE.y),
					Vector2(0, 20), HERO_SIZE, 1.0 / 60)
				check(result.grounded and not result.falling, "Removed footprint has real floor: " + id)
	for pit: Vector2 in level.pits:
		for percent in [0.64, 0.65, 0.66]:
			var result: Dictionary = level.move_body(Vector2(pit.x - HERO_SIZE.x * (1 - percent),
				level.floor_y - HERO_SIZE.y), Vector2(0, 20), HERO_SIZE, 1.0 / 60)
			check(result.falling == (percent >= 0.65), "Authored 65% pit threshold preserved")
	# Negative control: the rejected pressure-tank location must still expose a lethal fall.
	check(drop(level, Vector2(13220 - HERO_SIZE.x / 2, 320 - HERO_SIZE.y), 60).falling,
		"Regression detector catches the rejected over-pit placement")
	print("Destructible placement safety: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

func check_access_routes(level: RefCounted) -> void:
	# Approved access chains are explicit so a future relocation requires reviewing its route too.
	var routes := [
		[Rect2(2600, 440, 61, 1), Rect2(2661, 380, 154, 16), Rect2(2856.27907, 320, 167.44186, 1),
			Rect2(3048, 380, 154, 16), Rect2(3202, 440, 60, 1)],
		[Rect2(4070, 380, 160, 16), Rect2(4230, 320, 200, 16), Rect2(4434.36364, 260, 109.63636, 1),
			Rect2(4546, 320, 50, 16), Rect2(4596, 380, 50, 16), Rect2(4646, 440, 60, 1)]
	]
	for route: Array in routes:
		for index in range(route.size() - 1):
			for direction in [-1, 1]:
				var start: Rect2 = route[index if direction == 1 else index + 1]
				var finish: Rect2 = route[index + 1 if direction == 1 else index]
				# Descending may drop onto safe floor; landing on each optional step is not required.
				if finish.position.y > start.position.y: continue
				for speed in SPEEDS:
					for hz in RATES:
						check(can_transfer(level, start, finish, direction, speed, hz),
							"Access transfer %s > %s speed=%s hz=%s" % [start.position, finish.position, speed, hz])

func can_transfer(level: RefCounted, start: Rect2, finish: Rect2, direction: int, speed: float, hz: int) -> bool:
	# Bounded full jumps with horizontal braking; this is reachability, not visual/input acceptance.
	for offset in range(0, int(start.size.x - HERO_SIZE.x) + 1, 4):
		var position := Vector2(start.position.x + offset, start.position.y - HERO_SIZE.y)
		var velocity := Vector2(direction * speed, JUMP_SPEED)
		for tick in range(hz * 2):
			velocity.y += GRAVITY / hz
			var target_x := finish.end.x - HERO_SIZE.x if direction == 1 else finish.position.x
			velocity.x = clampf((target_x - position.x) * hz, -speed, speed)
			var result: Dictionary = level.move_body(position, velocity, HERO_SIZE, 1.0 / hz)
			position = result.pos
			velocity = result.velocity
			if result.falling: break
			if result.grounded:
				if absf(position.y + HERO_SIZE.y - finish.position.y) < 0.1 \
						and position.x + HERO_SIZE.x > finish.position.x and position.x < finish.end.x:
					return true
				break
	return false
