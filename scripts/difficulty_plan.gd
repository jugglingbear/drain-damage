extends RefCounted
## Resolve encounter choices once per run; retries reuse this data rather than rerolling.
const IDS := ["easy", "normal", "hard"]
const OPENING_TRIGGERS := [100.0,250.0,450.0,600.0,800.0,1000.0,1200.0,1400.0,1650.0,1900.0,2200.0,2450.0]
const OPENING_ROLES := ["runner","runner","runner","rear_runner","perched_shooter","runner",
	"floor_emerger","runner","aggressive_flyer","aggressive_flyer","runner","runner"]
const WAVE_RANGES := [Vector2(3500,4800),Vector2(4900,6480),Vector2(6860,8160),Vector2(8400,9380)]
const CHECKPOINT := 4650.0
const LATER_TRIGGERS := [
	[3500,3660,3820,3980,4140,4300,4460,4700],
	[4900,5060,5220,5380,5540,5700,5860,6020,6180,6340],
	[6860,6990,7120,7250,7380,7510,7640,7770,7900,8030],
	[8400,8520,8640,8760,8880,9000,9120,9240]]

const NORMAL_SLOTS := [
	[3250,"perched_shooter",3850],
	[3450,"runner",4050],
	[3650,"floor_emerger",4250],
	[3850,"runner",4450],
	[4050,"aggressive_flyer",4650],
	[4250,"runner",4850],
	[4450,"runner",5050],
	[4700,"runner",4800],
	[4900,"runner",5500],
	[5100,"aggressive_flyer",5700],
	[5300,"perched_shooter",5900],
	[5500,"runner",6100],
	[5700,"runner",6300],
	[5900,"floor_emerger",6500],
	[6100,"runner",6700],
	[6300,"runner",6900],
	[6500,"aggressive_flyer",7100],
	[6700,"aggressive_flyer",7300],
	[6900,"perched_shooter",7500],
	[7100,"runner",7700],
	[7300,"runner",7900],
	[7500,"runner",8100],
	[7700,"runner",8300],
	[7900,"floor_emerger",8500],
	[8100,"runner",8700],
	[8300,"runner",8900],
	[8500,"aggressive_flyer",9100],
	[8700,"aggressive_flyer",9300],
	[8900,"runner",9380],
	[9100,"runner",9380]]

static func resolve(mode: String, seed_value: int) -> Dictionary:
	assert(mode in IDS)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var roles := OPENING_ROLES.duplicate()
	# Keep the first introduction of each species fixed; variants come after those encounters.
	if mode == "normal":
		if rng.randi_range(0,1) == 1: roles[7] = "floor_emerger"
		if rng.randi_range(0,1) == 1: roles[11] = "rear_runner"
	if mode == "hard":
		roles[5] = "perched_shooter"
		roles[7] = "floor_emerger"
	var opening: Array[Dictionary] = []
	for index in range(12):
		var jitter := rng.randf_range(-35,35) if mode != "easy" and index > 0 else 0.0
		opening.append({"id":"opening-%02d" % (index+1),"role":roles[index],
			"trigger":OPENING_TRIGGERS[index]+jitter,"owner_origin":85.0,
			"enabled":mode != "easy" or index not in [1,3,7,9]})
	var counts: Array = [5,6,6,5] if mode == "easy" else [8,10,10,8]
	var later: Array[Dictionary] = []
	for wave in range(4):
		for index in range(LATER_TRIGGERS[wave].size()):
			var bounds: Vector2 = WAVE_RANGES[wave]
			var trigger: float = LATER_TRIGGERS[wave][index]
			# Partition the straddling wave by authored trigger, never by a moving enemy's position.
			var owner := CHECKPOINT if trigger >= CHECKPOINT else 85.0
			if mode != "easy" and index > 0 and not (wave == 0 and index == 7):
				trigger += rng.randf_range(-30,30)
				trigger = minf(trigger,CHECKPOINT-1) if owner == 85 else maxf(trigger,CHECKPOINT+50)
			var side := 1.0 if mode == "easy" else (-1.0 if rng.randf() < (0.4 if mode == "hard" else 0.25) else 1.0)
			var spacing := 1.2 if mode == "easy" else rng.randf_range(0.8,1.1) if mode == "normal" else rng.randf_range(0.65,0.8)
			later.append({"id":"wave-%d-%02d" % [wave,index],"wave":wave,"trigger":trigger,
				"owner_origin":owner,"side":1.0 if wave == 0 and index == 7 else side,
				"spacing":spacing,"end":bounds.y,"enabled":mode != "easy" or index % 2 == 0 or index == LATER_TRIGGERS[wave].size()-1})
	if mode == "normal":
		later = normal_route(rng)
		counts = [8,8,8,6]
	if mode != "easy":
		add_density_slots(opening,[0,5,10],100.0)
		for event in opening:
			if event.id.ends_with("-extra"): event.role = "runner"
		add_density_slots(later,[0,3,23,24] if mode == "normal" else [1,3,5,8,10,28,32],60.0)
		for event in later:
			if event.id.ends_with("-extra"):
				# A delayed addition can use the remaining safe segment, never spill across the boss room.
				event.end = 4650.0 if event.owner_origin == 85 else 5610.0 if event.trigger < 5610 else 9450.0
	return {"difficulty":mode,"seed":seed_value,"opening":opening,"later":later,"wave_counts":counts,
		"crowd_cap":4 if mode == "easy" else 6 if mode == "normal" else 8,
		"opening_spacing":1.1 if mode == "easy" else 0.8 if mode == "normal" else 0.6}

static func normal_route(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for index in range(NORMAL_SLOTS.size()):
		var slot: Array = NORMAL_SLOTS[index]
		var owner := 85.0 if index < 7 else CHECKPOINT
		var trigger := float(slot[0])
		if index != 7: trigger += rng.randf_range(-30,30)
		events.append({"id":"normal-route-%02d" % (index+1),"role":slot[1],
			"wave":mini(index/8,3),"trigger":trigger,"owner_origin":owner,
			"side":1.0,"spacing":0.8,"end":float(slot[2]),"enabled":true})
	return events

static func add_density_slots(events: Array[Dictionary], indices: Array, offset: float) -> void:
	# Add to the authored baseline once; retain its RNG stream, species and checkpoint ownership.
	var additions: Array[Dictionary] = []
	for index in indices:
		var event: Dictionary = events[index].duplicate(true)
		event.id += "-extra"
		event.trigger += offset
		additions.append(event)
	events.append_array(additions)
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.trigger < b.trigger)
