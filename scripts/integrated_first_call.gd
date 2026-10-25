extends "res://scripts/opening_trial_game.gd"
## Continuous first-level route with authored boss rooms and checkpoint-owned progress.
const SkitterlingRoom = preload("res://scripts/skitterling_room.gd")
var skitterling := SkitterlingRoom.new()
const ClogfatherRoom = preload("res://scripts/clogfather_room.gd")
var clogfather := ClogfatherRoom.new()
const FirstLevelEnding = preload("res://scripts/first_level_ending.gd")
var ending := FirstLevelEnding.new()
const ClogfatherRoute = preload("res://scripts/clogfather_route.gd")
const SwarmSchedule = preload("res://scripts/swarm_schedule.gd")
var swarm_schedule := SwarmSchedule.new()
const Flush = preload("res://scripts/level_two_flush.gd")
var flush := Flush.new()
const OPENING_END := 3120.0
var wave_spawned: Array[int] = [0,0,0,0,0]
var wave_bypassed: Array[int] = [0,0,0,0,0]
var wave_clock := 0.0
var next_wave_spawn := 0.0
var last_wave_admission := -100.0
var next_density_spawn := 0.0
var retired_crowd := 0
var route_progress := 0.0
const DifficultyPlan = preload("res://scripts/difficulty_plan.gd")
var difficulty := "normal"
var seed_override := -1
var run_seed := 0
var run_plan: Dictionary = {}
var encounter_states: Dictionary = {}
var respawn_origin := 85.0
var rebuilding_respawn := false
var post_skitterling_checkpoint := false
var next_opening_spawn := 0.0
var opening_passed := false
var route_admitted: Dictionary = {}
var route_fallbacks: Dictionary = {}
const BACKGROUND_MANIFEST := "res://assets/world/first-call/background-manifest-v2.json"
var background_panels: Array = []
var background_textures: Dictionary = {}
const BOSS_WORLD_SCALE := 0.9
const BOSS_WORLD_OFFSET := Vector2(0,54)
var boss_sidebar := false
const BossIntro = preload("res://scripts/boss_intro.gd")
var boss_intro := BossIntro.new()
var intro_input_release := false

func _ready() -> void:
	super._ready()
	add_child(boss_intro)
	flush.attach(self)
	# These screen-space controls must never inherit the encounter world framing.
	for overlay: CanvasItem in [boss_hud,dialogue,pause_menu]: overlay.set_as_top_level(true)
	# Dialogue and pause controls must cover the meter when they occupy the right edge.
	boss_hud.z_index = 10
	skitterling.attach(self)
	clogfather.attach(self)
	assert(ending.prepare(),"First-level portal art preparation failed")
	if FileAccess.file_exists(BACKGROUND_MANIFEST):
		var scenery: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BACKGROUND_MANIFEST))
		background_panels = scenery.panels
		for panel: Dictionary in background_panels:
			if not background_textures.has(panel.path): background_textures[panel.path] = load("res://"+panel.path)
	# Base _ready dispatched reset_game, so the mixed geometry is already configured.

func reset_game() -> void:
	var retry_flush := flush.active
	flush.reset()
	boss_intro.reset(true)
	intro_input_release = false
	dialogue.hard_portraits = difficulty == "hard"
	dialogue.hard_dialogue = difficulty == "hard"
	world_art.hero_aim_art.configure(difficulty == "hard")
	dispenser.configure(difficulty == "hard")
	run_seed = seed_override if seed_override >= 0 else randi()
	run_plan = DifficultyPlan.resolve(difficulty,run_seed)
	ClogfatherRoute.append_plan(run_plan)
	for event in run_plan.later:
		if event.trigger >= SkitterlingRoom.END:
			event.owner_origin = Level.POST_SKITTERLING_CHECKPOINT
	post_skitterling_checkpoint = false
	respawn_origin = 85.0
	if music_director != null: music_director.play_track("level")
	super.reset_game()
	if retry_flush: flush.begin(self)

