extends Node2D
## Stays responsive while its gameplay parent and every ordinary gameplay child are suspended.
const Card = preload("res://scripts/level_loading_card.gd")
signal accepted
var card := Card.new()
var progress := 0.0
var waiting_for_button := false
var slice_started := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_as_top_level(true)
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX

func _draw() -> void:
	card.draw(self,progress,waiting_for_button)

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if waiting_for_button and card.accepts(event):
		waiting_for_button = false
		accepted.emit()

func yield_slice() -> void:
	if Time.get_ticks_usec()-slice_started >= 4000:
		await get_tree().process_frame
		slice_started = Time.get_ticks_usec()

func report(fraction: float) -> void:
	progress = fraction
