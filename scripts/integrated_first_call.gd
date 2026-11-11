extends "res://scripts/opening_trial_game.gd"
## Continuous first-level route with authored boss rooms and checkpoint-owned progress.
const SkitterlingRoom = preload("res://scripts/skitterling_room.gd")
var skitterling := SkitterlingRoom.new()
const ClogfatherRoom = preload("res://scripts/clogfather_room.gd")
var clogfather := ClogfatherRoom.new()
const FirstLevelEnding = preload("res://scripts/first_level_ending.gd")
var ending := FirstLevelEnding.new()
const Flush = preload("res://scripts/level_two_flush.gd")
var flush := Flush.new()
const OPENING_END := 3120.0
var difficulty := "normal"
var seed_override := -1
var run_seed := -1
var encounter_states: Dictionary = {}
var respawn_origin := 85.0
var rebuilding_respawn := false
var post_skitterling_checkpoint := false
const BACKGROUND_MANIFEST := "res://assets/world/first-call/background-manifest-v2.json"
var background_panels: Array = []
var background_textures: Dictionary = {}
const BossIntro = preload("res://scripts/boss_intro.gd")
var boss_intro := BossIntro.new()
var intro_input_release := false
var startup_complete := false
const Campaign = preload("res://scripts/campaign_encounters.gd")
const CampaignArt = preload("res://scripts/campaign_world_art.gd")
var campaign := Campaign.new()
var campaign_art := CampaignArt.new()
const BULLET_RADIUS := 4.0
const BULLET_SPEED := 220.0
const TRAVEL_SECONDS := 0.6
const SETTLE_SECONDS := 0.2
var tuning: Dictionary = {}
var ledger: Dictionary = {}
var trial_clock := 0.0
var next_warning := 0.0
var pit_falling := false
var crossing_until := 0.0
var crossing_airborne := false
var shot_log: Array[Dictionary] = []
var arrival_log: Array[Dictionary] = []
var shooter_stats: Dictionary = {}
var suppressed_volleys := 0

func _ready() -> void:
	await super._ready()
	if startup_yield.is_valid(): await startup_yield.call()
	add_child(boss_intro)
	await flush.attach(self,startup_yield)
	# These screen-space controls must never inherit the encounter world framing.
	for overlay: CanvasItem in [boss_hud,dialogue,pause_menu]: overlay.set_as_top_level(true)
	# Dialogue and pause controls must cover the meter when they occupy the right edge.
	boss_hud.z_index = 10
	await skitterling.attach(self,startup_yield)
	clogfather.attach(self)
	assert(ending.prepare(),"First-level portal art preparation failed")
	if FileAccess.file_exists(BACKGROUND_MANIFEST):
		var scenery: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BACKGROUND_MANIFEST))
		background_panels = scenery.panels
		for panel: Dictionary in background_panels:
			if not background_textures.has(panel.path): background_textures[panel.path] = load("res://"+panel.path)
	await campaign_art.prepare(self,startup_yield)
	# Base _ready dispatched reset_game, so campaign geometry is already configured.
	startup_complete = true

func reset_game() -> void:
	var retry_ride := flush.active and flush.checkpoint_saved
	var retry_flush := flush.active
	var ride_checkpoint: int = flush.ride.checkpoint_index
	flush.reset()
	boss_intro.reset(true)
	intro_input_release = false
	dialogue.hard_portraits = difficulty == "hard"
	dialogue.costume = difficulty
	dialogue.hard_dialogue = difficulty == "hard"
	world_art.hero_aim_art.configure(difficulty)
	dispenser.configure(difficulty)
	# Retries keep the encounter layout; a new game instance starts a fresh run.
	if run_seed < 0:
		run_seed = seed_override if seed_override >= 0 else randi()
	post_skitterling_checkpoint = false
	respawn_origin = 85.0
	# Hidden preparation must retain menu music until the opening is revealed.
	if startup_complete and music_director != null: music_director.play_track("level")
	super.reset_game()
	if retry_flush:
		flush.begin(self,true)
		if retry_ride: flush.enter_ride(self,ride_checkpoint)

