extends "res://scripts/game.gd"
## Explicit comparison mode; original campaign data and progression remain independent.
const CeilingShooterArt = preload("res://scripts/ceiling_shooter_art.gd")
var ceiling_shooter_art := CeilingShooterArt.new()
var entry_fixtures: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
	"res://assets/world/three-screen-trial/shooter-entry-fixtures-v1.json"))
var entry_door_art := preload("res://scripts/entry_door_art.gd").new()
const MonsterEntry = preload("res://scripts/monster_entry.gd")
const DevilSpiderRuntime = preload("res://scripts/devil_spider_runtime.gd")
var devil_spiders := DevilSpiderRuntime.new()
const TrialState = preload("res://scripts/opening_trial_state.gd")
const TrialLevel = preload("res://scripts/opening_trial_level.gd")
var trial_state := TrialState.new()
var trial_level := TrialLevel.new()
var trial_data: Dictionary
var actors: Array[Dictionary] = []
var hostile_shots: Array[Dictionary] = []
var trial_textures: Dictionary = {}
var muck_art: Dictionary = {}
var muck_throw_art: Dictionary = {}
var angel_ground_art: Dictionary = {}
const DevilSpiderArt = preload("res://scripts/devil_spider_art.gd")
var devil_spider_art := DevilSpiderArt.new()
const DevilDebris = preload("res://scripts/devil_spider_debris.gd")
var devil_debris := DevilDebris.new()
var regular_remains := preload("res://scripts/regular_remains.gd").new()
var shooter_remains := preload("res://scripts/shooter_remains.gd").new()
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
	await load_trial_textures(trial_data.environment,startup_yield)
	await load_trial_textures(trial_data.role_art,startup_yield)
	muck_art = JSON.parse_string(FileAccess.get_file_as_string("res://assets/bestiary/gratecrawler/muck-ball-manifest-v1.json"))
	await load_trial_textures(muck_art,startup_yield)
	muck_throw_art = JSON.parse_string(FileAccess.get_file_as_string("res://assets/bestiary/gratecrawler/throw-manifest-v1.json"))
	await load_trial_textures(muck_throw_art,startup_yield)
	angel_ground_art = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/bestiary/angel-ground-v1/manifest.json"))
	for frame: Dictionary in angel_ground_art.frames:
		frame.path = angel_ground_art.source
		frame.alpha_cutoff = angel_ground_art.alpha_cutoff
	await load_trial_textures(angel_ground_art,startup_yield)
	await devil_spider_art.prepare(self,startup_yield)
	await shooter_remains.prepare(self,startup_yield)
	await regular_remains.prepare(self,startup_yield)
	await entry_door_art.prepare(self,startup_yield)
	await super._ready()
	var devil_audio := CreatureAudio.new("devil-spider")
	devil_audio.attach(self)
	creature_audio["devil-spider"] = devil_audio

func load_trial_textures(value: Variant, yield_frame := Callable()) -> void:
	if value is Dictionary:
		if value.has("path") and value.has("source_rect") and not trial_textures.has(value.path):
			if yield_frame.is_valid(): await yield_frame.call()
			trial_textures[value.path] = load("res://"+value.path)
			if value.has("alpha_cutoff"):
				var pixels: Image = trial_textures[value.path].get_image()
				pixels.convert(Image.FORMAT_RGBA8)
				var bytes := pixels.get_data()
				for index in range(3,bytes.size(),4):
					if bytes[index] < int(value.alpha_cutoff): bytes[index] = 0
				trial_textures[value.path] = ImageTexture.create_from_image(Image.create_from_data(
					pixels.get_width(),pixels.get_height(),false,Image.FORMAT_RGBA8,bytes))
		for child in value.values(): await load_trial_textures(child,yield_frame)
	elif value is Array:
		for child in value: await load_trial_textures(child,yield_frame)

func reset_game() -> void:
	super.reset_game()
	reset_observation()

func reset_observation() -> void:
	devil_debris.reset()
	shooter_remains.reset()
	regular_remains.reset()
	devil_spiders.clear(self,"retry")
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
	if lives > 0: reset_observation()
	super.respawn_after_death()

func resume_or_retry() -> void:
	if death_popup_locked: return
	if result_shown:
		reset_game()
		return
	super.resume_or_retry()

func move_player_body(position: Vector2, motion: Vector2, size: Vector2, delta: float) -> Dictionary:
	if size == PLAYER_SIZE and devil_spiders.locked() and devil_spiders.captured_actor().devil.capture_kind == "snare":
		return {"pos":position,"velocity":Vector2.ZERO,"grounded":true,"falling":false}
	return devil_spiders.move_body(self,position,motion,size,delta)

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
	if life_state != "alive": devil_spiders.clear(self,"hero_death")

func _input(event: InputEvent) -> void:
	devil_spiders.input_event(self,event)
	super._input(event)

func specials_allowed(ignore_active := false) -> bool:
	return not devil_spiders.locked() and super.specials_allowed(ignore_active)

func step_player(delta: float) -> void:
	devil_debris.step(self,delta)
	shooter_remains.step(self,delta)
	regular_remains.step(self,delta)
	devil_spiders.step(self,delta)
	if devil_spiders.locked() and devil_spiders.captured_actor().devil.capture_kind == "snare":
		# Floor silk blocks walking/jumping, while the ordinary weapon can still defend the hero.
		var snared_position := player
		var supported := grounded
		grounded = false
		coyote = 0
		jump_buffer = 0
		super.step_player(delta)
		player = snared_position
		grounded = supported
		velocity = Vector2.ZERO
		jump_buffer = 0
		return
	if devil_spiders.locked():
		invulnerable = maxf(0,invulnerable-delta)
		hurt_time = maxf(0,hurt_time-delta)
		fire_timer = maxf(0,fire_timer-delta)
		velocity = Vector2.ZERO
		jump_buffer = 0
		return
	super.step_player(delta)

func request_title() -> void:
	if not death_popup_locked: devil_spiders.clear(self,"title")
	super.request_title()

func _exit_tree() -> void:
	devil_spiders.clear(self,"teardown")
	super._exit_tree()

func _physics_process(delta: float) -> void:
	if cinematic.active or cinematic_resume_frame == Engine.get_process_frames(): return
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
	if role in ["aggressive_flyer","floor_emerger"]:
		return float(trial_data.balance.roles[BALANCE_KEYS[role]].get("render_scale",1.0))
	return 1.0

