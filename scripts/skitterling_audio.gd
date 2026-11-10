extends RefCounted
## Encounter events own audio transitions; stream completion never advances gameplay.
const CreatureAudio = preload("res://scripts/creature_audio.gd")
const V1 := "res://assets/audio/sfx/cockroach-swarm-v1/"
const V2 := "res://assets/audio/sfx/cockroach-swarm-v2/"
const V4 := "res://assets/audio/sfx/skitterling-rat-recorded-v4/"
const V8 := "res://assets/audio/sfx/skitterling-action-sync-v8/"
const CUES := {
	"surface_warning": [V8+"surface_warning.wav", -3.0],
	"swarm_entry": [V2+"swarm-entry.wav", -4.0],
	"rat_assembly": [V4+"rat_assembly.wav", -4.0],
	"assembly_layer": [V2+"assembly.wav", -5.0],
	"rat_bite_warning": [V1+"rat-warning.wav", -3.0],
	"rat_pipe_hide": [V2+"swarm-entry.wav", -4.0],
	"pipe_warning": [V2+"pipe-warning.wav", -3.0],
	"pipe_launch": [V2+"pipe-launch.wav", -3.0],
	"pipe_land": [V2+"landing.wav", -3.0],
	"rat_phase_defeat": [V2+"rat-false-collapse.wav", -4.0],
	"alligator_assembly": [V8+"alligator_assembly.wav", -4.0],
	"alligator_jaw_warning": [V8+"alligator_jaw_warning.wav", -4.0],
	"water_dive": [V2+"water-dive.wav", -4.0],
	"water_emerge": [V2+"water-emerge.wav", -4.0],
	"tail_warning": [V8+"tail_warning.wav", -4.0],
	"debris_release": [V2+"debris-release.wav", -4.0],
	"debris_impact": [V2+"debris-impact.wav", -4.0],
	# The roach jaws use the existing chitin contact, with no animal voice or extra loop.
	"jaw_snap": [V2+"debris-release.wav", -4.0],
	"rat_climb": [V2+"swarm-entry.wav", -4.0],
	"rat_pounce_warning": [V8+"rat_pounce_warning.wav", -4.0],
	"rat_pounce": [V2+"pipe-launch.wav", -3.0],
	"rat_pounce_land": [V2+"landing.wav", -3.0],
	"rat_rush_warning": [V8+"rat_rush_warning.wav", -4.0],
	"rat_rush": [V2+"swarm-entry.wav", -4.0],
	"alligator_tail_warning": [V8+"alligator_tail_warning.wav", -4.0],
	"alligator_tail_sweep": [V2+"debris-release.wav", -4.0],
}
var damage = CreatureAudio.new("cockroach-swarm")
var beds: Array[AudioStreamPlayer] = []
var effects: Array[AudioStreamPlayer] = []
var warning: AudioStreamPlayer
var streams: Dictionary = {}
var target := -1
var levels := [0.0, 0.0]
var cursor := 0
var clock := 0.0
var impact_after := 0.0
var paused := false
var defeated := false
var event_starts: Dictionary = {}
var cue_cutoffs: Dictionary = {}

func attach(game: Node) -> void:
	damage.attach(game)
	for name in ["formed-loop", "dispersed-loop"]:
		var voice := AudioStreamPlayer.new()
		var stream: AudioStreamWAV = load(V1+name+".wav").duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
		voice.stream = stream
		voice.volume_db = -80
		game.add_child(voice)
		beds.append(voice)
	for index in range(2):
		var voice := AudioStreamPlayer.new()
		game.add_child(voice)
		effects.append(voice)
	warning = AudioStreamPlayer.new()
	game.add_child(warning)
	for name in CUES:
		var stream: AudioStreamWAV = load(CUES[name][0]).duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		streams[name] = stream

