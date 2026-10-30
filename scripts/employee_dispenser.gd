extends RefCounted
const Costume = preload("res://scripts/hero_costume.gd")
## Event-driven checkpoint presentation; never waits for audio or animation callbacks.
const Data = preload("res://scripts/combat_data.gd")
const HardArt = preload("res://scripts/hard_costume_art.gd")
const INSPECTION_CONTRACT := "res://assets/world/spare-employee-dispenser/inspection-contract-v1.json"
var inspection: Dictionary = {}
var hard_mode := false
var costume := "normal"
const GUARDED_ACTIONS := ["shoot", "jump", "dialogue_next", "dialogue_skip", "pause_game"]
static var full_sequence_seen := false
var art: Dictionary
var audio: Dictionary
var textures: Dictionary = {}
var voices: Dictionary = {}
var active := false
var stocked := true
var spent_checkpoints: Dictionary = {}
var arrival_health := 0
var arrival_max_health := 1
var dispenses := 0
var mode := ""
var elapsed := 0.0
var deadline := 0.0
var timeline: Array = []
var next_event := 0
var events: Array[String] = []
var checkpoint := -1
var hero := "tony"
var phase := ""
var can_skip := false
var skip_armed := false
var actions_locked := false
var finalizations := 0
var just_finished := false
var cosmetic_rng := RandomNumberGenerator.new()
var impact_point := Vector2(480,280)
var impact_scale := 1.9
var impact_bounds := Rect2()

func sample_impact(viewport_size: Vector2, unit := Vector2(-1,-1)) -> void:
	var states: Dictionary = art.heroes[hero].states
	var bounds := rect(states.ball.destination)
	for state in ["impact", "slide", "blood_trail"]:
		bounds = bounds.merge(rect(states[state].destination))
	bounds.position -= Vector2(64,64)
	var safe := Rect2(Vector2(12,minf(76,viewport_size.y*0.25)),Vector2.ZERO)
	safe.size = viewport_size-safe.position-Vector2(12,12)
	impact_scale = minf(1.9,minf(safe.size.x/bounds.size.x,safe.size.y/bounds.size.y))
	impact_bounds = Rect2(bounds.position*impact_scale,bounds.size*impact_scale)
	var low := safe.position-impact_bounds.position
	var high := safe.end-impact_bounds.end
	if unit.x < 0: unit = Vector2(cosmetic_rng.randf(),cosmetic_rng.randf())
	impact_point = Vector2(lerpf(low.x,high.x,unit.x),lerpf(low.y,high.y,unit.y))

func _init() -> void:
	cosmetic_rng.randomize()
	Data.load_data()
	inspection = JSON.parse_string(FileAccess.get_file_as_string(INSPECTION_CONTRACT))
	audio = Data.bundle.dispenser.audio
	configure(false)

func configure(value: Variant) -> void:
	var selected := Costume.mode(value)
	if art != null and not art.is_empty() and costume == selected: return
	costume = selected
	hard_mode = costume == "hard"
	textures.clear()
	art = Data.bundle.dispenser.art
	if costume != "normal":
		art = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/%s-mode/dispenser-manifest-v1.json" % costume))
		art.sleeping_heroes = JSON.parse_string(FileAccess.get_file_as_string(
			"res://" + str(art.machine.sleeping_occupants.source_manifest)))
	load_art(art.machine)
	load_art(art.heroes)
	load_art(art.sleeping_heroes)
	load_art(inspection.get("parts",{}))
	load_art(inspection.get("diagnosis_art",{}))
	load_art(inspection.get("hero_states",{}))

func load_art(value: Variant) -> void:
	if value is Dictionary:
		if value.has("path") and value.has("source_rect"):
			textures[value.path] = HardArt.texture(value.path)
		for child: Variant in value.values(): load_art(child)
	elif value is Array:
		for child: Variant in value: load_art(child)

func attach(game: Node2D) -> void:
	for cue: Dictionary in audio.cues:
		var voice := AudioStreamPlayer.new()
		voice.stream = load("res://"+cue.path)
		voice.volume_db = cue.gain_db
		game.add_child(voice)
		voices[cue.cue_id] = voice

func stop_audio() -> void:
	for voice: AudioStreamPlayer in voices.values():
		if is_instance_valid(voice): voice.stop()

func cancel() -> void:
	just_finished = false
	active = false
	phase = ""
	next_event = timeline.size()
	actions_locked = false
	stop_audio()

