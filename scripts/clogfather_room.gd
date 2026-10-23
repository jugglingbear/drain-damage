extends RefCounted
## World adapter; combat state and HP remain exclusively in the encounter controller.
const Encounter = preload("res://scripts/clogfather_encounter.gd")
const Audio = preload("res://scripts/clogfather_audio.gd")
const Art = preload("res://scripts/clogfather_art.gd")
const Route = preload("res://scripts/clogfather_route.gd")
const START := Route.ARENA_ORIGIN
const COMMIT := Route.ENTRY_COMMIT
const QUIET := Route.QUIET
const CONTAINMENT := Route.CONTAINMENT
const CHECKPOINT := Route.CHECKPOINT
const FINISH := Route.COMPLETION_X
const ORIGIN := Vector2(START,0)
var encounter := Encounter.new()
var audio := Audio.new()
var art := Art.new()
var entered := false
var kill_recorded := false
var clock := 0.0
var owner_host: Node2D
var spawned_wave := -1

func attach(host: Node2D) -> void:
	owner_host = host
	audio.attach(host)
	assert(art.prepare(),"Clogfather art preparation failed")

func reset(seed_value: int) -> void:
	clear_reinforcements()
	if is_instance_valid(owner_host) and owner_host.music_director != null:
		owner_host.music_director.set_combat_warning(false)
	spawned_wave = -1
	encounter.reset(seed_value)
	audio.stop()
	entered = false
	kill_recorded = false
	clock = 0
	art.reset()

func frozen(host: Node2D) -> bool:
	return host.paused or host.dialogue.active or host.dialogue.release_guard > 0 \
		or host.dispenser.active or host.won or host.life_state != "alive"

func sync_music_warning(host: Node2D) -> void:
	if host.music_director == null: return
	var warning := encounter.state in ["volley_warning","acid_warning","pressure_warning"] \
		or (encounter.state == "recovery" and encounter.elapsed >= 4.25)
	host.music_director.set_combat_warning(entered and encounter.active and warning)

func process_audio(host: Node2D, delta: float) -> void:
	sync_music_warning(host)
	audio.set_paused(frozen(host))
	audio.tick(delta)

func constrain(position: Vector2, size: Vector2) -> Vector2:
	if not entered: return position
	var right := INF if encounter.exit_open else START+encounter.shell.position.x-size.x
	return Vector2(clampf(position.x,COMMIT,right),position.y)

func camera_position(player_x: float) -> float:
	if not entered:
		if player_x < 13790: return -1
		return lerpf(13470,START,smoothstep(13790,COMMIT,player_x))
	if not encounter.exit_open: return START
	return lerpf(START,14240,smoothstep(14824,FINISH,player_x))

func advance(host: Node2D, delta: float) -> void:
	var hero := Rect2(host.player-ORIGIN,host.PLAYER_SIZE)
	if frozen(host):
		encounter.step(0,hero,true)
		return
	if not entered and host.player.x >= COMMIT:
		entered = true
		host.skitterling.clear_prior(host,true)
		encounter.start(hero)
		host.boss_hud.begin_encounter("clogfather")
		if host.music_director != null: host.music_director.play_track("clogfather",true)
	var camera := camera_position(host.player.x)
	if camera >= 0: host.camera_x = camera
	if not entered: return
	host.player = constrain(host.player,host.PLAYER_SIZE)
	clock += delta
	encounter.step(delta,Rect2(host.player-ORIGIN,host.PLAYER_SIZE))
	art.step(encounter.snapshot(),delta)
	flush_events(host)
	for region in encounter.hurt_rects():
		if region.intersects(Rect2(host.player-ORIGIN,host.PLAYER_SIZE)):
			host.hurt_player()
			break