func reset_observation() -> void:
	# Parent respawn calls this after restoring the hero/dispenser; reset once beforehand instead.
	if rebuilding_respawn: return
	boss_intro.reset()
	intro_input_release = false
	super.reset_observation()
	skitterling.reset(run_seed)
	if respawn_origin >= Level.POST_SKITTERLING_CHECKPOINT: skitterling.restore_completed()
	clogfather.reset(run_seed)
	sync_boss_presentation()
	ending.reset()
	boss_hud.end_encounter()
	opening_passed = respawn_origin >= OPENING_END
	corpses.clear()
	particles.clear()
	kills = 0
	player_kills = 0
	fire_timer = 0
	jump_buffer = 0
	next_opening_spawn = 0
	encounter_states.clear()
	route_admitted.clear()
	route_fallbacks.clear()
	for event in run_plan.later:
		encounter_states[event.id] = "pending" if event.enabled and event.owner_origin >= respawn_origin else "excluded"
	wave_spawned.fill(0)
	wave_bypassed.fill(0)
	wave_clock = 0
	next_wave_spawn = 0
	last_wave_admission = -100
	next_density_spawn = 0
	retired_crowd = 0
	route_progress = respawn_origin
	swarms.reset()
	for index in range(swarms.actors.size()-1,-1,-1):
		if swarms.actors[index].pos.x < maxf(OPENING_END,respawn_origin): swarms.actors.remove_at(index)
	swarm_schedule.reset(self)
	var layout: Dictionary = trial_data.layout.duplicate(true)
	var kept: Array = []
	for item in layout.geometry:
		if float(item.rect[0]) < OPENING_END - 500: kept.append(item)
	layout.geometry = kept
	layout.timeline = []
	for resolved in run_plan.opening:
		for authored in trial_data.layout.timeline:
			if authored.role != resolved.role: continue
			var event: Dictionary = authored.duplicate(true)
			event.id = resolved.id
			event.eligible_gameplay_second = 0.0
			layout.timeline.append(event)
			break
	for resolved in run_plan.later:
		if difficulty == "normal" or resolved.wave == 4:
			for authored in trial_data.layout.timeline:
				if authored.role != resolved.role: continue
				var event: Dictionary = authored.duplicate(true)
				event.id = resolved.id
				event.eligible_gameplay_second = 0.0
				layout.timeline.append(event)
				break
	var configured := trial_state.configure(layout, trial_data.balance, true)
	assert(configured)
	for event in run_plan.later:
		if difficulty == "normal" or event.wave == 4:
			if event.owner_origin < respawn_origin:
				trial_state.mark_unavailable(event.id,"excluded by respawn ownership")
	for event in run_plan.opening:
		if not event.enabled or event.owner_origin < respawn_origin:
			trial_state.mark_unavailable(event.id,"excluded by difficulty or respawn ownership")
	trial_level.configure(layout)
	trial_level.width = WORLD_WIDTH
	trial_level.plinths.append_array(ClogfatherRoute.SOLIDS)
	trial_level.decks.append_array(ClogfatherRoute.LEDGES)
	for rect in Level.PROPS:
		# Retain a descending 60px stair before the quiet boundary instead of a trapped floor pocket.
		if rect == Rect2(5390,320,180,120):
			trial_level.plinths.append(Rect2(5390,320,60,120))
			trial_level.plinths.append(Rect2(5450,380,160,60))
			continue
		if rect.position.x >= OPENING_END and skitterling.allowed_body(rect): trial_level.plinths.append(rect)
	for event in run_plan.later:
		if event.trigger >= SkitterlingRoom.QUIET and event.trigger < SkitterlingRoom.END:
			encounter_states[event.id] = "excluded"
			if difficulty == "normal": trial_state.mark_unavailable(event.id,"replaced by authored boss room")
	# Legacy indices remain for checkpoint telemetry only, never as kill quotas.
	mission.zone_counts.fill(0)
	mission.current_zone = 2
	gate_progress.fill(1)

func respawn_after_death() -> void:
	if flush.active:
		if lives <= 0: return
		health = employee.max_health
		invulnerable = 3.0
		flush.begin(self,true)
		return
	if lives <= 0: return
	respawn_origin = respawn_point.x
	if music_director != null: music_director.play_track("level")
	reset_observation()
	flushfiend_death_audio.stop()
	swarm_audio.stop()
	rebuilding_respawn = true
	# Victory saves progress without adding a vending machine or consuming existing clone stock.
	var automatic := post_skitterling_checkpoint and respawn_point.x == Level.POST_SKITTERLING_CHECKPOINT
	if automatic: checkpoint_active = false
	super.respawn_after_death()
	if automatic: checkpoint_active = true
	rebuilding_respawn = false
	if respawn_origin >= ClogfatherRoom.CHECKPOINT:
		camera_x = clogfather.camera_position(player.x)

func save_skitterling_checkpoint() -> void:
	if not skitterling.entered or skitterling.encounter.hp > 0: return
	post_skitterling_checkpoint = true
	if respawn_point.x >= Level.POST_SKITTERLING_CHECKPOINT: return
	checkpoint_active = true
	checkpoint_index = maxi(checkpoint_index,0)
	respawn_point = Vector2(Level.POST_SKITTERLING_CHECKPOINT,FLOOR_Y-PLAYER_SIZE.y)

func activate_checkpoint(index: int = 0) -> void:
	super.activate_checkpoint(index)
	if index == 1 and checkpoint_index == 1:
		camera_x = clogfather.camera_position(player.x)