func event_size(role: String) -> Rect2:
	if role in ["runner","rear_runner"]: return FlushfiendGeometry.body_at_feet(Vector2.ZERO)
	var r: Array = trial_data.role_art.roles[ROLE_KEYS[role]].proposed_hitbox_relative_to_anchor
	return Rect2(Vector2(r[0],r[1])*role_scale(role),Vector2(r[2],r[3])*role_scale(role))

func ceiling_direction(actor: Dictionary) -> Vector2:
	var committed: Vector2 = actor.get("committed_dir",Vector2.ZERO)
	if not actor.winding and not committed.is_zero_approx(): return committed
	return (player+PLAYER_SIZE*0.5-ceiling_shooter_art.pivot(actor.feet)).normalized()

func actor_shape(actor: Dictionary) -> Rect2:
	if actor.get("variant","") == "devil": return DevilSpiderRuntime.BODY
	if actor.get("mount","") == "ceiling":
		return ceiling_shooter_art.bounds(Vector2.ZERO,ceiling_direction(actor))
	return event_size(actor.role)

func actor_rect(actor: Dictionary) -> Rect2:
	var body := actor_shape(actor)
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
		"throw_state":"","throw_clock":0.0,"patrol_facing":-1.0,"throw_target":Vector2.ZERO,
		"warning_seconds":float(event.warning_seconds),"target":Vector2.ZERO,"flight_time":0.0,"hover_started":false,"hover_remaining":0.0,
		"runner":Data.spawn("toilet",home-Vector2(19,36))})

	var actor: Dictionary = actors.back()
	if role == "aggressive_flyer" and event.get("variant","") == "devil" and devil_spiders.production_ready():
		devil_spiders.register(actor,event)
	var radius := actor_render_radius(actor.role)
	if home.x+radius >= camera_x and home.x-radius <= camera_x+960:
		start_actor_entry(actor,"top" if role == "aggressive_flyer" else "floor")

func render_bounds(role: String) -> Rect2:
	var result := Rect2()
	if role in ["runner","rear_runner"]: return event_size(role)
	var spec: Dictionary = trial_data.role_art.roles[ROLE_KEYS[role]]
	for frame: Dictionary in spec.frames:
		var rect := region(frame.destination)
		rect.position -= Vector2(spec.anchor[0],spec.anchor[1])
		rect = Rect2(rect.position*role_scale(role),rect.size*role_scale(role))
		result = result.merge(rect) if result.has_area() else rect
	return result

func actor_render_radius(role: String) -> float:
	var radius := 1.0
	if role in ["runner","rear_runner"]:
		var renderer = world_art.damage_art
		renderer.prepare("toilet")
		var scale: float = FlushfiendGeometry.RENDER_HEIGHT / Data.monster("toilet").damage_art.runtime_preparation.reference_body_height_pixels
		for index in range(renderer.regions.toilet.size()):
			var rect := Rect2(-renderer.anchors.toilet[index]*scale,renderer.regions.toilet[index].size*scale)
			radius = maxf(radius,maxf(rect.position.length(),rect.end.length()))
	else:
		var spec: Dictionary = trial_data.role_art.roles[ROLE_KEYS[role]]
		for frame: Dictionary in spec.frames:
			var rect := region(frame.destination)
			rect.position -= Vector2(spec.anchor[0],spec.anchor[1])
			radius = maxf(radius,maxf(rect.position.length(),rect.end.length())*role_scale(role))
	return radius

func start_actor_entry(actor: Dictionary, mode: String, mouth := Vector2.ZERO, duration := 1.2) -> void:
	if actor.role == "perched_shooter" and mode == "foreground":
		push_error("Stationary shooters cannot enter from the foreground")
		return
	actor.mount = mode if mode in ["floor","ceiling"] else ""
	actor.entry = MonsterEntry.create(actor.home,actor_render_radius(actor.role),
		maxf(duration,actor.warning_seconds),mode,mouth,camera_x,player+PLAYER_SIZE*0.5)
	MonsterEntry.advance(actor.entry,0)
	actor.feet = actor.entry.pos
	actor.contact_live = false
	actor.winding = false

func step_actor_entry(actor: Dictionary, delta: float) -> bool:
	if not MonsterEntry.active(actor):
		if not actor.active: hurt_from_exposed_entry(actor)
		return false
	MonsterEntry.advance(actor.entry,delta)
	actor.feet = actor.entry.pos
	actor.contact_live = false
	actor.winding = false
	if actor.entry.complete: actor.entry_cleared_age = actor.age
	hurt_from_exposed_entry(actor)
	return not actor.entry.complete

func exposed_entry_rect(actor: Dictionary) -> Rect2:
	if actor.hp <= 0 or actor.get("mount","") != "floor": return Rect2()
	var entry: Dictionary = actor.get("entry",{})
	if entry.is_empty() or entry.get("mode","") != "floor" or float(entry.clock) <= 0: return Rect2()
	# Match the rendered clipping plane: hidden body below the gate cannot hit the hero.
	return actor_rect(actor).intersection(entry.clip)

func hurt_from_exposed_entry(actor: Dictionary) -> void:
	var exposed := exposed_entry_rect(actor)
	if exposed.has_area() and exposed.intersects(Rect2(player,PLAYER_SIZE)): hurt_player()

func entry_door_open_fraction(actor: Dictionary) -> float:
	# Negative means concealed; admission warnings alone never reveal a future doorway.
	if actor.get("mount","") not in ["floor","ceiling"] or not actor.has("entry"): return -1
	if float(actor.entry.get("clock",0)) <= 0: return -1
	if actor.hp <= 0:
		var death_close := float(actor.get("death",0))/0.25
		return -1 if death_close >= 1 else 1-smoothstep(0,1,death_close)
	if actor.entry.complete and actor.role in ["runner","rear_runner"]:
		var close := (float(actor.age)-float(actor.get("entry_cleared_age",actor.age)))/0.25
		return -1 if close >= 1 else 1-smoothstep(0,1,close)
	return smoothstep(0,0.3,float(actor.entry.clock))

func draw_entry_fixture(actor: Dictionary, front := false) -> void:
	entry_door_art.draw(self,actor,entry_door_open_fraction(actor),front)

