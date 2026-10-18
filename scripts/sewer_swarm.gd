extends RefCounted
signal damaged(actor: Dictionary, lethal: bool)
## Seeded environmental wander: steering never receives a player or target position.
const DISPLAY_SIZE := Vector2(128,128)
const Data = preload("res://scripts/combat_data.gd")
var definition: Dictionary
var texture: Texture2D
var actors: Array[Dictionary] = []
var hero_cooldown := 0.0

func _init() -> void:
	definition = Data.monster("sewer-fly-swarm")
	texture = load("res://" + definition.animation.image)

func spawn(position: Vector2, bounds: Rect2, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return {"pos":position, "bounds":bounds, "rng":rng, "velocity":Vector2.ZERO,
		"heading":rng.randf_range(-PI,PI), "desired":0.0, "decision":0.0, "hover_decision":2.0,
		"hover":0.0, "hp":float(definition.health.spawn_hp), "clock":0.0, "death":0.0,
		"animation":"hover", "axis":"x", "flash":0.0, "stuck_time":0.0, "stuck_origin":position,
		"blocked":false, "recovery_wait":0.0}

func reset() -> void:
	hero_cooldown = 0
	actors = [spawn(Vector2(2090,290),Rect2(2000,220,180,204),101),
		spawn(Vector2(4400,330),Rect2(4140,230,430,194),202)]

func clear_path(start: Vector2, finish: Vector2, bounds: Rect2, solids: Array[Rect2]) -> bool:
	var radius: float = definition.movement.contact_radius_pixels
	var interior := bounds.grow(-radius)
	if not interior.has_point(finish): return false
	for rect in solids:
		var expanded := rect.grow(radius + 0.01)
		if expanded.has_point(finish) or segment_hit(start,finish,expanded) >= 0: return false
	return true

func segment_hit(start: Vector2, finish: Vector2, rect: Rect2) -> float:
	var delta := finish-start
	var near := 0.0
	var far := 1.0
	for axis in range(2):
		if is_zero_approx(delta[axis]):
			if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]: return -1
		else:
			var a: float = (rect.position[axis]-start[axis])/delta[axis]
			var b: float = (rect.end[axis]-start[axis])/delta[axis]
			near = maxf(near,minf(a,b))
			far = minf(far,maxf(a,b))
			if near > far: return -1
	return near

func recovery_heading(actor: Dictionary, solids: Array[Rect2]) -> float:
	var best := -INF
	var chosen: float = actor.heading
	var radius: float = definition.movement.contact_radius_pixels
	var interior: Rect2 = actor.bounds.grow(-radius)
	actor.blocked = true
	for index in range(16):
		var angle := index * TAU / 16.0
		var finish: Vector2 = actor.pos + Vector2.from_angle(angle)*20
		if not clear_path(actor.pos,finish,actor.bounds,solids): continue
		var clearance: float = minf(minf(finish.x-interior.position.x,interior.end.x-finish.x),
			minf(finish.y-interior.position.y,interior.end.y-finish.y))
		var score := clearance - absf(angle_difference(actor.heading,angle))*2
		if score > best:
			best = score
			chosen = angle
			actor.blocked = false
	return chosen

func step_motion(actor: Dictionary, delta: float, solids: Array[Rect2]) -> void:
	var tuning: Dictionary = definition.movement
	actor.clock += delta
	actor.flash = maxf(0,actor.flash-delta)
	if actor.hp <= 0:
		actor.death += delta
		return
	actor.decision -= delta
	actor.hover_decision -= delta
	actor.hover = maxf(0,actor.hover-delta)
	if actor.decision <= 0:
		actor.desired = actor.heading + deg_to_rad(actor.rng.randf_range(
			-tuning.max_random_heading_delta_degrees,tuning.max_random_heading_delta_degrees))
		actor.decision = tuning.heading_update_seconds
	if actor.hover_decision <= 0:
		actor.hover_decision = actor.rng.randf_range(tuning.hover_decision_interval_seconds[0],
			tuning.hover_decision_interval_seconds[1])
		if actor.rng.randf() < tuning.hover_pause_probability:
			actor.hover = actor.rng.randf_range(tuning.hover_pause_seconds[0],tuning.hover_pause_seconds[1])
	var interior: Rect2 = actor.bounds.grow(-tuning.contact_radius_pixels)
	var margin: float = tuning.boundary_steering_margin_pixels
	var forward := Vector2.from_angle(actor.heading)
	var look: Vector2 = actor.pos + forward*tuning.speed_pixels_per_second*tuning.obstacle_lookahead_seconds
	var near_edge: bool = (actor.pos.x-interior.position.x < margin and forward.x < 0) \
		or (interior.end.x-actor.pos.x < margin and forward.x > 0) \
		or (actor.pos.y-interior.position.y < margin and forward.y < 0) \
		or (interior.end.y-actor.pos.y < margin and forward.y > 0)
	actor.stuck_time += delta
	actor.recovery_wait = maxf(0,actor.recovery_wait-delta)
	if (not actor.blocked or actor.recovery_wait <= 0) and (near_edge \
			or not clear_path(actor.pos,look,actor.bounds,solids) or actor.blocked):
		actor.desired = recovery_heading(actor,solids)
		if actor.blocked: actor.recovery_wait = 0.6
	if actor.stuck_time >= 1:
		if actor.hover <= 0 and actor.pos.distance_to(actor.stuck_origin) < 4:
			actor.desired = recovery_heading(actor,solids)
		actor.stuck_origin = actor.pos
		actor.stuck_time = 0
	actor.heading = rotate_toward(actor.heading,actor.desired,deg_to_rad(tuning.max_turn_rate_degrees_per_second)*delta)
	var speed: float = 0 if actor.hover > 0 or actor.blocked else tuning.speed_pixels_per_second
	var intended: Vector2 = actor.velocity.move_toward(Vector2.from_angle(actor.heading)*speed,
		tuning.acceleration_pixels_per_second_squared*delta)
	var before: Vector2 = actor.pos
	# Axis-separated swept movement slides along obstacles and cannot tunnel under stalls.
	for axis in range(2):
		var finish: Vector2 = actor.pos
		finish[axis] += intended[axis]*delta
		if clear_path(actor.pos,finish,actor.bounds,solids): actor.pos = finish
	actor.velocity = (actor.pos-before)/delta if delta > 0 else Vector2.ZERO
	select_animation(actor)