func move_player_body(position: Vector2, motion: Vector2, size: Vector2, delta: float) -> Dictionary:
	var result := trial_level.move_body(position,motion,size,delta)
	if size == PLAYER_SIZE:
		var bounded := skitterling.constrain(result.pos,size)
		bounded = clogfather.constrain(bounded,size)
		if bounded.x != result.pos.x: result.velocity.x = 0
		result.pos = bounded
	return result

func actor_solids() -> Array[Rect2]:
	var solids := trial_level.actor_solids()
	solids.append(Rect2(0,440,WORLD_WIDTH,100))
	return solids

func player_shot_solids() -> Array[Rect2]:
	var solids := trial_level.projectile_solids()
	solids.append(Rect2(0,440,WORLD_WIDTH,100))
	return solids

func step_gates(_delta: float) -> void:
	# Service shutters are removed from traversal, projectiles and presentation.
	gate_progress.fill(1)

func crowd_population() -> int:
	var count := enemies.size()+(1 if skitterling.encounter.active else 0)
	for actor in actors:
		if actor.hp > 0: count += 1
	for swarm in swarms.actors:
		if swarm.hp > 0: count += 1
	return count

func ordinary_population() -> int:
	return crowd_population()-swarm_schedule.additional_population(self)

func crowd_limit() -> int:
	for actor in actors:
		if actor.hp > 0 and actor.role == "aggressive_flyer": return mini(6,int(run_plan.crowd_cap))
	return int(run_plan.crowd_cap)

func issue_event() -> void:
	if player.x >= OPENING_END: opening_passed = true
	if opening_passed:
		# Unseen pending threats are retired from scheduling, never credited as kills.
		for event: Dictionary in trial_state.results().events:
			if event.id.begins_with("opening-") and event.state == "pending":
				trial_state.mark_unavailable(event.id,"passed opening before safe entry")
		return
	if trial_state.elapsed < next_opening_spawn: return
	if ordinary_population() >= crowd_limit() or trial_state.next_eligible().is_empty(): return
	var events: Array = trial_state.results().events
	var by_id: Dictionary = {}
	for event in events: by_id[event.id] = event
	for resolved in run_plan.opening:
		var event: Dictionary = by_id[resolved.id]
		if event.state != "pending" or player.x < resolved.trigger: continue
		if trial_state.elapsed < retry_after.get(event.id,0.0): continue
		if event.role == "aggressive_flyer":
			if ordinary_population() >= mini(6,int(run_plan.crowd_cap)): continue
		var home := choose_home(event)
		if home == Vector2.INF or home.x >= OPENING_END - 40: continue
		if not trial_state.reserve(event.id): continue
		create_actor(event,home)
		next_opening_spawn = trial_state.elapsed+run_plan.opening_spacing
		return

func actor_world_limit() -> float:
	return ClogfatherRoom.CONTAINMENT

func route_home(event: Dictionary) -> Vector2:
	if event.get("id", "").ends_with("-extra") and event.role == "runner": return density_runner_home()
	var home := Vector2.INF
	if event.role == "perched_shooter":
		var supports: Array[Rect2] = trial_level.plinths.duplicate()
		supports.append_array(trial_level.decks)
		for deck in supports:
			if deck.position.x < OPENING_END: continue
			for x in [deck.end.x-30,deck.get_center().x,deck.position.x+30]:
				var feet := Vector2(x,deck.position.y)
				var shape := event_size(event.role)
				if x+shape.position.x < deck.position.x or x+shape.end.x > deck.end.x: continue
				if x >= player.x+220 and x < camera_x+900 and x < camera_x+910 \
					and position_safe(feet,event.role) and route_clearance(feet,event.role) \
					and predicted_entry_clear(feet,event.role,0.8): return feet
	elif event.role == "floor_emerger":
		for offset in range(580,219,-20):
			var feet := Vector2(player.x+offset,440)
			if absf(feet.x-(player.x+velocity.x*1.45)) < 160: continue
			if feet.x < camera_x+900 and position_safe(feet,event.role) \
				and route_clearance(feet,event.role): return feet
	elif event.role == "runner":
		# The existing landing warning is visible at the forward edge before contact can activate.
		for offset in range(0,121,40):
			var feet := Vector2(minf(camera_x+900+offset,actor_world_limit()-40),440)
			if feet.x-player.x >= 220 and position_safe(feet,event.role) and route_clearance(feet,event.role):
				return feet
	else:
		home = super.choose_home(event)
	if home != Vector2.INF and route_clearance(home,event.role): return home
	return Vector2.INF

func density_runner_home() -> Vector2:
	# Use existing floor and solid tops, with the same visible warning and predicted landing exclusion.
	for offset in range(580,219,-20):
		var x := player.x+offset
		var heights: Array[float] = [440.0]
		for solid in trial_level.plinths:
			if x-19 >= solid.position.x and x+19 <= solid.end.x: heights.append(solid.position.y)
		for height in heights:
			var feet := Vector2(x,height)
			if x >= camera_x+900 or not predicted_entry_clear(feet,"runner",0.6): continue
			if position_safe(feet,"runner") and route_clearance(feet,"runner"):
				return feet
	return Vector2.INF

