extends RefCounted
## World integration for the authored room; the encounter retains sole phase and HP authority.
const Encounter = preload("res://scripts/skitterling_encounter.gd")
const Audio = preload("res://scripts/skitterling_audio.gd")
const QUIET := 5610.0
const START := 6570.0
const END := 7530.0
const ORIGIN := Vector2(START,0)
const ENTRY_START := 6450.0
const ENTRY_END := 6690.0
const EXIT_START := 7410.0
const EXIT_END := 7650.0
const CAMERA_ENTRY := 6250.0
var encounter := Encounter.new()
var audio := Audio.new()
var art: RefCounted
var entered := false
var released := false
var clock := 0.0
var hit_actor := {"hp":Encounter.MAX_HP}
var kill_recorded := false

func attach(host: Node2D) -> void:
	audio.attach(host)
	art = load("res://scripts/skitterling_art.gd").new()
	var prepared: bool = art.prepare()
	assert(prepared,"Skitterling authored art failed preparation")

func reset(seed_value: int) -> void:
	encounter.configure(seed_value)
	audio.stop()
	entered = false
	released = false
	clock = 0
	hit_actor = {"hp":Encounter.MAX_HP}
	kill_recorded = false

func locked() -> bool:
	return entered and not released

func frozen(host: Node2D) -> bool:
	return host.paused or host.dialogue.active or host.dispenser.active or host.won or host.life_state != "alive"

func process_audio(host: Node2D, delta: float) -> void:
	audio.set_paused(frozen(host) or host.dialogue.release_guard > 0)
	audio.step(delta)

func hero_rect(host: Node2D) -> Rect2:
	return Rect2(host.player-ORIGIN,host.PLAYER_SIZE)

func constrain(position: Vector2, size: Vector2) -> Vector2:
	if not entered: return position
	# Entry closes only once the entire hero has walked out; the open exit remains reversible.
	return Vector2(clampf(position.x,ENTRY_END,INF if encounter.exit_open else EXIT_START-size.x),position.y)

func camera_position(player_x: float) -> float:
	if not entered:
		if player_x < CAMERA_ENTRY: return -1
		return lerpf(CAMERA_ENTRY-320,START,smoothstep(CAMERA_ENTRY,ENTRY_END,player_x))
	if not encounter.exit_open or player_x <= EXIT_START: return START
	if player_x < EXIT_END:
		return lerpf(START,player_x-320,smoothstep(EXIT_START,EXIT_END,player_x))
	return -1 if released else player_x-320

func advance(host: Node2D, delta: float) -> void:
	if frozen(host):
		encounter.step(0,hero_rect(host),true)
		return
	if not entered and host.player.x >= ENTRY_END:
		entered = true
		# Every prior threat is behind the quiet approach and offscreen at this boundary.
		clear_prior(host,true)
		encounter.start(hero_rect(host))
		host.boss_hud.begin_encounter("cockroach-swarm")
		flush_events(host)
	var camera := camera_position(host.player.x)
	if camera >= 0: host.camera_x = camera
	if entered and not released:
		host.player = constrain(host.player,host.PLAYER_SIZE)
		clock += delta
		encounter.step(delta,hero_rect(host))
		flush_events(host)
		var player_body := Rect2(host.player,host.PLAYER_SIZE)
		var touching := false
		var snapshot := encounter.snapshot()
		if encounter.rat_contact_active():
			for region: Rect2 in art.visible_contact_regions(snapshot, ORIGIN, clock):
				if region.intersects(player_body):
					touching = true
					break
		for region in encounter.hurt_regions():
			var world: Rect2 = Rect2(region.position+ORIGIN,region.size)
			if encounter.state != "alligator_debris":
				world = world.intersection(art.collision_bounds(snapshot,ORIGIN))
			if world.has_area() and world.intersects(player_body):
				touching = true
				break
		# Contact and attack overlap share one damage call and the normal immunity window.
		if touching: host.hurt_player()
		if encounter.exit_open and host.player.x >= EXIT_END:
			released = true
			host.boss_hud.end_encounter()
			audio.stop()

