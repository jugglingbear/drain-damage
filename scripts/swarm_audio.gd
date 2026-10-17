extends RefCounted
## One bounded ambient voice avoids stacking gain from overlapping swarms.
const LOOP = preload("res://assets/audio/sfx/sewer-fly-buzz-v1/swarm-loop.wav")
const MAX_GAIN_DB := -8.0
const HEARING_RADIUS := 520.0
var voice: AudioStreamPlayer
var level := 0.0
var starts := 0

func attach(game: Node) -> void:
	voice = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = LOOP.duplicate()
	stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	voice.stream = stream
	voice.volume_db = -80
	game.add_child(voice)

func stop() -> void:
	level = 0
	if is_instance_valid(voice):
		voice.stop()
		voice.stream_paused = false

func tick(game: Node2D, delta: float) -> void:
	var frozen: bool = game.paused or game.dialogue.active or game.dispenser.active
	voice.stream_paused = frozen
	if game.life_state != "alive" or game.won:
		stop()
		return
	if frozen: return
	var target := 0.0
	var living := false
	for actor: Dictionary in game.swarms.actors:
		if actor.hp <= 0: continue
		living = true
		var distance: float = actor.pos.distance_to(game.player+game.PLAYER_SIZE*0.5)
		target = maxf(target,pow(clampf(1-distance/HEARING_RADIUS,0,1),2))
	# The shared Master bus is the existing SFX route; music mute remains music-only.
	if not living or AudioServer.is_bus_mute(AudioServer.get_bus_index(voice.bus)):
		stop()
		return
	level = move_toward(level,target,maxf(delta,0)*3)
	if level <= 0.0001:
		voice.stop()
		return
	voice.volume_db = minf(MAX_GAIN_DB,MAX_GAIN_DB+linear_to_db(level))
	if not voice.playing:
		voice.play()
		starts += 1

func dispose() -> void:
	stop()
	if is_instance_valid(voice): voice.stream = null