func predicted_entry_clear(feet: Vector2, role: String, delay: float) -> bool:
	var body := event_size(role)
	body.position += feet
	var predicted := Rect2(player+Vector2(velocity.x*delay,0),PLAYER_SIZE)
	return not body.grow(100).intersects(predicted)

func route_clearance(feet: Vector2, role: String) -> bool:
	var body := event_size(role)
	body.position += feet
	if body.end.x > ClogfatherRoom.CONTAINMENT: return false
	if body.position.x < respawn_origin or not skitterling.allowed_body(body): return false
	for checkpoint in Level.CHECKPOINTS:
		if body.position.x < checkpoint+200 and body.end.x > checkpoint-200: return false
	return true

func choose_home(event: Dictionary) -> Vector2:
	if event.get("id", "").ends_with("-extra") and event.role == "runner": return density_runner_home()
	if event.role == "perched_shooter":
		# Any forward position on a visible deck is valid, not only its far edge.
		for deck in trial_level.decks:
			for x in [deck.position.x+30,deck.get_center().x,deck.end.x-30]:
				var feet := Vector2(x,deck.position.y)
				if x >= player.x+220 and x <= player.x+420 and x > camera_x+50 \
					and x < camera_x+910 and position_safe(feet,event.role): return feet
		return Vector2.INF
	return super.choose_home(event)

func begin_pending_boss_intro() -> bool:
	var id := "clogfather" if clogfather.entered else "cockroach-swarm" if skitterling.locked() else ""
	if id.is_empty() or not boss_intro.begin(id): return false
	jump_buffer = 0
	tone_time = 0
	intro_input_release = true
	sync_boss_presentation()
	return true

func step_player(delta: float) -> void:
	if intro_input_release and not Input.is_action_pressed("shoot") and not Input.is_action_pressed("jump"):
		intro_input_release = false
	var locked: bool = dispenser.actions_locked
	dispenser.actions_locked = locked or intro_input_release
	super.step_player(delta)
	dispenser.actions_locked = locked

func _physics_process(delta: float) -> void:
	if flush.active:
		if paused or won or life_state in ["death_popup","game_over"]: return
		if life_state == "dying":
			step_death(delta)
			return
		if dialogue.release_guard > 0 or restart_guard_device >= 0: return
		if flush.input_guard:
			if restart_inputs_held() or Input.is_action_pressed("shoot") or Input.is_action_pressed("jump"): return
			flush.input_guard = false
		var steering := Input.get_vector("left","right","aim_up","aim_down")
		var count := maxi(1,ceili(delta*120))
		for index in range(count):
			flush.tick(self,delta/count,steering,Input.is_action_just_pressed("jump") and index == 0,
				Input.is_action_pressed("shoot"))
		return
	if dispenser.just_finished:
		dispenser.just_finished = false
		return
	if won or life_state != "alive": boss_intro.reset()
	if dispenser.active or paused or won or life_state in ["game_over","death_popup"]: return
	if life_state == "dying":
		step_death(delta)
		return
	if dialogue.active or dialogue.release_guard > 0 or restart_guard_device >= 0: return
	var was_blocking := boss_intro.blocking()
	delta = boss_intro.advance(delta)
	if boss_intro.blocking() or (was_blocking and delta <= 0): return
	if ending.active():
		ending.step(self,delta)
		return
	var count := maxi(1,ceili(delta*120))
	for index in range(count):
		var dt := delta/count
		trial_state.advance(dt)
		step_gates(dt)
		var old_count := shots.size()
		step_player(dt)
		if shots.size() > old_count:
			shot_serial += 1
			shots[-1].trial_id = "shot-%d" % shot_serial
			trial_state.record_shot(shots[-1].trial_id)
		if not skitterling.locked():
			camera_x = move_toward(camera_x,clampf(player.x-320,0,WORLD_WIDTH-960),400*dt)
		skitterling.advance(self,dt)
		clogfather.advance(self,dt)
		if begin_pending_boss_intro(): return
		swarm_schedule.step(self)
		issue_event()
		step_trial_actors(dt)
		skitterling.contain_prior(self)
		clogfather.contain_prior(self)
		# Base combat advances campaign bodies. One shared sweep below owns all shots.
		var saved: Array[Dictionary] = shots
		shots = []
		step_combat(dt)
		skitterling.contain_prior(self)
		clogfather.contain_prior(self)
		shots = saved
		step_trial_shots(dt)
		clogfather.contain_prior(self)
		if life_state == "alive": swarms.step(self,minf(dt,0.1/count))
		if life_state != "alive": break
		step_encounters(dt)
	if life_state != "alive": return
	for checkpoint in range(Level.CHECKPOINTS.size()):
		if player.x >= Level.CHECKPOINTS[checkpoint] and checkpoint > checkpoint_index:
			activate_checkpoint(checkpoint)
			if dispenser.active: return
	if clogfather.encounter.exit_open: ending.begin(self)
	for index in range(particles.size()-1,-1,-1):
		particles[index].pos += particles[index].vel*delta
		particles[index].vel.y += 350*delta
		particles[index].life -= delta
		if particles[index].life <= 0: particles.remove_at(index)