func reset_observation() -> void:
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
	corpses.clear()
	particles.clear()
	kills = 0
	player_kills = 0
	fire_timer = 0
	jump_buffer = 0
	campaign.reset(difficulty,respawn_origin,run_seed)
	trial_level = campaign.level
	tuning = campaign.tuning
	ledger = campaign.ledger
	encounter_states = ledger
	trial_clock = 0
	next_warning = 0
	crossing_until = 0
	crossing_airborne = false
	pit_falling = false
	shot_log.clear()
	arrival_log.clear()
	shooter_stats.clear()
	suppressed_volleys = 0
	swarms.hero_cooldown = 0
	# Legacy trial telemetry remains available, but has no campaign scheduling authority.
	var layout: Dictionary = trial_data.layout.duplicate(true)
	assert(trial_state.configure(layout,trial_data.balance,true))
	mission.zone_counts.fill(0)
	mission.current_zone = 2
	gate_progress.fill(1)

func respawn_after_death() -> void:
	if flush.active:
		if lives <= 0: return
		var retry_ride := flush.checkpoint_saved
		var ride_checkpoint: int = flush.ride.checkpoint_index
		health = employee.max_health
		invulnerable = 3.0
		flush.begin(self,true)
		if retry_ride: flush.enter_ride(self,ride_checkpoint)
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
	if size == PLAYER_SIZE and devil_spiders.locked() and devil_spiders.captured_actor().devil.capture_kind == "snare":
		return {"pos":position,"velocity":Vector2.ZERO,"grounded":true,"falling":false}
	var result := devil_spiders.move_body(self,position,motion,size,delta)
	if size == PLAYER_SIZE:
		if result.get("falling",false): pit_falling = true
		var bounded := skitterling.constrain(result.pos,size)
		bounded = clogfather.constrain(bounded,size)
		if bounded.x != result.pos.x: result.velocity.x = 0
		result.pos = bounded
	return result

func swarm_hunt_bounds(actor: Dictionary) -> Rect2:
	var bounds := super.swarm_hunt_bounds(actor)
	if actor.get("clogfather_reinforcement",false): return bounds
	var home: Rect2 = actor.get("wander_bounds",actor.bounds)
	if home.end.x <= SkitterlingRoom.QUIET:
		bounds.end.x = minf(bounds.end.x,SkitterlingRoom.QUIET)
	elif home.position.x >= SkitterlingRoom.END:
		bounds = bounds.intersection(Rect2(SkitterlingRoom.END,0,WORLD_WIDTH-SkitterlingRoom.END,440))
	if home.end.x <= ClogfatherRoom.CONTAINMENT:
		bounds.end.x = minf(bounds.end.x,ClogfatherRoom.CONTAINMENT)
	return bounds

func actor_solids() -> Array[Rect2]:
	var solids := trial_level.actor_solids()
	solids.append_array(campaign.level.floor_solids())
	return solids

func player_shot_solids() -> Array[Rect2]:
	var solids := trial_level.projectile_solids()
	solids.append_array(campaign.level.floor_solids())
	return solids

func step_gates(_delta: float) -> void:
	# Service shutters are removed from traversal, projectiles and presentation.
	gate_progress.fill(1)

func crowd_population() -> int:
	var count := enemies.size()+(1 if skitterling.encounter.active else 0)
	for actor in actors:
		if actor.hp > 0: count += 1
	for swarm in swarms.actors:
		if swarm.hp > 0 and not swarm.get("clogfather_reinforcement",false): count += 1
	return count

func ordinary_population() -> int:
	return live_population()

func crowd_limit() -> int:
	return int(tuning.total_actors_max)

