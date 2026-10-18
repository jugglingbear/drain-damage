extends RefCounted
## Canonical creature cues use separate bounded pools and never consume gameplay RNG.
const Data = preload("res://scripts/combat_data.gd")
static var next_token := 0
var creature_id: String
var definition: Dictionary
var streams: Dictionary = {}
var hit_voices: Array[AudioStreamPlayer] = []
var death_voices: Array[AudioStreamPlayer] = []
var cooldowns: Dictionary = {}
var hit_cursor := 0
var death_cursor := 0
var hit_starts := 0
var death_starts := 0
var variant_cursor := 0
var paused := false
# Preserve existing death-controller inspection points for callers and regression checks.
var voices: Array[AudioStreamPlayer]:
	get: return death_voices
var starts: int:
	get: return death_starts

func _init(id: String) -> void:
	creature_id = id

func attach(game: Node) -> void:
	definition = Data.monster(creature_id).audio
	for event in ["hit", "death"]:
		var spec: Dictionary = definition[event]
		var loaded: Array[AudioStreamWAV] = []
		for variant in spec.variants:
			var stream: AudioStreamWAV = load("res://" + str(variant.path)).duplicate()
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
			loaded.append(stream)
		streams[event] = loaded
		var pool: Array[AudioStreamPlayer] = hit_voices if event == "hit" else death_voices
		for index in range(int(spec.max_voices)):
			var voice := AudioStreamPlayer.new()
			voice.stream = loaded[index % loaded.size()]
			voice.volume_db = spec.variants[index % loaded.size()].gain_db
			game.add_child(voice)
			pool.append(voice)

func allowed() -> bool:
	return not paused and not hit_voices.is_empty() and not AudioServer.is_bus_mute(0)

func play_hit(actor: Dictionary, clock := -1.0) -> void:
	if actor.hp <= 0 or not allowed(): return
	if not actor.has("audio_token"):
		next_token += 1
		actor.audio_token = next_token
	var now := clock if clock >= 0 else float(actor.get("age", 0))
	if now < float(cooldowns.get(actor.audio_token, -INF)): return
	cooldowns[actor.audio_token] = now + float(definition.hit.cooldown_seconds)
	var index: int = variant_cursor % streams.hit.size()
	var voice := hit_voices[hit_cursor]
	voice.stream = streams.hit[index]
	voice.volume_db = definition.hit.variants[index].gain_db
	voice.play()
	hit_cursor = (hit_cursor + 1) % hit_voices.size()
	variant_cursor += 1
	hit_starts += 1

func play_defeat() -> void:
	if not allowed(): return
	var index: int = death_starts % streams.death.size()
	var voice := death_voices[death_cursor]
	voice.stream = streams.death[index]
	voice.volume_db = definition.death.variants[index].gain_db
	voice.play()
	death_cursor = (death_cursor + 1) % death_voices.size()
	death_starts += 1

func set_paused(value: bool) -> void:
	paused = value
	for voice in hit_voices + death_voices: voice.stream_paused = value

func stop() -> void:
	for voice in hit_voices + death_voices:
		voice.stop()
		voice.stream_paused = false
	paused = false
	cooldowns.clear()
	hit_cursor = 0
	death_cursor = 0
	variant_cursor = 0

func dispose() -> void:
	stop()
	for voice in hit_voices + death_voices: voice.stream = null
	hit_voices.clear()
	death_voices.clear()
	streams.clear()
