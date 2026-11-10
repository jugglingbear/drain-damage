extends RefCounted
## Registered permanent props share one placement source for drawing and material collision.
const MANIFEST := "res://assets/world/basement-platforms-v1/manifest.json"
const PLACEMENTS := "res://levels/first-call/platform-variety-v1.json"
# Reviewed subset only: new proposals must not silently become runtime geometry.
const ENABLED := ["pump-machine-0", "approach-machine-0-0", "approach-machine-0-1",
	"approach-machine-0-2", "approach-machine-1-0", "approach-machine-1-1", "approach-machine-1-2"]
var assets: Dictionary = {}
var placements: Dictionary = {}

func _init() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for asset: Dictionary in manifest.assets: assets[asset.id] = asset
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLACEMENTS))
	for item: Dictionary in data.placements:
		if item.replaces_support_id not in ENABLED: continue
		assert(not item.destructible and not assets[item.family].destructible)
		placements[item.replaces_support_id] = item

func colliders(id: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var item: Dictionary = placements[id]
	var anchor := Vector2(item.floor_center_anchor[0],item.floor_center_anchor[1])
	for values: Array in assets[item.family].collision_rects:
		result.append(Rect2(anchor+Vector2(values[0],values[1]),Vector2(values[2],values[3])))
	return result

func prepare(host: Node, yield_frame := Callable()) -> void:
	for item: Dictionary in placements.values():
		var asset: Dictionary = assets[item.family]
		var frame: Dictionary = asset.frames[0].duplicate(true)
		frame.path = asset.path
		frame.alpha_cutoff = asset.alpha_cutoff
		await host.load_trial_textures(frame,yield_frame)

func draw(host: Node2D, id: String) -> void:
	var item: Dictionary = placements[id]
	var asset: Dictionary = assets[item.family]
	var frame: Dictionary = asset.frames[0].duplicate(true)
	frame.path = asset.path
	var destination: Rect2 = host.region(frame.destination)
	destination.position += Vector2(item.floor_center_anchor[0],item.floor_center_anchor[1])
	host.draw_asset(frame,destination)