func issue_event() -> void:
	campaign.expire(player.x)
	if in_pressure_dip() or crossing_reserved(): return
	var specs := event_specs().duplicate()
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
				"additive":true,"contact_ready":false,"pattern_live":false,"end":spec.end,"seen":false})
			swarm.entry = route
			swarm.pos = route.pos
			swarms.actors.append(swarm)
			ledger[spec.id] = "active"
			next_warning = trial_clock+float(campaign.contract.admission_interval_seconds)
			return
		create_actor({"id":spec.id,"role":spec.role,"warning_seconds":tuning.arrival_warning_seconds,
			"variant":spec.get("variant",""),"devil_limits":spec.get("devil_limits",spec.bounds)},spec.feet)
		var actor: Dictionary = actors.back()
		actor.merge({"depth":spec.depth, "source":spec.get("source",spec.feet), "bounds":spec.bounds,
			"end":spec.end, "mount":"ceiling" if spec.entry.mode == "ceiling" else "floor" if spec.entry.mode == "floor" else "", "phase":"warning", "volley_left":0, "volley_clock":0.0,
			"volley_index":0, "recovery":0.0, "warn_clock":0.0, "committed_dir":Vector2.ZERO,
			"activation_time":-1.0, "warning_started":trial_clock,"seen":false},true)
		actor.home = route.home
		if spec.entry.mode in ["left","right"]:
			actor.bounds = Vector2(minf(actor.bounds.x,actor.home.x),maxf(actor.bounds.y,actor.home.x))
			actor.facing = 1.0 if spec.entry.mode == "left" else -1.0
		if not arrival_safe(actor):
			actors.pop_back()
			continue
		actor.entry = route
		actor.feet = route.pos
		ledger[spec.id] = "warning"
		next_warning = trial_clock+float(campaign.contract.admission_interval_seconds)
		return

func actor_world_limit() -> float:
	return ClogfatherRoom.CONTAINMENT

func purple_shot_allowed(origin: Vector2, direction: Vector2) -> bool:
	if not super.purple_shot_allowed(origin,direction): return false
	# Refuse a conflicting launch; never erase an already visible bolt at a room boundary.
	if purple_bolt_reaches_x(origin,direction,ClogfatherRoom.CONTAINMENT): return false
	if not skitterling.entered and purple_bolt_reaches_x(origin,direction,SkitterlingRoom.QUIET): return false
	return true

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

func specials_allowed(ignore_active := false) -> bool:
	return not flush.active and not boss_intro.blocking() and not ending.active() \
		and not intro_input_release and super.specials_allowed(ignore_active)

func special_damage(segments: Array[Dictionary], amount: float, activation: int, boss_tick_damage: Dictionary) -> Dictionary:
	var applied := super.special_damage(segments,amount,activation,boss_tick_damage)
	for region: Rect2 in skitterling.target_regions():
		if StarterSpecials.overlaps(segments,region):
			applied.skitterling = skitterling.damage(self,int(boss_tick_damage.get("skitterling",0)))
			break
	var weak: Rect2 = clogfather.target_rect()
	if weak.has_area() and StarterSpecials.overlaps(segments,weak):
		applied.clogfather = clogfather.damage(self,int(boss_tick_damage.get("clogfather",0)),
			"special-%d-%d" % [activation,specials.tick_serial],not grounded)
	return applied

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
		trial_clock += dt
		trial_state.advance(dt)
		step_gates(dt)
		var old_count := shots.size()
		var was_grounded := grounded
		step_player(dt)
		update_crossing(was_grounded)
		if pit_falling:
			begin_pit_fall()
			break
		if shots.size() > old_count:
			shot_serial += 1
			shots[-1].trial_id = "shot-%d" % shot_serial
			trial_state.record_shot(shots[-1].trial_id)
		if not skitterling.locked():
			camera_x = move_toward(camera_x,clampf(player.x-320,0,WORLD_WIDTH-960),400*dt)
		skitterling.advance(self,dt)
		clogfather.advance(self,dt)
		if begin_pending_boss_intro(): return
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
		if life_state == "alive": step_campaign_swarms(dt)
		if life_state != "alive": break
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
	step_hostile_projectiles(delta)
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
	campaign_art.draw(self)
	dispenser.draw_machines(self)

func sync_boss_presentation() -> void:
	# Boss meters overlay the continuous scene, without reserving a separate sidebar.
	transform = Transform2D.IDENTITY

