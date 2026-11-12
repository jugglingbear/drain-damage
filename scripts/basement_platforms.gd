extends RefCounted
## Registered props share placement, live collision, damage and collapse state.
const MANIFEST := "res://assets/world/basement-platforms-v1/manifest.json"
const PLACEMENTS := "res://levels/first-call/platform-variety-v1.json"
const AUDIO_PATHS := {
	"water-heater/hit":"res://assets/audio/sfx/basement-platforms-v1/water-heater-hit.wav",
	"water-heater/break":"res://assets/audio/sfx/basement-platforms-v1/water-heater-break.wav",
	"cast-iron-boiler/hit":"res://assets/audio/sfx/basement-platforms-v1/cast-iron-boiler-hit.wav",
	"cast-iron-boiler/break":"res://assets/audio/sfx/basement-platforms-v1/cast-iron-boiler-break.wav",
	"pressure-tank/hit":"res://assets/audio/sfx/basement-platforms-v1/pressure-tank-hit.wav",
	"pressure-tank/break":"res://assets/audio/sfx/basement-platforms-v1/pressure-tank-break.wav"
}
const HIT_COOLDOWN := 0.12
# Reviewed permanent subset only; new breakables require explicit placement admission.
const ENABLED := ["pump-machine-0", "approach-machine-0-0", "approach-machine-0-1",
	"approach-machine-0-2", "approach-machine-1-0", "approach-machine-1-1", "approach-machine-1-2"]
var assets: Dictionary = {}
var placements: Dictionary = {}
var states: Dictionary = {}
var supplemental: Array[Dictionary] = []
var overrides: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_cursor := 0
var initial_hp := 54.0

func _init() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for asset: Dictionary in manifest.assets: assets[asset.id] = asset
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLACEMENTS))
	for item: Dictionary in data.placements:
		if item.replaces_support_id in ENABLED: placements[item.replaces_support_id] = item
	var breakables: Dictionary = data.get("breakables",{})
	initial_hp = float(breakables.get("initial_tuning",{}).get("hit_points",54))
	for item: Dictionary in breakables.get("runtime_placements",[]):
		if not item.get("enabled",false): continue
		var replacement: String = str(item.get("replaces_support_id","") if item.get("replaces_support_id") != null else "")
		placements[item.id if replacement.is_empty() else replacement] = item
	for item: Dictionary in breakables.get("supplemental_geometry",[]): supplemental.append(item)
	for item: Dictionary in breakables.get("geometry_overrides",[]): overrides[item.replaces_support_id] = item.rect
	reset()

func reset() -> void:
	stop_audio()
	states.clear()
	for id: String in placements:
		states[id] = {"hp":initial_hp,"break_age":-1.0,"hit_cooldown":0.0}

func anchor(id: String) -> Vector2:
	var values: Array = placements[id].floor_center_anchor
	return Vector2(values[0],values[1])

func colliders(id: String) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var asset: Dictionary = assets[placements[id].family]
	if asset.destructible and float(states[id].break_age) >= float(asset.events.support_release)-0.0000001:
		return result
	for values: Array in asset.collision_rects:
		result.append(Rect2(anchor(id)+Vector2(values[0],values[1]),Vector2(values[2],values[3])))
	return result

func targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in placements:
		if assets[placements[id].family].destructible and states[id].hp > 0:
			result.append({"id":id,"regions":colliders(id)})
	return result

func damage(id: String, amount: float) -> float:
	if not states.has(id) or amount <= 0 or not is_finite(amount): return 0
	var state: Dictionary = states[id]
	if not assets[placements[id].family].destructible or state.hp <= 0: return 0
	var accepted := minf(float(state.hp),amount)
	state.hp -= accepted
	if state.hp <= 0:
		state.break_age = 0.0
		play_cue(id,"break")
	elif state.hit_cooldown <= 0:
		state.hit_cooldown = HIT_COOLDOWN
		play_cue(id,"hit")
	return accepted

func advance(delta: float) -> bool:
	if delta <= 0 or not is_finite(delta): return false
	var released := false
	for id: String in states:
		var state: Dictionary = states[id]
		state.hit_cooldown = maxf(0,float(state.hit_cooldown)-delta)
		if state.break_age < 0: continue
		var supported := not colliders(id).is_empty()
		state.break_age = minf(0.8,float(state.break_age)+delta)
		if supported and colliders(id).is_empty(): released = true
	return released

func frame_id(id: String) -> int:
	var asset: Dictionary = assets[placements[id].family]
	if not asset.destructible: return 0
	var state: Dictionary = states[id]
	if state.break_age < 0:
		if state.hp <= initial_hp/3.0: return int(asset.states.damage_heavy[0])
		if state.hp <= initial_hp*2.0/3.0: return int(asset.states.damage_light[0])
		return 0
	var boundary := 0.0
	for index in range(asset.break_durations.size()):
		boundary += float(asset.break_durations[index])
		if float(state.break_age) < boundary-0.0000001: return int(asset.states.break[index])
	return int(asset.states.wreck[0])

