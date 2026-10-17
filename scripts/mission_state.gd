extends RefCounted
## Finite encounter accounting, independent of art, collision, and spawn placement.
var zone_counts: Array[int] = []
var spawned: Array[int] = []
var defeated: Array[int] = []
var alive: Dictionary = {}
var maximum_active := 4
var current_zone := 0
var next_id := 0

func configure(counts: Array[int], cap: int = 4) -> void:
	assert(cap > 0 and not counts.is_empty())
	zone_counts = counts.duplicate()
	for count in zone_counts:
		assert(count > 0)
	maximum_active = cap
	reset()

func reset() -> void:
	spawned.clear()
	defeated.clear()
	for count in zone_counts:
		spawned.append(0)
		defeated.append(0)
	alive.clear()
	current_zone = 0
	next_id = 0

func can_spawn() -> bool:
	return current_zone < zone_counts.size() and alive.size() < maximum_active \
		and spawned[current_zone] < zone_counts[current_zone]

func register_spawn() -> int:
	# Call only after runtime has found a offscreen, clear, safe entrance.
	if not can_spawn():
		return -1
	var id := next_id
	next_id += 1
	alive[id] = current_zone
	spawned[current_zone] += 1
	return id

func register_defeat(id: int) -> bool:
	if not alive.has(id):
		return false
	var zone: int = alive[id]
	alive.erase(id)
	defeated[zone] += 1
	if defeated[current_zone] == zone_counts[current_zone]:
		current_zone += 1
	return true

func completed() -> bool:
	return not zone_counts.is_empty() and current_zone == zone_counts.size() and alive.is_empty()

func remaining() -> int:
	var count := 0
	for zone in range(zone_counts.size()):
		count += zone_counts[zone] - defeated[zone]
	return count