func _draw() -> void:
	if flush.active:
		flush.draw(self)
		return
	if trial_data.is_empty(): return
	draw_set_transform(Vector2(-floorf(camera_x),0))
	draw_environment()
	for actor in actors:
		if actor.hp > 0 and MonsterEntry.active(actor) and actor.entry.mode == "background" and actor.entry.clip.has_area():
			draw_entry_actor(actor)
	campaign_art.draw_opening_lips(self)
	skitterling.draw_back(self)
	for enemy: Dictionary in enemies: draw_toilet(enemy)
	for corpse: Dictionary in corpses: draw_toilet(corpse)
	swarms.draw(self,show_enemy_health_bars)
	dispenser.draw_world(self)
	for actor in actors:
		if MonsterEntry.active(actor) and actor.entry.mode == "background" and actor.entry.clip.has_area(): continue
		if not foreground_entry(actor): draw_actor(actor)
	campaign_art.draw_fixtures(self,true)
	skitterling.draw_actor(self)
	ending.draw_portal(self)
	clogfather.draw(self)
	# Room scenery must not cover the continuous route's below-floor cutaway.
	wastewater_art.draw(self,camera_x,elapsed,false,campaign_art.pit_water.channel_exclusions(campaign.level.pits))
	campaign_art.draw_pit_cutaways(self)
	ending.draw_surge(self,false)
	special_art.draw_back(self)
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
	devil_spider_art.draw_effects(self)
	shooter_remains.draw(self)
	regular_remains.draw(self)
	special_art.draw_front(self)
	draw_foreground_entries()
	draw_set_transform(Vector2.ZERO)
	ending.draw_shout(self)
	draw_set_transform_matrix(transform.affine_inverse())
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
			flush.ride.audio.stop()
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
	devil_spiders.clear(self,"level_transition")
	specials.cancel("level transition")
	special_audio.stop()
	specials.configure(employee.id,"level-two")
	flush.ride.checkpoint_index = 0
	flush.begin(self)

func step_death(delta: float) -> void:
	if not flush.active:
		if pit_falling: death_ground_time = 0.5 if death_time > 0.9 else 0.0
		super.step_death(delta)
		return
	if paused or life_state != "dying": return
	death_time += delta
	if flush.state == "drain_death":
		var progress := smoothstep(0.0,1.0,death_time)
		flush.position = flush.drain_origin*(1.0-progress)
		flush.sink_depth = progress
		flush.sync_hero(self)
	var duration: float = flush.ride.FALL_DURATION if flush.state == "ride" and flush.ride.events.has("fall") else 1.0
	if death_time < duration: return
	life_state = "game_over" if lives == 0 else "death_popup"
	death_popup_locked = true
	death_popup_guard = 0.35
	resume_button.disabled = true
	title_button.disabled = true
	resume_button.text = ("Retry Encounter" if lives == 0 else "Continue at Encounter") if flush.checkpoint_saved \
		else ("Retry Flush" if lives == 0 else "Continue at Bowl")
	resume_button.position = Vector2(245,326)
	title_button.position = Vector2(245,416)
	style_pause_buttons()
	set_paused(true)