func step_encounters(delta: float) -> void:
	wave_clock += delta
	route_progress = maxf(route_progress,player.x)
	if player.x >= ClogfatherRoom.QUIET: return
	if player.x >= SkitterlingRoom.QUIET and not skitterling.released: return
	# Retire only well outside view, without kill credit or a visible disappearance.
	for index in range(enemies.size()-1,-1,-1):
		if enemies[index].pos.x+38 < camera_x-320:
			enemies.remove_at(index)
			retired_crowd += 1
	if difficulty == "normal" or player.x >= 9500:
		step_normal_route()
		return
	for event in run_plan.later:
		if encounter_states[event.id] == "pending" and route_progress >= event.end:
			encounter_states[event.id] = "bypassed"
			wave_bypassed[event.wave] += 1
	if wave_clock < last_wave_admission+0.3 or ordinary_population() >= crowd_limit(): return
	if respawn_origin >= DifficultyPlan.CHECKPOINT and wave_clock < 1.25: return
	for event in run_plan.later:
		if encounter_states[event.id] != "pending" or player.x < event.trigger: continue
		var extra: bool = event.id.ends_with("-extra")
		if wave_clock < (next_density_spawn if extra else next_wave_spawn): continue
		if extra:
			var extra_nearby := false
			for enemy in enemies:
				if enemy.get("encounter_id", "").ends_with("-extra") and enemy.hp > 0 \
						and enemy.pos.x >= camera_x-160 and enemy.pos.x <= camera_x+1250:
					extra_nearby = true
			if extra_nearby: continue
		var radius := entrance_radius()
		var sides: Array = [event.side,-event.side]
		if event.wave == 0 and event.owner_origin == DifficultyPlan.CHECKPOINT: sides = [1.0]
		for side in sides:
			for offset in range(0,385,48):
				var x: float = floorf(camera_x)+(984+radius if side>0 else -24-radius)-19+side*offset
				var hero_body := Rect2(player,PLAYER_SIZE)
				var spawn_left: float = x+19-radius
				var spawn_right: float = x+19+radius
				if spawn_left < respawn_origin or not skitterling.allowed_body(Rect2(spawn_left,404,spawn_right-spawn_left,36)): continue
				if maxf(spawn_left-hero_body.end.x,hero_body.position.x-spawn_right) < 220: continue
				if not safe_entrance(x): continue
				var blocked := false
				for checkpoint in Level.CHECKPOINTS:
					if absf(x+19-checkpoint) < 200+radius: blocked = true
				for actor in actors:
					if actor.hp <= 0: continue
					var body: Rect2 = actor_rect(actor)
					# A high flyer must not reserve the floor entrance beneath it.
					if body.end.y > 388 and body.position.y < 456 \
						and absf(actor.feet.x-x-19) < radius*2+16: blocked = true
				if blocked: continue
				var enemy := Data.spawn("toilet",Vector2(x,404))
				enemy.entering = true
				enemy.encounter_id = event.id
				enemy.owner_origin = event.owner_origin
				enemy.direction = signf(player.x-x)
				enemy.hp = float(trial_data.balance.roles.runner.spawn_hp)
				enemy.max_hp = float(trial_data.balance.roles.runner.max_hp)
				enemies.append(enemy)
				encounter_states[event.id] = "spawned"
				wave_spawned[event.wave] += 1
				last_wave_admission = wave_clock
				if extra: next_density_spawn = wave_clock+1.0
				else: next_wave_spawn = wave_clock+event.spacing
				return

func route_pressure(include_additions: bool = true) -> int:
	# All warnings commit future pressure. Remote survivors still consume the global safety cap;
	# local pressure counts them again as soon as they approach the view, without deleting them.
	var count := 0
	for enemy in enemies:
		if enemy.pos.x >= camera_x-160 and enemy.pos.x <= camera_x+1250: count += 1
	var living_shooter := false
	for actor in actors:
		if actor.hp <= 0: continue
		if actor.active and (actor_rect(actor).end.x < camera_x-160 or actor.feet.x > camera_x+1250): continue
		if not include_additions and actor.event_id.ends_with("-extra"):
			if actor.role == "perched_shooter": living_shooter = true
			continue
		count += 1
		if actor.role == "perched_shooter": living_shooter = true
	for swarm in swarms.actors:
		if not swarm.get("additive",false) and swarm.hp > 0 and swarm.pos.x >= camera_x-48 and swarm.pos.x <= camera_x+1008: count += 1
	if not living_shooter:
		for shot in hostile_shots:
			if shot.pos.x >= camera_x and shot.pos.x <= camera_x+960:
				count += 1
				break
	return count

