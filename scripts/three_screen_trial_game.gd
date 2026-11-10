extends "res://scripts/opening_trial_game.gd"
## Separate finite comparison route. Production encounters and their budgets are untouched.
const ThreeLevel = preload("res://scripts/three_screen_trial_level.gd")
const CONTRACT_PATH := "res://levels/first-call/three-screen-trial.json"
const ART_PATH := "res://assets/world/three-screen-trial/manifest.json"
const BULLET_RADIUS := 4.0
const BULLET_SPEED := 220.0
const TRAVEL_SECONDS := 0.6
const SETTLE_SECONDS := 0.2
const BACKGROUND_TINT := Color(0.65, 0.70, 0.75)
const DECK_TINT := Color(1.15, 1.15, 1.15)
var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
var difficulty := "normal"
var seed_override := 42
var run_seed := 42
var tuning: Dictionary = {}
var ledger: Dictionary = {}
var trial_clock := 0.0
var next_warning := 0.0
var pit_falling := false
var shot_log: Array[Dictionary] = []
var arrival_log: Array[Dictionary] = []
var scene_art: Dictionary = {}
var scene_textures: Dictionary = {}
const ArrivalAudio = preload("res://scripts/three_screen_arrival_audio.gd")
var arrival_audio := ArrivalAudio.new()
var suppressed_volleys := 0
var crossing_until := 0.0
var crossing_airborne := false
var pressure_log: Array[Dictionary] = []
var next_pressure_sample := 0.0
var shooter_stats: Dictionary = {}

func _ready() -> void:
	if FileAccess.file_exists(ART_PATH):
		scene_art = JSON.parse_string(FileAccess.get_file_as_string(ART_PATH))
		configure_scene_art()
		load_trial_textures(scene_art)
	super._ready()
	arrival_audio.attach(self)

func configure_scene_art() -> void:
	pass

func trial_name() -> String:
	return str(contract.get("display_name","Three-Screen Trial"))

func reset_observation() -> void:
	super.reset_observation()
	arrival_audio.stop()
	suppressed_volleys = 0
	trial_level = ThreeLevel.new()
	trial_level.configure(contract)
	respawn_point = Vector2(contract.world.spawn_feet[0]-PLAYER_SIZE.x*0.5,contract.world.spawn_feet[1]-PLAYER_SIZE.y)
	player = respawn_point
	tuning = contract.difficulty[difficulty].duplicate(true)
	var aggressive: Dictionary = contract.aggressive_replacement.difficulty[difficulty]
	tuning.total_actors_max = aggressive.actor_cap
	tuning.active_patterns_max = aggressive.pattern_cap
	tuning.hostile_projectiles_max = aggressive.projectile_cap
	tuning.speed_multiplier = aggressive.projectile_speed_multiplier
	tuning.burst_count = aggressive.burst_count
	tuning.shot_warning_seconds = 0.55
	tuning.burst_spacing_seconds = 0.18
	tuning.recovery_seconds = float(aggressive.get("recovery_seconds",1.2))
	tuning.shooter_cap = int(aggressive.get("shooter_cap",tuning.total_actors_max))
	tuning.flyer_cap = int(aggressive.get("flyer_cap",tuning.total_actors_max))
	crossing_until = 0
	crossing_airborne = false
	pressure_log.clear()
	shooter_stats.clear()
	next_pressure_sample = 0
	run_seed = seed_override if seed_override >= 0 else 42
	trial_clock = 0
	next_warning = 0
	pit_falling = false
	shot_log.clear()
	arrival_log.clear()
	corpses.clear()
	particles.clear()
	ledger.clear()
	dialogue.costume = difficulty
	dialogue.hard_portraits = difficulty == "hard"
	world_art.hero_aim_art.configure(difficulty)
	for spec in event_specs():
		ledger[spec.id] = "pending"

