extends RefCounted
## Registered source poses and independent silk effects; all positions are world coordinates.
const MANIFEST := "res://assets/bestiary/devil-spider-v1/manifest.json"
const EFFECTS := "res://assets/bestiary/devil-spider-v1/web-effects-manifest-v1.json"
var spec: Dictionary = {}
var effects: Dictionary = {}
var frames: Dictionary = {}
var support: Dictionary = {}
var death_spec: Dictionary = {}
var web_line: Dictionary = {}

func prepare(host: Node, yield_frame := Callable()) -> void:
	spec = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	effects = JSON.parse_string(FileAccess.get_file_as_string(EFFECTS))
	support = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/bestiary/devil-spider-v1/support-manifest-v1.json"))
	support.path = support.source
	for frame: Dictionary in spec.frames: frames[frame.id] = frame
	for component: Dictionary in effects.components.values():
		component.path = effects.source
		component.alpha_cutoff = effects.alpha_cutoff
	await host.load_trial_textures(spec,yield_frame)
	await host.load_trial_textures(effects,yield_frame)
	await host.load_trial_textures(support,yield_frame)
	death_spec = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/bestiary/devil-spider-v1/death-manifest-v2.json"))
	web_line = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/bestiary/devil-spider-v1/web-line-manifest-v2.json"))
	for frame: Dictionary in death_spec.frames+death_spec.head_props+[death_spec.ash]:
		frame.path = death_spec.source
		frame.alpha_cutoff = death_spec.alpha_cutoff
	for frame: Dictionary in web_line.components.values():
		frame.path = web_line.source
		frame.alpha_cutoff = web_line.alpha_cutoff
	await host.load_trial_textures(death_spec,yield_frame)
	await host.load_trial_textures(web_line,yield_frame)

func pose(actor: Dictionary) -> Dictionary:
	if frames.is_empty(): return {}
	var model = actor.devil
	var state: String = model.state
	var clock: float = model.state_time
	if state == "recover":
		if clock < 0.1: state = "fire"
		elif clock < 0.24:
			state = "recover"
			clock -= 0.1
		else:
			state = "idle"
			clock -= 0.24
	if not spec.states.has(state): state = "idle"
	if actor.flash > 0:
		state = "hurt"
		clock = 0.1-actor.flash
	if actor.hp <= 0:
		state = "death"
		clock = actor.death
	var animation: Dictionary = spec.states[state]
	var duration := 0.0
	for value in animation.durations: duration += float(value)
	if animation.loop: clock = fposmod(clock,duration)
	for index in range(animation.frames.size()):
		if clock < float(animation.durations[index]): return frames[animation.frames[index]]
		clock -= float(animation.durations[index])
	return frames[animation.frames.back()]

func point(actor: Dictionary, frame: Dictionary, key: String) -> Vector2:
	var local := Vector2(frame[key][0],frame[key][1])-Vector2(64,12)
	local.x *= actor.facing
	return actor.feet+local

func draw(host: Node2D, actor: Dictionary, entry_render := false) -> void:
	if actor.hp <= 0: return # Independent death snapshots survive live-actor retirement.
	var frame := pose(actor)
	if frame.is_empty(): return
	var destination: Rect2 = host.region(frame.destination)
	destination.position -= Vector2(64,12)
	var entry_scale := float(actor.entry.scale) if entry_render else 1.0
	host.draw_set_transform(actor.feet-Vector2(floorf(host.camera_x),0),0,
		Vector2(actor.facing,1)*entry_scale)
	host.draw_asset(frame,destination,Color(1,1,1,1-clampf(actor.death/0.6,0,1)))
	host.draw_set_transform(Vector2(-floorf(host.camera_x),0))
	if actor.hp > 0 and actor.active and host.show_enemy_health_bars:
		var body: Rect2 = host.actor_rect(actor)
		host.draw_rect(Rect2(body.position+Vector2(0,-8),Vector2(body.size.x,3)),Color("243447"))
		host.draw_rect(Rect2(body.position+Vector2(0,-8),Vector2(body.size.x*actor.hp/actor.max_hp,3)),host.MINT)

func component(host: Node2D, name: String, position: Vector2) -> void:
	if not effects.get("components",{}).has(name): return
	var part: Dictionary = effects.components[name]
	var destination: Rect2 = host.region(part.destination)
	destination.position += position
	host.draw_asset(part,destination)

func torn_component(host: Node2D, name: String, position: Vector2, progress: float) -> void:
	var part: Dictionary = effects.components[name]
	var destination: Rect2 = host.region(part.destination)
	var source: Rect2 = host.region(part.source_rect)
	# Each accepted escape press widens the existing torn halves; it never redraws silk procedurally.
	for side in range(2):
		var half := part.duplicate(true)
		var target := Rect2(destination.position+position,destination.size)
		if name.begins_with("cocoon"):
			half.source_rect = [source.position.x,source.position.y+source.size.y*0.5*side,source.size.x,source.size.y*0.5]
			target.size.y *= 0.5
			target.position.y += destination.size.y*0.5*side+(1 if side else -1)*progress*8
		else:
			half.source_rect = [source.position.x+source.size.x*0.5*side,source.position.y,source.size.x*0.5,source.size.y]
			target.size.x *= 0.5
			target.position.x += destination.size.x*0.5*side+(1 if side else -1)*progress*12
		host.draw_asset(half,target)