func reset_stock() -> void:
	stocked = true
	spent_checkpoints.clear()
	dispenses = 0

func consume_stock() -> void:
	if not stocked: return
	stocked = false
	spent_checkpoints[checkpoint] = true
	dispenses += 1

func dispose() -> void:
	cancel()
	for voice: AudioStreamPlayer in voices.values():
		if is_instance_valid(voice): voice.stream = null
	voices.clear()
	textures.clear()

func held_actions() -> bool:
	for action: String in GUARDED_ACTIONS:
		if Input.is_action_pressed(action): return true
	return false

func start(game: Node2D, kind: String, index: int, previous_health := -1) -> void:
	cancel()
	stocked = not spent_checkpoints.has(index)
	arrival_max_health = maxi(1,game.employee.max_health)
	arrival_health = clampi(game.health if previous_health < 0 else previous_health,0,arrival_max_health)
	if kind in ["injured","respawn"] and not stocked: kind = "empty_arrival"
	active = true
	mode = kind
	checkpoint = index
	hero = game.employee.id
	if kind == "injured": sample_impact(game.get_viewport_rect().size)
	elapsed = 0
	phase = ""
	events.clear()
	next_event = 0
	finalizations = 0
	skip_armed = not held_actions()
	can_skip = kind != "injured" or full_sequence_seen
	timeline = [{"time":0.4,"event":"release"}] if kind == "empty_arrival" else \
		inspection_timeline() if kind == "injured" else art.short_paths[kind]
	deadline = 7.0 if kind == "injured" else 2.0 if kind == "respawn" else 0.5
	game.shots.clear()
	game.velocity = Vector2.ZERO
	game.jump_buffer = 0
	game.player = game.respawn_point
	game.grounded = true
	game.camera_x = clampf(game.player.x-320,0,game.WORLD_WIDTH-960)
	game.tone_time = 0
	dispatch(game)

func inspection_timeline() -> Array:
	var times: Dictionary = inspection.timing_seconds
	var result: Array = []
	for pair in [["grab","grab_lift"],["inspection_arm_deploy","inspection_arm_deploy"],
		["inspect","inspect"],["diagnosis","diagnosis_visible"],
		["inspection_arm_retract","inspection_arm_retract"],["compress","compress"],
		["throw","throw"],["impact","impact"],["slide","slide_vend"],["vend","slide_vend"],
		["emerge","emerge"],["look_left","look_left"],["look_right","look_right"],["shrug","shrug"]]:
		result.append({"time":times[pair[1]][0],"event":pair[0]})
	result.append({"time":inspection.release_seconds-0.15,"event":"stamp"})
	result.append({"time":inspection.release_seconds,"event":"release"})
	return result

func emit_event(event: String) -> void:
	if event == "vend" and mode in ["injured","respawn"]: consume_stock()
	events.append(event)
	phase = event
	if mode == "full_health" and event == "release": return
	for cue_id: String in audio.event_mapping.get(event,[]):
		if voices.has(cue_id): voices[cue_id].play()

func dispatch(game: Node2D) -> void:
	while active and next_event < timeline.size() and elapsed >= timeline[next_event].time:
		var event: String = timeline[next_event].event
		next_event += 1
		if event == "release":
			finish(game,false)
		else:
			emit_event(event)

func tick(game: Node2D, delta: float) -> void:
	if actions_locked and not held_actions(): actions_locked = false
	for voice: AudioStreamPlayer in voices.values(): voice.stream_paused = game.paused
	if not active or game.paused: return
	if not skip_armed and not held_actions(): skip_armed = true
	if can_skip and skip_armed and Input.is_action_pressed("dialogue_skip") \
		and Input.is_action_just_pressed("dialogue_skip"):
		finish(game,true)
		return
	elapsed = minf(elapsed+maxf(delta,0),deadline)
	if elapsed >= deadline:
		finish(game,true)
		return
	dispatch(game)

func finish(game: Node2D, silent: bool) -> void:
	if not active: return
	active = false
	phase = ""
	next_event = timeline.size()
	stop_audio()
	finalizations += 1
	just_finished = true
	# Skip/watchdog completes the same replacement, never creates a second clone.
	if mode in ["injured","respawn"]: consume_stock()
	if mode == "injured": full_sequence_seen = true
	game.player = game.respawn_point
	game.health = game.employee.max_health
	game.velocity = Vector2.ZERO
	game.grounded = true
	game.animation_state = "idle"
	game.animation_time = 0
	game.jump_buffer = 0
	game.fire_timer = maxf(game.fire_timer,0.1)
	game.invulnerable = maxf(game.invulnerable,1.5)
	game.dialogue.awaiting_release = false
	game.dialogue.release_guard = 0
	actions_locked = held_actions()
	if not silent:
		emit_event("release")
		phase = ""

