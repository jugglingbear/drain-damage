extends RefCounted
## World adapter for ceiling spiders; the state module owns attack and escape timing.
const State = preload("res://scripts/devil_spider_state.gd")
const MANIFEST := "res://assets/bestiary/devil-spider-v1/manifest.json"
const BODY := Rect2(-48,0,96,108)
const ESCAPE_ACTIONS := ["left","right","aim_up","aim_down","jump","shoot","special",
	"aim_up_left_stationary","aim_up_right_stationary"]
var release_immunity := 0.0
var pending_press := false
var sampled_frame := -1
var captured: Dictionary = {}
var art_spec: Dictionary = {}
var trigger_held: Dictionary = {}
var release_decks: Array[Rect2] = []

func production_ready() -> bool:
	return FileAccess.file_exists(MANIFEST)

func locked() -> bool:
	return not captured.is_empty() and captured.hp > 0 and captured.devil.movement_locked()

func captured_actor() -> Dictionary:
	return captured if locked() else {}

func register(actor: Dictionary, event: Dictionary) -> void:
	actor.variant = "devil"
	actor.hp = 135.0
	actor.max_hp = 135.0
	actor.devil = State.new()
	actor.devil_webs = []
	actor.devil_events = []
	actor.devil_release_age = 1.0
	actor.devil_release_position = Vector2.ZERO
	actor.devil_release_kind = ""
	actor.devil_limits = event.get("devil_limits",Vector2(actor.home.x-90,actor.home.x+90))
	actor.devil_bounds = actor.devil_limits

func input_event(host: Node2D, event: InputEvent) -> void:
	var fresh_trigger := false
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT:
		var held: bool = trigger_held.get(event.device,false)
		if event.axis_value < 0.25: trigger_held[event.device] = false
		elif event.axis_value > 0.5:
			trigger_held[event.device] = true
			fresh_trigger = not held
	if host.paused or host.life_state != "alive" or host.dialogue.active or host.dialogue.release_guard > 0 \
			or host.dispenser.actions_locked or host.restart_guard_device >= 0 or not locked(): return
	if fresh_trigger:
		pending_press = true
		return
	if not (event is InputEventKey or event is InputEventJoypadButton): return
	if event.is_echo(): return
	for action in ESCAPE_ACTIONS:
		if event.is_action_pressed(action):
			pending_press = true
			return

func clear(host: Node2D, reason: String) -> void:
	if not captured.is_empty() and captured.devil.capture_kind == "cocoon": resolve_release(host)
	release_decks.clear()
	for actor: Dictionary in host.actors:
		if not actor.has("devil"): continue
		host.stop_trial_actions(actor)
		actor.devil.clear(reason)
		actor.devil_webs.clear()
		actor.devil_events = actor.devil.drain_events()
		actor.contact_live = false
	captured = {}
	release_immunity = 0
	pending_press = false
	sampled_frame = -1

func owner_killed(host: Node2D, actor: Dictionary) -> void:
	if not actor.has("devil"): return
	host.stop_trial_actions(actor)
	actor.devil.owner_killed()
	actor.devil_webs.clear()
	host.end_flyer_pattern(actor)
	consume_events(host,actor)

func sync_lifecycle(host: Node2D) -> void:
	if host.life_state != "alive" or host.won or host.result_shown:
		clear(host,"hero_inactive")
		return
	if not captured.is_empty() and (captured.hp <= 0 or not host.actors.has(captured)):
		owner_killed(host,captured)
	if host.paused or host.dialogue.active: pending_press = false