func draw_ceiling_entry_support(home: Vector2) -> void:
	# Permanent architecture remains; only the concealed door follows the occupant lifecycle.
	var fixture: Dictionary = entry_fixtures.ceiling
	var texture: Texture2D = load("res://"+fixture.path)
	var destination := region(fixture.support_destination_offset)
	destination.position += home
	var source := region(fixture.support_source_rect)
	var corners := PackedVector2Array([destination.position,Vector2(destination.end.x,destination.position.y),
		destination.end,Vector2(destination.position.x,destination.end.y)])
	var uvs := PackedVector2Array([Vector2(source.position.x,source.end.y),source.end,
		Vector2(source.end.x,source.position.y),source.position])
	for index in range(uvs.size()): uvs[index] /= texture.get_size()
	draw_polygon(corners,PackedColorArray([Color.WHITE]),uvs,texture)
	for offset in fixture.post_center_offsets_x:
		var y := 0.0
		var end: float = home.y+float(fixture.support_destination_offset[1])+2
		while y < end:
			var height := minf(float(fixture.post_logical_tile_height),end-y)
			var post := region(fixture.post_source_rect)
			post.size.y *= height/float(fixture.post_logical_tile_height)
			draw_texture_rect_region(texture,Rect2(home.x+float(offset)-5.5,y,11,height),post)
			y += height

func draw_entry_actor(actor: Dictionary) -> void:
	var entry: Dictionary = actor.entry
	var scale: float = entry.scale
	if actor.role in ["runner","rear_runner"]:
		draw_entry_fixture(actor)
		var enemy: Dictionary = actor.runner.duplicate()
		enemy.hp = actor.hp
		enemy.max_hp = actor.max_hp
		enemy.phase = actor.age*4.5
		enemy.direction = actor.facing
		enemy.grounded = true
		var renderer = world_art.damage_art
		var index: int = renderer.frame_for(enemy)
		var source: Rect2 = renderer.regions.toilet[index]
		var pivot: Vector2 = renderer.anchors.toilet[index]
		scale *= FlushfiendGeometry.RENDER_HEIGHT / Data.monster("toilet").damage_art.runtime_preparation.reference_body_height_pixels
		var destination := Rect2(entry.pos-pivot*scale,source.size*scale)
		if actor.facing > 0:
			destination.position.x = entry.pos.x-(source.size.x-pivot.x)*scale
		# The actual pipe opening, rather than a fade, reveals the leading body.
		var visible: Rect2 = destination.intersection(entry.clip) if entry.clip.has_area() else destination
		if not visible.has_area(): return
		var corners := PackedVector2Array([visible.position,Vector2(visible.end.x,visible.position.y),
			visible.end,Vector2(visible.position.x,visible.end.y)])
		var uvs := PackedVector2Array()
		for point in corners:
			var fraction: Vector2 = (point-destination.position)/destination.size
			if actor.facing > 0: fraction.x = 1-fraction.x
			uvs.append((source.position+fraction*source.size)/renderer.textures.toilet.get_size())
		draw_polygon(corners,PackedColorArray([Color.WHITE]),uvs,renderer.textures.toilet)
		draw_entry_fixture(actor,true)
	else:
		# The ordinary role renderer supplies current animation frames and registered pivots.
		draw_actor(actor,true)

func stop_trial_actions(actor: Dictionary) -> void:
	var id: String = "devil-spider" if actor.get("variant","") == "devil" else AUDIO_IDS[actor.role]
	if creature_audio.has(id): creature_audio[id].stop_actor_actions(actor)

func play_trial_action(actor: Dictionary, event: String) -> void:
	if actor.hp <= 0 or not actor.active or paused or life_state != "alive" or dialogue.active or dispenser.active: return
	if not actor_rect(actor).intersects(Rect2(camera_x,0,960,540)): return
	var id: String = "devil-spider" if actor.get("variant","") == "devil" else AUDIO_IDS[actor.role]
	if creature_audio.has(id): creature_audio[id].play_action(event,actor)

func sync_trial_action_motion(actor: Dictionary) -> void:
	var previous: Vector2 = actor.get("action_audio_feet",actor.feet)
	actor.action_audio_feet = actor.feet
	if actor.hp <= 0 or not actor.active or not actor_rect(actor).intersects(Rect2(camera_x,0,960,540)):
		stop_trial_actions(actor)
		return
	if not actor.get("action_audio_arrived",false):
		actor.action_audio_arrived = true
		play_trial_action(actor,"arrival")
	if actor.role == "perched_shooter" and actor.get("fire_age",-1.0) >= 0:
		if actor.age-actor.fire_age >= 0.15 and actor.get("audio_vent_fire_age",-1.0) != actor.fire_age:
			actor.audio_vent_fire_age = actor.fire_age
			play_trial_action(actor,"vent")
	if actor.get("variant","") == "devil": return
	if not actor.feet.is_equal_approx(previous):
		if actor.role == "floor_emerger": play_trial_action(actor,"step")
		elif actor.role == "aggressive_flyer":
			play_trial_action(actor,"scuttle" if actor.get("attack_state","") == "scuttle" else "wingbeat")

func play_trial_impact(shot: Dictionary, position: Vector2) -> void:
	if paused or dialogue.active or dispenser.active: return
	if not Rect2(camera_x,0,960,540).has_point(position): return
	var id := "gratecrawler" if shot.get("kind","") == "muck" else "sputtervalve"
	if creature_audio.has(id): creature_audio[id].play_action("impact",shot)

func trial_actor_contact(actor: Dictionary) -> void:
	var before := health
	hurt_player()
	if health < before and actor.role == "aggressive_flyer" and actor.get("variant","") != "devil":
		play_trial_action(actor,"contact")

func damage_trial_actor(actor: Dictionary, amount: float) -> void:
	if amount <= 0 or not is_finite(amount) or actor.hp <= 0: return
	var previous_hp: float = actor.hp
	actor.hp = maxf(0, actor.hp - amount)
	actor.flash = 0.1
	if actor.role == "floor_emerger": cancel_muck_throw(actor)
	if actor.hp == 0:
		finish_trial_defeat(actor)
	elif actor.hp < previous_hp:
		creature_audio["devil-spider" if actor.get("variant","") == "devil" else AUDIO_IDS[actor.role]].play_hit(actor, float(actor.get("age", elapsed)))

func special_damage(segments: Array[Dictionary], amount: float, activation: int, boss_remaining: Dictionary) -> Dictionary:
	var applied := super.special_damage(segments,amount,activation,boss_remaining)
	for actor: Dictionary in actors:
		if actor.hp > 0 and actor.active and StarterSpecials.overlaps(segments,actor_projectile_rect(actor)):
			damage_trial_actor(actor,amount)
	return applied