func hides_hero() -> bool:
	return active and mode in ["respawn","injured"]

func overlay_visible() -> bool:
	return active and mode == "injured" and elapsed >= inspection.timing_seconds.throw[0] \
		and elapsed < inspection.timing_seconds.emerge[0]

func rect(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])

func frame_geometry(frame: Dictionary, origin: Vector2, scale_value := 1.0,
		clip := Rect2()) -> Dictionary:
	var destination := rect(frame.destination)
	var source := rect(frame.source_rect)
	var mirrored: bool = frame.get("mirror_x",false)
	if mirrored:
		var anchor: Array = frame.get("anchor",[64,104])
		destination.position.x = 2*anchor[0]-destination.end.x
	if clip.has_area():
		var cropped := destination.intersection(clip)
		if not cropped.has_area(): return {}
		var ratio := source.size/destination.size
		var offset := cropped.position-destination.position
		if mirrored: offset.x = destination.end.x-cropped.end.x
		source.position += offset*ratio
		source.size = cropped.size*ratio
		destination = cropped
	# Godot treats negative width as a UV flip; it keeps the destination's left edge.
	if mirrored: destination.size.x = -destination.size.x
	destination.position = origin+destination.position*scale_value
	destination.size *= scale_value
	return {"destination":destination,"source":source}

func draw_frame(canvas: Node2D, frame: Dictionary, origin: Vector2, scale_value := 1.0,
		alpha := 1.0, clip := Rect2()) -> void:
	var geometry := frame_geometry(frame,origin,scale_value,clip)
	if geometry.is_empty(): return
	canvas.draw_texture_rect_region(textures[frame.path],geometry.destination,geometry.source,Color(1,1,1,alpha))

func machine_origin(game: Node2D, index: int) -> Vector2:
	return Vector2(game.Level.CHECKPOINTS[index]-32,248)

func sleeping_frames(employee_id: String, clock_value: float, machine_index := -1) -> Array[Dictionary]:
	if (not stocked if machine_index < 0 else spent_checkpoints.has(machine_index)): return []
	var slots: Dictionary = art.machine.sleeping_occupants
	var sources: Array = art.sleeping_heroes.heroes[employee_id]
	var result: Array[Dictionary] = []
	for index in range(slots.count):
		var clock_offset: float = index*slots.second_slot_phase_seconds
		var frame_index := int((clock_value+clock_offset)/slots.animation_seconds_per_frame) % sources.size()
		var frame: Dictionary = sources[frame_index].duplicate(true)
		var source := rect(frame.source_rect)
		var feet: Array = slots.foot_anchors[index]
		var scale_value: float = slots.source_scale
		frame.destination = [feet[0]-slots.source_center_x*scale_value,
			feet[1]-slots.source_foot_y[employee_id]*scale_value,
			source.size.x*scale_value,source.size.y*scale_value]
		result.append({"frame":frame,"clip":rect(slots.clip_rects[index])})
	return result

func draw_machines(game: Node2D) -> void:
	game.draw_set_transform(Vector2(-floorf(game.camera_x),0))
	for index in range(game.Level.CHECKPOINTS.size()):
		var state := "activated" if index <= game.checkpoint_index else "idle"
		if active and index == checkpoint:
			state = "scan" if mode == "injured" and elapsed < inspection.timing_seconds.throw[0] \
				else "dispense" if mode != "full_health" else "activated"
		var origin := machine_origin(game,index)
		draw_frame(game,art.machine.states[state],origin)
		for occupant in sleeping_frames(game.employee.id,game.elapsed,index):
			draw_frame(game,occupant.frame,origin,1,1,occupant.clip)
		draw_frame(game,art.machine.glass_front,origin)