func step(host: Node2D, delta: float) -> void:
	sync_lifecycle(host)
	if host.paused or host.life_state != "alive" or host.dialogue.active or host.dispenser.active: return
	release_immunity = maxf(0,release_immunity-delta)
	var frame := Engine.get_physics_frames()
	if sampled_frame != frame:
		sampled_frame = frame
		if pending_press and locked():
			captured.devil.escape_press()
			consume_events(host,captured)
		pending_press = false
	for actor: Dictionary in host.actors:
		if not actor.has("devil"): continue
		actor.devil_release_age += delta
		if actor.hp <= 0 or not actor.active:
			host.stop_trial_actions(actor)
			continue
		var state = actor.devil
		actor.devil_events = []
		if not state.alive:
			state.start(actor.feet,actor.devil_limits,actor.facing)
			state.drain_events()
		var can_attack: bool = host.actor_rect(actor).position.x >= host.camera_x \
			and host.actor_rect(actor).end.x <= host.camera_x+960
		if host.has_method("crossing_reserved") and host.crossing_reserved(): can_attack = false
		if host.has_method("in_pressure_dip") and host.in_pressure_dip(): can_attack = false
		if not can_attack and state.state == "windup":
			host.stop_trial_actions(actor)
			state.state = "recover"
			state.state_time = 0
		if state.state == "crawl" and state.state_time+delta >= float(state.tuning.crawl_seconds):
			if not can_attack or (not actor.contact_live and not host.begin_flyer_pattern(actor)):
				state.state_time = 0
			else: actor.contact_live = true
		if state.capture_kind == "cocoon": state.captive_position = host.player+host.PLAYER_SIZE*0.5
		if state.state == "windup":
			actor.facing = -1.0 if host.player.x+host.PLAYER_SIZE.x*0.5 < state.position.x else 1.0
		update_emitter(actor)
		var was_cocoon: bool = state.capture_kind == "cocoon"
		var previous_state: String = state.state
		var previous: Vector2 = state.position
		state.step(delta,host.player+host.PLAYER_SIZE*0.5)
		state.position = sweep_body(host,previous,state.position,BODY)
		if not state.position.is_equal_approx(previous) and state.state == "crawl": actor.facing = state.direction
		elif state.state == "crawl" and not state.position.is_equal_approx(previous+Vector2(state.direction*35*delta,0)):
			state.direction *= -1
		actor.feet = state.position
		if state.state != previous_state:
			host.stop_trial_actions(actor)
			if state.state == "windup": host.play_trial_action(actor,"aim")
		if state.state == "crawl" and not state.position.is_equal_approx(previous):
			host.play_trial_action(actor,"crawl")
		elif state.state == "haul": host.play_trial_action(actor,"haul")
		if state.movement_locked(): host.play_trial_action(actor,"struggle")
		if not can_attack: host.stop_trial_actions(actor)
		# The mouth release clears capture_kind; still apply its final haul pose before bite damage.
		if was_cocoon:
			var desired: Vector2 = state.captive_position-host.PLAYER_SIZE*0.5
			host.player = desired
			state.captive_position = host.player+host.PLAYER_SIZE*0.5
			host.velocity = Vector2.ZERO
			host.grounded = false
		consume_events(host,actor)
		step_webs(host,actor,delta,can_attack)
		for trap: Dictionary in state.traps:
			var region := Rect2(trap.position-Vector2(20,5),Vector2(40,10))
			if host.grounded and region.intersects(Rect2(host.player,host.PLAYER_SIZE)):
				state.trigger_floor_trap(int(trap.id),host.player+host.PLAYER_SIZE*0.5,available(host,can_attack))
		consume_events(host,actor)
		if state.state not in ["windup","haul"] and actor.devil_webs.is_empty() and not state.movement_locked():
			host.end_flyer_pattern(actor)

func available(host: Node2D, permitted: bool) -> bool:
	return permitted and not locked() and release_immunity <= 0 and host.invulnerable <= 0 \
		and host.life_state == "alive"

func consume_events(host: Node2D, actor: Dictionary) -> void:
	for event: Dictionary in actor.devil.drain_events():
		actor.devil_events.append(event)
		match event.event:
			"tear":
				host.play_trial_action(actor,"tear")
			"trap_spawned":
				host.play_trial_action(actor,"attach")
			"web_fired":
				host.stop_trial_actions(actor)
				host.play_trial_action(actor,"launch")
				actor.devil_webs.append({"id":event.id,"pos":event.origin,"previous":event.origin,
					"velocity":event.velocity,"travel":0.0})
			"captured":
				host.stop_trial_actions(actor)
				host.play_trial_action(actor,"capture")
				release_decks.clear()
				captured = actor
				pending_press = false
				host.velocity = Vector2.ZERO
				host.jump_buffer = 0
				# Main Break is already deployed in the world; restraining Sean cannot turn off the rain.
				if not (host.specials.active and host.specials.hero_id == "sean"):
					host.specials.cancel("web_capture")
					host.special_audio.stop()
			"released":
				host.stop_trial_actions(actor)
				if event.reason == "escaped": host.play_trial_action(actor,"escape")
				actor.devil_release_age = 0.0
				actor.devil_release_position = event.position
				actor.devil_release_kind = event.kind
				if captured == actor:
					if event.kind == "cocoon":
						resolve_release(host)
						actor.devil_release_position = host.player+host.PLAYER_SIZE*0.5
					captured = {}
				pending_press = false
				release_immunity = maxf(release_immunity,float(event.immunity))
			"ordinary_hit":
				host.play_trial_action(actor,"hunger")
				if (host.player+host.PLAYER_SIZE*0.5).distance_to(actor.devil.mouth_position()) <= 1.0:
					host.hurt_player()

func sweep_body(host: Node2D, origin: Vector2, destination: Vector2, shape: Rect2) -> Vector2:
	var closest := 1.0
	for solid: Rect2 in host.actor_solids():
		var expanded := Rect2(solid.position-shape.end,solid.size+shape.size)
		if (origin.x <= expanded.position.x+0.00001 and destination.x <= origin.x) \
				or (origin.x >= expanded.end.x-0.00001 and destination.x >= origin.x) \
				or (origin.y <= expanded.position.y+0.00001 and destination.y <= origin.y) \
				or (origin.y >= expanded.end.y-0.00001 and destination.y >= origin.y): continue
		var hit: float = host.segment_hit(origin,destination,expanded)
		if hit >= 0: closest = minf(closest,maxf(0,hit-0.001))
	return origin.lerp(destination,closest)

