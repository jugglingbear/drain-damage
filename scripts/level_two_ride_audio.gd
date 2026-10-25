extends RefCounted
## A steady current bed and one contact voice reuse the preserved source cues.
var voices: Dictionary = {}
var cues: Dictionary = {}
var frozen := false
var cooldown := 0.0
var starts: Dictionary = {}

func attach(host: Node, definitions: Array) -> void:
	for id in ["current", "contact"]:
		var voice := AudioStreamPlayer.new()
		host.add_child(voice)
		voices[id] = voice
	for cue: Dictionary in definitions:
		var stream: AudioStreamWAV = load("res://"+str(cue.path)).duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if cue.loop else AudioStreamWAV.LOOP_DISABLED
		stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
		cues[cue.event] = {"stream":stream,"gain":float(cue.gain_db)}

func play(event: String) -> void:
	if frozen or AudioServer.is_bus_mute(0) or not cues.has(event): return
	var current := event == "current_loop"
	if not current and cooldown > 0: return
	var voice: AudioStreamPlayer = voices.current if current else voices.contact
	voice.stream = cues[event].stream
	voice.volume_db = cues[event].gain
	voice.play()
	starts[event] = int(starts.get(event,0))+1
	if not current: cooldown = 0.12

func advance(delta: float, paused: bool, active: bool) -> void:
	frozen = paused
	for voice: AudioStreamPlayer in voices.values(): voice.stream_paused = paused
	if AudioServer.is_bus_mute(0) or not active:
		for voice: AudioStreamPlayer in voices.values(): voice.stop()
		return
	if paused: return
	cooldown = maxf(0,cooldown-delta)
	if not voices.current.playing: play("current_loop")

func stop() -> void:
	for voice: AudioStreamPlayer in voices.values():
		voice.stop()
		voice.stream_paused = false
	frozen = false
	cooldown = 0

func dispose() -> void:
	stop()
	for voice: AudioStreamPlayer in voices.values(): voice.stream = null
	cues.clear()
