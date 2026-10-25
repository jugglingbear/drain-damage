extends RefCounted
## Four bounded voices separate current, flush, impacts and radio; no paused or muted backlog.
var voices: Dictionary = {}
var cues: Dictionary = {}
var starts: Dictionary = {}
var frozen := false
var clock := 0.0
var debris_after := 0.0
var radio_after := 0.0
var duck := 0.0

func attach(host: Node, definitions: Array) -> void:
	for id in ["current","flush","debris","radio"]:
		var voice := AudioStreamPlayer.new()
		host.add_child(voice)
		voices[id] = voice
	for cue: Dictionary in definitions:
		var stream: AudioStreamWAV = load("res://"+str(cue.path)).duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if cue.loop else AudioStreamWAV.LOOP_DISABLED
		stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
		cues[cue.event] = {"stream":stream,"gain":float(cue.gain_db)}

func channel(event: String) -> String:
	if event == "current_loop": return "current"
	if event == "radio_chirp": return "radio"
	if event.begins_with("debris_"): return "debris"
	return "flush"

func play(event: String) -> void:
	if frozen or not cues.has(event) or AudioServer.is_bus_mute(0): return
	var id := channel(event)
	if id == "debris":
		if clock < debris_after: return
		debris_after = clock+0.12
	if id == "radio":
		if clock < radio_after: return
		radio_after = clock+0.5
	var voice: AudioStreamPlayer = voices[id]
	voice.stream = cues[event].stream
	voice.volume_db = cues[event].gain+(duck if id in ["current","flush"] else 0.0)
	voice.play()
	starts[event] = int(starts.get(event,0))+1

func advance(delta: float, paused: bool, active: bool, radio: bool) -> void:
	frozen = paused
	for voice: AudioStreamPlayer in voices.values(): voice.stream_paused = paused
	if paused: return
	clock += delta
	duck = move_toward(duck,-8.0 if radio else 0.0,40.0*delta)
	if AudioServer.is_bus_mute(0):
		for voice: AudioStreamPlayer in voices.values(): voice.stop()
		return
	var current: AudioStreamPlayer = voices.current
	if active and not current.playing: play("current_loop")
	if not active: current.stop()
	for id in ["current","flush"]:
		var voice: AudioStreamPlayer = voices[id]
		for cue: Dictionary in cues.values():
			if voice.stream == cue.stream: voice.volume_db = cue.gain+duck

func stop() -> void:
	for voice: AudioStreamPlayer in voices.values():
		voice.stop()
		voice.stream_paused = false
	frozen = false
	clock = 0
	debris_after = 0
	radio_after = 0
	duck = 0

func dispose() -> void:
	stop()
	for voice: AudioStreamPlayer in voices.values(): voice.stream = null
	cues.clear()
