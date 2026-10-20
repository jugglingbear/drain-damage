extends "res://scripts/game.gd"
## Explicit comparison mode; original campaign data and progression remain independent.
const TrialState = preload("res://scripts/opening_trial_state.gd")
const TrialLevel = preload("res://scripts/opening_trial_level.gd")
var trial_state := TrialState.new()
var trial_level := TrialLevel.new()
var trial_data: Dictionary
var actors: Array[Dictionary] = []
var hostile_shots: Array[Dictionary] = []
var trial_textures: Dictionary = {}
var shot_serial := 0
var result_shown := false
var retry_after: Dictionary = {}
const ROLE_KEYS := {"perched_shooter":"sputtervalve", "floor_emerger":"gratecrawler",
	"aggressive_flyer":"hallowed-widow-trial"}
const AUDIO_IDS := {"runner":"toilet", "rear_runner":"toilet", "perched_shooter":"sputtervalve",
	"floor_emerger":"gratecrawler", "aggressive_flyer":"spider"}
const BALANCE_KEYS := {"runner":"runner", "rear_runner":"runner", "perched_shooter":"shooter",
	"floor_emerger":"emerger", "aggressive_flyer":"flyer"}

func _ready() -> void:
	Data.load_data()
	trial_data = Data.bundle.opening_trial
	trial_level.configure(trial_data.layout)
	trial_state.configure(trial_data.layout,trial_data.balance)
	load_trial_textures(trial_data.environment)
	load_trial_textures(trial_data.role_art)
	super._ready()

func load_trial_textures(value: Variant) -> void:
	if value is Dictionary:
		if value.has("path") and value.has("source_rect"):
			trial_textures[value.path] = load("res://"+value.path)
		for child in value.values(): load_trial_textures(child)
	elif value is Array:
		for child in value: load_trial_textures(child)

func reset_game() -> void:
	super.reset_game()
	reset_observation()

func reset_observation() -> void:
	for sound in creature_audio.values(): sound.stop()
	dispenser.cancel()
	elapsed = 0.0
	trial_state.reset()
	retry_after.clear()
	actors.clear()
	hostile_shots.clear()
	enemies.clear()
	swarms.actors.clear()
	shots.clear()
	result_shown = false
	shot_serial = 0
	weapon = Data.weapon(employee.weapon_id,employee.id).duplicate(true)
	for key in ["damage","attack_interval_seconds"]:
		weapon[key] = trial_data.balance.weapons[employee.weapon_id][key]

func respawn_after_death() -> void:
	super.respawn_after_death()
	if lives > 0: reset_observation()

func resume_or_retry() -> void:
	if death_popup_locked: return
	if result_shown:
		reset_game()
		return
	super.resume_or_retry()

func move_player_body(position: Vector2, motion: Vector2, size: Vector2, delta: float) -> Dictionary:
	return trial_level.move_body(position,motion,size,delta)

func actor_solids() -> Array[Rect2]:
	var solids := trial_level.actor_solids()
	solids.append(Rect2(0,440,6000,100))
	return solids

func player_shot_solids() -> Array[Rect2]:
	var solids := trial_level.projectile_solids()
	solids.append(Rect2(0,440,6000,100))
	return solids

func hurt_player() -> void:
	var before := health
	super.hurt_player()
	if health < before: trial_state.record_damage(before-health)

func _physics_process(delta: float) -> void:
	if paused or result_shown or life_state in ["game_over","death_popup"]: return
	if life_state == "dying":
		step_death(delta)
		return
	if dialogue.active or dialogue.release_guard > 0 or restart_guard_device >= 0: return
	var count := maxi(1,ceili(delta*120))
	for index in range(count):
		var dt := delta/count
		trial_state.advance(dt,false)
		if trial_state.finished:
			show_results()
			break
		var old_size := shots.size()
		step_player(dt)
		if shots.size() > old_size:
			shot_serial += 1
			shots[-1].trial_id = "shot-%d" % shot_serial
			trial_state.record_shot(shots[-1].trial_id)
		camera_x = move_toward(camera_x,clampf(player.x-320,0,5040),400*dt)
		issue_event()
		step_trial_actors(dt)
		step_trial_shots(dt)
		if life_state != "alive": break

