extends RefCounted
## Four dedicated voices preserve warnings and terminal death under rapid combat events.
const Data = preload("res://scripts/combat_data.gd")
const BASE := "res://assets/audio/sfx/clogfather-v1/"
const CUES := {
	"volley_warning": ["pressure-warning"], "acid_warning": ["acid-warning"],
	"projectile_spawn": ["sludge-fire-a", "sludge-fire-b"],
	"projectile_hit": ["sludge-impact-a", "sludge-impact-b"],
	"acid_impact": ["sludge-impact-a", "sludge-impact-b"],
	"idle_optional": ["groan-b"], "major_stagger": ["groan-a"],
	"weak_point_open": ["weak-point-open"], "closed_shell_hit": ["armored-hit"],
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
			var stream: AudioStreamWAV = load(BASE+name+".wav").duplicate()
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
			streams[event].append(stream)
			gains[event].append(-12.0 if event == "idle_optional" else -5.0)
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
	for value in events:
		var event := str(value)
		if event == "attack_start":
			voices[0].stop()
			continue
		if event in ["projectile_spawn", "acid_impact", "weak_point_open", "weak_point_closing"]:
			voices[0].stop()
		if not streams.has(event) or AudioServer.is_bus_mute(0): continue
		var slot := 3
		var interval := 0.0
		var key := event
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
	var index: int = int(cursors.get(event, 0)) % streams[event].size()
	voices[slot].stream = streams[event][index]
	voices[slot].volume_db = gains[event][index]
	voices[slot].play()
	cursors[event] = index+1
	starts[event] = int(starts.get(event, 0))+1

func tick(delta: float) -> void:
	if not paused: clock += maxf(delta, 0)

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

func dispose() -> void:
	stop()
	for voice in voices:
		voice.stream = null
		voice.queue_free()
	voices.clear()
	streams.clear()
	gains.clear()
