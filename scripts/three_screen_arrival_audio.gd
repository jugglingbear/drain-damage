extends RefCounted
## Screen-space warning voices; the caller admits and deduplicates depth arrivals.
const CUE = preload("res://assets/audio/sfx/level-two-flush-v1/radio-chirp.wav")
const VOICE_COUNT := 2
var layer: CanvasLayer
var voices: Array[AudioStreamPlayer2D] = []
var paused := false
var next_voice := 0
var starts := 0

func attach(host: Node) -> void:
	dispose()
	# A separate canvas keeps panning independent of the world camera and hero position.
	layer = CanvasLayer.new()
	host.add_child(layer)
	for index in range(VOICE_COUNT):
		var voice := AudioStreamPlayer2D.new()
		var stream: AudioStreamWAV = CUE.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		voice.stream = stream
		voice.bus = "Master"
		voice.volume_db = -4.0
		voice.max_distance = 2000.0
		voice.attenuation = 0.0
		voice.panning_strength = 1.0
		layer.add_child(voice)
		voices.append(voice)
	starts = 0

func warn(screen_x: float) -> void:
	if paused or voices.is_empty() or not is_instance_valid(layer): return
	if AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")): return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stop()
	voice.position = Vector2(clampf(screen_x,0.0,960.0),270.0)
	voice.play()
	starts += 1

func set_paused(value: bool) -> void:
	paused = value
	for voice in voices:
		if is_instance_valid(voice): voice.stream_paused = value

func stop() -> void:
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream_paused = false
	paused = false
	next_voice = 0

func dispose() -> void:
	stop()
	for voice in voices:
		if is_instance_valid(voice): voice.stream = null
	voices.clear()
	if is_instance_valid(layer): layer.queue_free()
	layer = null
