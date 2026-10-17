extends Node
## One music voice prevents overlap; transitions fade out before switching streams.

const TITLE = preload("res://assets/audio/music/it-takes-a-hero-v1.ogg")
const LEVEL = preload("res://assets/audio/music/hallow-quest-16-bit-v1.ogg")
const TITLE_GAIN_DB := -16.0
const LEVEL_GAIN_DB := -20.0
const FADE_SECONDS := 0.25
var player := AudioStreamPlayer.new()
var current := ""
var requested := ""
var muted := false
var paused := false
var fade_db := -60.0
var duck_db := 0.0
var transition: Tween

func _ready() -> void:
	add_child(player)
	player.finished.connect(_on_finished)

func _process(_delta: float) -> void:
	apply_volume()

func apply_volume() -> void:
	var gain := LEVEL_GAIN_DB if current == "level" else TITLE_GAIN_DB
	player.volume_db = -80.0 if muted else gain + fade_db + duck_db

func set_muted(value: bool) -> void:
	muted = value
	apply_volume()

func set_paused(value: bool) -> void:
	paused = value
	player.stream_paused = value

func play_track(id: String) -> void:
	assert(id in ["title", "level"])
	set_paused(false)
	duck_db = 0
	if requested == id: return
	requested = id
	if transition != null: transition.kill()
	transition = create_tween()
	if player.playing:
		transition.tween_property(self, "fade_db", -60.0, FADE_SECONDS)
		transition.tween_callback(_switch.bind(id))
	else:
		_switch(id)
	transition.tween_property(self, "fade_db", 0.0, FADE_SECONDS)

func _switch(id: String) -> void:
	player.stop()
	current = id
	var source: AudioStreamOggVorbis = LEVEL if id == "level" else TITLE
	player.stream = source.duplicate()
	# Hero has a complete ending, not a seamless loop. Its finished signal starts a fresh playthrough.
	player.stream.loop = id == "level"
	fade_db = -60
	apply_volume()
	player.play()
	player.stream_paused = paused

func _on_finished() -> void:
	if current == "title" and requested == "title":
		player.play()

func _exit_tree() -> void:
	if transition != null: transition.kill()
	player.stop()
