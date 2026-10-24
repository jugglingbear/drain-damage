extends RefCounted
## Fixed voice pools preserve the selected shot tails without unbounded allocations.
const BASE := "res://assets/audio/sfx/starter-weapons-v1/"
const CUES := {"tony":"tony-water-gush.wav","sean":"sean-suction-pop.wav"}
const LIMITS := {"tony":3,"sean":1}
var pools: Dictionary = {}
var cursors := {"tony":0,"sean":0}
var starts := {"tony":0,"sean":0}
var paused := false

func attach(host: Node) -> void:
	for id: String in CUES:
		var stream: AudioStreamWAV = load(BASE+CUES[id]).duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		pools[id] = []
		for index in range(LIMITS[id]):
			var voice := AudioStreamPlayer.new()
			voice.stream = stream
			voice.volume_db = 0
			host.add_child(voice)
			pools[id].append(voice)

func play_shot(id: String) -> void:
	if paused or not pools.has(id) or AudioServer.is_bus_mute(0): return
	pools[id][cursors[id]].play()
	cursors[id] = (cursors[id]+1) % LIMITS[id]
	starts[id] += 1

func set_paused(value: bool) -> void:
	paused = value
	for pool: Array in pools.values():
		for voice: AudioStreamPlayer in pool: voice.stream_paused = value

func stop() -> void:
	paused = false
	for id: String in pools:
		cursors[id] = 0
		for voice: AudioStreamPlayer in pools[id]:
			voice.stop()
			voice.stream_paused = false

func dispose() -> void:
	stop()
	for pool: Array in pools.values():
		for voice: AudioStreamPlayer in pool: voice.stream = null