func role_scale(role: String) -> float:
	return float(trial_data.balance.roles.flyer.get("render_scale",1.0)) if role == "aggressive_flyer" else 1.0

func event_size(role: String) -> Rect2:
	if role in ["runner","rear_runner"]: return Rect2(-19,-36,38,36)
	var r: Array = trial_data.role_art.roles[ROLE_KEYS[role]].proposed_hitbox_relative_to_anchor
	return Rect2(Vector2(r[0],r[1])*role_scale(role),Vector2(r[2],r[3])*role_scale(role))

func actor_rect(actor: Dictionary) -> Rect2:
	var body := event_size(actor.role)
	body.position += actor.feet
	return body

func actor_projectile_rect(actor: Dictionary) -> Rect2:
	if actor.role in ["runner", "rear_runner"]: return flushfiend_projectile_rect(actor.feet)
	return actor_rect(actor)

func actor_world_limit() -> float:
	return 6000.0

func position_safe(feet: Vector2, role: String, activation := false) -> bool:
	var body := event_size(role)
	body.position += feet
	if body.position.x < 0 or body.end.x > actor_world_limit(): return false
	if body.grow(45 if activation else 100).intersects(Rect2(player,PLAYER_SIZE)): return false
	for other in actors:
		if other.hp > 0 and other.feet != feet and body.grow(12).intersects(actor_rect(other)): return false
	for solid in actor_solids():
		if body.grow(-0.1).intersects(solid): return false
	return true

func choose_home(event: Dictionary) -> Vector2:
	var role: String = event.role
	if role == "aggressive_flyer":
		for actor in actors:
			if actor.role == role and actor.hp > 0: return Vector2.INF
	if role == "perched_shooter":
		for point in trial_data.layout.placement_rules.visible_deck.candidate_feet:
			var feet := Vector2(point[0],point[1])
			if feet.x > player.x+220 and feet.x < player.x+420 and feet.x > camera_x+50 \
				and feet.x < camera_x+910 and position_safe(feet,role): return feet
	elif role == "floor_emerger":
		for x in trial_data.layout.placement_rules.visible_grate.candidate_x:
			var feet := Vector2(x,440)
			var landing_x := player.x+velocity.x*1.45
			if absf(x-landing_x) < 160: continue
			if x > player.x+180 and x < player.x+420 and x < camera_x+920 and position_safe(feet,role): return feet
	elif role == "rear_runner":
		if camera_x < 150 or velocity.x > 150: return Vector2.INF
		var feet := Vector2(camera_x-48,440)
		if player.x-feet.x >= 220 and position_safe(feet,role): return feet
	else:
		var y := 440.0
		if role == "aggressive_flyer": y = 250
		for offset in range(0,241,40):
			var feet := Vector2(minf(camera_x+1008+offset,actor_world_limit()-40),y)
			if feet.x-player.x >= 220 and position_safe(feet,role): return feet
	return Vector2.INF

func issue_event() -> void:
	if trial_state.next_eligible().is_empty(): return
	# An unsafe role remains pending, but must not block other safe eligible roles.
	for event: Dictionary in trial_state.results().events:
		if event.state != "pending" or event.eligible_gameplay_second > trial_state.elapsed: continue
		if trial_state.elapsed < retry_after.get(event.id, 0.0): continue
		var home := choose_home(event)
		if home == Vector2.INF or not trial_state.reserve(event.id): continue
		create_actor(event, home)
		return

func create_actor(event: Dictionary, home: Vector2) -> void:
	var role: String = event.role
	var stats: Dictionary = trial_data.balance.roles[BALANCE_KEYS[role]]
	actors.append({"event_id":event.id,"role":role,"feet":home,"home":home,"hp":float(stats.spawn_hp),
		"max_hp":float(stats.max_hp),"age":0.0,"active":false,"visible_age":0.0,"death":0.0,
		"flash":0.0,"facing":1.0 if role == "rear_runner" else -1.0,"vy":0.0,"clock":0.0,
		"shot_clock":0.0,"winding":false,"fire_age":-1.0,"contact_live":false,
		"warning_seconds":float(event.warning_seconds),"target":Vector2.ZERO,"flight_time":0.0,"hover_started":false,"hover_remaining":0.0,
		"runner":Data.spawn("toilet",home-Vector2(19,36))})