func finish_trial_defeat(actor: Dictionary) -> void:
	stop_trial_actions(actor)
	if actor.get("variant","") == "devil": devil_debris.begin(actor,devil_spider_art.death_spec)
	devil_spiders.owner_killed(self,actor)
	if actor.get("defeat_recorded",false): return
	actor.defeat_recorded = true
	if actor.role == "perched_shooter":
		actor.contact_live = false
		actor.winding = false
		actor.volley_left = 0
		shooter_remains.begin(self,actor)
	elif actor.role == "floor_emerger" or (actor.role == "aggressive_flyer" and actor.get("variant","") != "devil"):
		actor.contact_live = false
		actor.winding = false
		regular_remains.begin(self,actor)
	creature_audio["devil-spider" if actor.get("variant","") == "devil" else AUDIO_IDS[actor.role]].play_defeat()
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
	actor.grounded = motion.grounded
	# The body sweep uses this role's actual bounds; a blocked patrol turns instead of jumping.
	if actor.role == "floor_emerger" and delta > 0 and dx != 0 and motion.velocity.x == 0:
		actor.facing = -signf(dx)

func step_trial_actors(delta: float) -> void:
	if paused or life_state != "alive" or dispenser.active or dialogue.active or delta <= 0: return
	step_opening_actors(delta)
	for actor: Dictionary in actors: sync_trial_action_motion(actor)

func step_opening_actors(delta: float) -> void:
	if paused or life_state != "alive" or dispenser.active or dialogue.active or delta <= 0: return
	for actor in actors:
		actor.age += delta
		actor.clock += delta
		actor.flash = maxf(0,actor.flash-delta)
		if actor.hp <= 0:
			actor.death += delta
			continue
		if step_actor_entry(actor,delta): continue
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
		elif actor.role == "floor_emerger":
			var was_throwing: bool = not actor.throw_state.is_empty()
			step_muck_thrower(actor,delta,visible)
			if not was_throwing and actor.throw_state.is_empty():
				if actor.feet.x <= actor.home.x-70 and actor.facing < 0:
					actor.facing = 1.0
				elif actor.feet.x >= actor.home.x+70 and actor.facing > 0:
					actor.facing = -1.0
				move_ground_actor(actor,actor.facing*float(trial_data.balance.roles.emerger.ground_speed_pixels_per_second),delta)
		else:
			var dx := 0.0
			if actor.role in ["runner","rear_runner"]:
				var pursuit: Dictionary = Data.monster("toilet").pursuit
				dx = pursuit_velocity(actor.runner,player.x-actor.feet.x,pursuit,delta)
				actor.facing = signf(dx) if dx != 0 else actor.facing
			move_ground_actor(actor,dx,delta)
		var pattern := "contact-"+str(actor.event_id)
		# Hold a contact slot for the entire visible threat, not just the collision tick.
		if actor.role != "perched_shooter" and actor.get("variant","") != "devil":
			if visible and not actor.contact_live:
				actor.contact_live = trial_state.begin_pattern(pattern,actor.event_id)
			elif not visible and actor.contact_live:
				trial_state.end_pattern(pattern)
				actor.contact_live = false
			if actor.contact_live and actor_rect(actor).intersects(Rect2(player,PLAYER_SIZE)): trial_actor_contact(actor)
		if actor.role != "aggressive_flyer" and (actor.feet.x < camera_x-160 or actor.feet.x > actor_world_limit()+160):
			stop_trial_actions(actor)
			trial_state.retire(actor.event_id)
			actor.hp = -1
			actor.death = 1
	for index in range(actors.size()-1,-1,-1):
		if actors[index].hp <= 0 and actors[index].death >= 0.6: actors.remove_at(index)

func move_flyer_clear(actor: Dictionary, destination: Vector2) -> bool:
	# Sweep the whole scaled body so a committed dive cannot tunnel through a deck.
	var shape := event_size("aggressive_flyer")
	destination.x = clampf(destination.x,-shape.position.x,actor_world_limit()-shape.end.x)
	destination.y = clampf(destination.y,-shape.position.y+1,440-shape.end.y-1)
	var closest := 1.0
	for solid in actor_solids():
		var expanded := Rect2(solid.position-shape.end,solid.size+shape.size)
		var start: Vector2 = actor.feet
		# Boundary contact permits sliding or moving away, without shrinking the solid into a penetration.
		if (start.x <= expanded.position.x+0.00001 and destination.x <= start.x) \
				or (start.x >= expanded.end.x-0.00001 and destination.x >= start.x) \
				or (start.y <= expanded.position.y+0.00001 and destination.y <= start.y) \
				or (start.y >= expanded.end.y-0.00001 and destination.y >= start.y): continue
		var hit := segment_hit(start,destination,expanded)
		if hit >= 0: closest = minf(closest,maxf(0,hit-0.001))
	actor.feet = actor.feet.lerp(destination,closest)
	return closest >= 1.0

func face_flyer_toward_hero(actor: Dictionary) -> void:
	var distance: float = player.x+PLAYER_SIZE.x*0.5-actor.feet.x
	# Keep the previous heading under a nearly centered hero instead of jittering left/right.
	if absf(distance) > 6.0: actor.facing = signf(distance)

func begin_flyer_pattern(actor: Dictionary) -> bool:
	return trial_state.begin_pattern("contact-"+str(actor.event_id),actor.event_id)

func end_flyer_pattern(actor: Dictionary) -> void:
	stop_trial_actions(actor)
	trial_state.end_pattern("contact-"+str(actor.event_id))
	actor.contact_live = false

func begin_flyer_recovery(actor: Dictionary) -> void:
	var stats: Dictionary = trial_data.balance.roles.flyer
	actor.attack_state = "recover"
	actor.attack_clock = 0.0
	actor.erase("recovery_escape")
	actor.recovery_origin = actor.feet
	var forward_distance := maxf(absf(actor.feet.x-actor.attack_origin.x),
		float(stats.speed_pixels_per_second)*float(stats.recovery_seconds))
	# Recovery stays near the fight; reaching the bound still uses the full-body sweep.
	var shape := event_size("aggressive_flyer")
	var left := maxf(-shape.position.x,camera_x-shape.position.x)
	var right := minf(actor_world_limit()-shape.end.x,camera_x+960-shape.end.x)
	actor.recovery_target = Vector2(clampf(actor.feet.x+actor.attack_direction*forward_distance,left,right),
		actor.attack_origin.y)

