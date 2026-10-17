extends RefCounted
## One voice follows a hero death; it never controls gameplay timing.
const CUE = preload("res://assets/audio/sfx/player-death-flush-v1/toilet-flush.wav")
var voice: AudioStreamPlayer
var starts := 0

func attach(game: Node) -> void:
	voice = AudioStreamPlayer.new()
	voice.stream = CUE.duplicate()
	voice.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	voice.volume_db = -3
	game.add_child(voice)

func play_death() -> void:
	if AudioServer.is_bus_mute(0): return
	voice.stream_paused = false
	voice.play()
	starts += 1

func set_paused(value: bool) -> void:
	voice.stream_paused = value

func stop() -> void:
	voice.stop()
	voice.stream_paused = false

func dispose() -> void:
	stop()
	voice.stream = null
	voice = null