func damage_trial_actor(actor: Dictionary, amount: float) -> void:
	if amount <= 0 or not is_finite(amount) or actor.hp <= 0: return
	var previous_hp: float = actor.hp
	actor.hp = maxf(0, actor.hp - amount)
	actor.flash = 0.1
	if actor.hp == 0:
		finish_trial_defeat(actor)
	elif actor.hp < previous_hp:
		creature_audio[AUDIO_IDS[actor.role]].play_hit(actor, float(actor.get("age", elapsed)))

func finish_trial_defeat(actor: Dictionary) -> void:
	if actor.get("defeat_recorded",false): return
	actor.defeat_recorded = true
	creature_audio[AUDIO_IDS[actor.role]].play_defeat()
	trial_state.death(actor.event_id)
	kills += 1
	player_kills += 1
	if actor.role in ["runner","rear_runner"]:
		# Opening runners share the persistent animated wreckage used by later Flushfiends.
		var corpse: Dictionary = actor.runner.duplicate(true)
		corpse.pos = actor.feet-Vector2(19,36)
		corpse.hp = 0.0
		corpse.max_hp = actor.max_hp
		corpse.direction = actor.facing
		corpse.flash = actor.flash
		corpse.death_time = 0.0
		corpse.death_velocity = 0.0
		corpses.append(corpse)

func move_ground_actor(actor: Dictionary, dx: float, delta: float) -> void:
	if actor.role in ["runner","rear_runner"]:
		var bounds := event_size(actor.role)
		var navigation := FlushfiendNavigation.velocity(Rect2(actor.feet+bounds.position,bounds.size),
			Vector2(dx,actor.vy),actor,delta,trial_level.plinths,trial_level.move_body,GRAVITY,JUMP_SPEED)
		dx = navigation.x
		actor.vy = navigation.y
		if dx != 0: actor.facing = signf(dx)
	actor.vy += GRAVITY*delta
	var shape := event_size(actor.role)
	var motion: Dictionary = trial_level.move_body(actor.feet+shape.position,Vector2(dx,actor.vy),shape.size,delta)
	actor.feet = motion.pos-shape.position
	actor.vy = motion.velocity.y
	# The body sweep uses this role's actual bounds; a blocked patrol turns instead of jumping.
	if actor.role == "floor_emerger" and delta > 0 and dx != 0 and motion.velocity.x == 0:
		actor.facing = -signf(dx)