func flush_events(host: Node2D) -> void:
	host.boss_hud.player_status = "%s   HP %d / %d   LIVES %d" % [
		host.employee.name,host.health,host.employee.max_health,host.lives]
	host.boss_hud.update_hp(encounter.hp)
	var events := encounter.drain_events()
	art.events(events)
	sync_music_warning(host)
	audio.handle_events(events)
	if events.has("pressure_cleared") or events.has("death_started") or events.has("boss_defeated"):
		clear_reinforcements()
	elif events.has("reinforcements_spawn"):
		spawn_reinforcements(host)
	if events.has("boss_defeated") and not kill_recorded:
		kill_recorded = true
		host.kills += 1
		host.player_kills += 1
		if host.music_director != null: host.music_director.play_track("level")

func clear_reinforcements() -> void:
	if not is_instance_valid(owner_host): return
	for index in range(owner_host.swarms.actors.size()-1,-1,-1):
		if owner_host.swarms.actors[index].get("clogfather_reinforcement",false):
			owner_host.swarms.actors.remove_at(index)
	if owner_host.swarms.actors.is_empty(): owner_host.swarm_audio.stop()

func spawn_reinforcements(host: Node2D) -> void:
	if encounter.state != "pressure_active" or encounter.pressure_kind != "reinforcements" \
			or spawned_wave == encounter.pressure_wave: return
	clear_reinforcements()
	spawned_wave = encounter.pressure_wave
	for request: Dictionary in encounter.reinforcement_requests:
		var bounds: Rect2 = request.bounds
		bounds.position += ORIGIN
		var actor: Dictionary = host.swarms.spawn(request.center+ORIGIN,bounds,
			host.run_seed+spawned_wave*31+host.swarms.actors.size())
		actor.clogfather_reinforcement = true
		actor.pressure_wave = spawned_wave
		actor.additive = true
		actor.contact_ready = false
		host.swarms.actors.append(actor)

func target_rect() -> Rect2:
	var body := encounter.weak_point_rect()
	if body.has_area(): body.position += ORIGIN
	return body

func draw(host: Node2D) -> void:
	if host.camera_x+960 < START or host.camera_x > START+960: return
	var snapshot := encounter.snapshot()
	if host.ending.active(): snapshot.remains_alpha = 1-smoothstep(0,0.8,host.ending.clock)
	art.draw(host,snapshot,ORIGIN-Vector2(floorf(host.camera_x),0),clock)
	host.draw_set_transform(Vector2(-floorf(host.camera_x),0))
	if snapshot.state == "pressure_warning" and snapshot.pressure_kind == "reinforcements":
		var animation: Dictionary = host.swarms.definition.animation.animations.hover
		var source: Array = animation.frames[int(clock*8)%4].source_rect
		for request: Dictionary in snapshot.reinforcement_requests:
			host.draw_texture_rect_region(host.swarms.texture,
				Rect2(request.center+ORIGIN-Vector2(64,64),Vector2(128,128)),
				Rect2(source[0],source[1],source[2],source[3]),Color(1,1,1,0.4+0.2*sin(clock*12)))

func shell_rect() -> Rect2:
	var body := encounter.body_rect()
	if body.has_area(): body.position += ORIGIN
	return body

func damage(host: Node2D, amount: int, attack_id: String, airborne_attack := false) -> int:
	var accepted := encounter.hit(amount,attack_id,airborne_attack)
	flush_events(host)
	return accepted

func deflect(position: Vector2) -> void:
	art.deflect_position = position-ORIGIN
	art.events(["closed_shell_hit"])
	audio.handle_events(["closed_shell_hit"])

func contain_prior(host: Node2D) -> void:
	for actor in host.actors:
		var shape: Rect2 = host.event_size(actor.role)
		if actor.feet.x+shape.end.x > CONTAINMENT:
			actor.feet.x = CONTAINMENT-shape.end.x
			actor.facing = -1.0
	for enemy in host.enemies:
		if enemy.pos.x+38 > CONTAINMENT:
			enemy.pos.x = CONTAINMENT-38
			enemy.direction = -1.0
	for index in range(host.hostile_shots.size()-1,-1,-1):
		if host.hostile_shots[index].pos.x >= CONTAINMENT:
			host.trial_state.remove_bullet(host.hostile_shots[index].id)
			host.hostile_shots.remove_at(index)