func sync_capture_input() -> void:
	# A fire press made during screenshot freeze must not queue a cosmetic action.
	if flush.active and flush.state == "ride":
		flush.ride.fidget.step(flush.ride,Input.is_action_pressed("shoot"),0,true,true,life_state == "alive")
		flush.ride.super_held = Input.is_action_pressed("special")

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
		if not source.is_finite(): return {}
	for point in authored.get("waypoints",[]): waypoints.append(Vector2(point[0],point[1]))
	var mouth: Vector2 = source if mode == "background" else Vector2.ZERO
	var duration: float = authored.get("duration",float(tuning.arrival_warning_seconds)+TRAVEL_SECONDS+SETTLE_SECONDS 		if mode in ["foreground","background"] else 1.2)
	# Edge arrivals finish at the first fully visible position. Crossing the room is ordinary combat.
	var destination: Vector2 = spec.feet
	if mode == "left": destination.x = camera_x+radius+2
	elif mode == "right": destination.x = camera_x+960-radius-2
	var lane_left := 0.0 if spec.feet.x < SkitterlingRoom.QUIET else SkitterlingRoom.EXIT_END
	var lane_right := SkitterlingRoom.QUIET if spec.feet.x < SkitterlingRoom.QUIET else ClogfatherRoom.CONTAINMENT
	var footprint := swarm_cloud_bounds() if spec.role == "swarm" else Rect2(-48,0,96,108) if spec.get("variant","") == "devil" else render_bounds(spec.role)
	if destination.x+footprint.position.x < lane_left or destination.x+footprint.end.x > lane_right: return {}
	var route := MonsterEntry.create(destination,radius,duration,mode,mouth,camera_x,player+PLAYER_SIZE*0.5,
		source if mode != "background" else Vector2.INF,waypoints)
	MonsterEntry.advance(route,0)
	if mode in ["left","right","bottom"]:
		route.duration = maxf(route.duration,route.length/(240 if spec.role == "runner" else 450))
	if mode in ["left","right","top","bottom"]:
		var shape := swarm_cloud_bounds() if spec.role == "swarm" else Rect2(-48,0,96,108) if spec.get("variant","") == "devil" else render_bounds(spec.role)
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
	var margin := 4.0+float(swarms.formations.micro_motion.amplitude_pixels)
	for point in swarms.formations.formations.cloud.anchors:
		var glyph := Rect2(Vector2(point[0],point[1])-Vector2(64,64)-Vector2.ONE*margin,Vector2.ONE*margin*2)
		result = result.merge(glyph) if result.has_area() else glyph
	return result


func live_population() -> int:
	var count := 0
	for actor in actors:
		if actor.hp > 0: count += 1
	for swarm in swarms.actors:
		if swarm.hp > 0 and not swarm.get("clogfather_reinforcement",false): count += 1
	return count


func pattern_owners() -> Dictionary:
	var owners := {}
	for actor in actors:
		if actor.hp <= 0: continue
		if actor.contact_live or actor.winding or actor.volley_left > 0 \
			or (not actor.depth.is_empty() and not actor.active): owners[actor.event_id] = true
	for swarm in swarms.actors:
		if swarm.hp > 0 and swarm.has("event_id") and swarm.get("pattern_live",false): owners[swarm.event_id] = true
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


func step_trial_actors(delta: float) -> void:
	for index in range(actors.size()-1,-1,-1):
		var actor: Dictionary = actors[index]
		actor.age += delta
		actor.clock += delta
		actor.flash = maxf(0,actor.flash-delta)
		var shape := actor_shape(actor)
		actor.seen = actor.get("seen",false) or Rect2(actor.feet+shape.position,shape.size).intersects(Rect2(camera_x,0,960,540))
		if not actor.seen and not actor.active and player.x >= actor.end:
			ledger[actor.event_id] = "expired"
			actors.remove_at(index)
			continue
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
			var was_grounded: bool = actor.get("grounded",false)
			var requested := Vector2(direction*90,actor.vy)
			requested = FlushfiendNavigation.velocity(Rect2(actor.feet+body.position,body.size),
					requested,actor,delta,trial_level.plinths,trial_level.move_body,GRAVITY,JUMP_SPEED)
			requested.y += GRAVITY*delta
			var motion := trial_level.move_body(actor.feet+body.position,
				requested,body.size,delta)
			actor.feet = motion.pos-body.position
			actor.vy = motion.velocity.y
			actor.grounded = motion.grounded
			if actor.feet.x >= camera_x and actor.feet.x <= camera_x+960:
				if was_grounded and not actor.grounded and requested.y < 0:
					creature_audio["toilet"].play_action("hop",actor)
				elif not was_grounded and actor.grounded:
					creature_audio["toilet"].play_action("land",actor)
				elif actor.grounded and absf(requested.x) > 1:
					creature_audio["toilet"].play_action("step",actor)
			actor.facing = signf(requested.x) if requested.x != 0 else actor.facing
			actor.feet.x = clampf(actor.feet.x,actor.bounds.x,actor.bounds.y)
			if not actor.get("arrival_guard",false) and actor.age >= actor.get("rearm_until",0.0) \
				and actor_rect(actor).grow(120).intersects(Rect2(player,PLAYER_SIZE)) and can_pattern(actor.event_id):
				actor.contact_live = true
			if actor.contact_live and actor_rect(actor).intersects(Rect2(player,PLAYER_SIZE)): hurt_player()
		elif actor.role == "aggressive_flyer":
			if actor.get("variant","") == "devil": continue
			if crossing_reserved() \
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

	for actor: Dictionary in actors: sync_trial_action_motion(actor)


