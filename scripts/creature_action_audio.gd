extends RefCounted
## Fixed action pools; actor tokens isolate cancellation and quiet movement is globally bounded.
const SPEC_PATH := "res://data/creature-action-audio.json"
const MOVEMENT_LIMIT := 2
static var movement_voices: Array[WeakRef] = []
var specs: Dictionary = {}
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var owners: Array[int] = []
var events: Array[String] = []
var channels: Array[String] = []
var cooldowns: Dictionary = {}
var starts: Dictionary = {}
var paused := false

func attach(host: Node, creature_id: String) -> void:
	assert(voices.is_empty())
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPEC_PATH))
	specs = data.creatures.get(creature_id, {})
	if specs.is_empty(): return
	for event in specs:
		var stream: AudioStreamWAV = load("res://"+str(specs[event].path)).duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		streams[event] = stream
	for index in range(4):
		var voice := AudioStreamPlayer.new()
		host.add_child(voice)
		voices.append(voice)
		owners.append(-1)
		events.append("")
		channels.append("")

func movement_count() -> int:
	var live: Array[WeakRef] = []
	for reference in movement_voices:
		var voice = reference.get_ref()
		if is_instance_valid(voice) and voice.playing:
			live.append(reference)
	movement_voices = live
	return live.size()

func forget_movement(voice: AudioStreamPlayer) -> void:
	for index in range(movement_voices.size()-1, -1, -1):
		if movement_voices[index].get_ref() == voice:
			movement_voices.remove_at(index)

func stop_slot(index: int) -> void:
	forget_movement(voices[index])
	voices[index].stop()
	owners[index] = -1
	events[index] = ""
	channels[index] = ""

func play(event: String, token: int, clock: float) -> void:
	if paused or voices.is_empty() or not specs.has(event) or AudioServer.is_bus_mute(0): return
	var spec: Dictionary = specs[event]
	var key := str(token)+"/"+event
	if clock < float(cooldowns.get(key, -INF)): return
	var channel: String = spec.channel
	if channel == "movement":
		if movement_count() >= MOVEMENT_LIMIT: return
		for index in range(voices.size()):
			if owners[index] == token and voices[index].playing and channels[index] != "movement": return
	# Warning admissions replace that actor's previous tell and motion, never another actor's death/hit.
	if channel == "warning":
		for index in range(voices.size()):
			if owners[index] == token: stop_slot(index)
	if channel == "effect":
		for index in range(2):
			if owners[index] == token: stop_slot(index)
	var first := 0 if channel == "warning" else 2
	var slot := -1
	for index in range(first, first+2):
		if channel == "movement" and voices[index].playing and channels[index] == "effect": continue
		if owners[index] == token or not voices[index].playing:
			slot = index
			break
	if slot < 0:
		if channel == "movement": return
		slot = first
	stop_slot(slot)
	voices[slot].stream = streams[event]
	voices[slot].volume_db = float(spec.gain_db)
	owners[slot] = token
	events[slot] = event
	channels[slot] = channel
	voices[slot].play()
	if channel == "movement": movement_voices.append(weakref(voices[slot]))
	cooldowns[key] = clock+float(spec.cooldown_seconds)
	starts[event] = int(starts.get(event, 0))+1

func stop_actor(token: int) -> void:
	for index in range(voices.size()):
		if owners[index] == token: stop_slot(index)
	# A new admission after cancellation is a fresh tell, even if the old cooldown remains.
	for key in cooldowns.keys():
		if str(key).begins_with(str(token)+"/"): cooldowns.erase(key)

func set_paused(value: bool) -> void:
	paused = value
	for voice in voices: voice.stream_paused = value

func stop() -> void:
	for index in range(voices.size()):
		stop_slot(index)
		voices[index].stream_paused = false
	paused = false
	cooldowns.clear()

func dispose() -> void:
	stop()
	for voice in voices:
		voice.stream = null
		voice.queue_free()
	voices.clear()
	owners.clear()
	events.clear()
	channels.clear()
	streams.clear()
