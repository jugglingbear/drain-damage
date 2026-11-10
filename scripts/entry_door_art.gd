extends RefCounted
## Hinged artwork appears only during an actual entrance or while a mounted actor occupies it.
const MANIFEST := "res://assets/world/pit-water-transition-v1/manifest.json"
var spec: Dictionary = {}

func prepare(host: Node, yield_frame := Callable()) -> void:
	spec = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)).hatch
	for frame: Dictionary in spec.frames:
		frame.path = spec.path
		frame.alpha_cutoff = spec.alpha_cutoff
	await host.load_trial_textures(spec.frames,yield_frame)

func draw(host: Node2D, actor: Dictionary, fraction: float, front: bool) -> void:
	if spec.is_empty() or fraction < 0: return
	var frame: Dictionary = spec.frames[mini(5,int(clampf(fraction,0,1)*6))]
	var source: Rect2 = host.region(frame.front_source_rect if front else frame.source_rect)
	var destination: Rect2 = host.region(frame.front_destination if front else frame.destination)
	var ceiling: bool = actor.mount == "ceiling"
	if ceiling: destination.position.y = -destination.end.y
	destination.position += actor.home
	var texture: Texture2D = host.trial_textures[spec.path]
	if not ceiling:
		host.draw_texture_rect_region(texture,destination,source)
		return
	var corners := PackedVector2Array([destination.position,Vector2(destination.end.x,destination.position.y),
		destination.end,Vector2(destination.position.x,destination.end.y)])
	var uvs := PackedVector2Array([Vector2(source.position.x,source.end.y),source.end,
		Vector2(source.end.x,source.position.y),source.position])
	for index in range(uvs.size()): uvs[index] /= texture.get_size()
	host.draw_polygon(corners,PackedColorArray([Color.WHITE]),uvs,texture)
