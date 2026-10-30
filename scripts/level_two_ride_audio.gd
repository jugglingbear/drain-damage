extends RefCounted
## Bounded ride voices keep fatal falls separate from current, contacts and mechanisms.
var voices: Dictionary = {}
var cues: Dictionary = {}
var frozen := false
var cooldown := 0.0
var starts: Dictionary = {}

func attach(host: Node, definitions: Array) -> void:
	for id in ["current", "contact", "mechanism", "fatal", "fracture", "fidget"]:
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
	var channel := "fidget" if event == "board_fart" else "fracture" if event == "track_smash" else "fatal" if event == "fall_panic" else "current" if event == "current_loop" else "mechanism" if event == "hinge_move" else "contact"
	if channel == "contact" and cooldown > 0: return
	if channel == "mechanism" and voices[channel].playing: return
	var voice: AudioStreamPlayer = voices[channel]
	voice.stream = cues[event].stream
	voice.volume_db = cues[event].gain
	voice.play()
	starts[event] = int(starts.get(event,0))+1
	if channel == "contact": cooldown = 0.12

func advance(delta: float, paused: bool, active: bool, falling := false) -> void:
	frozen = paused
	for voice: AudioStreamPlayer in voices.values(): voice.stream_paused = paused
	if AudioServer.is_bus_mute(0) or (not active and not falling):
		for voice: AudioStreamPlayer in voices.values(): voice.stop()
		return
	if falling:
		for channel in ["current","contact","mechanism","fracture","fidget"]: voices[channel].stop()
		return
	voices.fatal.stop()
	if paused: return
	cooldown = maxf(0,cooldown-delta)
	if not voices.current.playing: play("current_loop")

func stop_mechanism() -> void:
	voices.mechanism.stop()
	voices.mechanism.stream_paused = false

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
