extends RefCounted
## Dedicated looping ride score; menu music mute leaves hazard voices audible.
var voice: AudioStreamPlayer
var gain_db := -8.0
var starts := 0

func attach(host: Node, definition: Dictionary) -> void:
	voice = AudioStreamPlayer.new()
	host.add_child(voice)
	var stream: AudioStreamOggVorbis = load("res://"+str(definition.path)).duplicate()
	stream.loop = true
	voice.stream = stream
	gain_db = float(definition.gain_db)
	voice.volume_db = gain_db

func advance(time: float, paused: bool, active: bool, muted: bool) -> void:
	if not active or AudioServer.is_bus_mute(0):
		stop()
		return
	voice.volume_db = -80.0 if muted else gain_db
	voice.stream_paused = paused
	if paused: return
	if not voice.playing:
		voice.play(fposmod(time,voice.stream.get_length()))
		starts += 1

func stop() -> void:
	if voice == null: return
	voice.stop()
	voice.stream_paused = false

func dispose() -> void:
	stop()
	if voice != null: voice.stream = null