func step_trial_actors(delta: float) -> void:
	for actor in actors:
		actor.age += delta
		actor.clock += delta
		actor.flash = maxf(0,actor.flash-delta)
		if actor.hp <= 0:
			actor.death += delta
			continue
		var visible: bool = actor.feet.x > camera_x+25 and actor.feet.x < camera_x+935
		if visible: actor.visible_age += delta
		if not actor.active:
			if actor.age > 3.0 or actor.feet.x < camera_x-80:
				trial_state.cancel(actor.event_id,"entry never became safely visible")
				retry_after[actor.event_id] = trial_state.elapsed+0.6
				actor.hp = -1
				actor.death = 1
				continue
			# Edge entrants approach harmlessly; arrival time alone cannot enable offscreen damage.
			if actor.role in ["runner","rear_runner","aggressive_flyer"]:
				if actor.role == "aggressive_flyer": actor.feet.x += actor.facing*100*delta
				else: move_ground_actor(actor,actor.facing*150,delta)
			if not visible or actor.visible_age < actor.warning_seconds: continue
			if not position_safe(actor.feet,actor.role,true): continue
			if not trial_state.activate(actor.event_id): continue
			actor.active = true
			actor.clock = 0
		if actor.role == "perched_shooter":
			step_shooter(actor,delta,visible)
		elif actor.role == "aggressive_flyer":
			step_flyer(actor,delta)
		else:
			if actor.role == "floor_emerger":
				if actor.feet.x <= actor.home.x-70 and actor.facing < 0:
					actor.facing = 1.0
				elif actor.feet.x >= actor.home.x+70 and actor.facing > 0:
					actor.facing = -1.0
			var dx: float = actor.facing*90
			if actor.role in ["runner","rear_runner"]:
				var pursuit: Dictionary = Data.monster("toilet").pursuit
				dx = pursuit_velocity(actor.runner,player.x-actor.feet.x,pursuit,delta)
				actor.facing = signf(dx) if dx != 0 else actor.facing
			move_ground_actor(actor,dx,delta)
		var pattern := "contact-"+str(actor.event_id)
		# Hold a contact slot for the entire visible threat, not just the collision tick.
		if actor.role != "perched_shooter":
			if visible and not actor.contact_live:
				actor.contact_live = trial_state.begin_pattern(pattern,actor.event_id)
			elif not visible and actor.contact_live:
				trial_state.end_pattern(pattern)
				actor.contact_live = false
			if actor.contact_live and actor_rect(actor).intersects(Rect2(player,PLAYER_SIZE)): hurt_player()
		if actor.role != "aggressive_flyer" and (actor.feet.x < camera_x-160 or actor.feet.x > actor_world_limit()+160):
			trial_state.retire(actor.event_id)
			actor.hp = -1
			actor.death = 1
	for index in range(actors.size()-1,-1,-1):
		if actors[index].hp <= 0 and actors[index].death >= 0.6: actors.remove_at(index)

func move_flyer_clear(actor: Dictionary, destination: Vector2) -> bool:
	# Sweep the whole scaled body so a committed dive cannot tunnel through a deck.
	var shape := event_size("aggressive_flyer")
	destination.x = clampf(destination.x,-shape.position.x,WORLD_WIDTH-shape.end.x)
	var closest := 1.0
	for solid in actor_solids():
		var expanded := Rect2(solid.position-shape.end,solid.size+shape.size)
		var hit := segment_hit(actor.feet,destination,expanded)
		if hit >= 0: closest = minf(closest,maxf(0,hit-0.001))
	actor.feet = actor.feet.lerp(destination,closest)
	return closest >= 1.0

func face_flyer_toward_hero(actor: Dictionary) -> void:
	var distance: float = player.x+PLAYER_SIZE.x*0.5-actor.feet.x
	# Keep the previous heading under a nearly centered hero instead of jittering left/right.
	if absf(distance) > 6.0: actor.facing = signf(distance)

