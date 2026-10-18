extends RefCounted
## Source and exported games share the same implemented-target registry and initialization.
const REGISTRY_PATH := "res://data/playtest-targets.json"

static func registry() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(REGISTRY_PATH))

static func parse(arguments: PackedStringArray) -> Dictionary:
	var values := {}
	var listing := false
	var verify := false
	for argument in arguments:
		if argument in ["--agent-test","--verify-combat-data"]: continue
		if argument == "--list-playtest-targets":
			listing = true
			continue
		if argument == "--verify-playtest-launch":
			verify = true
			continue
		var parts := argument.trim_prefix("--").split("=",true,1)
		if not argument.begins_with("--") or parts.size() != 2 \
				or parts[0] not in ["level","miniboss","boss","hero","difficulty","seed"]:
			return {"error":"Unknown playtest argument: "+argument}
		if values.has(parts[0]) or parts[1].is_empty(): return {"error":"Duplicate or empty option: "+parts[0]}
		values[parts[0]] = parts[1]
	var selectors: Array = []
	for kind in ["level","miniboss","boss"]:
		if values.has(kind): selectors.append(kind)
	if listing:
		return {"error":"Target listing cannot be combined with launch options."} if not values.is_empty() \
			or verify else {"list":true}
	if selectors.is_empty():
		return {"error":"Choose exactly one level, miniboss or boss selector."} if not values.is_empty() \
			or verify else {}
	if selectors.size() != 1: return {"error":"Choose exactly one level, miniboss or boss selector."}
	var data := registry()
	var target: Dictionary = {}
	for candidate in data.targets:
		if candidate.kind == selectors[0] and candidate.id == values[selectors[0]]: target = candidate
	if target.is_empty():
		return {"error":"Unknown or unimplemented "+selectors[0]+": "+values[selectors[0]]+". Use --list-playtest-targets."}
	var hero: String = values.get("hero","tony")
	var difficulty: String = values.get("difficulty","normal")
	if hero not in data.heroes: return {"error":"Unknown hero: "+hero+". Choose tony or sean."}
	if difficulty not in data.difficulties: return {"error":"Unknown difficulty: "+difficulty}
	var seed_text: String = values.get("seed","42")
	if not seed_text.is_valid_int() or int(seed_text) < 0 or int(seed_text) > 2147483647:
		return {"error":"Seed must be an integer from0 through2147483647."}
	return {"target":target,"hero":hero,"difficulty":difficulty,"seed":int(seed_text),"verify":verify}

static func listing() -> String:
	var lines: PackedStringArray = ["Implemented playtest targets:"]
	for target in registry().targets:
		lines.append("  --%s=%s  %s" % [target.kind,target.id,target.name])
	lines.append("No full boss target is implemented. HERO=tony|sean; DIFFICULTY=easy|normal|hard; SEED=0..2147483647.")
	return "\n".join(lines)

static func initialize(game: Node2D, target: Dictionary) -> void:
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.dispenser.just_finished = false
	if target.initializer == "skitterling-approach":
		# Rebuild checkpoint ownership before placing the hero at the real walk-in approach.
		game.checkpoint_active = true
		game.checkpoint_index = 0
		game.respawn_point = Vector2(4650,394)
		game.respawn_origin = 4650
		game.reset_observation()
		game.player = Vector2(6410,394)
		game.camera_x = game.skitterling.camera_position(game.player.x)
		game.route_progress = game.player.x
		game.grounded = true
		game.velocity = Vector2.ZERO
		game.wave_clock = 2
		game.skitterling.clear_prior(game)
		# The shortcut has passed the pump pocket; it must not appear behind the player.
		game.swarm_schedule.ledger["pump-overhead"].state = "bypassed"
	game.dialogue.release_guard = 0
	game.invulnerable = 1.0

static func summary(game: Node2D, options: Dictionary) -> Dictionary:
	return {"target":options.target.id,"kind":options.target.kind,"hero":game.employee.id,
		"difficulty":game.difficulty,"seed":game.run_seed,"player":[game.player.x,game.player.y],
		"checkpoint":game.checkpoint_index,"respawn_origin":game.respawn_origin,
		"boss_state":game.skitterling.encounter.state,"boss_hp":game.skitterling.encounter.hp,
		"weapon":game.weapon.id,"health":game.health,"lives":game.lives,
		"dialogue":game.dialogue.active,"dispenser":game.dispenser.active}
