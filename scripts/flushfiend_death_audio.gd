extends RefCounted
## A bounded pool permits overlapping defeats without accumulating audio nodes.

const CUE = preload("res://assets/audio/sfx/flushfiend-shatter-v1/porcelain-break.wav")
const MAX_VOICES := 4
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var starts := 0
var paused := false

func attach(game: Node) -> void:
	for index in range(MAX_VOICES):
		var voice := AudioStreamPlayer.new()
		voice.stream = CUE.duplicate()
		voice.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		voice.volume_db = -3
		game.add_child(voice)
		voices.append(voice)

func play_defeat() -> void:
	if paused or voices.is_empty() or AudioServer.is_bus_mute(0): return
	voices[cursor].play()
	cursor = (cursor + 1) % MAX_VOICES
	starts += 1

func set_paused(value: bool) -> void:
	paused = value
	for voice in voices: voice.stream_paused = value

func stop() -> void:
	for voice in voices:
		voice.stop()
		voice.stream_paused = false
	paused = false
	cursor = 0

func dispose() -> void:
	stop()
	for voice in voices: voice.stream = null
	voices.clear()
