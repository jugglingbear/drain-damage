extends RefCounted
## Independent bounded pools keep rapid hits from cutting off the terminal pressure collapse.
const HITS := [preload("res://assets/audio/sfx/sputtervalve-v1/hit-a.wav"),
	preload("res://assets/audio/sfx/sputtervalve-v1/hit-b.wav")]
const DEATH = preload("res://assets/audio/sfx/sputtervalve-v1/death.wav")
const HIT_COOLDOWN := 0.10
var hit_voices: Array[AudioStreamPlayer] = []
var death_voices: Array[AudioStreamPlayer] = []
var cooldowns: Dictionary = {}
var hit_cursor := 0
var death_cursor := 0
var hit_starts := 0
var death_starts := 0
var paused := false

func attach(game: Node) -> void:
	for index in range(2):
		for pool in [hit_voices, death_voices]:
			var voice := AudioStreamPlayer.new()
			voice.volume_db = -3
			game.add_child(voice)
			pool.append(voice)
		hit_voices[index].stream = HITS[index].duplicate()
		death_voices[index].stream = DEATH.duplicate()
	for voice in hit_voices + death_voices:
		voice.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

func allowed() -> bool:
	return not paused and not hit_voices.is_empty() and not AudioServer.is_bus_mute(0)

func play_hit(actor: Dictionary) -> void:
	if actor.role != "perched_shooter" or actor.hp <= 0 or not allowed(): return
	var now := float(actor.age)
	if now < float(cooldowns.get(actor.event_id, -INF)): return
	cooldowns[actor.event_id] = now + HIT_COOLDOWN
	hit_voices[hit_cursor].play()
	hit_cursor = (hit_cursor + 1) % hit_voices.size()
	hit_starts += 1

func play_defeat() -> void:
	if not allowed(): return
	death_voices[death_cursor].play()
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

func dispose() -> void:
	stop()
	for voice in hit_voices + death_voices: voice.stream = null
	hit_voices.clear()
	death_voices.clear()
