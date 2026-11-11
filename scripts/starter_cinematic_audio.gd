extends RefCounted
## Cinematic-clock cues; world simulation is frozen and handoff remains host-owned.
const DEFINITION_PATH := "res://data/starter-cinematic-audio.json"
var definition: Dictionary = {}
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var active := false
var paused := false
var hero := ""
var elapsed := 0.0
var next_event := 0
var cursor := 0
var event_starts: Dictionary = {}

func attach(host: Node) -> void:
	dispose()
	definition = JSON.parse_string(FileAccess.get_file_as_string(DEFINITION_PATH))
	for event in definition.cues:
		var stream: AudioStreamWAV = load("res://"+str(definition.cues[event].path)).duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		streams[event] = stream
	for index in range(2):
		var voice := AudioStreamPlayer.new()
		voice.bus = "Master"
		host.add_child(voice)
		voices.append(voice)
	event_starts.clear()

func begin(id: String) -> void:
	if active or paused or voices.is_empty() or not definition.get("heroes",{}).has(id): return
	stop()
	hero = id
	active = true
	_dispatch()

func advance(delta: float) -> void:
	if not active or paused: return
	elapsed += maxf(delta,0)
	if elapsed >= float(definition.heroes[hero].duration):
		for voice in voices: voice.stop()
		elapsed = float(definition.heroes[hero].duration)
		active = false
		return
	_dispatch()

func seek(seconds: float) -> void:
	# Restore only live gestures at the destination; do not replay elapsed preparation.
	if hero.is_empty(): return
	for voice in voices: voice.stop()
	elapsed = clampf(seconds,0,float(definition.heroes[hero].duration))
	next_event = 0
	cursor = 0
	active = elapsed < float(definition.heroes[hero].duration)
	if active: _dispatch()
	set_paused(paused)

func _dispatch() -> void:
	var events: Array = definition.heroes[hero].events
	while next_event < events.size() and float(events[next_event].time) <= elapsed:
		var event: Dictionary = events[next_event]
		_play(str(event.cue),elapsed-float(event.time))
		next_event += 1

func _play(event: String, offset: float) -> void:
	var stream: AudioStreamWAV = streams[event]
	if offset >= stream.get_length() or AudioServer.is_bus_mute(0): return
	var voice := voices[cursor]
	cursor = (cursor+1) % voices.size()
	voice.stop()
	voice.stream = stream
	voice.volume_db = float(definition.cues[event].gain_db)
	voice.play(offset)
	voice.stream_paused = paused
	event_starts[event] = int(event_starts.get(event,0))+1

func set_paused(value: bool) -> void:
	paused = value
	for voice in voices: voice.stream_paused = value

func stop() -> void:
	for voice in voices:
		voice.stop()
		voice.stream_paused = false
	active = false
	paused = false
	hero = ""
	elapsed = 0
	next_event = 0
	cursor = 0

func dispose() -> void:
	stop()
	for voice in voices:
		voice.stream = null
		voice.queue_free()
	voices.clear()
	streams.clear()
	definition.clear()
