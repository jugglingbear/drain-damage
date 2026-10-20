extends RefCounted
## Authored continuation; Engineering integrates collision, admission and checkpoint ownership.
const WORLD_WIDTH := 15200.0
const CHECKPOINT := 13800.0
const ARENA_ORIGIN := 14150.0
const ARENA_END := 15110.0
const ENTRY_COMMIT := 14230.0
const QUIET := 13710.0
const CONTAINMENT := 13650.0
const COMPLETION_X := 15150.0
const OWNER_ORIGIN := 4650.0
const WAVE := 4
const SOLIDS: Array[Rect2] = [
	Rect2(9740,380,160,60),
	Rect2(9900,320,180,120),
	Rect2(10080,380,160,60),
	Rect2(11180,380,160,60),
	Rect2(11340,320,180,120),
	Rect2(11520,380,160,60),
	Rect2(12540,380,160,60),
	Rect2(12700,320,180,120),
	Rect2(12880,380,160,60),
]
const LEDGES: Array[Rect2] = [
	Rect2(10520,320,240,16),
	Rect2(11940,320,240,16),
]
const SWARMS := [
	{"id":"clog-feed-west","home":Vector2(10880,330),
		"bounds":Rect2(10770,230,300,194),"owner":4650},
	{"id":"clog-feed-middle","home":Vector2(12280,330),
		"bounds":Rect2(12190,230,300,194),"owner":4650},
	{"id":"clog-feed-east","home":Vector2(13380,330),
		"bounds":Rect2(13250,230,300,194),"owner":4650},
]
const SCENERY := [
	{"id":"return-service","span":Vector2(7650,9570)},
	{"id":"pump-gallery","span":Vector2(9570,11490)},
	{"id":"collector-feed","span":Vector2(11490,13410)},
	{"id":"checkpoint-approach","span":Vector2(13410,14150)},
	{"id":"clogfather-chamber","span":Vector2(14150,15200)},
]
const SLOTS := [
	[9500,"runner",10150,1,true,""],
	[9690,"floor_emerger",10340,1,true,""],
	[9880,"runner",10530,1,true,""],
	[10070,"perched_shooter",10720,1,false,"continuation-ledge-1"],
	[10260,"runner",10910,1,true,""],
	[10450,"aggressive_flyer",11100,1,false,""],
	[10640,"runner",11290,1,true,""],
	[10830,"rear_runner",11480,-1,false,""],
	[11020,"runner",11670,1,true,""],
	[11210,"floor_emerger",11860,1,true,""],
	[11400,"perched_shooter",12050,1,false,"continuation-ledge-2"],
	[11590,"runner",12240,1,true,""],
	[11780,"aggressive_flyer",12430,1,false,""],
	[11970,"runner",12620,1,true,""],
	[12160,"floor_emerger",12810,1,false,""],
	[12350,"runner",13000,1,true,""],
	[12540,"perched_shooter",13190,1,false,"continuation-solid-12700"],
	[12730,"runner",13380,1,true,""],
	[12920,"rear_runner",13570,-1,false,""],
	[13110,"runner",13650,1,true,""],
]
const EXTRA_INDICES := [0,4,8,12,16]

static func append_plan(run_plan: Dictionary) -> void:
	## Append once without consuming RNG or changing any preexisting event or counter.
	var mode: String = run_plan.difficulty
	assert(mode in ["easy","normal","hard"])
	var existing: Dictionary = {}
	for event: Dictionary in run_plan.later: existing[event.id] = true
	for index in range(SLOTS.size()):
		var slot: Array = SLOTS[index]
		if mode == "easy" and not slot[4]: continue
		var event := {
			"id":"clog-approach-%02d" % (index+1),"trigger":float(slot[0]),
			"role":slot[1],"end":float(slot[2]),"side":float(slot[3]),
			"owner_origin":OWNER_ORIGIN,"wave":WAVE,"enabled":true,
			"spacing":1.1 if mode == "easy" else 0.8 if mode == "normal" else 0.65,
		}
		if not str(slot[5]).is_empty(): event.preferred_support_id = slot[5]
		if not existing.has(event.id): run_plan.later.append(event)
		if mode != "easy" and index in EXTRA_INDICES:
			var extra: Dictionary = event.duplicate(true)
			extra.id += "-extra"
			extra.trigger += 60.0
			extra.role = "runner"
			extra.side = 1.0
			extra.erase("preferred_support_id")
			if not existing.has(extra.id): run_plan.later.append(extra)