func step_flyer(actor: Dictionary, delta: float) -> void:
	if actor.hp <= 0 or paused or life_state != "alive" or dispenser.active or dialogue.active: return
	var stats: Dictionary = trial_data.balance.roles.flyer
	if not actor.has("attack_state"):
		actor.attack_state = "approach"
		actor.attack_clock = 0.0
		actor.attack_origin = actor.feet
		actor.attack_target = actor.feet
	actor.flight_time += delta
	actor.attack_clock += delta
	var visible := actor_rect(actor).position.x >= camera_x and actor_rect(actor).end.x <= camera_x+960
	match actor.attack_state:
		"approach":
			if visible and absf(actor.feet.x-(player.x+PLAYER_SIZE.x*0.5)) <= stats.aggro_distance_pixels:
				var token := "contact-"+str(actor.event_id)
				if not actor.contact_live:
					actor.contact_live = trial_state.begin_pattern(token,actor.event_id)
				if not actor.contact_live: return
				actor.attack_state = "windup"
				actor.attack_clock = 0.0
				actor.attack_origin = actor.feet
				# Lock the warned target even if the hero crosses behind during the approach.
				actor.attack_target = player+PLAYER_SIZE*0.5
				actor.attack_target.y = minf(actor.attack_target.y,440-event_size("aggressive_flyer").end.y-1)
				face_flyer_toward_hero(actor)
				actor.attack_direction = actor.facing
			else:
				var previous: Vector2 = actor.feet
				move_flyer_clear(actor,actor.feet+Vector2(actor.facing*float(stats.speed_pixels_per_second)*delta,0))
				if actor.feet.is_equal_approx(previous): face_flyer_toward_hero(actor)
		"windup":
			if not visible:
				actor.attack_state = "top_pause"
				actor.attack_clock = 0.0
			elif actor.attack_clock >= stats.attack_warning_seconds:
				actor.attack_state = "swoop"
				actor.attack_clock = 0.0
		"swoop":
			var t := clampf(actor.attack_clock/float(stats.swoop_seconds),0,1)
			var clear := move_flyer_clear(actor,actor.attack_origin.lerp(actor.attack_target,t))
			if not clear or t >= 1:
				actor.attack_state = "recover"
				actor.attack_clock = 0.0
				actor.recovery_origin = actor.feet
				var forward_distance := maxf(absf(actor.feet.x-actor.attack_origin.x),
					float(stats.speed_pixels_per_second)*float(stats.recovery_seconds))
				actor.recovery_target = Vector2(actor.feet.x+actor.attack_direction*forward_distance,actor.attack_origin.y)
		"recover":
			var t := clampf(actor.attack_clock/float(stats.recovery_seconds),0,1)
			var clear := move_flyer_clear(actor,actor.recovery_origin.lerp(actor.recovery_target,t))
			if not clear:
				# A blocked diagonal climbs vertically at the recovery rate; never teleport through scenery.
				var climb_speed := maxf(100.0,absf(actor.recovery_origin.y-actor.attack_origin.y)/float(stats.recovery_seconds))
				move_flyer_clear(actor,Vector2(actor.feet.x,move_toward(actor.feet.y,actor.attack_origin.y,climb_speed*delta)))
			if t >= 1 and is_equal_approx(actor.feet.y,actor.attack_origin.y):
				actor.attack_state = "top_pause"
				actor.attack_clock = 0.0
		"top_pause":
			if actor.attack_clock >= float(stats.get("top_pause_seconds",1.0)):
				face_flyer_toward_hero(actor)
				actor.attack_state = "approach"
				actor.attack_clock = 0.0

func step_shooter(actor: Dictionary, delta: float, visible: bool) -> void:
	actor.shot_clock += delta
	var pattern := "fire-"+str(actor.event_id)
	if not visible:
		actor.winding = false
		actor.shot_clock = 0
		trial_state.end_pattern(pattern)
		return
	if not actor.winding:
		if actor.fire_age >= 0 and actor.age-actor.fire_age >= 0.35:
			trial_state.end_pattern(pattern)
		if actor.shot_clock < 0.8: return
		if not trial_state.begin_pattern(pattern,actor.event_id): return
		actor.target = player+PLAYER_SIZE*0.5
		actor.facing = signf(actor.target.x-actor.feet.x)
		actor.winding = true
		actor.shot_clock = 0
		return
	if actor.shot_clock < 0.65: return
	var muzzle: Vector2 = actor.feet+Vector2(actor.facing*22,-25)
	var clear := true
	for solid in player_shot_solids():
		if segment_hit(muzzle,actor.target,solid) >= 0: clear = false
	var token := "bullet-%s-%s" % [actor.event_id,actor.age]
	if clear and trial_state.add_bullet(token):
		hostile_shots.append({"id":token,"pos":muzzle,"dir":(actor.target-muzzle).normalized(),"age":0.0})
	actor.winding = false
	actor.shot_clock = -0.35
	actor.fire_age = actor.age