func draw_world(game: Node2D) -> void:
	if not active or mode in ["full_health","empty_arrival"]: return
	var origin := machine_origin(game,checkpoint)
	var states: Dictionary = art.heroes[hero].states
	var feet: Vector2 = game.respawn_point+Vector2(13,46)
	var times: Dictionary = inspection.timing_seconds
	if mode == "injured" and elapsed < times.throw[0]:
		var grab_feet := origin+Vector2(inspection.held_hero_feet[0],inspection.held_hero_feet[1])
		var progress := smoothstep(0,times.grab_lift[1],elapsed)
		var position: Vector2 = feet.lerp(grab_feet,progress)
		var state := "grab" if elapsed < times.compress[0] else "compress"
		var grip: Vector2 = position-origin-Vector2(0,38)
		draw_holding_arm(game,origin,grip,false)
		var held_frame: Dictionary = states[state]
		if state == "grab" and inspection.has("hero_states"):
			held_frame = inspection.hero_states[costume][hero].grab
		draw_frame(game,held_frame,position-Vector2(64,104))
		draw_holding_arm(game,origin,grip,true)
		draw_inspection_arm(game,origin)
		draw_diagnosis(game,origin)
	elif mode == "injured" and elapsed < times.slide_vend[0]:
		var grip := Vector2(34,67).lerp(Vector2(68,35),smoothstep(times.throw[0],times.throw[1],elapsed))
		draw_holding_arm(game,origin,grip,false)
		draw_holding_arm(game,origin,grip,true)
	else:
		if mode == "injured" and elapsed < times.slide_vend[0]+0.4:
			var retract := clampf((elapsed-times.slide_vend[0])/0.4,0,1)
			var grip := Vector2(68,35).lerp(Vector2(120,95),smoothstep(0,1,retract))
			draw_holding_arm(game,origin,grip,false,1-retract)
			draw_holding_arm(game,origin,grip,true,1-retract)
		var emergence_start: float = times.emerge[0] if mode == "injured" else 0.3
		if elapsed < emergence_start: return
		var local_time := elapsed-emergence_start
		var state := "emerge" if elapsed < times.look_left[0] else "look_left" if elapsed < times.look_right[0] \
			else "look_right" if elapsed < times.shrug[0] else "shrug"
		if mode == "respawn":
			state = "emerge" if elapsed < 0.9 else "look_left" if elapsed < 1.15 \
				else "look_right" if elapsed < 1.4 else "shrug"
		var exit_feet := origin+Vector2(82,166)
		if local_time < 0.2:
			var destination_origin := exit_feet-Vector2(64,104)
			var opening := rect(art.machine.attachment.opening_rect)
			opening.position -= destination_origin-origin
			draw_frame(game,states[state],destination_origin,1,1,opening)
			draw_frame(game,art.machine.foreground_trim,origin)
		else:
			var position: Vector2 = exit_feet.lerp(feet,clampf((local_time-0.2)/0.3,0,1))
			draw_frame(game,states[state],position-Vector2(64,104))

func draw_overlay(game: Node2D) -> void:
	if not overlay_visible(): return
	game.draw_set_transform(Vector2.ZERO)
	var states: Dictionary = art.heroes[hero].states
	var impact := impact_point
	var times: Dictionary = inspection.timing_seconds
	if elapsed < times.impact[0]:
		var progress := clampf((elapsed-times.throw[0])/0.5,0,1)
		var start := machine_origin(game,checkpoint)+Vector2(34,67)-Vector2(floorf(game.camera_x),0)
		var scale_value := lerpf(minf(0.4,impact_scale),impact_scale,progress)
		draw_frame(game,states.ball,start.lerp(impact,progress)-Vector2(64,64)*scale_value,scale_value)
	elif elapsed < times.slide_vend[0]:
		draw_frame(game,states.impact,impact-Vector2(64,64)*impact_scale,impact_scale)
	else:
		var progress := clampf((elapsed-times.slide_vend[0])/1.5,0,1)
		var alpha := 1.0-smoothstep(0.35,1.0,progress)
		# Residue stays on the screen while the X-eyed body slides; neither inherits camera movement.
		draw_frame(game,states.blood_trail,impact-Vector2(64,64)*impact_scale,impact_scale,alpha*0.65,
			Rect2(0,0,128,lerpf(30,132,progress)))
		draw_frame(game,states.slide,impact+Vector2(0,progress*270)-Vector2(64,64)*impact_scale,impact_scale,alpha)

func vector(values: Array) -> Vector2:
	return Vector2(values[0],values[1])

func diagnosis_fraction() -> float:
	return clampf(float(arrival_health)/arrival_max_health,0,1)

