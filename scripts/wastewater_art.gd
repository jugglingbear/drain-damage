extends RefCounted
## Art-only pipe renderer. Draw under the caller's world transform (-camera_x, 0).
const Profile = preload("res://scripts/wastewater_profile.gd")
const TILE := 480.0
const STRIP := 16.0
const BORE := Rect2(0, 464, 9600, 56)
var profile = Profile.new()
var assets: Dictionary = {}
var textures: Dictionary = {}
var debris_ids: Array[String] = []
var ready := false

func configure(data: Dictionary) -> bool:
	## Accept Data.bundle.wastewater = {art: manifest, progression: sections}.
	ready = false
	assets.clear()
	textures.clear()
	debris_ids.clear()
	var art: Dictionary = data.get("art", {})
	var sections: Array = data.get("progression", [])
	if sections.is_empty(): return false
	for entry: Dictionary in art.get("assets", []):
		var path: String = "res://" + str(entry.path).trim_prefix("res://")
		if not textures.has(path):
			var texture = load(path)
			if not texture is Texture2D: return false
			textures[path] = texture
		var values: Array = entry.source_rect
		var source := Rect2(values[0], values[1], values[2], values[3])
		var texture: Texture2D = textures[path]
		if source.size.x <= 0 or source.size.y <= 0: return false
		if not Rect2(Vector2.ZERO, texture.get_size()).encloses(source): return false
		assets[entry.id] = {"path":path, "source":source,
			"size":Vector2(entry.destination_size[0], entry.destination_size[1]),
			"anchor":Vector2(entry.anchor[0], entry.anchor[1])}
		if entry.get("role") == "floating-debris": debris_ids.append(str(entry.id))
	for id in ["interior", "rim-top", "rim-bottom", "water-a", "grease-light",
			"grease-medium", "grease-heavy", "plug"]:
		if not assets.has(id): return false
	if debris_ids.is_empty(): return false
	profile.configure(sections)
	ready = true
	return true

func draw(game: Node2D, camera: float, clock: float, trial := false) -> void:
	## Call inside _draw with world transform active. Does not change transforms or advance time.
	for command: Dictionary in commands(camera, clock, trial):
		var destination: Rect2 = command.rect
		if command.flip: destination.size.x = -destination.size.x
		game.draw_texture_rect_region(textures[assets[command.id].path], destination,
			command.source, Color(1, 1, 1, command.alpha))

func commands(camera: float, clock: float, trial := false) -> Array[Dictionary]:
	## Deterministic, inspectable draw plan. Frozen gameplay clock means frozen animation.
	var output: Array[Dictionary] = []
	if not ready: return output
	var limit: float = 6000.0 if trial else profile.world_end
	var left := maxf(0, camera)
	var right := minf(limit, camera + 960)
	var x := left
	while x < right:
		var end := minf((floorf(x / STRIP) + 1) * STRIP, right)
		if not trial and x < profile.terminal_x and end > profile.terminal_x:
			end = profile.terminal_x
		var state: Dictionary = profile.sample((x + end) / 2.0, trial)
		_tiled(output, "interior", x, end, 464, 56, 0)
		if state.water > 0:
			_tiled(output, "water-a", x, end, 520 - 56 * state.water, 56 * state.water,
				maxf(clock, 0) * state.flow)
		x = end
	_add_debris(output, left, right, maxf(clock, 0), trial)
	x = left
	while x < right:
		var end := minf((floorf(x / STRIP) + 1) * STRIP, right)
		if not trial and x < profile.terminal_x and end > profile.terminal_x:
			end = profile.terminal_x
		var state: Dictionary = profile.sample((x + end) / 2.0, trial)
		if state.coverage >= 1:
			_tiled(output, "plug", x, end, 464, 56, 0)
		else:
			# Crossfade source art without a visible tier switch; both share the sampled height.
			var scaled: float = clampf(state.coverage * 2, 0, 2)
			var ids := ["grease-light", "grease-medium", "grease-heavy"]
			var index := mini(int(scaled), 1)
			var blend := scaled - index
			_tiled(output, ids[index], x, end, 520 - 56 * state.coverage, 56 * state.coverage, 0)
			_tiled(output, ids[index + 1], x, end, 520 - 56 * state.coverage,
				56 * state.coverage, 0, blend)
		_tiled(output, "rim-top", x, end, 456, 8, 0)
		_tiled(output, "rim-bottom", x, end, 520, 8, 0)
		x = end
	return output

func _tiled(output: Array[Dictionary], id: String, left: float, right: float,
		y: float, height: float, phase: float, alpha := 1.0) -> void:
	if height <= 0 or alpha <= 0: return
	var x := left
	while x < right:
		var tile := int(floor((x - phase) / TILE))
		var local := fposmod(x - phase, TILE)
		var span := minf(right - x, TILE - local)
		if span < 0.00001: break
		var mirrored := posmod(tile, 2) == 1
		var source: Rect2 = assets[id].source
		var unit: float = source.size.x / TILE
		source.position.x += (TILE - local - span if mirrored else local) * unit
		source.size.x = span * unit
		output.append({"id":id, "rect":Rect2(x, y, span, height), "source":source,
			"flip":mirrored, "alpha":alpha})
		x += span

func _add_debris(output: Array[Dictionary], left: float, right: float, clock: float, trial: bool) -> void:
	# Stable world cells, not camera-relative RNG. Fade at wrap boundaries prevents popping.
	for cell in range(maxi(0, int(floor(left / 240))), int(ceil(right / 240))):
		var origin := float(cell * 240)
		var state: Dictionary = profile.sample(origin + 120, trial)
		if state.water < 0.08 or state.flow <= 0: continue
		var local := fposmod(float(posmod(cell * 97 + 53, 240)) + clock * state.flow, 240)
		var x := origin + local
		var at: Dictionary = profile.sample(x, trial)
		if at.water < 0.08 or at.flow <= 0: continue
		var alpha: float = minf(local / 24, (240 - local) / 24) * (1 - at.coverage)
		alpha = clampf(alpha, 0, 0.85)
		var id: String = debris_ids[posmod(cell * 5 + 1, debris_ids.size())]
		var asset: Dictionary = assets[id]
		var rect := Rect2(Vector2(x, 520 - 56 * at.water + 3) - asset.anchor, asset.size)
		var clip := rect.intersection(Rect2(left, 464, right - left, 56))
		if not clip.has_area(): continue
		var source: Rect2 = asset.source
		var ratio := source.size / rect.size
		source.position += (clip.position - rect.position) * ratio
		source.size = clip.size * ratio
		output.append({"id":id, "rect":clip, "source":source, "flip":false, "alpha":alpha})
