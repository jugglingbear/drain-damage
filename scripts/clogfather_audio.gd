extends RefCounted
## Four dedicated voices preserve warnings and terminal death under rapid combat events.
const Data = preload("res://scripts/combat_data.gd")
const BASE := "res://assets/audio/sfx/clogfather-v1/"
const ROAR_BASE := "res://assets/audio/sfx/clogfather-festering-v3/"
const ROAR_INTERVALS := [10.0, 12.0, 14.0, 11.0]
const CUES := {
	"volley_warning": ["pressure-warning"], "acid_warning": ["acid-warning"],
	"gas_warning": ["pressure-warning"], "gas_started": ["sludge-fire-b"],
	"reinforcements_warning": ["groan-b"],
	"projectile_spawn": ["sludge-fire-a", "sludge-fire-b"],
	"projectile_hit": ["sludge-impact-a", "sludge-impact-b"],
	"acid_impact": ["sludge-impact-a", "sludge-impact-b"],
	"gas_destroyed": ["sludge-impact-a", "sludge-impact-b"],
	"gas_damaged": ["sludge-impact-a", "sludge-impact-b"],
	"idle_optional": ["groan-b"], "major_stagger": ["groan-a"],
	"weak_point_open": ["weak-point-open"], "closed_shell_hit": ["armored-hit"],
	"ambient_roar": ["ambient-roar"], "reactive_roar": ["reactive-roar"],
}
var voices: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var gains: Dictionary = {}
var cursors: Dictionary = {}
var starts: Dictionary = {}
var cooldowns: Dictionary = {}
var clock := 0.0
var paused := false
var defeated := false
var hit_cooldown := .25
var presence_active := false
var warning_blocked := false
var effect_is_roar := false
var next_roar := 10.0
var roar_cursor := 0

func attach(host: Node) -> void:
	assert(voices.is_empty())
	for index in range(4):
		var voice := AudioStreamPlayer.new()
		host.add_child(voice)
		voices.append(voice)
	for event in CUES:
		streams[event] = []
		gains[event] = []
		for name in CUES[event]:
			var base := ROAR_BASE if event in ["ambient_roar", "reactive_roar"] else BASE
			var stream: AudioStreamWAV = load(base+name+".wav").duplicate()
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
			streams[event].append(stream)
			var gain := -12.0 if event == "idle_optional" else -5.0
			if event == "ambient_roar": gain = -8.0
			if event == "reactive_roar": gain = -6.0
			gains[event].append(gain)
	var definition: Dictionary = Data.monster("clogfather").audio
	hit_cooldown = float(definition.hit.cooldown_seconds)
	for pair in [["damage_accepted", "hit"], ["death_started", "death"]]:
		streams[pair[0]] = []
		gains[pair[0]] = []
		for variant in definition[pair[1]].variants:
			var stream: AudioStreamWAV = load("res://"+str(variant.path)).duplicate()
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
			streams[pair[0]].append(stream)
			gains[pair[0]].append(float(variant.gain_db))

func handle_events(events: Array) -> void:
	if paused or defeated or voices.is_empty(): return
	# A lethal batch wins over nonlethal events from the same simulation step.
	if "death_started" in events:
		stop()
		defeated = true
		_play("death_started", 1)
		return
	var batch_warning := false
	for value in events:
		if str(value).ends_with("warning"): batch_warning = true
	for value in events:
		var event := str(value)
		if event == "phase_changed": event = "reactive_roar"
		if event == "attack_start":
			voices[0].stop()
			continue
		if event in ["projectile_spawn", "acid_impact", "weak_point_open", "weak_point_closing",
			"gas_started", "reinforcements_spawn"]:
			voices[0].stop()
		if not streams.has(event) or AudioServer.is_bus_mute(0): continue
		var slot := 3
		var interval := 0.0
		var key := event
		if event in ["gas_destroyed", "gas_damaged"]:
			if effect_is_roar and voices[3].playing: continue
			interval = .12
			key = "gas_impact"
		if event in ["ambient_roar", "reactive_roar"]:
			if not presence_active or warning_blocked or batch_warning or voices[0].playing: continue
			if voices[3].playing: continue
			interval = 8.0
			key = "roar"
		if event.ends_with("warning"):
			slot = 0
			voices[3].stop()
		elif event == "damage_accepted":
			slot = 2
			interval = hit_cooldown
		elif event in ["projectile_hit", "acid_impact", "closed_shell_hit"]:
			interval = .08
			key = "impact"
		elif event in ["idle_optional", "major_stagger"]:
			if voices[0].playing: continue
			interval = 6.0
			key = "groan"
		if clock < float(cooldowns.get(key, -INF)): continue
		cooldowns[key] = clock+interval
		_play(event, slot)

func _play(event: String, slot: int) -> void:
	if AudioServer.is_bus_mute(0): return
	if slot == 3: effect_is_roar = event in ["ambient_roar", "reactive_roar"]
	var index: int = int(cursors.get(event, 0)) % streams[event].size()
	voices[slot].stream = streams[event][index]
	voices[slot].volume_db = gains[event][index]
	voices[slot].play()
	cursors[event] = index+1
	starts[event] = int(starts.get(event, 0))+1

func tick(delta: float) -> void:
	if paused: return
	clock += maxf(delta, 0)
	if presence_active and not defeated and clock >= next_roar:
		# No backlog: a suppressed or muted roar is skipped, not replayed on unmute.
		handle_events(["ambient_roar"])
		next_roar = clock+ROAR_INTERVALS[roar_cursor % ROAR_INTERVALS.size()]
		roar_cursor += 1

func set_presence(active: bool, warning := false) -> void:
	presence_active = active and not defeated
	warning_blocked = warning
	if not presence_active: next_roar = clock+ROAR_INTERVALS[0]
	if (not presence_active or warning) and effect_is_roar and not voices.is_empty():
		voices[3].stop()
		effect_is_roar = false

func set_paused(value: bool) -> void:
	paused = value
	for voice in voices: voice.stream_paused = value

func stop() -> void:
	for voice in voices:
		voice.stop()
		voice.stream_paused = false
	clock = 0
	paused = false
	defeated = false
	cooldowns.clear()
	cursors.clear()
	presence_active = false
	warning_blocked = false
	effect_is_roar = false
	next_roar = ROAR_INTERVALS[0]
	roar_cursor = 0

func dispose() -> void:
	stop()
	for voice in voices:
		voice.stream = null
		voice.queue_free()
	voices.clear()
	streams.clear()
	gains.clear()
