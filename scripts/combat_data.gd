extends RefCounted
## Runtime access to a validated bundle generated from canonical per-entity JSON.

const PATH := "res://data/combat.json"
const SUPPORTED_WEAPONS := ["pressure-gun", "heavy-plunger-launcher"]
static var bundle: Dictionary = {}

static func load_data() -> bool:
	if not bundle.is_empty():
		return true
	var parser := JSON.new()
	var error := parser.parse(FileAccess.get_file_as_string(PATH))
	if error != OK or not parser.data is Dictionary:
		push_error("Combat data missing or invalid. Run make combat-data: " + parser.get_error_message())
		return false
	var data: Dictionary = parser.data
	if data.get("schema_version") != 1 or not data.get("weapons") is Dictionary or not data.get("monsters") is Dictionary:
		push_error("Combat data schema is invalid. Run make combat-data.")
		return false
	bundle = data
	return true

static func weapon(id: String, owner: String, require_supported := true) -> Dictionary:
	if not load_data(): return {}
	if not bundle.weapons.has(id):
		push_error("Unknown weapon ID: " + id)
		return {}
	var value: Dictionary = bundle.weapons[id]
	if value.owner != owner or value.exclusive != true:
		push_error("Weapon ownership violation: " + id + " cannot be equipped by " + owner)
		return {}
	if require_supported and id not in SUPPORTED_WEAPONS:
		push_error("Weapon mechanics not implemented: " + id)
		return {}
	return value

static func monster(id: String) -> Dictionary:
	if not load_data(): return {}
	if not bundle.monsters.has(id):
		push_error("Unknown monster ID: " + id)
		return {}
	return bundle.monsters[id]

static func damage_state(hp: float, maximum: float) -> String:
	if maximum <= 0 or not is_finite(maximum) or not is_finite(hp):
		push_error("Damage state requires finite HP and positive maximum HP")
		return ""
	if not load_data(): return ""
	var fraction := clampf(hp / maximum, 0, 1)
	for state: Dictionary in bundle.visual_policy.states:
		if state.has("equals"):
			if fraction == state.equals: return state.id
		elif fraction > state.min_exclusive and fraction <= state.max_inclusive:
			return state.id
	push_error("Uncovered health fraction")
	return ""

static func spawn(id: String, position: Vector2) -> Dictionary:
	var definition := monster(id)
	if definition.is_empty(): return {}
	if definition.damage_art == null:
		push_error("Monster is metadata/HUD only, not spawnable: " + id)
		return {}
	return {"id": id, "pos": position, "home": position.x, "direction": -1.0, "aggro": false,
		"hp": float(definition.health.spawn_hp), "max_hp": float(definition.health.max_hp),
		"phase": 0.0, "flash": 0.0, "death_time": 0.0}
