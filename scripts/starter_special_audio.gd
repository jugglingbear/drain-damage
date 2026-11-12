extends RefCounted
## Simulation-clock special playback: one sustain and two reusable transient voices.
const DEFINITION_PATH := "res://data/starter-special-audio.json"
const TRANSIENT_LIMIT := 2
var definition: Dictionary = {}
var streams: Dictionary = {}
var loop_voice: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var active := false
var paused := false
var hero := ""
var elapsed := 0.0
var next_event := 0
var cinematic_entry := false
var onset_tail: AudioStreamPlayer
var onset_tail_gain := 0.0
var cursor := 0
var loop_active := false
var loop_starts := 0
var event_starts: Dictionary = {}

func attach(host: Node) -> void:
	dispose()
	definition = JSON.parse_string(FileAccess.get_file_as_string(DEFINITION_PATH))
	for event: String in definition.cues:
		var cue: Dictionary = definition.cues[event]
		if event == "sean-rain":
			assert(FileAccess.file_exists("res://"+str(cue.path)),"Rain asset missing; do not substitute old jet")
			assert(FileAccess.get_sha256("res://"+str(cue.path)) == str(cue.sha256),"Rain asset hash mismatch")
		var stream: AudioStreamWAV = load("res://"+str(cue.path)).duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if cue.loop else AudioStreamWAV.LOOP_DISABLED
		if cue.loop:
			stream.loop_begin = 0
			stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
		streams[event] = stream
	loop_voice = _voice(host)
	for index in range(TRANSIENT_LIMIT): voices.append(_voice(host))
	loop_starts = 0
	event_starts.clear()

func _voice(host: Node) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.bus = "Master"
	host.add_child(voice)
	return voice

func begin(id: String) -> void:
	# Repeated aim/state updates cannot restart an accepted, still-running action.
	if active or paused or not definition.get("heroes",{}).has(id): return
	if not is_instance_valid(loop_voice): return
	stop()
	hero = id
	active = true
	_dispatch()

func begin_from_cinematic(id: String, cinematic_audio = null) -> void:
	if active or paused or not definition.get("heroes",{}).has(id): return
	if not is_instance_valid(loop_voice): return
	stop()
	hero = id
	active = true
	cinematic_entry = true
	elapsed = 0.0
	var events: Array = definition.heroes[hero].events
	while next_event < events.size() and float(events[next_event].time) <= elapsed:
		next_event += 1
	if hero == "tony": _play("tony-start")
	if cinematic_audio != null:
		if hero == "sean":
			var transferred = cinematic_audio.exchange_geyser_voice(voices[0])
			if transferred != null:
				voices[0] = transferred
				onset_tail = transferred
				onset_tail_gain = transferred.volume_db
		cinematic_audio.stop()
	_dispatch()

func advance(delta: float, is_paused: bool = false) -> void:
	set_paused(is_paused)
	if paused or not active: return
	elapsed += maxf(delta,0.0)
	if elapsed >= float(definition.duration):
		stop()
		return
	_dispatch()
	if is_instance_valid(onset_tail):
		if elapsed >= .1:
			onset_tail.stop()
			onset_tail = null
		else:
			onset_tail.volume_db = onset_tail_gain+linear_to_db(maxf(1-elapsed/.1,.0001))

func _dispatch() -> void:
	var schedule: Dictionary = definition.heroes[hero]
	var events: Array = schedule.events
	while next_event < events.size() and float(events[next_event].time) <= elapsed:
		var event: Dictionary = events[next_event]
		var offset := elapsed-float(event.time)
		# Frame stalls skip expired transients instead of bursting every missed sound at once.
		_play(str(event.cue),offset)
		next_event += 1
	var core: Dictionary = schedule.sustain.duplicate()
	if cinematic_entry:
		core.start = 0.0
		core.fade_in = .1
	var in_core := elapsed >= float(core.start) and elapsed < float(core.end)
	if in_core:
		var cue: Dictionary = definition.cues[core.cue]
		if not loop_active:
			loop_voice.stream = streams[core.cue]
			loop_voice.volume_db = -80.0
			loop_voice.play(fposmod(elapsed-float(core.start),loop_voice.stream.get_length()))
			loop_active = true
			loop_starts += 1
		var gain := minf(1.0,minf((elapsed-float(core.start))/float(core.fade_in),
			(float(core.end)-elapsed)/float(core.fade_out)))
		loop_voice.volume_db = float(cue.gain_db)+linear_to_db(maxf(gain,0.0001))
	elif loop_active:
		loop_voice.stop()
		loop_active = false

func _play(event: String, offset: float = 0.0) -> void:
	if voices.is_empty() or not streams.has(event): return
	var stream: AudioStreamWAV = streams[event]
	if offset >= stream.get_length(): return
	var voice := voices[cursor]
	cursor = (cursor+1) % voices.size()
	voice.stop()
	voice.stream = stream
	voice.volume_db = float(definition.cues[event].gain_db)
	voice.play(offset)
	event_starts[event] = int(event_starts.get(event,0))+1

func empty() -> void:
	# The controller admits one fresh rejected press; holding the button must not call this repeatedly.
	if paused or active or not is_instance_valid(loop_voice): return
	_play("hud-empty")

func set_paused(value: bool) -> void:
	paused = value
	if is_instance_valid(loop_voice): loop_voice.stream_paused = value
	for voice in voices:
		if is_instance_valid(voice): voice.stream_paused = value

func stop() -> void:
	active = false
	hero = ""
	elapsed = 0.0
	next_event = 0
	cinematic_entry = false
	onset_tail = null
	cursor = 0
	loop_active = false
	set_paused(false)
	if is_instance_valid(loop_voice): loop_voice.stop()
	for voice in voices:
		if is_instance_valid(voice): voice.stop()

func dispose() -> void:
	stop()
	if is_instance_valid(loop_voice):
		loop_voice.stream = null
		loop_voice.queue_free()
	loop_voice = null
	for voice in voices:
		if is_instance_valid(voice):
			voice.stream = null
			voice.queue_free()
	voices.clear()
	streams.clear()
	definition.clear()