func event_specs() -> Array[Dictionary]:
	var envelope: Array = contract.geometry.mandatory_climb.runner_pursuit.horizontal_body_envelope
	var climb_bounds := Vector2(envelope[0]+FlushfiendGeometry.BODY_SIZE.x*0.5,envelope[1]-FlushfiendGeometry.BODY_SIZE.x*0.5)
	var specs: Array[Dictionary] = [
		{"id":"opening-runner-a", "role":"runner", "trigger":180, "end":900,
			"feet":Vector2(500,440), "bounds":Vector2(220,880), "depth":""},
		{"id":"opening-runner-b", "role":"runner", "trigger":180, "end":900,
			"feet":Vector2(820,440), "bounds":Vector2(220,880), "depth":""},
		{"id":"opening-single", "role":"perched_shooter", "trigger":120, "end":900,
			"feet":Vector2(780,320), "bounds":Vector2(780,780), "depth":""},
		{"id":"background-entry", "role":"runner", "trigger":960, "end":1780,
			"feet":Vector2(1590,380), "source":Vector2(1590,240), "bounds":climb_bounds, "depth":"background"},
		{"id":"climb-runner", "role":"runner", "trigger":1120, "end":1780,
			"feet":Vector2(1740,440), "bounds":climb_bounds, "depth":""},
		{"id":"climb-burst", "role":"perched_shooter", "trigger":1180, "end":1780,
			"feet":Vector2(1460,320), "bounds":Vector2(1460,1460), "depth":""},
		{"id":"foreground-entry", "role":"runner", "trigger":1650, "end":2040,
			"feet":Vector2(1920,440), "source":Vector2(1920,600), "bounds":Vector2(1840,2010), "depth":"foreground"},
		{"id":"final-exchange", "role":"perched_shooter", "trigger":2210, "end":2880,
			"feet":Vector2(2800,440), "bounds":Vector2(2800,2800), "depth":""},
	]

	# Finite authored reinforcements; each ID is issued at most once per life.
	var ground := [Vector2(600,440),Vector2(850,440),Vector2(360,440),Vector2(1040,440),
		Vector2(1160,380),Vector2(1540,380),Vector2(1770,440),Vector2(1990,440),
		Vector2(2490,440),Vector2(2740,440)]
	var perches := [Vector2(620,320),Vector2(920,440),Vector2(1320,320),Vector2(1760,440),Vector2(2700,440)]
	var air := [Vector2(620,200),Vector2(870,180),Vector2(1280,190),Vector2(1680,180),
		Vector2(2100,190),Vector2(2710,190)]
	for role in ["runner","perched_shooter","aggressive_flyer","swarm"]:
		var points: Array = ground if role == "runner" else perches if role == "perched_shooter" else air \
			if role == "aggressive_flyer" else [Vector2(780,220),Vector2(1650,220),Vector2(2700,220)]
		for index in range(points.size()):
			var point: Vector2 = points[index]
			var limits := Vector2(220,1000) if point.x < 1000 else climb_bounds if point.x < 2040 \
				else Vector2(2500,2840) if point.x > 2360 else Vector2(1810,2160)
			specs.append({"id":"pressure-%s-%d" % [role,index],"role":role,
				"trigger":maxf(100,point.x-550),"end":2880,"feet":point,"bounds":limits,"depth":""})
	return authored_entries(specs)

func authored_entries(specs: Array[Dictionary]) -> Array[Dictionary]:
	for spec in specs:
		var override: Dictionary = contract.get("entry_assignments",{}).get(spec.id,{})
		for key in ["entry","feet","bounds"]:
			if override.has(key): spec[key] = override[key].duplicate(true)
		for key in ["feet","bounds","source"]:
			if spec.has(key) and spec[key] is Array: spec[key] = Vector2(spec[key][0],spec[key][1])
		if spec.has("entry"):
			spec.entry = spec.entry.duplicate(true)
			if spec.entry.has("source") and spec.entry.source is Array:
				spec.entry.source = Vector2(spec.entry.source[0],spec.entry.source[1])
	for spec in specs:
		if spec.id not in ["pressure-aggressive_flyer-0","b-fly1"]: continue
		spec.variant = "devil"
		spec.feet = Vector2(620,110) if spec.id == "pressure-aggressive_flyer-0" else Vector2(1580,110)
		spec.devil_limits = Vector2(480,760) if spec.id == "pressure-aggressive_flyer-0" else Vector2(1450,1690)
		spec.bounds = spec.devil_limits
		spec.entry = {"mode":"top"}
	return specs

func entry_route(spec: Dictionary) -> Dictionary:
	if not spec.has("entry"): return {}
	var authored: Dictionary = spec.entry
	var mode: String = authored.mode
	if mode not in ["left","right","top","bottom","floor","ceiling","foreground","background"]: return {}
	if spec.role == "perched_shooter" and mode not in ["floor","ceiling"]: return {}
	var radius: float = 128 if spec.role == "swarm" else ceiling_shooter_art.radius() if mode == "ceiling" else actor_render_radius(spec.role)
	var source: Vector2 = authored.get("source",Vector2.INF)
	var waypoints: Array[Vector2] = []
	if mode == "bottom":
		if crossing_reserved(): return {}
		source = Vector2((trial_level.pit.x+trial_level.pit.y)*0.5,540+radius+32)
		waypoints.append(Vector2(source.x,280))
	var mouth: Vector2 = source if mode == "background" else Vector2.ZERO
	var duration: float = authored.get("duration",float(tuning.arrival_warning_seconds)+TRAVEL_SECONDS+SETTLE_SECONDS 		if mode in ["foreground","background"] else 1.2)
	# Edge arrivals finish at the first fully visible position. Crossing the room is ordinary combat.
	var destination: Vector2 = spec.feet
	if mode == "left": destination.x = camera_x+radius+2
	elif mode == "right": destination.x = camera_x+960-radius-2
	var route := MonsterEntry.create(destination,radius,duration,mode,mouth,camera_x,player+PLAYER_SIZE*0.5,
		source if mode != "background" else Vector2.INF,waypoints)
	MonsterEntry.advance(route,0)
	if mode in ["left","right","bottom"]:
		route.duration = maxf(route.duration,route.length/(240 if spec.role == "runner" else 450))
	if mode in ["left","right","top","bottom"]:
		var shape := swarm_cloud_bounds() if spec.role == "swarm" else render_bounds(spec.role)
		if Rect2(route.start+shape.position,shape.size).intersects(Rect2(camera_x,0,960,540)): return {}
		for index in range(1,route.path.size()):
			var start: Vector2 = route.path[index-1]
			var finish: Vector2 = route.path[index]
			for solid in actor_solids():
				var expanded := Rect2(solid.position-shape.end,solid.size+shape.size).grow(-0.01)
				if segment_hit(start,finish,expanded) >= 0: return {}
			if spec.role == "runner":
				if not is_equal_approx(start.y,finish.y): return {}
				for step in range(ceili(absf(finish.x-start.x)/8)+1):
					var x := lerpf(start.x,finish.x,float(step)/maxf(1,ceili(absf(finish.x-start.x)/8)))
					if x < 0 or x > actor_world_limit(): continue
					var supported := false
					for solid in actor_solids():
						if is_equal_approx(solid.position.y,finish.y) and x >= solid.position.x and x <= solid.end.x:
							supported = true
					if not supported: return {}
	return route