func shooter_allowed(actor: Dictionary) -> bool:
	return actor.feet.x >= camera_x+24 and actor.feet.x <= camera_x+936 \
		and absf(actor.feet.x-player.x) < 700 and not crossing_reserved()


func begin_flyer_pattern(actor: Dictionary) -> bool:
	if crossing_reserved() or in_pressure_dip() or not can_pattern(actor.event_id): return false
	actor.contact_live = true
	return true


func end_flyer_pattern(actor: Dictionary) -> void:
	actor.contact_live = false


func shot_origin(actor: Dictionary) -> Vector2:
	if actor.get("mount","") == "ceiling": return ceiling_shooter_art.muzzle(actor.feet,ceiling_direction(actor))
	return actor.feet + Vector2(18 * actor.facing,25 if actor.get("mount","") == "ceiling" else -25)


func count_shooter(reason: String) -> void:
	shooter_stats[reason] = int(shooter_stats.get(reason,0))+1


func step_three_shooter(actor: Dictionary, delta: float) -> void:
	if in_pressure_dip() and not actor.winding and actor.volley_left == 0:
		actor.recovery = maxf(0,actor.recovery-delta)
		return
	actor.recovery = maxf(0,actor.recovery-delta)
	if actor.volley_left > 0:
		actor.volley_clock -= delta
		if actor.volley_clock <= 0:
			emit_trial_shot(actor)
		return
	if not shooter_allowed(actor):
		count_shooter("outside_or_crossing")
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
		actor.winding = false
		actor.recovery = float(tuning.recovery_seconds)
		return
	actor.volley_left = next_volley_size(actor)
	actor.volley_index += 1
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


func event_specs() -> Array[Dictionary]:
	return campaign.specs

func draw_entry_fixture(_actor: Dictionary, _front := false) -> void:
	# Campaign art batches each door behind and in front of the actor pass.
	pass

func in_pressure_dip() -> bool:
	return campaign.pressure_dip(player.x)

func special_floor_solids() -> Array[Rect2]:
	return campaign.level.floor_solids()

func crossing_reserved() -> bool:
	if crossing_airborne or trial_clock < crossing_until: return true
	for opening in campaign.level.pits:
		if player.x > opening.x-80 and player.x < opening.y+50: return true
	return false

func update_crossing(was_grounded: bool) -> void:
	for opening in campaign.level.pits:
		if was_grounded and not grounded and player.x > opening.x-140 and player.x < opening.y+60:
			crossing_airborne = true
	if crossing_airborne and grounded:
		crossing_airborne = false
		crossing_until = trial_clock+0.45

func admitted_trajectory(origin: Vector2, direction: Vector2, _max_range := INF) -> bool:
	if not purple_shot_allowed(origin,direction) or crossing_reserved(): return false
	var end := origin+direction*6000
	for opening in campaign.level.pits:
		var corridor := Rect2(opening.x-60,300,opening.y-opening.x+140,140).grow(BULLET_RADIUS)
		var crossing_hit := segment_hit(origin,end,corridor)
		if crossing_hit < 0: continue
		var blocked := false
		for solid in player_shot_solids():
			var hit := segment_hit(origin,end,solid.grow(BULLET_RADIUS))
			if hit >= 0 and hit < crossing_hit:
				blocked = true
				break
		if not blocked and not (player.x > opening.y+80 and origin.x > player.x and direction.x < 0):
			return false
	return true

