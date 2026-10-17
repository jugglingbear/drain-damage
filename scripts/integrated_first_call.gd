extends "res://scripts/opening_trial_game.gd"
## Continuous opening replaces the first two rooms; campaign coordinates never change.
const OPENING_END := 3120.0
const TRIGGERS := [100.0,250.0,450.0,600.0,800.0,1000.0,1200.0,1400.0,1650.0,1900.0,2200.0,2450.0]
const WAVE_RANGES := [Vector2(3500,4800), Vector2(4900,6480), Vector2(6860,8160), Vector2(8400,9380)]
const WAVE_COUNTS := [8,10,10,8]
const CROWD_CAP := 8
var wave_spawned: Array[int] = [0,0,0,0]
var wave_bypassed: Array[int] = [0,0,0,0]
var wave_clock := 0.0
var next_wave_spawn := 0.0
var retired_crowd := 0
var route_progress := 0.0
var preserving_respawn := false
var opening_passed := false

func _ready() -> void:
	super._ready()
	# Base _ready dispatched reset_game, so the mixed geometry is already configured.

func reset_observation() -> void:
	if preserving_respawn: return
	super.reset_observation()
	opening_passed = false
	wave_spawned.fill(0)
	wave_bypassed.fill(0)
	wave_clock = 0
	next_wave_spawn = 0
	retired_crowd = 0
	route_progress = 0
	swarms.reset()
	for index in range(swarms.actors.size()-1,-1,-1):
		if swarms.actors[index].pos.x < OPENING_END: swarms.actors.remove_at(index)
	var layout: Dictionary = trial_data.layout.duplicate(true)
	var kept: Array = []
	for item in layout.geometry:
		if float(item.rect[0]) < OPENING_END - 500: kept.append(item)
	layout.geometry = kept
	for event in layout.timeline: event.eligible_gameplay_second = 0.0
	trial_state.configure(layout, trial_data.balance, true)
	trial_level.configure(layout)
	trial_level.width = WORLD_WIDTH
	for rect in Level.PROPS:
		if rect.position.x >= OPENING_END: trial_level.plinths.append(rect)
	# Legacy indices remain for checkpoint telemetry only, never as kill quotas.
	mission.zone_counts.fill(0)
	mission.current_zone = 2
	gate_progress.fill(1)

func respawn_after_death() -> void:
	preserving_respawn = true
	super.respawn_after_death()
	preserving_respawn = false
	for shot in hostile_shots: trial_state.remove_bullet(shot.id)
	hostile_shots.clear()

func move_player_body(position: Vector2, motion: Vector2, size: Vector2, delta: float) -> Dictionary:
	return trial_level.move_body(position,motion,size,delta)

func player_shot_solids() -> Array[Rect2]:
	var solids := trial_level.projectile_solids()
	solids.append(Rect2(0,440,WORLD_WIDTH,100))
	return solids

func step_gates(_delta: float) -> void:
	# Service shutters are removed from traversal, projectiles and presentation.
	gate_progress.fill(1)

func crowd_population() -> int:
	var count := enemies.size()
	for actor in actors:
		if actor.hp > 0: count += 1
	for swarm in swarms.actors:
		if swarm.hp > 0: count += 1
	return count

func crowd_limit() -> int:
	for actor in actors:
		if actor.hp > 0 and actor.role == "aggressive_flyer": return 6
	return CROWD_CAP

func issue_event() -> void:
	if player.x >= OPENING_END: opening_passed = true
	if opening_passed:
		# Unseen pending threats are retired from scheduling, never credited as kills.
		for event: Dictionary in trial_state.results().events:
			if event.state == "pending":
				trial_state.mark_unavailable(event.id,"passed opening before safe entry")
		return
	if crowd_population() >= crowd_limit() or trial_state.next_eligible().is_empty(): return
	var events: Array = trial_state.results().events
	for index in range(events.size()):
		var event: Dictionary = events[index]
		if event.state != "pending" or player.x < TRIGGERS[index]: continue
		if trial_state.elapsed < retry_after.get(event.id,0.0): continue
		if event.role == "aggressive_flyer":
			if crowd_population() >= 6 or crowd_limit() == 6: continue
		var home := choose_home(event)
		if home == Vector2.INF or home.x >= OPENING_END - 40: continue
		if not trial_state.reserve(event.id): continue
		create_actor(event,home)
		return

func choose_home(event: Dictionary) -> Vector2:
	if event.role == "perched_shooter":
		# Any forward position on a visible deck is valid, not only its far edge.
		for deck in trial_level.decks:
			for x in [deck.position.x+30,deck.get_center().x,deck.end.x-30]:
				var feet := Vector2(x,deck.position.y)
				if x >= player.x+220 and x <= player.x+420 and x > camera_x+50 \
					and x < camera_x+910 and position_safe(feet,event.role): return feet
		return Vector2.INF
	return super.choose_home(event)

func _physics_process(delta: float) -> void:
	if dispenser.just_finished:
		dispenser.just_finished = false
		return
	if dispenser.active or paused or won or life_state in ["game_over","death_popup"]: return
	if life_state == "dying":
		step_death(delta)
		return
	if dialogue.active or dialogue.release_guard > 0 or restart_guard_device >= 0: return
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
		camera_x = move_toward(camera_x,clampf(player.x-320,0,WORLD_WIDTH-960),400*dt)
		issue_event()
		step_trial_actors(dt)
		# Base combat advances campaign bodies. One shared sweep below owns all shots.
		var saved: Array[Dictionary] = shots
		shots = []
		step_combat(dt)
		shots = saved
		step_trial_shots(dt)
		if life_state == "alive": swarms.step(self,minf(dt,0.1/count))
		if life_state != "alive": break
		step_encounters(dt)
	if life_state != "alive": return
	for checkpoint in range(Level.CHECKPOINTS.size()):
		if player.x >= Level.CHECKPOINTS[checkpoint] and checkpoint > checkpoint_index:
			activate_checkpoint(checkpoint)
			if dispenser.active: return
	if player.x >= 9450: complete_job()
	for index in range(particles.size()-1,-1,-1):
		particles[index].pos += particles[index].vel*delta
		particles[index].vel.y += 350*delta
		particles[index].life -= delta
		if particles[index].life <= 0: particles.remove_at(index)