func swarm_cloud_bounds() -> Rect2:
	var result := Rect2()
	for point in swarms.formations.formations.cloud.anchors:
		var glyph := Rect2(Vector2(point[0],point[1])-Vector2(70,70),Vector2(12,12))
		result = result.merge(glyph) if result.has_area() else glyph
	return result

func actor_world_limit() -> float: return float(contract.world.width)

func actor_solids() -> Array[Rect2]:
	var solids := trial_level.actor_solids()
	solids.append_array(trial_level.floor_solids())
	return solids

func player_shot_solids() -> Array[Rect2]:
	var solids := trial_level.projectile_solids()
	solids.append_array(trial_level.floor_solids())
	return solids

func special_floor_solids() -> Array[Rect2]:
	return trial_level.floor_solids()

func move_player_body(position: Vector2, motion: Vector2, size: Vector2, delta: float) -> Dictionary:
	if size == PLAYER_SIZE and devil_spiders.locked() and devil_spiders.captured_actor().devil.capture_kind == "snare":
		return {"pos":position,"velocity":Vector2.ZERO,"grounded":true,"falling":false}
	var result := devil_spiders.move_body(self,position,motion,size,delta)
	if result.falling: pit_falling = true
	return result

func hurt_player() -> void:
	var before := player
	var previous_health := health
	super.hurt_player()
	if health < previous_health:
		# Shared damage applies an immediate shove; sweep that displacement through trial solids.
		var shove := Vector2(player.x-before.x,0)
		player = move_player_body(before,shove,PLAYER_SIZE,1.0).pos

func live_population() -> int:
	var count := 0
	for actor in actors:
		if actor.hp > 0: count += 1
	for swarm in swarms.actors:
		if swarm.hp > 0: count += 1
	return count

func pattern_owners() -> Dictionary:
	var owners := {}
	for actor in actors:
		if actor.hp <= 0: continue
		if actor.contact_live or actor.winding or actor.volley_left > 0 \
			or (not actor.depth.is_empty() and not actor.active): owners[actor.event_id] = true
	for swarm in swarms.actors:
		if swarm.hp > 0 and swarm.get("pattern_live",false): owners[swarm.event_id] = true
	for bullet in hostile_shots: owners[bullet.owner] = true
	return owners

func can_pattern(id: String) -> bool:
	var owners := pattern_owners()
	return owners.has(id) or owners.size() < int(tuning.active_patterns_max)

func arrival_safe(actor: Dictionary) -> bool:
	var bounds := actor_shape(actor)
	var body := Rect2(actor.home + bounds.position, bounds.size)
	if body.grow(45).intersects(Rect2(player,PLAYER_SIZE)): return false
	# Reserve the current ballistic landing, not a moving destination that follows the hero.
	var remaining := maxf(0, (-(velocity.y) + sqrt(velocity.y * velocity.y + 2 * GRAVITY *
		maxf(0, actor.home.y - (player.y + PLAYER_SIZE.y)))) / GRAVITY)
	var predicted := Rect2(player + Vector2(velocity.x * remaining, actor.home.y - player.y - PLAYER_SIZE.y), PLAYER_SIZE)
	if not grounded and body.grow(32).intersects(predicted): return false
	for other in actors:
		if other.event_id != actor.event_id and other.hp > 0 and body.grow(12).intersects(Rect2((other.home if not other.active else other.feet)+actor_shape(other).position,actor_shape(other).size)):
			return false
	return true