func step_normal_route() -> void:
	var states: Dictionary = {}
	for event in trial_state.results().events: states[event.id] = event
	for resolved in run_plan.later:
		if not states.has(resolved.id): continue
		var event: Dictionary = states[resolved.id]
		if event.state == "pending" and route_progress >= resolved.end:
			trial_state.mark_unavailable(event.id,"passed route window before safe entry")
			encounter_states[event.id] = "bypassed"
			wave_bypassed[resolved.wave] += 1
	if player.x < OPENING_END or wave_clock < last_wave_admission+0.3: return
	var local_target := 3 if player.x < 4450 else 2
	var baseline_pressure := route_pressure(false)
	var total_pressure := route_pressure()
	if ordinary_population() >= crowd_limit(): return
	if respawn_origin >= DifficultyPlan.CHECKPOINT and wave_clock < 1.25: return
	for resolved in run_plan.later:
		if not states.has(resolved.id): continue
		var event: Dictionary = states[resolved.id]
		if event.state != "pending" or route_progress >= resolved.end or player.x < resolved.trigger: continue
		# Extra encounters have one local pacing slot; all global threat and entry checks still apply.
		var extra: bool = resolved.id.ends_with("-extra")
		if wave_clock < (next_density_spawn if extra else next_wave_spawn): continue
		if extra:
			if total_pressure-baseline_pressure >= 1 or total_pressure >= local_target+1: continue
		elif baseline_pressure >= local_target: continue
		if trial_state.elapsed < retry_after.get(event.id,0.0): continue
		var home := route_home(event)
		if home == Vector2.INF and event.role in ["perched_shooter","floor_emerger"]:
			# Keep a reachable perch pending while occupied; fallback only after its forward window closes.
			if event.role == "perched_shooter":
				var forward_support := false
				for prop in trial_level.plinths:
					if prop.end.x-30 >= player.x+220 and prop.position.x+30 <= player.x+420:
						forward_support = true
				if forward_support: continue
			elif player.x < resolved.trigger+180: continue
			var fallback: Dictionary = event.duplicate(true)
			fallback.role = "runner"
			home = route_home(fallback)
			if home == Vector2.INF or not trial_state.use_runner_fallback(event.id): continue
			route_fallbacks[event.id] = event.role
			for updated in trial_state.results().events:
				if updated.id == event.id: event = updated
		if home == Vector2.INF or not trial_state.reserve(event.id): continue
		create_actor(event,home)
		actors[-1].owner_origin = resolved.owner_origin
		encounter_states[event.id] = "spawned"
		if not route_admitted.has(event.id):
			route_admitted[event.id] = true
			wave_spawned[resolved.wave] += 1
		last_wave_admission = wave_clock
		if extra: next_density_spawn = wave_clock+1.0
		else: next_wave_spawn = wave_clock+resolved.spacing
		return