func flyer_support(position: Vector2, reach: float, minimum_overlap := 0.65) -> Dictionary:
	var shape := event_size("aggressive_flyer")
	var body := Rect2(position+shape.position,shape.size)
	var result: Dictionary = {}
	for solid in actor_solids():
		var overlap := minf(body.end.x,solid.end.x)-maxf(body.position.x,solid.position.x)
		var gap := solid.position.y-body.end.y
		if overlap < body.size.x*minimum_overlap or gap < -0.01 or gap > reach: continue
		if result.is_empty() or solid.position.y < float(result.y):
			var supported_left := solid.position.x+shape.size.x*.65-shape.end.x
			var supported_right := solid.end.x-shape.size.x*.65-shape.position.x
			if supported_left > supported_right: continue
			result = {"y":solid.position.y,"x":clampf(position.x,supported_left,supported_right)}
	return result

func step_flyer_landing(actor: Dictionary, delta: float) -> void:
	var descent := 240.0*delta
	var support := flyer_support(actor.feet,descent+1.01,0.01)
	var destination: Vector2 = actor.feet+Vector2(0,descent)
	if not support.is_empty():
		# A diagonal dive can touch a top before enough legs overlap it. Ease inward at crawl
		# speed while staying above the surface, instead of rejecting that landing indefinitely.
		destination.x = move_toward(actor.feet.x,float(support.x),65.0*delta)
		destination.y = float(support.y)-event_size("aggressive_flyer").end.y
	move_flyer_clear(actor,destination)
	# The aerial sweep leaves a tiny separation. Snap only after reaching a verified clear surface.
	if not support.is_empty() and actor.feet.distance_to(destination) <= 1.01:
		var body := Rect2(destination+event_size("aggressive_flyer").position,event_size("aggressive_flyer").size)
		for solid in actor_solids():
			if body.intersects(solid):
				if actor.attack_clock >= 1.0: begin_flyer_recovery(actor)
				return
		actor.feet = destination
		if flyer_support(destination,.02).is_empty():
			if actor.attack_clock >= 1.0: begin_flyer_recovery(actor)
			return
		actor.attack_state = "scuttle"
		play_trial_action(actor,"land")
		actor.attack_clock = 0.0
		actor.scuttle_direction = actor.attack_direction
	elif actor.attack_clock >= 1.0:
		begin_flyer_recovery(actor)

func begin_flyer_takeoff(actor: Dictionary) -> void:
	if flyer_support(actor.feet,0.02).is_empty():
		begin_flyer_recovery(actor)
		return
	actor.attack_state = "takeoff"
	stop_trial_actions(actor)
	play_trial_action(actor,"takeoff")
	actor.attack_clock = 0.0

func step_flyer_scuttle(actor: Dictionary, delta: float) -> void:
	var destination: Vector2 = actor.feet+Vector2(float(actor.scuttle_direction)*65.0*delta,0)
	var support := flyer_support(destination,0.02)
	# Take off before unsupported motion; do not crawl across a pit or fall through a platform edge.
	if support.is_empty() or actor.attack_clock+0.000001 >= 1.2:
		begin_flyer_takeoff(actor)
		return
	move_flyer_clear(actor,destination)
	# Aerial movement reserves a one-pixel floor gap, including the section override.
	# Restore contact only when the whole destination body is clear and the sweep reached it.
	if absf(actor.feet.x-destination.x) < 0.01 and absf(actor.feet.y-destination.y) <= 1.01:
		var shape := event_size("aggressive_flyer")
		var body := Rect2(destination+shape.position,shape.size)
		for solid in actor_solids():
			if body.intersects(solid):
				begin_flyer_takeoff(actor)
				return
		actor.feet = destination
	else:
		begin_flyer_takeoff(actor)

func step_flyer(actor: Dictionary, delta: float) -> void:
	if actor.get("variant","") == "devil": return
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
				if not actor.contact_live:
					actor.contact_live = begin_flyer_pattern(actor)
				if not actor.contact_live: return
				actor.attack_state = "windup"
				play_trial_action(actor,"warning")
				actor.attack_clock = 0.0
				actor.attack_origin = actor.feet
				# Lock the warned target even if the hero crosses behind during the approach.
				actor.attack_target = player+PLAYER_SIZE*0.5
				actor.attack_target.y = minf(actor.attack_target.y,440-event_size("aggressive_flyer").end.y-1)
				face_flyer_toward_hero(actor)
				actor.attack_direction = actor.facing
			else:
				face_flyer_toward_hero(actor)
				var speed := float(stats.get("pursuit_speed_pixels_per_second",300.0))
				if not move_flyer_clear(actor,actor.feet+Vector2(actor.facing*speed*delta,0)):
					if not move_flyer_clear(actor,actor.feet+Vector2(0,-180*delta)):
						move_flyer_clear(actor,actor.feet+Vector2(0,180*delta))
		"windup":
			if not visible:
				end_flyer_pattern(actor)
				actor.attack_state = "top_pause"
				actor.attack_clock = 0.0
			elif actor.attack_clock >= stats.attack_warning_seconds:
				actor.attack_state = "swoop"
				stop_trial_actions(actor)
				play_trial_action(actor,"attack")
				actor.attack_clock = 0.0
		"swoop":
			var t := clampf(actor.attack_clock/float(stats.swoop_seconds),0,1)
			var clear := move_flyer_clear(actor,actor.attack_origin.lerp(actor.attack_target,t))
			if not clear or t >= 1:
				actor.attack_state = "landing"
				actor.attack_clock = 0.0
		"landing":
			step_flyer_landing(actor,delta)
		"scuttle":
			step_flyer_scuttle(actor,delta)
		"takeoff":
			if flyer_support(actor.feet,0.02).is_empty() or actor.attack_clock+0.000001 >= 0.2:
				begin_flyer_recovery(actor)
		"recover":
			var t := clampf(actor.attack_clock/float(stats.recovery_seconds),0,1)
			var clear := move_flyer_clear(actor,actor.recovery_origin.lerp(actor.recovery_target,t))
			if not clear:
				# A blocked diagonal climbs vertically at the recovery rate; never teleport through scenery.
				var climb_speed := maxf(100.0,absf(actor.recovery_origin.y-actor.attack_origin.y)/float(stats.recovery_seconds))
				var climbed := move_flyer_clear(actor,Vector2(actor.feet.x,move_toward(actor.feet.y,actor.attack_origin.y,climb_speed*delta)))
				if not climbed:
					if not actor.has("recovery_escape"): actor.recovery_escape = actor.facing
					if not move_flyer_clear(actor,actor.feet+Vector2(actor.recovery_escape*150*delta,0)):
						actor.recovery_escape *= -1
						move_flyer_clear(actor,actor.feet+Vector2(actor.recovery_escape*150*delta,0))
			if (t >= 1 and is_equal_approx(actor.feet.y,actor.attack_origin.y)) or actor.attack_clock >= 2.5:
				end_flyer_pattern(actor)
				actor.attack_state = "top_pause"
				actor.attack_clock = 0.0
		"top_pause":
			if actor.attack_clock >= float(stats.get("top_pause_seconds",1.0)):
				face_flyer_toward_hero(actor)
				actor.attack_state = "approach"
				actor.attack_clock = 0.0