func issue_event() -> void:
	var specs := event_specs()
	var shooters := 0
	var flyers := 0
	for actor in actors:
		if actor.hp > 0 and actor.role == "perched_shooter": shooters += 1
		if actor.hp > 0 and actor.role == "aggressive_flyer": flyers += 1
	if not actors.is_empty() and shooters < 2:
		specs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return a.role == "perched_shooter" and b.role != "perched_shooter")
	for spec in specs:
		if ledger[spec.id] != "pending": continue
		if player.x >= spec.end:
			ledger[spec.id] = "expired"
			continue
		if player.x < spec.trigger or trial_clock < next_warning: continue
		if spec.id == "opening-single" and ledger["opening-runner-a"] == "pending": continue
		if live_population() >= int(tuning.total_actors_max): continue
		# Count living arrivals too; defer admission instead of deleting visible enemies.
		if spec.role == "perched_shooter" and shooters >= int(tuning.shooter_cap): continue
		if spec.role == "aggressive_flyer" and flyers >= int(tuning.flyer_cap): continue
		if not spec.depth.is_empty() and not can_pattern(spec.id): continue
		if spec.feet.x < camera_x + 40 or spec.feet.x > camera_x + 920: continue
		var route := entry_route(spec)
		if route.is_empty(): continue
		if spec.role == "swarm":
			if Rect2(spec.feet-Vector2(90,90),Vector2(180,180)).intersects(Rect2(player,PLAYER_SIZE)): continue
			var wander_bounds := Rect2(spec.bounds.x,80,spec.bounds.y-spec.bounds.x,340)
			if spec.entry.mode in ["left","right"]:
				wander_bounds = wander_bounds.merge(Rect2(route.home-Vector2(64,64),Vector2(128,128)))
			var swarm: Dictionary = swarms.spawn(route.home,wander_bounds,
				run_seed+ledger.keys().find(spec.id))
			swarm.merge({"event_id":spec.id,"warning":float(tuning.arrival_warning_seconds),
				"additive":true,"contact_ready":false,"pattern_live":false})
			swarm.entry = route
			swarm.pos = route.pos
			swarms.actors.append(swarm)
			ledger[spec.id] = "active"
			next_warning = trial_clock+0.25
			return
		create_actor({"id":spec.id,"role":spec.role,"warning_seconds":tuning.arrival_warning_seconds,
			"variant":spec.get("variant",""),"devil_limits":spec.get("devil_limits",spec.bounds)},spec.feet)
		var actor: Dictionary = actors.back()
		actor.merge({"depth":spec.depth, "source":spec.get("source",spec.feet), "bounds":spec.bounds,
			"end":spec.end, "mount":"ceiling" if spec.entry.mode == "ceiling" else "floor" if spec.entry.mode == "floor" else "", "phase":"warning", "volley_left":0, "volley_clock":0.0,
			"volley_index":0, "recovery":0.0, "warn_clock":0.0, "committed_dir":Vector2.ZERO,
			"activation_time":-1.0, "warning_started":trial_clock},true)
		actor.home = route.home
		if spec.entry.mode in ["left","right"]:
			actor.bounds = Vector2(minf(actor.bounds.x,actor.home.x),maxf(actor.bounds.y,actor.home.x))
			actor.facing = 1.0 if spec.entry.mode == "left" else -1.0
		if not arrival_safe(actor):
			actors.pop_back()
			continue
		actor.entry = route
		actor.feet = route.pos
		if not spec.depth.is_empty(): arrival_audio.warn(actor.home.x-camera_x)
		ledger[spec.id] = "warning"
		next_warning = trial_clock + 0.25
		return

func _physics_process(delta: float) -> void:
	if paused or result_shown or life_state in ["game_over","death_popup"]: return
	if life_state == "dying":
		step_death(delta)
		return
	if dialogue.active or dialogue.release_guard > 0 or restart_guard_device >= 0: return
	var steps := maxi(1,ceili(delta * 120))
	for index in range(steps):
		var dt := delta / steps
		trial_clock += dt
		var was_grounded := grounded
		step_player(dt)
		if was_grounded and not grounded and player.x > trial_level.pit.x-140 and player.x < trial_level.pit.y+60:
			crossing_airborne = true
		if crossing_airborne and grounded:
			crossing_airborne = false
			crossing_until = trial_clock+0.45
		if pit_falling:
			begin_pit_fall()
			break
		camera_x = move_toward(camera_x,clampf(player.x-320,0,maxf(0,actor_world_limit()-960)),400*dt)
		issue_event()
		step_trial_actors(dt)
		step_trial_swarms(dt)
		step_trial_shots(dt)
		if trial_clock >= next_pressure_sample:
			pressure_log.append({"time":trial_clock,"x":player.x,"actors":live_population(),
				"patterns":pattern_owners().size(),"bullets":hostile_shots.size()})
			next_pressure_sample = trial_clock+0.25
		if life_state != "alive": break
		if player.x >= float(contract.world.finish_x):
			show_results()
			break

func begin_pit_fall() -> void:
	if life_state != "alive": return
	devil_spiders.clear(self,"pit_death")
	specials.clear_transients()
	special_audio.stop()
	lives -= 1
	health = 0
	life_state = "dying"
	death_time = 0
	death_ground_time = 0
	death_message = Story.choose_death_line()
	animation_state = "death"
	animation_time = 0
	velocity.x = 0
	velocity.y = maxf(velocity.y,80)
	shots.clear()
	starter_weapon_audio.stop()
	hero_death_audio.play_death()

func step_death(delta: float) -> void:
	if pit_falling:
		# Allow the visible fall below the shaft before the ordinary death popup opens.
		death_ground_time = 0.5 if death_time > 0.9 else 0.0
	super.step_death(delta)

func step_trial_actors(delta: float) -> void:
	if paused or life_state != "alive" or dispenser.active or dialogue.active or delta <= 0: return
	step_three_actors(delta)
	for actor: Dictionary in actors: sync_trial_action_motion(actor)

