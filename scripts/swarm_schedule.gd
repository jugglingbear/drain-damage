extends RefCounted
## Additive environmental encounters never consume the ordinary roster's admission budget.
const LIMIT := 2
const WARNING := 0.8
const SLOTS := [
	{"id":"opening-east","home":Vector2(920,330),"bounds":Rect2(840,230,200,194),"owner":85},
	{"id":"opening-middle","home":Vector2(1880,330),"bounds":Rect2(1760,230,200,194),"owner":85},
	{"id":"opening-exit","home":Vector2(2890,330),"bounds":Rect2(2760,230,260,194),"owner":85},
	{"id":"service-entry","home":Vector2(3310,330),"bounds":Rect2(3170,230,260,194),"owner":85},
	{"id":"original-service","home":Vector2(4400,330),"bounds":Rect2(4140,230,430,194),"owner":85},
	{"id":"pump-overhead","home":Vector2(5260,190),"bounds":Rect2(5020,130,480,120),"owner":4650},
	{"id":"boss-exit","home":Vector2(7990,330),"bounds":Rect2(7820,230,340,194),"owner":4650},
	{"id":"terminal-west","home":Vector2(8720,330),"bounds":Rect2(8550,230,340,194),"owner":4650},
	{"id":"terminal-east","home":Vector2(9240,330),"bounds":Rect2(9110,230,260,194),"owner":4650},
]
var ledger: Dictionary = {}
var enabled := true

func reset(host: Node2D) -> void:
	ledger.clear()
	for slot in SLOTS:
		ledger[slot.id] = {"state":"pending" if slot.owner >= host.respawn_origin else "excluded",
			"issued":false,"visible":false,"defeated":false}
	# Preserve the original actor's seed, timing and ordinary-budget contribution.
	for actor in host.swarms.actors:
		actor.schedule_id = "original-service"
		ledger["original-service"].state = "issued"
		ledger["original-service"].issued = true

func additional_population(host: Node2D) -> int:
	var count := 0
	for actor in host.swarms.actors:
		if actor.hp > 0 and actor.get("additive",false): count += 1
	return count

func step(host: Node2D) -> void:
	for index in range(host.swarms.actors.size()-1,-1,-1):
		var actor: Dictionary = host.swarms.actors[index]
		var entry: Dictionary = ledger[actor.schedule_id]
		var death_frames: Array = host.swarms.definition.animation.animations.death.frames
		var drawable: bool = actor.hp > 0 or actor.death < death_frames[0].duration_seconds*death_frames.size()
		if drawable and actor.pos.x+64 >= host.camera_x and actor.pos.x-64 <= host.camera_x+960:
			entry.visible = true
		if actor.hp <= 0:
			entry.defeated = true
			entry.state = "defeated"
		if actor.get("additive",false) and actor.pos.x+64 < host.camera_x:
			if actor.hp > 0: entry.state = "retired"
			host.swarms.actors.remove_at(index)
	if not enabled or host.life_state != "alive" or host.paused or host.dispenser.active \
			or host.dialogue.active or host.dialogue.release_guard > 0 or host.won: return
	if host.respawn_origin >= 4650 and host.wave_clock < 1.25: return
	if host.player.x >= host.skitterling.QUIET and not host.skitterling.released: return
	for index in range(SLOTS.size()):
		var slot: Dictionary = SLOTS[index]
		var entry: Dictionary = ledger[slot.id]
		if entry.state != "pending" or slot.id == "original-service": continue
		if slot.home.x >= host.skitterling.END and not host.skitterling.released: continue
		if slot.bounds.end.x+16 < host.camera_x:
			entry.state = "bypassed"
			continue
		if host.player.x < slot.home.x-960: continue
		if additional_population(host) >= LIMIT: return
		# Defer a late/occupied entry; the visible art and buzz lead harmless contact by 0.8 seconds.
		if Rect2(slot.home-Vector2(64,64),Vector2(128,128)).grow(64).intersects(
				Rect2(host.player,host.PLAYER_SIZE)): continue
		var actor: Dictionary = host.swarms.spawn(slot.home,slot.bounds,host.run_seed+71000+index*7919)
		actor.schedule_id = slot.id
		actor.additive = true
		actor.warning = WARNING
		host.swarms.actors.append(actor)
		entry.state = "issued"
		entry.issued = true

func report() -> Dictionary:
	var result := {"potential":SLOTS.size(),"issued":0,"visible":0,"defeated":0,"bypassed":0,"excluded":0}
	for entry in ledger.values():
		for field in ["issued","visible","defeated"]:
			if entry[field]: result[field] += 1
		if entry.state in ["bypassed","excluded"]: result[entry.state] += 1
	return result