func flush_events(host: Node2D) -> void:
	host.boss_hud.player_status = "%s   HP %d / %d   LIVES %d" % [host.employee.name,host.health,host.employee.max_health,host.lives]
	hit_actor.hp = encounter.hp
	for event in encounter.drain_events():
		if event == "hit": audio.play_hit(hit_actor,clock)
		elif event == "exit_open":
			if not kill_recorded:
				kill_recorded = true
				host.kills += 1
				host.player_kills += 1
		else: audio.event(event)
	host.boss_hud.update_hp(encounter.hp)

func damage(host: Node2D, amount: int) -> int:
	if frozen(host): return 0
	var accepted := encounter.damage(amount)
	flush_events(host)
	return accepted

func target_rect() -> Rect2:
	if not encounter.damageable(): return Rect2()
	var body := encounter.body_rect()
	body.position += ORIGIN
	return body.intersection(art.collision_bounds(encounter.snapshot(),ORIGIN))

func target_regions() -> Array[Rect2]:
	## Retreat shots can hit only the exposed swarm, never insects concealed by pipe metal.
	var result: Array[Rect2] = []
	var baseline := target_rect()
	if not baseline.has_area(): return result
	if encounter.state != "rat_pipe_retreat":
		result.append(baseline)
		return result
	for visible: Rect2 in art.visible_target_regions(encounter.snapshot(), ORIGIN):
		var clipped := baseline.intersection(visible)
		if clipped.has_area(): result.append(clipped)
	return result

func allowed_body(body: Rect2) -> bool:
	return body.end.x <= QUIET or body.position.x >= END

func clear_prior(host: Node2D, preserve_visible := false) -> void:
	# Walk-in cleanup occurs after all prior threats are offscreen; no kill credit.
	for actor in host.actors:
		if not host.trial_state.retire(actor.event_id):
			host.trial_state.mark_unavailable(actor.event_id,"concealed room isolation")
	for shot in host.hostile_shots: host.trial_state.remove_bullet(shot.id)
	for index in range(host.shots.size()-1,-1,-1):
		var shot: Dictionary = host.shots[index]
		if preserve_visible and shot.pos.x >= host.camera_x: continue
		if shot.has("trial_id"): host.trial_state.resolve_shot(shot.trial_id,false)
		host.shots.remove_at(index)
	host.actors.clear()
	host.enemies.clear()
	host.swarms.actors.clear()
	host.hostile_shots.clear()
	if not preserve_visible:
		host.particles.clear()
		host.corpses.clear()
	for sound in host.creature_audio.values(): sound.stop()
	host.swarm_audio.stop()

func contain_prior(host: Node2D) -> void:
	if entered: return
	# Existing pursuers may remain visible behind the player, but never enter the quiet approach.
	for actor in host.actors:
		var shape: Rect2 = host.event_size(actor.role)
		if actor.feet.x+shape.end.x > QUIET:
			actor.feet.x = QUIET-shape.end.x
			actor.facing = -1.0
	for enemy in host.enemies:
		if enemy.pos.x+38 > QUIET:
			enemy.pos.x = QUIET-38
			enemy.direction = -1.0
	for index in range(host.hostile_shots.size()-1,-1,-1):
		if host.hostile_shots[index].pos.x >= QUIET:
			host.trial_state.remove_bullet(host.hostile_shots[index].id)
			host.hostile_shots.remove_at(index)

func draw_back(host: Node2D) -> void:
	if art == null: return
	if host.camera_x+960 >= START and host.camera_x <= END:
		art.draw_room(host,ORIGIN,encounter.exit_open)
	art.draw_portals_back(host,ORIGIN,entered,encounter.exit_open)

func draw_actor(host: Node2D) -> void:
	if art != null and entered: art.draw_boss(host,encounter.snapshot(),ORIGIN,clock)

func draw_front(host: Node2D) -> void:
	if art == null: return
	if entered: art.draw_front(host,encounter.snapshot(),ORIGIN,clock)
	art.draw_portals_front(host,ORIGIN,entered,encounter.exit_open)