func step_webs(host: Node2D, actor: Dictionary, delta: float, permitted: bool) -> void:
	for index in range(actor.devil_webs.size()-1,-1,-1):
		var web: Dictionary = actor.devil_webs[index]
		var start: Vector2 = web.pos
		var finish: Vector2 = start+web.velocity*delta
		var fraction := 1.0
		var obstacle := Rect2()
		for solid: Rect2 in host.player_shot_solids():
			var hit: float = host.segment_hit(start,finish,solid.grow(3))
			if hit >= 0 and hit <= fraction:
				fraction = hit
				obstacle = solid
		var tail: Vector2 = start-Vector2(web.velocity).normalized()*minf(64,float(web.get("travel",0)))
		var hero_hit: float = host.segment_hit(start,finish,Rect2(host.player,host.PLAYER_SIZE).grow(2.5))
		if hero_hit < 0 and host.segment_hit(tail,start,Rect2(host.player,host.PLAYER_SIZE).grow(2.5)) >= 0:
			hero_hit = 0.0
		if hero_hit >= 0 and hero_hit < fraction:
			actor.devil.projectile_hit_player(int(web.id),host.player+host.PLAYER_SIZE*0.5,available(host,permitted))
			actor.devil_webs.remove_at(index)
		elif obstacle.has_area():
			var point := start.lerp(finish,fraction)
			var floor_hit: bool = web.velocity.y > 0 and absf(point.y-(obstacle.position.y-3)) < 0.1
			if floor_hit: point.y = obstacle.position.y
			actor.devil.projectile_hit_solid(int(web.id),point,floor_hit)
			actor.devil_webs.remove_at(index)
		elif finish.x < host.camera_x-64 or finish.x > host.camera_x+1024 or finish.y > 560 or finish.y < -64:
			actor.devil.projectiles.erase(web.id)
			actor.devil_webs.remove_at(index)
		else:
			web.previous = start
			web.pos = finish
			web.travel = float(web.get("travel",0))+start.distance_to(finish)

func update_emitter(actor: Dictionary) -> void:
	# The emitted projectile and initial taut line originate at the registered fire pose.
	if art_spec.is_empty() and production_ready():
		art_spec = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if art_spec.is_empty(): return
	var id: String = art_spec.states.fire.frames[0]
	for frame: Dictionary in art_spec.frames:
		if frame.id != id: continue
		var local := Vector2(frame.web_emitter[0],frame.web_emitter[1])-Vector2(64,12)
		local.x *= actor.facing
		actor.devil.tuning.mouth_offset = local
		return

func placements(host: Node2D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if host.has_method("event_specs"):
		for spec: Dictionary in host.event_specs():
			if spec.get("variant","") == "devil":
				result.append({"home":spec.feet,"devil_bounds":spec.devil_limits,"bounds":spec.devil_limits})
	elif host.has_method("route_home"):
		for event: Dictionary in host.run_plan.later:
			if event.id == "clog-approach-06":
				result.append({"home":Vector2(10920,110),"devil_bounds":Vector2(10820,11040),
					"bounds":Vector2(10820,11040)})
	return result

func resolve_release(host: Node2D) -> void:
	# One-way plates may be crossed downward; solid machinery must never retain an embedded body.
	release_decks.clear()
	var position: Vector2 = host.player
	var size: Vector2 = host.PLAYER_SIZE
	var solids: Array[Rect2] = []
	for rect: Rect2 in host.actor_solids():
		if rect not in host.trial_level.decks: solids.append(rect)
	# Each raise eliminates at least one overlapping top. Rechecking the complete union also
	# handles a sink lip above its basin and adjacent taller machinery, without choosing a seam.
	for iteration in range(solids.size()+1):
		var top := position.y
		var body := Rect2(position,size).grow(-0.001)
		for rect in solids:
			if body.intersects(rect): top = minf(top,rect.position.y-size.y)
		if is_equal_approx(top,position.y): break
		position.y = top
	host.player = position
	host.velocity = Vector2.ZERO
	host.grounded = false
	host.jump_buffer = 0
	for rect: Rect2 in host.trial_level.decks:
		if Rect2(position,size).grow(-0.001).intersects(rect): release_decks.append(rect)

func move_body(host: Node2D, position: Vector2, motion: Vector2, size: Vector2, delta: float) -> Dictionary:
	# The exemption belongs only to the released hero and exact intersected one-way decks.
	# Restore geometry synchronously so monsters, projectiles and other actors never inherit it.
	if size != host.PLAYER_SIZE or release_decks.is_empty():
		return host.trial_level.move_body(position,motion,size,delta)
	for index in range(release_decks.size()-1,-1,-1):
		if not Rect2(position,size).grow(-0.001).intersects(release_decks[index]):
			release_decks.remove_at(index)
	var original: Array[Rect2] = host.trial_level.decks
	var filtered: Array[Rect2] = []
	for rect in original:
		if rect not in release_decks: filtered.append(rect)
	host.trial_level.decks = filtered
	var result: Dictionary = host.trial_level.move_body(position,motion,size,delta)
	host.trial_level.decks = original
	for index in range(release_decks.size()-1,-1,-1):
		if not Rect2(result.pos,size).grow(-0.001).intersects(release_decks[index]):
			release_decks.remove_at(index)
	return result