func step_campaign_swarms(delta: float) -> void:
	# Tick each swarm once. Boss-owned adds bypass ordinary admission/expiry/pattern accounting.
	swarms.target = player+PLAYER_SIZE*0.5
	swarms.viewport = Rect2(camera_x,0,960,540)
	swarms.hero_cooldown = maxf(0,swarms.hero_cooldown-delta)
	for index in range(swarms.actors.size()-1,-1,-1):
		var actor: Dictionary = swarms.actors[index]
		var ordinary: bool = actor.has("event_id") and not actor.get("clogfather_reinforcement",false)
		if actor.hp <= 0:
			swarms.step_motion(actor,delta,actor_solids())
			if ordinary: ledger[actor.event_id] = "killed"
			if actor.death >= 0.64: swarms.actors.remove_at(index)
			continue
		if ordinary:
			var shape := swarm_cloud_bounds()
			actor.seen = actor.get("seen",false) or Rect2(actor.pos+shape.position,shape.size).intersects(swarms.viewport)
			if not actor.seen and swarms.entry_active(actor) and player.x >= actor.get("end",INF):
				ledger[actor.event_id] = "expired"
				swarms.actors.remove_at(index)
				continue
		if swarms.entry_active(actor):
			swarms.step_motion(actor,delta,actor_solids())
			continue
		if ordinary and actor.pos.x+maxf(64,swarms.visual_radius) < camera_x:
			stop_trial_actions(actor)
			ledger[actor.event_id] = "retired"
			swarms.actors.remove_at(index)
			continue
		actor.hunt_bounds = swarm_hunt_bounds(actor)
		if ordinary:
			var committed: bool = actor.hunt_state in ["acquire","pursue","reform","recover"]
			actor.pattern_live = committed
			if not committed:
				if crossing_reserved() or in_pressure_dip() or not can_pattern(actor.event_id):
					actor.reacquire_wait = maxf(actor.reacquire_wait,delta*2)
				else: actor.pattern_live = true
		swarms.step_motion(actor,delta,actor_solids())
		if ordinary:
			actor.pattern_live = actor.hunt_state in ["acquire","pursue","reform","recover"]
		if swarms.viewport.intersects(Rect2(actor.pos-Vector2.ONE*64,Vector2.ONE*128)):
			actor.warning = maxf(0,actor.get("warning",0.0)-delta)
		if not actor.get("contact_ready",false):
			if swarms.overlaps(actor,Rect2(player,PLAYER_SIZE)): continue
			actor.contact_ready = true
		if swarms.hero_cooldown <= 0 and invulnerable <= 0 and life_state == "alive" \
				and swarms.overlaps(actor,Rect2(player,PLAYER_SIZE)):
			hurt_player()
			swarms.hero_cooldown = float(swarms.definition.contact.per_target_cooldown_seconds)

func move_flyer_clear(actor: Dictionary, destination: Vector2) -> bool:
	# Bound the requested sweep before motion; containment must not teleport a visible survivor.
	var shape := actor_shape(actor)
	var left := 0.0 if actor.home.x < SkitterlingRoom.QUIET else SkitterlingRoom.EXIT_END
	var right := SkitterlingRoom.QUIET if actor.home.x < SkitterlingRoom.QUIET else ClogfatherRoom.CONTAINMENT
	destination.x = clampf(destination.x,left-shape.position.x,right-shape.end.x)
	return super.move_flyer_clear(actor,destination)

func step_encounters(_delta: float) -> void:
	# Compatibility for callers of the base hook; never run the inherited kill-quota spawner.
	issue_event()

func _on_swarm_damaged(actor: Dictionary, lethal: bool) -> void:
	if flush.active:
		var sound = creature_audio["sewer-fly-swarm"]
		if lethal: sound.play_defeat()
		else: sound.play_hit(actor,elapsed)
	else: super._on_swarm_damaged(actor,lethal)
