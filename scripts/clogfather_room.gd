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

func attach(host: Node2D) -> void:
	audio.attach(host)
	assert(art.prepare(),"Clogfather art preparation failed")

func reset(seed_value: int) -> void:
	encounter.reset(seed_value)
	audio.stop()
	entered = false
	kill_recorded = false
	clock = 0
	art.reset()

func frozen(host: Node2D) -> bool:
	return host.paused or host.dialogue.active or host.dialogue.release_guard > 0 \
		or host.dispenser.active or host.won or host.life_state != "alive"

func process_audio(host: Node2D, delta: float) -> void:
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
	audio.handle_events(events)
	if events.has("boss_defeated") and not kill_recorded:
		kill_recorded = true
		host.kills += 1
		host.player_kills += 1
		if host.music_director != null: host.music_director.play_track("level")

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