func event(name: String) -> void:
	if paused or defeated or beds.is_empty(): return
	if name == "terminal_death":
		stop()
		defeated = true
		damage.play_defeat()
		event_starts[name] = int(event_starts.get(name, 0))+1
		return
	if name in ["swarm_entry", "reskitter", "rat_pipe_hide", "water_dive", "swim_start"]: target = 1
	if name in ["rat_assembly", "alligator_assembly", "water_emerge", "pipe_land"]: target = 0
	if name in ["rat_climb", "rat_pounce_warning", "rat_pounce_land", "rat_rush",
		"alligator_tail_warning"]: target = 0
	if name == "rat_phase_defeat":
		target = -1
		warning.stop()
		for voice in effects: voice.stop()
	if name in ["pipe_launch", "rat_pipe_hide", "water_dive", "debris_release", "jaw_snap"]: warning.stop()
	if name in ["attack_start", "swim_start", "water_emerge", "reskitter", "motion_end"]: warning.stop()
	if name in ["rat_pounce", "rat_pounce_land", "rat_rush", "alligator_tail_sweep"]: warning.stop()
	# New tells and interrupted movement must not inherit an earlier motion/launch tail.
	if name.ends_with("warning") or name in ["rat_pipe_hide", "reskitter", "motion_end", "rat_pounce_land"]:
		for old_voice in effects:
			old_voice.stop()
			cue_cutoffs.erase(old_voice)
	if not streams.has(name) or AudioServer.is_bus_mute(0): return
	if name == "debris_impact":
		if clock < impact_after: return
		impact_after = clock+.10
	var voice: AudioStreamPlayer = warning if name.ends_with("warning") else effects[cursor]
	if voice != warning: cursor = (cursor+1)%effects.size()
	cue_cutoffs.erase(voice)
	# The original assembly source is longer than the revised gameplay transition.
	if name in ["assembly_layer", "alligator_assembly", "pipe_warning"]:
		var duration: float = {"assembly_layer":1.4, "alligator_assembly":1.85, "pipe_warning":1.9}[name]
		cue_cutoffs[voice] = {"end": clock+duration, "gain": float(CUES[name][1])}
	voice.stream = streams[name]
	voice.volume_db = CUES[name][1]
	voice.play()
	event_starts[name] = int(event_starts.get(name, 0))+1

func play_hit(actor: Dictionary, now := -1.0) -> void:
	if not defeated: damage.play_hit(actor, now if now >= 0 else clock)

func step(delta: float) -> void:
	if paused or beds.is_empty(): return
	clock += maxf(delta, 0)
	for voice in cue_cutoffs.keys():
		var remaining: float = cue_cutoffs[voice].end-clock
		if remaining <= 0:
			voice.stop()
			cue_cutoffs.erase(voice)
		else:
			voice.volume_db = cue_cutoffs[voice].gain+linear_to_db(minf(1.0, remaining/.06))
	for index in range(beds.size()):
		levels[index] = move_toward(levels[index], 1.0 if target == index else 0.0, maxf(delta,0)/.15)
		var voice := beds[index]
		if levels[index] <= .0001 or AudioServer.is_bus_mute(0):
			voice.stop()
			continue
		voice.volume_db = -9.0+linear_to_db(levels[index])+(-6.0 if warning.playing else 0.0)
		if not voice.playing: voice.play()

func set_paused(value: bool) -> void:
	paused = value
	damage.set_paused(value)
	for voice in beds+effects: voice.stream_paused = value
	if is_instance_valid(warning): warning.stream_paused = value

func stop() -> void:
	damage.stop()
	for voice in beds+effects:
		voice.stop()
		voice.stream_paused = false
	if is_instance_valid(warning):
		warning.stop()
		warning.stream_paused = false
	target = -1
	levels = [0.0, 0.0]
	paused = false
	defeated = false
	clock = 0
	impact_after = 0
	cursor = 0
	cue_cutoffs.clear()

func dispose() -> void:
	stop()
	for voice in damage.hit_voices+damage.death_voices: voice.queue_free()
	damage.dispose()
	for voice in beds+effects+[warning]:
		if is_instance_valid(voice):
			voice.stream = null
			voice.queue_free()
	beds.clear()
	effects.clear()
	streams.clear()