func draw_support(host: Node2D, actor: Dictionary) -> void:
	if support.is_empty(): return
	var bounds: Vector2 = actor.get("devil_bounds",actor.get("bounds",Vector2(actor.home.x,actor.home.x)))
	var left := bounds.x-60
	var width := bounds.y-bounds.x+120
	var source: Rect2 = host.region(support.source_rect)
	var widths := [22.0,width-45.0,23.0]
	var crops := [120.0,source.size.x-248.0,128.0]
	var x := left
	var sx := source.position.x
	for index in range(3):
		var part := support.duplicate(true)
		part.source_rect = [sx,source.position.y,crops[index],source.size.y]
		host.draw_asset(part,Rect2(x,actor.home.y-17,widths[index],18))
		x += widths[index]
		sx += crops[index]

func cord(host: Node2D, start: Vector2, end: Vector2) -> void:
	var length := start.distance_to(end)
	if length < 0.1: return
	var part: Dictionary = effects.components.silk_tile
	host.draw_set_transform(start-Vector2(floorf(host.camera_x),0),(end-start).angle())
	var offset := 0.0
	while offset < length:
		var width := minf(48,length-offset)
		var crop := part.duplicate(true)
		crop.source_rect[2] *= width/48.0
		host.draw_asset(crop,Rect2(offset,-1.5,width,3))
		offset += 46
	host.draw_set_transform(Vector2(-floorf(host.camera_x),0))

func draw_effects(host: Node2D) -> void:
	draw_debris(host)
	if effects.is_empty(): return
	for actor: Dictionary in host.actors:
		if actor.get("variant","") != "devil" or not actor.has("devil"): continue
		var model = actor.devil
		for web: Dictionary in actor.get("devil_webs",[]):
			host.draw_set_transform(web.pos-Vector2(floorf(host.camera_x),0),Vector2(web.velocity).angle())
			var tip: Dictionary = web_line.components.tip.duplicate(true)
			var length := minf(64,float(web.get("travel",64)))
			var source_width := float(tip.source_rect[2])
			tip.source_rect[0] += source_width*(1-length/64.0)
			tip.source_rect[2] *= length/64.0
			if length > 0:
				var destination: Rect2 = host.region(tip.destination)
				destination.position.x = -length
				destination.size.x = length
				# Reuse the silk silhouette to keep the narrow projectile legible over bright pipes.
				for offset in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
					host.draw_asset(tip,Rect2(destination.position+offset,destination.size),Color(0.08,0.1,0.12))
				host.draw_asset(tip,destination)
			host.draw_set_transform(Vector2(-floorf(host.camera_x),0))
		for trap: Dictionary in model.traps:
			var name := "snare_torn" if model.capture_trap == int(trap.id) and model.presses > 0 else "snare_intact"
			if name == "snare_torn": torn_component(host,name,trap.position,model.tear_progress())
			else: component(host,name,trap.position)
		if model.capture_kind == "cocoon":
			var feet: Vector2 = host.player+Vector2(host.PLAYER_SIZE.x*0.5,host.PLAYER_SIZE.y)
			var frame := pose(actor)
			var grip: Array = frame.silk_grips[0]
			var local := Vector2(grip[0],grip[1])-Vector2(64,12)
			local.x *= actor.facing
			cord(host,actor.feet+local,feet-Vector2(0,55))
			if model.presses > 0: torn_component(host,"cocoon_torn",feet,model.tear_progress())
			else: component(host,"cocoon_intact",feet)
		if float(actor.get("devil_release_age",1)) < 0.3:
			var name := "cocoon_break" if actor.get("devil_release_kind","") == "cocoon" else "snare_break"
			var part: Dictionary = effects.components[name]
			var target: Rect2 = host.region(part.destination)
			target.position += Vector2(actor.devil_release_position)+Vector2(0,host.PLAYER_SIZE.y*0.5)
			host.draw_asset(part,target,Color(1,1,1,1-float(actor.devil_release_age)/0.3))

func draw_debris(host: Node2D) -> void:
	for death: Dictionary in host.devil_debris.deaths:
		if death.age >= float(death_spec.ash.release_seconds): continue
		var frame: Dictionary = death_spec.frames[0 if death.age < death_spec.head_release_seconds else 1]
		var destination: Rect2 = host.region(frame.destination)
		destination.position -= Vector2(64,12)
		host.draw_set_transform(death.origin-Vector2(floorf(host.camera_x),0),0,Vector2(death.facing,1))
		var flicker := 1.0+0.12*sin(death.age*70)
		host.draw_asset(frame,destination,Color(flicker,flicker,1))
	for prop: Dictionary in host.devil_debris.props:
		var part: Dictionary = prop.definition
		var destination: Rect2 = host.region(part.destination)
		if prop.kind == "ash":
			var settle := clampf(prop.age/1.5,0,1)
			destination.size.y *= lerpf(1,0.2,settle)
			destination.position.y = prop.bottom-destination.size.y
		# Settle heads upright so their authored contact envelope matches the visible bottom.
		host.draw_set_transform(prop.pos-Vector2(floorf(host.camera_x),0),0 if prop.landed else prop.angle)
		host.draw_asset(part,destination)
	host.draw_set_transform(Vector2(-floorf(host.camera_x),0))
