extends RefCounted
## Gate-owned voices follow movement transitions, never audio completion.

const CUES := [
	preload("res://assets/audio/sfx/sliding-progress-door-v1/latch.wav"),
	preload("res://assets/audio/sfx/sliding-progress-door-v1/motor-slide.wav"),
	preload("res://assets/audio/sfx/sliding-progress-door-v1/end-stop.wav"),
]
var voices: Array = []
var events: Array[String] = []

func attach(game: Node, count: int) -> void:
	for index in range(count):
		var gate: Array[AudioStreamPlayer] = []
		for cue in CUES:
			var voice := AudioStreamPlayer.new()
			voice.stream = cue
			voice.volume_db = -3
			game.add_child(voice)
			gate.append(voice)
		voices.append(gate)

func transition(index: int, before: float, after: float) -> void:
	if before == 0 and after > 0:
		events.append("%d:opening" % index)
		voices[index][0].play()
		voices[index][1].play()
	if before < 1 and after == 1:
		events.append("%d:open" % index)
		voices[index][1].stop()
		voices[index][2].play()

func set_paused(value: bool) -> void:
	for gate in voices:
		for voice in gate: voice.stream_paused = value

func stop() -> void:
	for gate in voices:
		for voice in gate:
			voice.stop()
			voice.stream_paused = false
	events.clear()

func dispose() -> void:
	stop()
	for gate in voices:
		for voice in gate: voice.stream = null
	voices.clear()