func step_shooter(actor: Dictionary, delta: float, visible: bool) -> void:
	if paused or life_state != "alive" or dispenser.active or dialogue.active or actor.hp <= 0: return
	var stats: Dictionary = trial_data.balance.roles.shooter
	actor.shot_clock += delta
	var pattern := "fire-"+str(actor.event_id)
	if not visible:
		stop_trial_actions(actor)
		actor.winding = false
		actor.visible_age = 0
		actor.shot_clock = 0
		trial_state.end_pattern(pattern)
		return
	if not actor.winding and actor.fire_age >= 0 and actor.age-actor.fire_age >= 0.35:
		trial_state.end_pattern(pattern)
	# Charge inside the existing cadence rather than adding a silent delay to every shot.
	if actor.visible_age+0.000001 < maxf(0,float(stats.first_shot_visible_delay_seconds)-0.65): return
	if actor.fire_age >= 0 and actor.shot_clock+0.000001 < float(stats.shot_interval_seconds)-0.65: return
	if not actor.winding:
		if not trial_state.begin_pattern(pattern,actor.event_id): return
		actor.winding = true
		play_trial_action(actor,"charge")
		actor.windup_started = actor.age
		return
	if actor.age-float(actor.windup_started)+0.000001 < 0.65: return
	actor.target = player+PLAYER_SIZE*0.5
	actor.facing = -1.0 if actor.target.x < actor.feet.x else 1.0
	var muzzle: Vector2 = actor.feet+Vector2(actor.facing*22,-25)
	if not purple_shot_allowed(muzzle,(actor.target-muzzle).normalized()):
		stop_trial_actions(actor)
		actor.winding = false
		actor.shot_clock = 0
		trial_state.end_pattern(pattern)
		return
	for solid in player_shot_solids():
		if segment_hit(muzzle,actor.target,solid) >= 0:
			stop_trial_actions(actor)
			actor.winding = false
			actor.shot_clock = 0
			trial_state.end_pattern(pattern)
			return
	var token := "bullet-%s-%s" % [actor.event_id,actor.age]
	if not trial_state.add_bullet(token):
		stop_trial_actions(actor)
		actor.winding = false
		actor.shot_clock = 0
		trial_state.end_pattern(pattern)
		return
	hostile_shots.append({"id":token,"pos":muzzle,"dir":(actor.target-muzzle).normalized(),"age":0.0})
	stop_trial_actions(actor)
	actor.winding = false
	actor.shot_clock = 0
	actor.fire_age = actor.age
	play_trial_action(actor,"fire")

func cancel_muck_throw(actor: Dictionary) -> void:
	stop_trial_actions(actor)
	if not actor.get("throw_state","").is_empty():
		actor.facing = actor.patrol_facing
		actor.fire_age = actor.age
	actor.throw_state = ""
	actor.throw_clock = 0.0
	actor.winding = false
	actor.shot_clock = 0.0

func muck_throw_frame(actor: Dictionary) -> Dictionary:
	var time: float = actor.throw_clock
	for frame: Dictionary in muck_throw_art.frames:
		if time < float(frame.duration_seconds)-0.000001: return frame
		time -= float(frame.duration_seconds)
	return muck_throw_art.frames.back()

func muck_hand(actor: Dictionary) -> Vector2:
	var frame := muck_throw_frame(actor)
	var anchor: Array = muck_throw_art.anchor
	var offset := Vector2(frame.hand[0]-anchor[0],frame.hand[1]-anchor[1])
	return actor.feet+offset*Vector2(-actor.facing,1)*role_scale(actor.role)

func muck_trajectory(origin: Vector2, target: Vector2, facing_direction: float) -> Dictionary:
	# Preserve clear ordinary throws; only obstructed throws spend longer climbing above a ledge.
	if (target.x-origin.x)*facing_direction <= 0: return {}
	var stats: Dictionary = trial_data.balance.roles.emerger
	var gravity := float(stats.muck_gravity)
	var baseline := float(stats.muck_flight_seconds)
	var solids := player_shot_solids()
	for attempt in range(11):
		var flight := baseline+attempt*0.1
		var velocity := Vector2((target.x-origin.x)/flight,(target.y-origin.y)/flight-gravity*flight*0.5)
		var previous := origin
		var clear := true
		var steps := ceili(flight*120)
		for index in range(1,steps+1):
			var time := flight*index/steps
			var point := origin+velocity*time+Vector2(0,gravity*time*time*0.5)
			if point.y < 12:
				clear = false
				break
			for solid in solids:
				if segment_hit(previous,point,solid.grow(12.01)) >= 0:
					clear = false
					break
			if not clear: break
			previous = point
		if clear: return {"velocity":velocity,"flight":flight}
	return {}