func draw_diagnosis(game: Node2D, origin: Vector2) -> void:
	var timing: Array = inspection.timing_seconds.diagnosis_visible
	if elapsed < timing[0] or elapsed >= timing[1] or not inspection.has("diagnosis_art"): return
	var pieces: Dictionary = inspection.diagnosis_art
	draw_frame(game,pieces.frame,origin)
	draw_frame(game,pieces.track,origin)
	var fill: Dictionary = pieces.fill.duplicate(true)
	fill.destination = pieces.aperture.duplicate()
	var amount := diagnosis_fraction()
	fill.destination[2] *= amount
	fill.source_rect[2] *= amount
	if amount > 0: draw_frame(game,fill,origin)
	if pieces.has("label_baseline"):
		game.label_at("HP %d / %d" % [arrival_health,arrival_max_health],
			origin+vector(pieces.label_baseline),10,Color("fff6d5"))

func elbow(start: Vector2, end: Vector2, first: float, second: float, bend: float) -> Vector2:
	var axis := (end-start).normalized()
	var distance := clampf(start.distance_to(end),absf(first-second)+0.001,first+second-0.001)
	var along := (first*first-second*second+distance*distance)/(2*distance)
	return start+axis*along+Vector2(-axis.y,axis.x)*sqrt(maxf(0,first*first-along*along))*bend

func articulated_part(game: Node2D, origin: Vector2, id: String, pivot_name: String,
		position: Vector2, rotation := 0.0, alpha := 1.0) -> void:
	if not inspection.get("parts",{}).has(id): return
	var part: Dictionary = inspection.parts[id]
	var pivot := vector(part.source_pivots[pivot_name])
	var source := rect(part.source_rect)
	game.draw_set_transform(origin+position-Vector2(floorf(game.camera_x),0),rotation)
	game.draw_texture_rect_region(textures[part.path],Rect2(-pivot*part.scale,source.size*part.scale),
		source,Color(1,1,1,alpha))
	game.draw_set_transform(Vector2(-floorf(game.camera_x),0))

func draw_holding_arm(game: Node2D, origin: Vector2, grip: Vector2, front: bool, alpha := 1.0) -> void:
	if inspection.get("parts",{}).is_empty(): return
	var closing := smoothstep(0,0.2,elapsed)
	closing *= 1-smoothstep(inspection.timing_seconds.throw[0],inspection.timing_seconds.throw[1],elapsed)
	var open_part: Dictionary = inspection.parts.hand_open
	var closed_part: Dictionary = inspection.parts.hand_grip
	var open_offset: Vector2 = (vector(open_part.source_pivots.wrist)-vector(open_part.source_pivots.grip))*open_part.scale
	var closed_offset: Vector2 = (vector(closed_part.source_pivots.wrist)-vector(closed_part.source_pivots.grip))*closed_part.scale
	var wrist := grip+open_offset.lerp(closed_offset,closing)
	if front:
		articulated_part(game,origin,"hand_open","grip",grip,0,alpha*(1-closing))
		articulated_part(game,origin,"hand_grip","grip",grip,0,alpha*closing)
		return
	var mount := vector(inspection.holding_arm_mount)
	var joint := elbow(mount,wrist,65,63.05,-1)
	articulated_part(game,origin,"holding_upper","mount",mount,(joint-mount).angle(),alpha)
	articulated_part(game,origin,"holding_fore","elbow",joint,(wrist-joint).angle()-PI,alpha)

func draw_inspection_arm(game: Node2D, origin: Vector2) -> void:
	var times: Dictionary = inspection.timing_seconds
	if elapsed < times.inspection_arm_deploy[0] or elapsed >= times.inspection_arm_retract[1]: return
	var progress := smoothstep(times.inspection_arm_deploy[0],times.inspection_arm_deploy[1],elapsed)
	progress *= 1-smoothstep(times.inspection_arm_retract[0],times.inspection_arm_retract[1],elapsed)
	var mount := vector(inspection.inspection_arm_mount)
	var lens := (mount+Vector2(0,-12)).lerp(vector(inspection.inspection_lens_center),progress)
	var part: Dictionary = inspection.parts.magnifier
	var handle: Vector2 = lens+(vector(part.source_pivots.handle)-vector(part.source_pivots.lens))*part.scale
	var joint := elbow(mount,handle,40.875,40.875,-1)
	articulated_part(game,origin,"inspection_segment","mount",mount,(joint-mount).angle(),progress)
	articulated_part(game,origin,"inspection_segment","mount",joint,(handle-joint).angle(),progress)
	articulated_part(game,origin,"magnifier","lens",lens,0,progress)