func step_trial_shots(delta: float) -> void:
	for index in range(shots.size()-1,-1,-1):
		var shot: Dictionary = shots[index]
		var direction := shot_direction(shot)
		var start: Vector2 = shot.pos
		var travel: float = minf(shot.speed*delta,maxf(0,shot.range-shot.distance))
		var end := start+direction*travel
		var nearest := 2.0
		var actor_target := -1
		var enemy_target := -1
		var swarm_target := -1
		var boss_target := false
		var clog_target := false
		var clog_weak := false
		var gas_target := ""
		for solid in player_shot_solids():
			var hit := projectile_hit(start,end,solid,direction)
			if hit >= 0: nearest = minf(nearest,hit)
		for a in range(actors.size()):
			if actors[a].hp <= 0 or not actors[a].active: continue
			var hit := projectile_hit(start,end,actor_projectile_rect(actors[a]),direction)
			if hit >= 0 and hit < nearest:
				nearest = hit
				actor_target = a
		for e in range(enemies.size()):
			var hit := projectile_hit(start,end,flushfiend_projectile_rect(enemies[e].pos+Vector2(19,36)),direction)
			if hit >= 0 and hit < nearest:
				nearest = hit
				enemy_target = e
				actor_target = -1
		for swarm_index in range(swarms.actors.size()):
			var hit: float = swarms.shot_hit(start,end,swarm_index,7.0 if employee.id == "sean" else 2.0)
			if hit >= 0 and hit < nearest:
				nearest = hit
				swarm_target = swarm_index
				actor_target = -1
				enemy_target = -1
		for boss_rect: Rect2 in skitterling.target_regions():
			var hit := projectile_hit(start,end,boss_rect,direction)
			if hit >= 0 and hit < nearest:
				nearest = hit
				boss_target = true
				actor_target = -1
				enemy_target = -1
				swarm_target = -1
		var clog_regions := [clogfather.target_rect(),clogfather.shell_rect()]
		for region_index in range(clog_regions.size()):
			var boss_rect: Rect2 = clog_regions[region_index]
			if not boss_rect.has_area(): continue
			var hit := projectile_hit(start,end,boss_rect,direction)
			if hit >= 0 and hit < nearest:
				nearest = hit
				clog_target = true
				clog_weak = region_index == 0
				boss_target = false
				actor_target = -1
				enemy_target = -1
				swarm_target = -1
		for target: Dictionary in clogfather.gas_targets():
			var hit := projectile_hit(start,end,target.rect,direction)
			if hit >= 0 and hit < nearest:
				nearest = hit
				gas_target = target.id
				clog_target = false
				boss_target = false
				actor_target = -1
				enemy_target = -1
				swarm_target = -1
		shot.pos = end
		shot.distance += travel
		if nearest <= 1 or shot.distance >= shot.range:
			if shot.has("trial_id"): trial_state.resolve_shot(shot.trial_id,actor_target >= 0 or enemy_target >= 0 or swarm_target >= 0 or boss_target or clog_target or not gas_target.is_empty())
			if not gas_target.is_empty():
				clogfather.damage_gas(self,gas_target,int(shot.damage),
					str(shot.get("trial_id","shot-%d" % shot_serial)))
			elif clog_target:
				var point := start.lerp(end,nearest)
				if clog_weak:
					var accepted := clogfather.damage(self,int(shot.damage),
						str(shot.get("trial_id","shot-%d" % shot_serial)),bool(shot.get("fired_airborne",false)))
					if accepted == 0: clogfather.deflect(start.lerp(end,nearest))
				else: clogfather.deflect(point)
			elif boss_target: skitterling.damage(self,int(shot.damage))
			elif swarm_target >= 0: swarms.damage(swarm_target,shot.damage)
			elif enemy_target >= 0: damage_enemy(enemy_target,shot.damage,start.lerp(end,nearest))
			elif actor_target >= 0:
				var actor: Dictionary = actors[actor_target]
				damage_trial_actor(actor,shot.damage)
			shots.remove_at(index)
	# Reuse the role projectile update without advancing friendly shots a second time.
	var saved: Array[Dictionary] = shots
	shots = []
	super.step_trial_shots(delta)
	shots = saved

func draw_progress() -> void:
	label_at("KILLS  %d" % kills,Vector2(800,30),16,MINT)
	label_at("SERVICE ENTRANCE" if player.x < OPENING_END else "FOLLOW THE SERVICE ROUTE →",
		Vector2(29,73),12,GOLD)

func draw_environment() -> void:
	if background_panels.is_empty():
		for bay in range(maxi(0,int(camera_x/960)-1),mini(ceili(WORLD_WIDTH/960),int(camera_x/960)+3)):
			draw_asset(trial_data.environment.background,Rect2(bay*960,15,960,540))
	else:
		var view := Rect2(camera_x,0,960,540)
		for panel: Dictionary in background_panels:
			var destination := region(panel.destination)
			if not destination.intersects(view): continue
			draw_texture_rect_region(background_textures[panel.path],destination,region(panel.source_rect))
	for rect in trial_level.decks:
		draw_asset(part("support"),Rect2(rect.position,Vector2(250,120)),Color(0.65,0.65,0.65))
		draw_asset(part("deck"),rect)
	for rect in trial_level.plinths:
		if rect.position.x < OPENING_END: draw_asset(part("access-plinth"),rect)
		else: Level.draw_prop(self,rect)
	for x in range(0,int(WORLD_WIDTH),480):
		draw_asset(part("floor-fascia"),Rect2(x,440,480,100))
	dispenser.draw_machines(self)

func sync_boss_presentation() -> void:
	if flush.active:
		boss_sidebar = false
		transform = Transform2D.IDENTITY
		return
	# Keep the full room visible, including the right pipe, through death and exit traversal.
	boss_sidebar = clogfather.entered or skitterling.locked()
	transform = Transform2D(0,Vector2.ONE*BOSS_WORLD_SCALE,0,BOSS_WORLD_OFFSET) \
		if boss_sidebar else Transform2D.IDENTITY