func step_muck_thrower(actor: Dictionary, delta: float, visible: bool) -> void:
	if paused or life_state != "alive" or dialogue.active or dispenser.active or delta <= 0: return
	if actor.hp <= 0 or not visible:
		cancel_muck_throw(actor)
		return
	var stats: Dictionary = trial_data.balance.roles.emerger
	actor.shot_clock += delta
	if actor.throw_state.is_empty():
		var delay := 0.3 if actor.fire_age < 0 else float(stats.muck_interval_seconds)-float(muck_throw_art.release_seconds)
		if actor.shot_clock+0.000001 < delay: return
		if not actor.contact_live:
			if not trial_state.begin_pattern("contact-"+str(actor.event_id),actor.event_id): return
			actor.contact_live = true
		actor.patrol_facing = actor.facing
		actor.throw_target = player+PLAYER_SIZE*0.5
		actor.facing = -1.0 if actor.throw_target.x < actor.feet.x else 1.0
		actor.throw_state = "windup"
		play_trial_action(actor,"gather")
		actor.throw_clock = 0.0
		actor.winding = true
		return
	actor.throw_clock += delta
	if actor.throw_state == "recover":
		if actor.throw_clock+0.000001 >= float(muck_throw_art.duration_seconds):
			actor.throw_state = ""
			actor.facing = actor.patrol_facing
		return
	if actor.throw_clock+0.000001 < float(muck_throw_art.release_seconds): return
	# Advance to the authored release pose before sampling its hand. Aim stays committed even if the hero crosses.
	actor.throw_clock = float(muck_throw_art.release_seconds)
	actor.throw_state = "recover"
	stop_trial_actions(actor)
	var target: Vector2 = actor.throw_target
	var origin := muck_hand(actor)
	var gravity := float(stats.muck_gravity)
	var trajectory := muck_trajectory(origin,target,actor.facing)
	var clear := not trajectory.is_empty()
	var velocity: Vector2 = trajectory.get("velocity",Vector2.ZERO)
	var token := "muck-%s-%s" % [actor.event_id,actor.age]
	if clear and trial_state.add_bullet(token):
		play_trial_action(actor,"throw")
		hostile_shots.append({"id":token,"kind":"muck","pos":origin,"dir":velocity.normalized(),
			"velocity":velocity,"gravity":gravity,"radius":12.0,"age":0.0,"target":target})
	actor.winding = false
	actor.shot_clock = 0
	actor.fire_age = actor.age

func draw_hostile_shot(shot: Dictionary) -> void:
	if shot.get("kind", "") != "muck":
		effect("hostile-projectile",shot.pos)
		return
	var frame: Dictionary = muck_art.frames[int(shot.age*12)%4]
	var destination := region(frame.destination)
	destination.position += shot.pos
	draw_asset(frame,destination)

func purple_bolt_rect(position: Vector2) -> Rect2:
	for item in trial_data.environment.effects:
		if item.id == "hostile-projectile":
			return Rect2(position-Vector2(item.anchor[0],item.anchor[1]),
				Vector2(item.logical_size[0],item.logical_size[1]))
	return Rect2(position-Vector2(40,32.5),Vector2(64,64))

func purple_bolt_offscreen(position: Vector2) -> bool:
	return not purple_bolt_rect(position).intersects(Rect2(camera_x,0,960,540))

func purple_shot_allowed(_origin: Vector2, direction: Vector2) -> bool:
	return direction.is_finite() and direction.length_squared() > 0.001

func purple_bolt_reaches_x(origin: Vector2, direction: Vector2, boundary: float) -> bool:
	if direction.x <= 0 or origin.x >= boundary: return false
	var end := origin+direction*((boundary-origin.x)/direction.x)
	if end.y < -32 or end.y > 573: return false
	for solid in player_shot_solids():
		if segment_hit(origin,end,solid.grow(4)) >= 0: return false
	return true

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
	step_hostile_projectiles(delta)

func step_hostile_projectiles(delta: float) -> void:
	if paused or life_state != "alive" or dispenser.active or dialogue.active or delta <= 0: return
	var remaining := delta
	while remaining > 0.000001 and life_state == "alive":
		var dt := minf(remaining,1.0/120)
		remaining -= dt
		for index in range(hostile_shots.size()-1,-1,-1):
			var shot: Dictionary = hostile_shots[index]
			var radius := float(shot.get("radius",4.0))
			var end: Vector2 = shot.pos+shot.dir*150*dt
			if shot.get("kind", "") == "muck":
				end = shot.pos+shot.velocity*dt+Vector2(0,shot.gravity*dt*dt*0.5)
				shot.velocity.y += shot.gravity*dt
			var fraction := segment_hit(shot.pos,end,Rect2(player,PLAYER_SIZE).grow(radius))
			var wall := 2.0
			for solid in player_shot_solids():
				var hit := segment_hit(shot.pos,end,solid.grow(radius))
				if hit >= 0: wall = minf(wall,hit)
			shot.age += dt
			if fraction >= 0 or wall <= 1:
				play_trial_impact(shot,shot.pos.lerp(end,minf(fraction if fraction >= 0 else 2.0,wall)))
			if fraction >= 0 and fraction < wall: hurt_player()
			var expired: bool = shot.age > 3.5 if shot.get("kind","") == "muck" else purple_bolt_offscreen(end)
			if fraction >= 0 or wall <= 1 or expired:
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
	if process_special_cinematic(delta): return
	devil_spiders.sync_lifecycle(self)
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

func foreground_entry(actor: Dictionary) -> bool:
	return MonsterEntry.active(actor) and actor.entry.mode == "foreground"

func draw_foreground_entries() -> void:
	# Near-camera creatures belong above playfield actors/projectiles and below the HUD.
	draw_set_transform(Vector2(-floorf(camera_x),0))
	for actor in actors:
		if actor.hp > 0 and foreground_entry(actor): draw_entry_actor(actor)

func draw_actor(actor: Dictionary, entry_render := false) -> void:
	if actor.hp <= 0 and (actor.role in ["perched_shooter","floor_emerger"] or
		(actor.role == "aggressive_flyer" and actor.get("variant","") != "devil")): return
	if MonsterEntry.active(actor) and not entry_render:
		draw_entry_actor(actor)
		return
	draw_entry_fixture(actor)
	draw_actor_body(actor,entry_render)
	draw_entry_fixture(actor,true)