func select_animation(actor: Dictionary) -> void:
	var velocity: Vector2 = actor.velocity
	if velocity.length() < 4:
		actor.animation = "hover"
		return
	if actor.axis == "x" and absf(velocity.y) > absf(velocity.x)*1.2: actor.axis = "y"
	elif actor.axis == "y" and absf(velocity.x) > absf(velocity.y)*1.2: actor.axis = "x"
	actor.animation = ("move_right" if velocity.x > 0 else "move_left") if actor.axis == "x" \
		else ("move_down" if velocity.y > 0 else "move_up")

func overlaps(actor: Dictionary, rect: Rect2) -> bool:
	var nearest: Vector2 = actor.pos.clamp(rect.position,rect.end)
	return actor.pos.distance_squared_to(nearest) <= pow(definition.movement.contact_radius_pixels,2)

func step(game: Node2D, delta: float) -> void:
	hero_cooldown = maxf(0,hero_cooldown-delta)
	var solids: Array[Rect2] = game.player_shot_solids()
	for enemy: Dictionary in game.enemies:
		enemy.swarm_cooldown = maxf(0,enemy.get("swarm_cooldown",0.0)-delta)
	for actor in actors:
		step_motion(actor,delta,solids)
		if actor.get("warning",0.0) > 0:
			# Offscreen staging must not spend the player's visible warning time.
			if actor.pos.x+64 >= game.camera_x and actor.pos.x-64 <= game.camera_x+960:
				actor.warning = maxf(0,actor.warning-delta)
			continue
		if actor.hp <= 0 or actor.blocked: continue
		# A hero entering the warning footprint remains safe until they clear it.
		if actor.get("additive",false) and not actor.get("contact_ready",false):
			if overlaps(actor,Rect2(game.player,game.PLAYER_SIZE)): continue
			actor.contact_ready = true
		if hero_cooldown <= 0 and game.invulnerable <= 0 and game.life_state == "alive" \
				and overlaps(actor,Rect2(game.player,game.PLAYER_SIZE)):
			game.hurt_player()
			hero_cooldown = definition.contact.per_target_cooldown_seconds
		for index in range(game.enemies.size()-1,-1,-1):
			var enemy: Dictionary = game.enemies[index]
			# Boss shell and invulnerability are never bypassed by environmental contact.
			if enemy.hp <= 0 or enemy.get("invulnerable",0.0) > 0 or enemy.get("is_boss",false) \
				or enemy.id == "clogfather": continue
			if enemy.get("swarm_cooldown",0.0) <= 0 and overlaps(actor,Rect2(enemy.pos,Vector2(38,36))):
				enemy.swarm_cooldown = definition.contact.per_target_cooldown_seconds
				game.damage_enemy(index,definition.contact.monster_damage,actor.pos,false)

func shot_hit(start: Vector2, finish: Vector2, index: int, thickness: float) -> float:
	var actor: Dictionary = actors[index]
	if actor.hp <= 0: return -1
	var offset: Vector2 = start-actor.pos
	var travel := finish-start
	var radius: float = definition.movement.contact_radius_pixels+thickness
	var c := offset.length_squared()-radius*radius
	if c <= 0: return 0
	var a := travel.length_squared()
	if a == 0: return -1
	var b := 2*offset.dot(travel)
	var discriminant := b*b-4*a*c
	if discriminant < 0: return -1
	var hit := (-b-sqrt(discriminant))/(2*a)
	return hit if hit >= 0 and hit <= 1 else -1

func damage(index: int, amount: float) -> void:
	var actor: Dictionary = actors[index]
	if actor.hp <= 0 or amount <= 0 or not is_finite(amount): return
	actor.hp = maxf(0,actor.hp-amount)
	actor.flash = 0.1
	damaged.emit(actor, actor.hp == 0)
	if actor.hp == 0:
		actor.death = 0
		actor.velocity = Vector2.ZERO

func draw(canvas: Node2D, show_bars: bool) -> void:
	for actor in actors:
		var state: String = "death" if actor.hp <= 0 else actor.animation
		var animation: Dictionary = definition.animation.animations[state]
		var duration: float = animation.frames[0].duration_seconds
		if actor.hp <= 0 and actor.death >= duration*animation.frames.size(): continue
		var clock: float = actor.death if actor.hp <= 0 else actor.clock
		var index := mini(int(clock/duration),3) if actor.hp <= 0 else int(clock/duration)%4
		var source: Array = animation.frames[index].source_rect
		canvas.draw_texture_rect_region(texture,Rect2(actor.pos-DISPLAY_SIZE/2,DISPLAY_SIZE),
			Rect2(source[0],source[1],source[2],source[3]),Color(2,2,2) if actor.flash > 0 else Color.WHITE)
		if show_bars and actor.hp > 0:
			canvas.draw_rect(Rect2(actor.pos+Vector2(-16,-57),Vector2(32,3)),Color("172432"))
			canvas.draw_rect(Rect2(actor.pos+Vector2(-16,-57),Vector2(32*actor.hp/definition.health.max_hp,3)),Color("7ce4bc"))