func _draw() -> void:
	if flush.active:
		flush.draw(self)
		return
	if trial_data.is_empty(): return
	draw_set_transform(Vector2(-floorf(camera_x),0))
	draw_environment()
	skitterling.draw_back(self)
	for enemy: Dictionary in enemies: draw_toilet(enemy)
	for corpse: Dictionary in corpses: draw_toilet(corpse)
	swarms.draw(self,show_enemy_health_bars)
	dispenser.draw_world(self)
	for actor in actors:
		if not actor.active and actor.hp > 0:
			effect("grate-warning" if actor.role == "floor_emerger" else "landing-warning",
				Vector2(clampf(actor.feet.x,camera_x+35,camera_x+925),minf(actor.feet.y,440)))
		draw_actor(actor)
	skitterling.draw_actor(self)
	ending.draw_portal(self)
	clogfather.draw(self)
	# Room scenery must not cover the continuous route's below-floor cutaway.
	wastewater_art.draw(self,camera_x,elapsed,false)
	ending.draw_surge(self,false)
	if ending.state == "pull":
		ending.draw_hero(self)
	elif ending.state != "complete" and not dispenser.hides_hero() \
		and (life_state != "alive" or invulnerable <= 0 or int(elapsed*12)%2 == 0): draw_sean(player)
	for shot in shots:
		# Reuse the existing original projectile presentation.
		draw_set_transform(shot.pos-Vector2(floorf(camera_x),0),shot.dir.angle())
		if employee.id == "tony":
			box(-15,-2,21,4,Color("70dfff"))
			box(-4,-1,12,2,Color("eaffff"))
		else:
			box(-16,-1,16,3,Color("ad7546"))
			box(0,-5,5,11,Color("e57356"))
		draw_set_transform(Vector2(-floorf(camera_x),0))
	for shot in hostile_shots: draw_hostile_shot(shot)
	for particle in particles:
		box(particle.pos.x,particle.pos.y,4,4,particle.color)
	skitterling.draw_front(self)
	ending.draw_surge(self,true)
	draw_set_transform(Vector2.ZERO)
	ending.draw_shout(self)
	draw_set_transform_matrix(transform.affine_inverse())
	if boss_sidebar: box(864,82,96,458,INK)
	draw_hud()
	dispenser.draw_overlay(self)
	draw_set_transform_matrix(transform.affine_inverse())
	if paused or (won and not dialogue.active):
		box(0,0,960,540,Color(0.03,0.07,0.12,0.88))
		if life_state in ["game_over","death_popup"]: draw_death_popup()
		else: draw_pause_panel()

func _process(delta: float) -> void:
	sync_boss_presentation()
	var frozen_intro := boss_intro.blocking()
	if frozen_intro: dialogue.tick(delta,paused)
	super._process(0.0 if frozen_intro else delta)
	for sound in creature_audio.values(): sound.set_paused(paused or frozen_intro)
	if frozen_intro:
		door_audio.set_paused(true)
		starter_weapon_audio.set_paused(true)
	if ending.state == "dialogue" and not paused: ending.clock += delta
	if flush.active:
		flush.process_audio(self,delta)
	else:
		skitterling.process_audio(self,delta)
		clogfather.process_audio(self,delta)

func draw_pause_panel() -> void:
	if not won or ending.state != "complete":
		super.draw_pause_panel()
		return
	var heading := "FIRST LEVEL COMPLETE"
	var width := ThemeDB.fallback_font.get_string_size(heading,HORIZONTAL_ALIGNMENT_LEFT,-1,32).x
	label_at(heading,Vector2((960-width)/2,200),32,Color("fff2cf"))
	var message := "Level two is not yet playable."
	width = ThemeDB.fallback_font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
	label_at(message,Vector2((960-width)/2,229),18,Color("fff2cf"))
	draw_pause_plates()

func hurt_player() -> void:
	super.hurt_player()
	if flush.active:
		flush.sync_hero(self)
		if life_state != "alive":
			flush.radio.clear()
			flush.audio.stop()
			flush.music.stop()
		return
	player = skitterling.constrain(player,PLAYER_SIZE)
	player = clogfather.constrain(player,PLAYER_SIZE)

func set_paused(value: bool) -> void:
	super.set_paused(value)
	if flush.active: flush.process_audio(self,0.0)
	skitterling.audio.set_paused(value or life_state != "alive")
	clogfather.audio.set_paused(value or life_state != "alive")

func request_title() -> void:
	if death_popup_locked: return
	flush.reset()
	skitterling.audio.stop()
	clogfather.audio.stop()
	super.request_title()

func _exit_tree() -> void:
	flush.dispose()
	skitterling.audio.dispose()
	clogfather.audio.dispose()
	super._exit_tree()

func begin_level_two() -> void:
	flush.begin(self)

func step_death(delta: float) -> void:
	if not flush.active:
		super.step_death(delta)
		return
	if paused or life_state != "dying": return
	death_time += delta
	if death_time < 1.0: return
	life_state = "game_over" if lives == 0 else "death_popup"
	death_popup_locked = true
	death_popup_guard = 0.35
	resume_button.disabled = true
	title_button.disabled = true
	resume_button.text = "Retry Flush" if lives == 0 else "Continue at Bowl"
	resume_button.position = Vector2(245,326)
	title_button.position = Vector2(245,416)
	style_pause_buttons()
	set_paused(true)