func step_encounters(delta: float) -> void:
	wave_clock += delta
	route_progress = maxf(route_progress,player.x)
	# Retire only well outside view, without kill credit or a visible disappearance.
	for index in range(enemies.size()-1,-1,-1):
		if enemies[index].pos.x+38 < camera_x-320:
			enemies.remove_at(index)
			retired_crowd += 1
	for index in range(WAVE_RANGES.size()):
		if route_progress >= WAVE_RANGES[index].y:
			wave_bypassed[index] = WAVE_COUNTS[index]-wave_spawned[index]
	if wave_clock < next_wave_spawn or crowd_population() >= crowd_limit(): return
	for index in range(WAVE_RANGES.size()):
		if player.x < WAVE_RANGES[index].x or route_progress >= WAVE_RANGES[index].y: continue
		if wave_spawned[index] >= WAVE_COUNTS[index]: continue
		var radius := entrance_radius()
		var first_side := -1.0 if wave_spawned[index] % 3 == 2 else 1.0
		for side in [first_side,-first_side]:
			for offset in range(0,385,48):
				var x: float = floorf(camera_x)+(984+radius if side>0 else -24-radius)-19+side*offset
				var hero_body := Rect2(player,PLAYER_SIZE)
				var spawn_left: float = x+19-radius
				var spawn_right: float = x+19+radius
				if maxf(spawn_left-hero_body.end.x,hero_body.position.x-spawn_right) < 220: continue
				if not safe_entrance(x): continue
				var blocked := false
				for checkpoint in Level.CHECKPOINTS:
					if absf(x+19-checkpoint) < 200: blocked = true
				for actor in actors:
					if actor.hp > 0 and absf(actor.feet.x-x-19) < radius*2+16: blocked = true
				if blocked: continue
				var enemy := Data.spawn("toilet",Vector2(x,404))
				enemy.entering = true
				enemy.direction = signf(player.x-x)
				enemy.hp = float(trial_data.balance.roles.runner.spawn_hp)
				enemy.max_hp = float(trial_data.balance.roles.runner.max_hp)
				enemies.append(enemy)
				wave_spawned[index] += 1
				next_wave_spawn = wave_clock+0.65
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
		shot.pos = end
		shot.distance += travel
		if nearest <= 1 or shot.distance >= shot.range:
			if shot.has("trial_id"): trial_state.resolve_shot(shot.trial_id,actor_target >= 0 or enemy_target >= 0 or swarm_target >= 0)
			if swarm_target >= 0: swarms.damage(swarm_target,shot.damage)
			elif enemy_target >= 0: damage_enemy(enemy_target,shot.damage,start.lerp(end,nearest))
			elif actor_target >= 0:
				var actor: Dictionary = actors[actor_target]
				actor.hp = maxf(0,actor.hp-shot.damage)
				actor.flash = 0.1
				if actor.hp == 0:
					finish_trial_defeat(actor)
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
	for bay in range(maxi(0,int(camera_x/960)-1),mini(10,int(camera_x/960)+3)):
		draw_asset(trial_data.environment.background,Rect2(bay*960,15,960,540))
	for rect in trial_level.decks:
		draw_asset(part("support"),Rect2(rect.position,Vector2(250,120)),Color(0.65,0.65,0.65))
		draw_asset(part("deck"),rect)
	for rect in trial_level.plinths:
		if rect.position.x < OPENING_END: draw_asset(part("access-plinth"),rect)
		else: Level.draw_prop(self,rect)
	for x in range(0,int(WORLD_WIDTH),480):
		draw_asset(part("floor-fascia"),Rect2(x,440,480,100))
	dispenser.draw_machines(self)
	label_at("EXIT →",Vector2(9450,315),16,MINT)

func _draw() -> void:
	if trial_data.is_empty(): return
	draw_set_transform(Vector2(-floorf(camera_x),0))
	draw_environment()
	wastewater_art.draw(self,camera_x,elapsed,false)
	for enemy: Dictionary in enemies: draw_toilet(enemy)
	for corpse: Dictionary in corpses: draw_toilet(corpse)
	swarms.draw(self,show_enemy_health_bars)
	dispenser.draw_world(self)
	for actor in actors:
		if not actor.active and actor.hp > 0:
			effect("grate-warning" if actor.role == "floor_emerger" else "landing-warning",
				Vector2(clampf(actor.feet.x,camera_x+35,camera_x+925),minf(actor.feet.y,440)))
		draw_actor(actor)
	if not dispenser.hides_hero() and (life_state != "alive" or invulnerable <= 0 or int(elapsed*12)%2 == 0): draw_sean(player)
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
	for shot in hostile_shots: effect("hostile-projectile",shot.pos)
	for particle in particles:
		box(particle.pos.x,particle.pos.y,4,4,particle.color)
	draw_set_transform(Vector2.ZERO)
	draw_hud()
	dispenser.draw_overlay(self)
	if paused or (won and not dialogue.active):
		box(0,0,960,540,Color(0.03,0.07,0.12,0.88))
		if life_state in ["game_over","death_popup"]: draw_death_popup()
		else: label_at("JOB COMPLETE" if won else "UNION BREAK",Vector2(245,216),36,MINT)
