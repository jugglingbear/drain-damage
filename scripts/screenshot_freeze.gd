extends Node
## Opt-in capture freeze owns tree pause, never the game's menu pause or HUD state.
var host: Node2D
var frozen := false
var y_down := false
var saved_audio: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func capture_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		saved_audio[node] = node.stream_paused
		node.stream_paused = true
	for child: Node in node.get_children():
		if child != self: capture_audio(child)

func begin_freeze() -> void:
	if frozen or get_tree().paused or host.paused or host.won or host.life_state not in ["alive","dying"]: return
	frozen = true
	capture_audio(get_tree().root)
	get_tree().paused = true

func resume() -> void:
	if not frozen: return
	for voice in saved_audio:
		if is_instance_valid(voice): voice.stream_paused = saved_audio[voice]
	saved_audio.clear()
	if host.has_method("sync_capture_input"): host.sync_capture_input()
	get_tree().paused = false
	frozen = false

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_Y:
		if event.pressed and not y_down:
			if frozen: resume()
			else: begin_freeze()
		y_down = event.pressed
		get_viewport().set_input_as_handled()
	elif frozen:
		# Keep pause/menu actions from leaking through this separate capture state.
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		y_down = false

func _exit_tree() -> void:
	if frozen: resume()