func step_three_actors(delta: float) -> void:
	for index in range(actors.size()-1,-1,-1):
		var actor: Dictionary = actors[index]
		actor.age += delta
		actor.clock += delta
		actor.flash = maxf(0,actor.flash-delta)
		if actor.hp <= 0:
			actor.death += delta
			if actor.death >= 0.6: actors.remove_at(index)
			continue
		if not actor.active:
			# Admission is checked before showing the actor. Once visible, proximity must not erase it.
			var delay := float(tuning.arrival_warning_seconds)
			if not actor.depth.is_empty():
				actor.phase = "warning" if actor.age < delay else "travel" if actor.age < delay+TRAVEL_SECONDS else "settle"
				delay += TRAVEL_SECONDS + SETTLE_SECONDS
			if step_actor_entry(actor,delta): continue
			if actor.age < delay: continue
			# Once visibly settled, the entrant must patrol and receive shots even if the hero waits.
			actor.active = true
			actor.phase = "combat"
			actor.activation_time = trial_clock
			actor.arrival_guard = actor.get("mount","") != "floor" and actor_rect(actor).grow(24).intersects(Rect2(player,PLAYER_SIZE))
			ledger[actor.event_id] = "active"
			arrival_log.append({"id":actor.event_id,"outcome":"active","time":trial_clock,"feet":[actor.feet.x,actor.feet.y]})
		if actor.get("arrival_guard",false):
			# The hero may occupy the landing during travel. Keep the entrant vulnerable, but do not
			# turn that overlap into an unavoidable first contact or attack.
			if not actor_rect(actor).grow(24).intersects(Rect2(player,PLAYER_SIZE)):
				actor.arrival_guard = false
				actor.rearm_until = actor.age+float(tuning.arrival_warning_seconds)
		if actor.feet.x < camera_x - 100 and (actor.role != "aggressive_flyer" or actor.get("variant","") == "devil"):
			stop_trial_actions(actor)
			ledger[actor.event_id] = "retired"
			actors.remove_at(index)
			continue
		if actor.role == "runner":
			actor.contact_live = false
			var direction := signf(player.x + PLAYER_SIZE.x * 0.5 - actor.feet.x)
			# Patrol when the hero leaves the encounter; containment edges are never jump targets.
			if player.x < actor.bounds.x or player.x > actor.bounds.y:
				if actor.feet.x <= actor.bounds.x+2: actor.patrol_facing = 1.0
				if actor.feet.x >= actor.bounds.y-2: actor.patrol_facing = -1.0
				direction = actor.patrol_facing
			var body := event_size(actor.role)
			var requested := Vector2(direction*90,actor.vy)
			var envelope: Array = contract.geometry.mandatory_climb.runner_pursuit.horizontal_body_envelope
			if actor.bounds.x >= float(envelope[0]) and actor.bounds.y <= float(envelope[1]):
				requested = FlushfiendNavigation.velocity(Rect2(actor.feet+body.position,body.size),
					requested,actor,delta,trial_level.plinths,trial_level.move_body,GRAVITY,JUMP_SPEED)
			requested.y += GRAVITY*delta
			var motion := trial_level.move_body(actor.feet+body.position,
				requested,body.size,delta)
			actor.feet = motion.pos-body.position
			actor.vy = motion.velocity.y
			actor.grounded = motion.grounded
			actor.facing = signf(requested.x) if requested.x != 0 else actor.facing
			actor.feet.x = clampf(actor.feet.x,actor.bounds.x,actor.bounds.y)
			if not actor.get("arrival_guard",false) and actor.age >= actor.get("rearm_until",0.0) \
				and actor_rect(actor).grow(120).intersects(Rect2(player,PLAYER_SIZE)) and can_pattern(actor.event_id):
				actor.contact_live = true
			if actor.contact_live and actor_rect(actor).intersects(Rect2(player,PLAYER_SIZE)): trial_actor_contact(actor)
		elif actor.role == "aggressive_flyer":
			if actor.get("variant","") == "devil": continue
			if actor.get("post_pit_pursuit",false) and crossing_reserved() \
					and actor.get("attack_state","") in ["windup","swoop","landing","scuttle","takeoff"]:
				# Backtracking into the crossing cancels contact, without snapping the flyer home.
				end_flyer_pattern(actor)
				actor.attack_state = "recover"
				actor.attack_clock = 0.0
				actor.erase("recovery_escape")
				actor.recovery_origin = actor.feet
				actor.recovery_target = Vector2(actor.feet.x,actor.attack_origin.y)
			step_flyer(actor,delta)
			if actor.contact_live and actor.attack_state in ["swoop","landing","scuttle","takeoff"] and actor_rect(actor).intersects(Rect2(player,PLAYER_SIZE)):
				trial_actor_contact(actor)
		elif not actor.get("arrival_guard",false) and actor.age >= actor.get("rearm_until",0.0):
			step_three_shooter(actor,delta)

func shooter_allowed(actor: Dictionary) -> bool:
	return actor.feet.x >= camera_x+24 and actor.feet.x <= camera_x+936 \
		and absf(actor.feet.x-player.x) < 700 and not crossing_reserved()

func crossing_reserved() -> bool:
	return crossing_airborne or trial_clock < crossing_until or (player.x > trial_level.pit.x-80 and player.x < trial_level.pit.y+50)

func begin_flyer_pattern(actor: Dictionary) -> bool:
	if crossing_reserved() or not can_pattern(actor.event_id): return false
	actor.contact_live = true
	return true

func move_flyer_clear(actor: Dictionary, destination: Vector2) -> bool:
	var shape := event_size("aggressive_flyer")
	# Keep the crossing clear, but do not strand survivors after a safe landing.
	if player.x > trial_level.pit.y+80 and grounded and not crossing_reserved():
		actor.post_pit_pursuit = true
	var unlocked: bool = actor.get("post_pit_pursuit",false)
	var left: float = 0.0 if unlocked or actor.home.x < trial_level.pit.x else trial_level.pit.y+130
	var right: float = actor_world_limit() if unlocked or actor.home.x >= trial_level.pit.x else trial_level.pit.x-70
	var bounded := destination
	bounded.x = clampf(bounded.x,left-shape.position.x,right-shape.end.x)
	var moved := super.move_flyer_clear(actor,bounded)
	return moved and actor.feet.is_equal_approx(destination)