func step_trial_shots(delta: float) -> void:
	for index in range(shots.size()-1,-1,-1):
		var shot: Dictionary = shots[index]
		var start: Vector2 = shot.pos
		var travel: float = minf(shot.speed*delta,shot.range-shot.distance)
		var end: Vector2 = start+shot.dir*travel
		var closest := 2.0
		var target := -1
		for solid in player_shot_solids():
			var fraction := projectile_hit(start,end,solid,shot.dir)
			if fraction >= 0 and fraction < closest: closest = fraction
		for a in range(actors.size()):
			if actors[a].hp <= 0 or not actors[a].active: continue
			var fraction := projectile_hit(start,end,actor_projectile_rect(actors[a]),shot.dir)
			if fraction >= 0 and fraction < closest:
				closest = fraction
				target = a
		shot.pos = end
		shot.distance += travel
		if closest <= 1 or shot.distance >= shot.range:
			trial_state.resolve_shot(shot.trial_id,target >= 0)
			if target >= 0:
				var actor: Dictionary = actors[target]
				trial_state.record_damage(minf(actor.hp,shot.damage),false)
				damage_trial_actor(actor,shot.damage)
			shots.remove_at(index)
	for index in range(hostile_shots.size()-1,-1,-1):
		var shot: Dictionary = hostile_shots[index]
		var end: Vector2 = shot.pos+shot.dir*150*delta
		var fraction := segment_hit(shot.pos,end,Rect2(player,PLAYER_SIZE).grow(4))
		var wall := 2.0
		for solid in player_shot_solids():
			var hit := segment_hit(shot.pos,end,solid.grow(4))
			if hit >= 0: wall = minf(wall,hit)
		shot.age += delta
		if fraction >= 0 and fraction < wall: hurt_player()
		if fraction >= 0 or wall <= 1 or shot.age > 3.5:
			trial_state.remove_bullet(shot.id)
			hostile_shots.remove_at(index)
		else: shot.pos = end

func show_results() -> void:
	result_shown = true
	set_paused(true)
	resume_button.text = "Retry Opening Trial"
	resume_button.position.y = 368
	title_button.position.y = 458
	death_popup_locked = true
	death_popup_guard = 0.35
	resume_button.disabled = true
	title_button.disabled = true
	resume_button.release_focus()
	title_button.release_focus()

func _process(delta: float) -> void:
	if result_shown:
		update_death_popup_guard(delta)
		queue_redraw()
		return
	super._process(delta)

func draw_progress() -> void:
	label_at("KILLS  %d" % kills,Vector2(800,30),16,MINT)
	label_at("OPENING TRIAL  ·  %.1f / 20 s" % trial_state.elapsed,Vector2(29,73),12,GOLD)

func region(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])

func draw_asset(asset: Dictionary, destination: Rect2, tint := Color.WHITE) -> void:
	draw_texture_rect_region(trial_textures[asset.path],destination,region(asset.source_rect),tint)

func part(id: String) -> Dictionary:
	for item in trial_data.environment.parts:
		if item.id == id: return item
	return {}

func effect(id: String, center: Vector2) -> void:
	for item in trial_data.environment.effects:
		if item.id == id:
			var size := Vector2(item.logical_size[0],item.logical_size[1])
			var anchor := Vector2(item.anchor[0],item.anchor[1])
			draw_asset(item,Rect2(center-anchor,size))
			return

func draw_environment() -> void:
	for bay in range(maxi(0,int(camera_x/960)-1),mini(7,int(camera_x/960)+3)):
		draw_asset(trial_data.environment.background,Rect2(bay*960,15,960,540))
	for item in trial_data.layout.geometry:
		var rect := region(item.rect)
		if item.collision == "one_way_top":
			draw_asset(part("support"),Rect2(rect.position,Vector2(250,120)),Color(0.65,0.65,0.65))
			draw_asset(part("deck"),rect)
		else: draw_asset(part("access-plinth"),rect)
	for x in range(0,6000,480):
		draw_asset(part("floor-fascia"),Rect2(x,440,480,100))