func draw_actor_body(actor: Dictionary, entry_render: bool) -> void:
	if actor.get("mount","") == "ceiling":
		ceiling_shooter_art.draw(self,actor,ceiling_direction(actor))
		if actor.hp > 0 and actor.active and show_enemy_health_bars:
			var body := actor_rect(actor)
			box(body.position.x,body.end.y+5,body.size.x,4,Color("243447"))
			box(body.position.x,body.end.y+5,body.size.x*actor.hp/actor.max_hp,4,MINT)
		return
	if MonsterEntry.active(actor) and not entry_render:
		draw_entry_actor(actor)
		return
	if actor.get("variant","") == "devil":
		devil_spider_art.draw(self,actor,entry_render)
		return
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
		if actor.has("grounded"): enemy.grounded = actor.grounded
		world_art.draw_toilet(self,enemy)
		return
	var spec: Dictionary = trial_data.role_art.roles[ROLE_KEYS[actor.role]]
	var state := "idle"
	if actor.role == "aggressive_flyer": state = "flight"
	elif actor.role == "floor_emerger":
		if not entry_render and not actor.active and actor.age < actor.warning_seconds: return
		state = "patrol" if actor.active or entry_render else ("emerge" if actor.age < actor.warning_seconds+0.35 else "settle")
	elif actor.winding: state = "windup"
	elif actor.fire_age >= 0 and actor.age-actor.fire_age < 0.15: state = "fire"
	elif actor.fire_age >= 0 and actor.age-actor.fire_age < 0.5: state = "recover"
	if actor.flash > 0: state = "hurt"
	if actor.hp <= 0: state = "death"
	var ground_pose := false
	if actor.role == "aggressive_flyer" and actor.hp > 0 and actor.flash <= 0:
		var ground_state: String = actor.get("attack_state", "")
		if ground_state == "scuttle":
			ground_state = "landing" if actor.attack_clock < 0.18 else "ground_scuttle"
		elif ground_state == "landing": ground_state = "flight"
		if angel_ground_art.get("states",{}).has(ground_state):
			spec = angel_ground_art
			state = ground_state
			ground_pose = true
	var animation: Dictionary = spec.states[state]
	var frames: Array = animation.frames
	var clock_value: float = actor.death if actor.hp <= 0 else actor.clock
	if ground_pose: clock_value = float(actor.attack_clock)
	if state == "windup": clock_value = actor.age-float(actor.get("windup_started",actor.age-actor.clock))
	elif state == "fire": clock_value = actor.age-actor.fire_age
	elif state == "recover": clock_value = actor.age-actor.fire_age-0.15
	elif state == "hurt": clock_value = 0.1-actor.flash
	if actor.role == "aggressive_flyer" and actor.get("attack_state","") == "windup":
		clock_value *= 2.0
	if actor.role == "floor_emerger" and not actor.active and not entry_render:
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
	var throwing: bool = actor.role == "floor_emerger" and actor.hp > 0 and not actor.throw_state.is_empty()
	if throwing: frame = muck_throw_frame(actor)
	frame = frame.duplicate(true)
	var destination := region(frame.destination)
	var anchor := Vector2(spec.anchor[0],spec.anchor[1])
	destination.position -= anchor
	if ground_pose:
		# Registered feet follow the actual support plane, without rescaling individual poses.
		var foot_y := float(frame.foot_contacts[0][1])-anchor.y
		destination.position.y += event_size(actor.role).end.y/role_scale(actor.role)-foot_y
	if actor.get("mount","") == "floor":
		var visible_height := minf(destination.end.y,(actor.home.y-actor.feet.y)/role_scale(actor.role))-destination.position.y
		if visible_height <= 0: return
		if visible_height < destination.size.y:
			frame.source_rect[3] *= visible_height/destination.size.y
			destination.size.y = visible_height
	# Mirror around the registered anchor, never around the crop's left edge.
	draw_set_transform(actor.feet-Vector2(floorf(camera_x),0),0,
		Vector2(-1 if actor.facing > 0 else 1,1)*role_scale(actor.role)*(float(actor.entry.scale) if entry_render else 1.0))
	if actor.role == "perched_shooter" and state in ["windup","fire"]:
		draw_shooter_pressure(frame,destination,actor,state)
	else:
		draw_asset(frame,destination,Color(1,1,1,1-clampf(actor.death/0.6,0,1)))
	draw_set_transform(Vector2(-floorf(camera_x),0))
	if throwing and actor.throw_state == "windup":
		var held: Dictionary = muck_art.frames[0]
		var held_destination := region(held.destination)
		held_destination.position += muck_hand(actor)
		draw_asset(held,held_destination)
	if actor.hp > 0 and actor.active and show_enemy_health_bars:
		var body := actor_rect(actor)
		box(body.position.x,body.position.y-14,body.size.x,4,Color("243447"))
		box(body.position.x,body.position.y-14,body.size.x*actor.hp/actor.max_hp,4,MINT)

func draw_shooter_pressure(frame: Dictionary, destination: Rect2, actor: Dictionary, state: String) -> void:
	# Art's seam-pinned deformation: the bolted base never translates or separates from the body.
	var source := region(frame.source_rect)
	var elapsed: float = actor.age-float(actor.get("windup_started",actor.age-actor.clock))
	var progress := clampf(elapsed/float(actor.get("windup_duration",0.65)),0,1)
	var amplitude := lerpf(0.15,0.75,progress)
	var duration := float(actor.get("windup_duration",0.65))
	var ramp_time := minf(elapsed,duration)
	var phase := TAU*(7*ramp_time+2*ramp_time*ramp_time/duration+11*maxf(0,elapsed-duration))
	var offset := sin(phase)*amplitude
	var brightness := 1+0.18*progress
	if state == "fire":
		offset = 1.5*(1-clampf((actor.age-actor.fire_age)/0.1,0,1))
		brightness = 1
	var y := 0.0
	while y < destination.size.y:
		var height := minf(1.5,destination.size.y-y)
		var source_y := y/destination.size.y*source.size.y
		var taper := clampf((390-source_y)/90,0,1)
		var strip := Rect2(destination.position+Vector2(offset*taper,y),Vector2(destination.size.x,height))
		var crop := Rect2(source.position+Vector2(0,source_y),Vector2(source.size.x,height/destination.size.y*source.size.y))
		var shade := lerpf(1,brightness,taper)
		draw_texture_rect_region(trial_textures[frame.path],strip,crop,Color(shade,shade,shade))
		y += height

func _draw() -> void:
	if trial_data.is_empty(): return
	draw_set_transform(Vector2(-floorf(camera_x),0))
	draw_environment()
	for fixture: Dictionary in devil_spiders.placements(self): devil_spider_art.draw_support(self,fixture)
	wastewater_art.draw(self,camera_x,trial_state.elapsed,true)
	for actor in actors:
		if not foreground_entry(actor): draw_actor(actor)
	special_art.draw_back(self)
	if cinematic.active or life_state != "alive" or invulnerable <= 0 or int(elapsed*12)%2 == 0: draw_sean(player)
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
	devil_spider_art.draw_effects(self)
	shooter_remains.draw(self)
	regular_remains.draw(self)
	special_art.draw_front(self)
	draw_foreground_entries()
	draw_set_transform_matrix(transform.affine_inverse())
	draw_hud()
	draw_cinematic_overlay()
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

func _on_swarm_damaged(actor: Dictionary, lethal: bool) -> void:
	super._on_swarm_damaged(actor,lethal)
	if lethal: regular_remains.begin_swarm(self,actor)