func end_flyer_pattern(actor: Dictionary) -> void:
	actor.contact_live = false

func swarm_hunt_bounds(actor: Dictionary) -> Rect2:
	# Wander pockets control admission, not the destination of an already locked charge.
	return Rect2(0,0,actor_world_limit(),trial_level.floor_y)

func step_trial_swarms(delta: float) -> void:
	swarms.target = player+PLAYER_SIZE*0.5
	swarms.viewport = Rect2(camera_x,0,960,540)
	swarms.hero_cooldown = maxf(0,swarms.hero_cooldown-delta)
	for index in range(swarms.actors.size()-1,-1,-1):
		var actor: Dictionary = swarms.actors[index]
		if actor.hp <= 0:
			swarms.step_motion(actor,delta,actor_solids())
			if actor.death >= 0.64: swarms.actors.remove_at(index)
			continue
		if swarms.entry_active(actor):
			swarms.step_motion(actor,delta,actor_solids())
			continue
		if actor.pos.x+maxf(64,swarms.visual_radius) < camera_x:
			stop_trial_actions(actor)
			ledger[actor.event_id] = "retired"
			swarms.actors.remove_at(index)
			continue
		actor.pattern_live = false
		actor.hunt_bounds = swarm_hunt_bounds(actor)
		swarms.step_motion(actor,delta,actor_solids())
		var visible_radius := maxf(64,swarms.visual_radius)
		if Rect2(actor.pos-Vector2.ONE*visible_radius,Vector2.ONE*visible_radius*2).intersects(Rect2(camera_x,0,960,540)):
			actor.warning = maxf(0,actor.get("warning",0.0)-delta)
		actor.contact_ready = true
		if can_pattern(actor.event_id): actor.pattern_live = true
		# Physical contact always hurts, including cloud and morph phases outside pattern budgets.
		if swarms.hero_cooldown <= 0 and invulnerable <= 0 and life_state == "alive" \
				and swarms.overlaps(actor,Rect2(player,PLAYER_SIZE)):
			hurt_player()
			swarms.hero_cooldown = float(swarms.definition.contact.per_target_cooldown_seconds)

func shot_origin(actor: Dictionary) -> Vector2:
	if actor.get("mount","") == "ceiling": return ceiling_shooter_art.muzzle(actor.feet,ceiling_direction(actor))
	return actor.feet + Vector2(18 * actor.facing,25 if actor.get("mount","") == "ceiling" else -25)

func admitted_trajectory(origin: Vector2, direction: Vector2, _max_range := INF) -> bool:
	if not purple_shot_allowed(origin,direction) or crossing_reserved(): return false
	# A fired bolt is never culled for safety. Reject a ray that could occupy the
	# actual crossing/landing corridor before its first physical impact.
	var end := origin+direction*6000
	var crossing := Rect2(trial_level.pit.x-60,300,trial_level.pit.y-trial_level.pit.x+140,140).grow(BULLET_RADIUS)
	var crossing_hit := segment_hit(origin,end,crossing)
	if crossing_hit < 0: return true
	for solid in player_shot_solids():
		var hit := segment_hit(origin,end,solid.grow(BULLET_RADIUS))
		if hit >= 0 and hit < crossing_hit: return true
	# After landing, shots approaching from ahead are ordinary combat again.
	return player.x > trial_level.pit.y+80 and origin.x > player.x and direction.x < 0

func count_shooter(reason: String) -> void:
	shooter_stats[reason] = int(shooter_stats.get(reason,0))+1

func step_three_shooter(actor: Dictionary, delta: float) -> void:
	actor.recovery = maxf(0,actor.recovery-delta)
	if actor.volley_left > 0:
		actor.volley_clock -= delta
		if actor.volley_clock <= 0:
			emit_trial_shot(actor)
		return
	if not shooter_allowed(actor):
		count_shooter("outside_or_crossing")
		stop_trial_actions(actor)
		actor.winding = false
		actor.warn_clock = 0
		return
	if actor.recovery > 0: return
	if not actor.winding:
		if actor.event_id == "climb-burst" and not grounded: return
		if not can_pattern(actor.event_id):
			count_shooter("no_pattern")
			return
		count_shooter("windups")
		actor.windup_started = actor.age
		actor.windup_duration = float(tuning.shot_warning_seconds)
		actor.winding = true
		play_trial_action(actor,"charge")
		actor.warn_clock = 0
		actor.clock = 0
		actor.facing = signf(player.x-actor.feet.x)
		return
	actor.warn_clock += delta
	if actor.warn_clock < float(tuning.shot_warning_seconds): return
	actor.committed_dir = (player + PLAYER_SIZE*0.5 - shot_origin(actor)).normalized()
	if not admitted_trajectory(shot_origin(actor),actor.committed_dir):
		count_shooter("unsafe_ray")
		suppressed_volleys += 1
		stop_trial_actions(actor)
		actor.winding = false
		actor.recovery = float(tuning.recovery_seconds)
		return
	actor.volley_left = next_volley_size(actor)
	actor.volley_index += 1
	stop_trial_actions(actor)
	actor.winding = false
	emit_trial_shot(actor)