func draw_actor(actor: Dictionary) -> void:
	if actor.hp <= 0 and actor.role in ["runner","rear_runner"]: return
	if actor.role in ["runner","rear_runner"]:
		var enemy: Dictionary = actor.runner
		enemy.pos = actor.feet-Vector2(19,36)
		enemy.hp = maxf(0,actor.hp)
		enemy.max_hp = actor.max_hp
		enemy.phase = actor.age*4.5
		enemy.flash = actor.flash
		enemy.death_time = actor.death
		enemy.direction = actor.facing
		world_art.draw_toilet(self,enemy)
		return
	var spec: Dictionary = trial_data.role_art.roles[ROLE_KEYS[actor.role]]
	var state := "idle"
	if actor.role == "aggressive_flyer": state = "flight"
	elif actor.role == "floor_emerger":
		if not actor.active and actor.age < actor.warning_seconds: return
		state = "patrol" if actor.active else ("emerge" if actor.age < actor.warning_seconds+0.35 else "settle")
	elif actor.winding: state = "windup"
	elif actor.fire_age >= 0 and actor.age-actor.fire_age < 0.15: state = "fire"
	elif actor.fire_age >= 0 and actor.age-actor.fire_age < 0.5: state = "recover"
	if actor.flash > 0: state = "hurt"
	if actor.hp <= 0: state = "death"
	var animation: Dictionary = spec.states[state]
	var frames: Array = animation.frames
	var clock_value: float = actor.death if actor.hp <= 0 else actor.clock
	if actor.role == "aggressive_flyer" and actor.get("attack_state","") == "windup":
		clock_value *= 2.0
	if actor.role == "floor_emerger" and not actor.active:
		clock_value = maxf(0,actor.age-actor.warning_seconds-(0.35 if state == "settle" else 0.0))
	var duration := 0.0
	for seconds in animation.durations: duration += float(seconds)
	if animation.loop: clock_value = fposmod(clock_value,duration)
	var frame_id: int = frames.back()
	for index in range(frames.size()):
		if clock_value < float(animation.durations[index]):
			frame_id = frames[index]
			break
		clock_value -= float(animation.durations[index])
	var frame: Dictionary = spec.frames[frame_id]
	var destination := region(frame.destination)
	var anchor := Vector2(spec.anchor[0],spec.anchor[1])
	destination.position -= anchor
	# Mirror around the registered anchor, never around the crop's left edge.
	draw_set_transform(actor.feet-Vector2(floorf(camera_x),0),0,
		Vector2(-1 if actor.facing > 0 else 1,1)*role_scale(actor.role))
	draw_asset(frame,destination,Color(1,1,1,1-clampf(actor.death/0.6,0,1)))
	draw_set_transform(Vector2(-floorf(camera_x),0))
	if actor.hp > 0 and actor.active and show_enemy_health_bars:
		var body := actor_rect(actor)
		box(body.position.x,body.position.y-14,body.size.x,4,Color("243447"))
		box(body.position.x,body.position.y-14,body.size.x*actor.hp/actor.max_hp,4,MINT)

func _draw() -> void:
	if trial_data.is_empty(): return
	draw_set_transform(Vector2(-floorf(camera_x),0))
	draw_environment()
	wastewater_art.draw(self,camera_x,trial_state.elapsed,true)
	for actor in actors:
		if not actor.active and actor.hp > 0:
			effect("grate-warning" if actor.role == "floor_emerger" else "landing-warning",
				Vector2(clampf(actor.feet.x,camera_x+35,camera_x+925),minf(actor.feet.y,440)))
		draw_actor(actor)
	if life_state != "alive" or invulnerable <= 0 or int(elapsed*12)%2 == 0: draw_sean(player)
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
	draw_set_transform(Vector2.ZERO)
	draw_hud()
	if paused:
		box(0,0,960,540,Color(0.03,0.07,0.12,0.88))
		if life_state in ["game_over","death_popup"]:
			draw_death_popup()
		elif result_shown:
			var result: Dictionary = trial_state.results()
			label_at("OPENING TRIAL RESULTS",Vector2(205,140),30,MINT)
			var line := 180
			for key in ["issued","killed","active","deferred","unavailable","damage","shots","misses"]:
				label_at("%s: %s" % [key.capitalize(),result.get(key,0)],Vector2(245,line),18,Color.WHITE)
				line += 21
			label_at("12 scheduled · Pickup trial not included",Vector2(245,345),15,GOLD)
			draw_pause_plates()
		else:
			draw_pause_panel()