func prepare(host: Node, yield_frame := Callable()) -> void:
	for item: Dictionary in placements.values():
		var asset: Dictionary = assets[item.family]
		var frame: Dictionary = asset.frames[0].duplicate(true)
		frame.path = asset.path
		frame.alpha_cutoff = asset.alpha_cutoff
		await host.load_trial_textures(frame,yield_frame)
		for registered: Dictionary in asset.frames:
			if not registered.has("path"): continue
			var separate := registered.duplicate(true)
			separate.alpha_cutoff = registered.get("alpha_cutoff",asset.alpha_cutoff)
			await host.load_trial_textures(separate,yield_frame)
		if asset.has("collapse_pieces"): await host.load_trial_textures(asset.collapse_pieces,yield_frame)
		if asset.has("effects"):
			var effect: Dictionary = asset.effects.frames[0].duplicate(true)
			effect.path = asset.effects.path
			effect.alpha_cutoff = asset.effects.alpha_cutoff
			await host.load_trial_textures(effect,yield_frame)
	if voices.is_empty():
		for index in range(2):
			var voice := AudioStreamPlayer.new()
			host.add_child(voice)
			voices.append(voice)

func draw(host: Node2D, id: String) -> void:
	var asset: Dictionary = assets[placements[id].family]
	var age: float = states[id].break_age
	var poses := piece_poses(id)
	var landed := false
	for pose: Dictionary in poses:
		if pose.settled: landed = true
	if poses.is_empty() or landed:
		var frame := registered_frame(id,15 if landed else -1).duplicate(true)
		frame.path = frame.get("path",asset.path)
		var destination: Rect2 = host.region(frame.destination)
		destination.position += anchor(id)
		host.draw_asset(frame,destination)
	for pose: Dictionary in poses:
		host.draw_set_transform(anchor(id)+pose.position-Vector2(floorf(host.camera_x),0),pose.rotation)
		host.draw_asset(pose,Rect2(-pose.pivot,pose.size))
	if not poses.is_empty(): host.draw_set_transform(Vector2(-floorf(host.camera_x),0))
	if not asset.has("effects") or age < 0 or age >= 0.8: return
	var effects: Dictionary = asset.effects
	var index := mini(effects.frames.size()-1,int(age/0.16))
	var effect: Dictionary = effects.frames[index].duplicate(true)
	effect.path = effects.path
	var effect_rect: Rect2 = host.region(effect.destination)
	effect_rect.position += anchor(id)+Vector2(effects.draw_origin[0],effects.draw_origin[1])
	host.draw_asset(effect,effect_rect,Color(1,1,1,clampf((0.8-age)/0.16,0,1)))

func registered_frame(id: String, selected := -1) -> Dictionary:
	# Manifest omits rejected atlas cells8–11; frame IDs are not dense array indices.
	if selected < 0: selected = frame_id(id)
	for frame: Dictionary in assets[placements[id].family].frames:
		if int(frame.id) == selected: return frame
	assert(false,"Missing registered platform frame")
	return {}

func piece_poses(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var asset: Dictionary = assets[placements[id].family]
	if not asset.has("collapse_pieces"): return result
	var collapse: Dictionary = asset.collapse_pieces
	var age: float = states[id].break_age
	if age < float(collapse.start_time): return result
	for piece: Dictionary in collapse.pieces:
		var duration := float(piece.settle_time)-float(collapse.start_time)
		var u := clampf((age-float(collapse.start_time))/duration,0,1)
		var start := Vector2(piece.start_position[0],piece.start_position[1])
		var end := Vector2(piece.settled_position[0],piece.settled_position[1])
		var position := Vector2(lerpf(start.x,end.x,smoothstep(0,1,u)),lerpf(start.y,end.y,u*u))
		var angle := deg_to_rad(lerpf(float(piece.start_rotation_degrees),float(piece.settled_rotation_degrees),u)
			+float(piece.flight_rotation_degrees)*sin(PI*u))
		var size := Vector2(piece.destination_size[0],piece.destination_size[1])
		var half_height := (absf(sin(angle))*size.x+absf(cos(angle))*size.y)/2
		position.y = minf(position.y,-half_height)
		result.append({"path":piece.path,"source_rect":piece.source_rect,"position":position,
			"rotation":angle,"size":size,"pivot":Vector2(piece.source_pivot[0],piece.source_pivot[1])*float(piece.uniform_scale),
			"settled":u >= 1})
	return result

func play_cue(id: String, event: String) -> void:
	if voices.is_empty(): return
	var voice := voices[voice_cursor%voices.size()]
	var oldest_hit: AudioStreamPlayer
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			oldest_hit = null
			break
		if candidate.get_meta("event","") == "hit" and (oldest_hit == null
			or candidate.get_meta("serial",0) < oldest_hit.get_meta("serial",0)):
			oldest_hit = candidate
	if oldest_hit != null: voice = oldest_hit
	if event == "hit" and voice.playing and voice.get_meta("event","") == "break": return
	voice_cursor += 1
	voice.stop()
	voice.set_meta("event",event)
	voice.set_meta("serial",voice_cursor)
	voice.stream = load(AUDIO_PATHS[placements[id].family+"/"+event])
	# Delivered combined cues all share these gains; source recipes stay outside runtime packaging.
	voice.volume_db = -3.0 if event == "break" else -2.0
	voice.play()

func set_paused(value: bool) -> void:
	for voice in voices:
		if is_instance_valid(voice): voice.stream_paused = value

func stop_audio() -> void:
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream_paused = false

func dispose() -> void:
	stop_audio()
	for voice in voices:
		if is_instance_valid(voice): voice.queue_free()
	voices.clear()