func next_volley_size(actor: Dictionary) -> int:
	# Per-shooter seeded randomness preserves reproducible retries without predictable alternation.
	if not actor.has("volley_rng"):
		var rng := RandomNumberGenerator.new()
		rng.seed = run_seed+str(actor.event_id).hash()
		actor.volley_rng = rng
	return actor.volley_rng.randi_range(1,3)

func emit_trial_shot(actor: Dictionary) -> void:
	var origin := shot_origin(actor)
	var direction: Vector2 = actor.committed_dir
	if hostile_shots.size() < int(tuning.hostile_projectiles_max) and shooter_allowed(actor) \
		and admitted_trajectory(origin,direction):
		count_shooter("fired")
		play_trial_action(actor,"fire")
		shot_serial += 1
		hostile_shots.append({"id":"three-%d" % shot_serial, "owner":actor.event_id,
			"pos":origin, "previous":origin, "dir":direction, "age":0.0, "radius":BULLET_RADIUS,
			"distance":0.0, "range":INF})
		shot_log.append({"id":shot_serial,"owner":actor.event_id,"time":trial_clock,
			"direction":[direction.x,direction.y],"volley":actor.volley_index})
		actor.volley_left -= 1
		actor.fire_age = actor.age
		actor.volley_clock = float(tuning.burst_spacing_seconds)
	else:
		# Drop a denied volley rather than saving a backlog for a later frame.
		suppressed_volleys += 1
		actor.volley_left = 0
	if actor.volley_left == 0: actor.recovery = float(tuning.recovery_seconds)

func step_trial_shots(delta: float) -> void:
	for index in range(shots.size()-1,-1,-1):
		var shot: Dictionary = shots[index]
		var start: Vector2 = shot.pos
		var travel := minf(shot.speed*delta,shot.range-shot.distance)
		var end: Vector2 = start+shot.dir*travel
		var closest := 2.0
		var target_actor := -1
		var target_swarm := -1
		for solid in player_shot_solids():
			var hit := projectile_hit(start,end,solid,shot.dir)
			if hit >= 0: closest = minf(closest,hit)
		for a in range(actors.size()):
			if actors[a].hp <= 0 or not actors[a].active: continue
			var hit := projectile_hit(start,end,actor_projectile_rect(actors[a]),shot.dir)
			if hit >= 0 and hit < closest:
				closest = hit
				target_actor = a
		for a in range(swarms.actors.size()):
			var hit: float = swarms.shot_hit(start,end,a,7.0 if employee.id == "sean" else 2.0)
			if hit >= 0 and hit < closest:
				closest = hit
				target_actor = -1
				target_swarm = a
		shot.pos = end
		shot.distance += travel
		if closest <= 1 or shot.distance >= shot.range:
			if target_actor >= 0: damage_trial_actor(actors[target_actor],shot.damage)
			elif target_swarm >= 0:
				var before: float = swarms.actors[target_swarm].hp
				swarms.damage(target_swarm,shot.damage)
				if before > 0 and swarms.actors[target_swarm].hp <= 0:
					kills += 1
					ledger[swarms.actors[target_swarm].event_id] = "killed"
			shots.remove_at(index)
	step_hostile_projectiles(delta)

func step_hostile_projectiles(delta: float) -> void:
	for index in range(hostile_shots.size()-1,-1,-1):
		var shot: Dictionary = hostile_shots[index]
		var travel := BULLET_SPEED * float(tuning.speed_multiplier) * delta
		var end: Vector2 = shot.pos + shot.dir * travel
		shot.distance += travel
		var hit := segment_hit(shot.pos,end,Rect2(player,PLAYER_SIZE).grow(BULLET_RADIUS))
		var wall := 2.0
		for solid in player_shot_solids():
			var fraction := segment_hit(shot.pos,end,solid.grow(BULLET_RADIUS))
			if fraction >= 0: wall = minf(wall,fraction)
		shot.age += delta
		if hit >= 0 or wall <= 1:
			play_trial_impact(shot,shot.pos.lerp(end,minf(hit if hit >= 0 else 2.0,wall)))
		if hit >= 0 and hit < wall: hurt_player()
		if hit >= 0 or wall <= 1 or purple_bolt_offscreen(end):
			count_shooter("wall_early" if wall <= 1 and shot.age < 0.3 else "retired_other")
			hostile_shots.remove_at(index)
		else:
			shot.previous = shot.pos
			shot.pos = end

func finish_trial_defeat(actor: Dictionary) -> void:
	super.finish_trial_defeat(actor)
	ledger[actor.event_id] = "killed"
	actor.contact_live = false
	actor.winding = false
	actor.volley_left = 0

func show_results() -> void:
	super.show_results()
	resume_button.text = "Retry "+trial_name()

func draw_progress() -> void:
	label_at("KILLS  %d" % kills,Vector2(800,30),16,MINT)
	label_at("%s  ·  %s  ·  %d / %d" % [trial_name().to_upper(),difficulty.to_upper(),int(player.x),int(actor_world_limit())],Vector2(29,73),12,GOLD)

func art_part(id: String) -> Dictionary:
	for item in scene_art.get("parts",[]):
		if item.id == id: return item
	return {}

