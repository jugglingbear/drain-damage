extends Node2D
## Encounter-owned presentation. No boss AI, phase logic, or independent HP authority.
const Data = preload("res://scripts/combat_data.gd")
var active := false
var boss_name := ""
var boss_id := ""
var player_status := ""
var hp := 0.0
var maximum := 1.0
var trail := 0.0
var trail_start := 0.0
var since_hit := 0.0
var death_time := 0.0
var opacity := 1.0
var policy: Dictionary
const MANIFEST := "res://assets/ui/boss-hud-right-v1/manifest.json"
var definition: Dictionary = {}
var textures: Dictionary = {}

func _ready() -> void:
	Data.load_data()
	policy = Data.bundle.visual_policy.boss_hud
	z_index = 30
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	definition = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var sources := {}
	for id: String in definition.skins:
		for key: String in definition.skins[id]:
			var part: Dictionary = definition.skins[id][key]
			if part.has("color"): continue
			if not sources.has(part.path):
				var texture: Texture2D = load("res://"+part.path)
				assert(texture != null,"Missing vertical boss HUD artwork")
				sources[part.path] = texture.get_image()
			var source: Image = sources[part.path]
			if source.is_compressed(): source.decompress()
			var crop := source.get_region(Rect2i(rect(part.source_rect)))
			assert(part.rotation_degrees == -90,"Unsupported boss HUD rotation")
			crop.rotate_90(COUNTERCLOCKWISE)
			part.texture_key = id+"/"+key
			textures[part.texture_key] = ImageTexture.create_from_image(crop)
			part.source_rect = [0,0,crop.get_width(),crop.get_height()]

func begin_encounter(id: String) -> void:
	var definition := Data.monster(id)
	if definition.is_empty(): return
	boss_id = id
	boss_name = definition.name
	maximum = definition.health.max_hp
	hp = definition.health.spawn_hp
	trail = hp / maximum
	trail_start = trail
	since_hit = 0
	death_time = 0
	opacity = 1
	active = true
	queue_redraw()

func update_hp(value: float) -> void:
	if not active or not is_finite(value): return
	# Encounter retries explicitly call begin_encounter; phase changes never refill this bar.
	var next := clampf(value, 0, hp)
	if next == hp: return
	hp = next
	trail_start = trail
	since_hit = 0
	if hp == 0:
		trail = 0
		death_time = 0
	queue_redraw()

func end_encounter() -> void:
	active = false
	hp = 0
	trail = 0
	opacity = 0
	queue_redraw()

func tick(delta: float) -> void:
	if not active: return
	if hp <= 0:
		death_time += delta
		opacity = 1.0 - clampf((death_time - policy.death_hold_seconds) / policy.death_fade_seconds, 0, 1)
		if opacity == 0: active = false
	else:
		since_hit += delta
		var feedback: Dictionary = policy.damage_feedback
		var progress := clampf((since_hit - feedback.trail_delay_seconds) / feedback.trail_catchup_seconds, 0, 1)
		trail = lerpf(trail_start, hp / maximum, progress)
	queue_redraw()

func reserved_height() -> float:
	# The normal player header retains its original coordinates and artwork.
	return 0.0

func rect(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])

func name_lines() -> PackedStringArray:
	return PackedStringArray(["THE","CLOGFATHER"]) if boss_id == "clogfather" \
		else PackedStringArray([boss_name.to_upper()])

func name_font_size(line: String) -> int:
	var size := 14
	while size > 8 and ThemeDB.fallback_font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x \
			> float(definition.name_rect[2]): size -= 1
	return size

func fill_regions(part: Dictionary, fraction: float) -> Array[Rect2]:
	var source := rect(part.source_rect)
	var destination := rect(part.destination)
	var amount := clampf(fraction,0,1)
	# Crop from the top without squeezing the authored texture; the bottom never moves.
	source.position.y += source.size.y*(1-amount)
	destination.position.y += destination.size.y*(1-amount)
	source.size.y *= amount
	destination.size.y *= amount
	return [source,destination]

func draw_part(id: String, fraction := 1.0, tint := Color.WHITE) -> void:
	if fraction <= 0: return
	var part: Dictionary = definition.skins[boss_id][id]
	if part.has("color"):
		draw_rect(rect(part.destination),Color(part.color)*tint)
		return
	var regions := fill_regions(part,fraction)
	draw_texture_rect_region(textures[part.texture_key],regions[1],regions[0],tint)

func _draw() -> void:
	if not active or not definition.skins.has(boss_id): return
	modulate.a = opacity
	draw_part("track")
	var fraction := hp/maximum
	var fill := "fill"
	if boss_id == "clogfather":
		fill = "fill_green" if fraction > .5 else "fill_yellow" if fraction > .25 else "fill_red"
	draw_part(fill,trail,Color("f3b597"))
	draw_part(fill,fraction)
	draw_part("frame")
	var names := name_lines()
	var area := rect(definition.name_rect)
	for index in range(names.size()):
		var baseline := area.position.y+16 if names.size() == 1 else area.position.y+12+index*14
		draw_string(ThemeDB.fallback_font,Vector2(area.position.x,baseline),names[index],
			HORIZONTAL_ALIGNMENT_CENTER,area.size.x,name_font_size(names[index]),Color("ffe18d"))
