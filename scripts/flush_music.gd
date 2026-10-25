extends RefCounted
## One non-looping score follows the active flush clock, including muted skips and checkpoint retries.
var voice: AudioStreamPlayer
var gain_db := -8.0
var duck := 0.0
var starts := 0
var seek_time := 0.0

func attach(host: Node, definition: Dictionary) -> void:
	voice = AudioStreamPlayer.new()
	host.add_child(voice)
	var stream: AudioStreamOggVorbis = load("res://"+str(definition.path)).duplicate()
	stream.loop = false
	voice.stream = stream
	gain_db = float(definition.gain_db)
	voice.volume_db = gain_db

func advance(time: float, delta: float, paused: bool, active: bool, radio: bool, panic: bool) -> void:
	if not active or time >= 45.0 or AudioServer.is_bus_mute(0):
		voice.stop()
		return
	voice.stream_paused = paused
	if paused: return
	duck = move_toward(duck,minf(-8.0 if radio else 0.0,-6.0 if panic else 0.0),40.0*delta)
	voice.volume_db = gain_db+duck
	if not voice.playing:
		seek_time = maxf(0,time)
		voice.play(seek_time)
		starts += 1
	elif absf(voice.get_playback_position()-time) > 0.15:
		# Muting or a held input guard must never restart or desynchronize the countdown.
		seek_time = maxf(0,time)
		voice.seek(seek_time)

func stop() -> void:
	if voice == null: return
	voice.stop()
	voice.stream_paused = false
	duck = 0
	seek_time = 0
	voice.volume_db = gain_db

func dispose() -> void:
	stop()
	if voice != null: voice.stream = null