func draw_scene_part(item: Dictionary, offset := Vector2.ZERO) -> void:
	if item.is_empty(): return
	if not scene_textures.has(item.path): scene_textures[item.path] = load("res://"+item.path)
	var source := region(item.source_rect)
	var destination := region(item.destination)
	destination.position += offset
	if item.id in ["access-deck","catwalk-deck"]:
		var x := 0.0
		while x < destination.size.x:
			var width := minf(250,destination.size.x-x)
			draw_texture_rect_region(scene_textures[item.path],Rect2(destination.position+Vector2(x,0),Vector2(width,16)),
				Rect2(source.position,Vector2(source.size.x*width/250,source.size.y)),DECK_TINT)
			x += width
	else:
		draw_texture_rect_region(scene_textures[item.path],destination,source)

func draw_environment() -> void:
	# Crop the painted ground out of the backdrop; only the authored floor spans provide support.
	var background: Dictionary = scene_art.get("background",trial_data.environment.background)
	var source := region(background.source_rect)
	source.size.y *= 425.0 / 540.0
	for bay in range(ceili(actor_world_limit()/960)):
		draw_texture_rect_region(trial_textures[background.path],Rect2(bay*960,15,960,425),source,BACKGROUND_TINT)
	for floor_rect in trial_level.floor_solids():
		var x: float = floor_rect.position.x
		while x < floor_rect.end.x:
			var width := minf(480,floor_rect.end.x-x)
			var fascia := part("floor-fascia").duplicate(true)
			fascia.source_rect[2] *= width/480
			draw_asset(fascia,Rect2(x,440,width,100))
			x += width
	for item in scene_art.get("parts",[]):
		if item.id in ["arrival-ring","pipe-front-lip"]: continue
		if item.layer == "solid_machinery":
			Level.draw_prop(self,region(item.destination))
		else: draw_scene_part(item)

func draw_entry_fixture(_actor: Dictionary, _front := false) -> void:
	# Batch doors behind/in front of the actors rather than drawing each one twice.
	pass

func draw_authored_entry_fixtures(front := false) -> void:
	if not front:
		for spec in event_specs():
			if spec.entry.mode == "ceiling": draw_ceiling_entry_support(spec.feet)
	for actor: Dictionary in actors:
		super.draw_entry_fixture(actor,front)

func draw_depth_actor(actor: Dictionary) -> void:
	draw_entry_actor(actor)

func _draw() -> void:
	if trial_data.is_empty(): return
	draw_set_transform(Vector2(-floorf(camera_x),0))
	draw_environment()
	for fixture: Dictionary in devil_spiders.placements(self): devil_spider_art.draw_support(self,fixture)
	draw_authored_entry_fixtures()
	# Only enemies still emerging from the wall belong behind the pipe lip.
	for actor in actors:
		if actor.hp > 0 and MonsterEntry.active(actor) and actor.entry.mode == "background" and actor.entry.clip.has_area():
			draw_depth_actor(actor)
	draw_scene_part(art_part("pipe-front-lip"))
	for corpse: Dictionary in corpses:
		world_art.draw_toilet(self,corpse)
	for actor in actors:
		if not actor.active and actor.hp > 0:
			if MonsterEntry.active(actor):
				if (actor.entry.mode != "background" or not actor.entry.clip.has_area()) and not foreground_entry(actor): draw_entry_actor(actor)
				continue
		draw_actor(actor)
	draw_authored_entry_fixtures(true)
	swarms.draw(self,show_enemy_health_bars)
	special_art.draw_back(self)
	if life_state != "alive" or invulnerable <= 0 or int(elapsed*12)%2 == 0: draw_sean(player)
	for shot in shots:
		draw_set_transform(shot.pos-Vector2(floorf(camera_x),0),shot.dir.angle())
		if employee.id == "tony":
			box(-15,-2,21,4,Color("70dfff"))
			box(-4,-1,12,2,Color("eaffff"))
		else:
			box(-16,-1,16,3,Color("ad7546"))
			box(0,-5,5,11,Color("e57356"))
		draw_set_transform(Vector2(-floorf(camera_x),0))
	for shot in hostile_shots: draw_hostile_shot(shot)
	devil_spider_art.draw_effects(self)
	shooter_remains.draw(self)
	regular_remains.draw(self)
	special_art.draw_front(self)
	draw_foreground_entries()
	draw_set_transform(Vector2.ZERO)
	draw_hud()
	if paused:
		box(0,0,960,540,Color(0.03,0.07,0.12,0.88))
		if life_state in ["game_over","death_popup"]: draw_death_popup()
		elif result_shown:
			label_at(trial_name().to_upper()+" COMPLETE",Vector2(170,150),28,MINT)
			label_at("%s  ·  %s  ·  %.1f seconds" % [employee.name,difficulty.to_upper(),trial_clock],Vector2(245,205),20,GOLD)
			label_at("%d defeats  ·  %d lives remaining" % [kills,lives],Vector2(245,240),20,Color.WHITE)
			label_at("Production Level 1 remains available from Start.",Vector2(245,280),16,Color.WHITE)
			draw_pause_plates()
		else: draw_pause_panel()

func set_paused(value: bool) -> void:
	super.set_paused(value)
	arrival_audio.set_paused(value)

func request_title() -> void:
	arrival_audio.stop()
	super.request_title()

func _exit_tree() -> void:
	arrival_audio.dispose()
	super._exit_tree()
