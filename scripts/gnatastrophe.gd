extends "res://scripts/sewer_swarm.gd"
## Continuous wandering alternates with announced straight charges at captured hero positions.
const NOTICE_DISTANCE := 320.0
const ACQUIRE_SECONDS := 0.8
const TERRAIN_RADIUS := 4.0
const WANDER_SPEED := 70.0
const HUNT_SPEED := WANDER_SPEED*2
const REFORM_SECONDS := 0.65
const WEAPON_SCALE := 1.5
var target := Vector2.ZERO
var viewport := Rect2()
const FORMATIONS_PATH := "res://assets/bestiary/sewer-flies/weapon-formations-v3.json"
var formations: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FORMATIONS_PATH))
var fly_texture: Texture2D
var visual_radius := 48.0
var motion_radius := TERRAIN_RADIUS

func _init() -> void:
	super._init()
	visual_radius = 0
	for name in ["sword","arrow","spear","spiked_mace"]:
		for point in formations.formations[name].anchors:
			visual_radius = maxf(visual_radius,(Vector2(point[0],point[1])-Vector2(64,64)).length())
	# Include the complete glyph and its orbit, independently of the unchanged damage circle.
	visual_radius = ceilf((visual_radius+Vector2(4,4).length()+float(formations.micro_motion.amplitude_pixels))*WEAPON_SCALE)
	var source: Dictionary = formations.source
	var original: Texture2D = load("res://"+source.image)
	var r: Array = source.source_rect
	var pixels := original.get_image().get_region(Rect2i(r[0],r[1],r[2],r[3]))
	pixels.convert(Image.FORMAT_RGBA8)
	var visited := {}
	var largest: Array[Vector2i] = []
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			var point := Vector2i(x,y)
			if visited.has(point) or pixels.get_pixelv(point).a < float(source.alpha_cutoff): continue
			var component: Array[Vector2i] = [point]
			visited[point] = true
			var index := 0
			while index < component.size():
				for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var next: Vector2i = component[index]+offset
					if not Rect2i(0,0,pixels.get_width(),pixels.get_height()).has_point(next): continue
					if visited.has(next) or pixels.get_pixelv(next).a < float(source.alpha_cutoff): continue
					visited[next] = true
					component.append(next)
				index += 1
			if component.size() > largest.size(): largest = component
	var retained := {}
	for point in largest: retained[point] = true
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			var point := Vector2i(x,y)
			if not retained.has(point): pixels.set_pixelv(point,Color.TRANSPARENT)
	fly_texture = ImageTexture.create_from_image(pixels)

func spawn(position: Vector2, bounds: Rect2, seed_value: int) -> Dictionary:
	var actor := super.spawn(position,bounds,seed_value)
	actor.merge({"hunt_state":"wander","hunt_clock":0.0,"morph":0.0,
		"wander_bounds":bounds,"locked_target":position,"reacquire_wait":0.0,
		"weapon_form":["sword","arrow","spear","spiked_mace"][posmod(seed_value,4)],
		"formed":false})
	return actor

func step(game: Node2D, delta: float) -> void:
	if game.paused or game.life_state != "alive" or delta < 0: return
	target = game.player+game.PLAYER_SIZE*0.5
	viewport = Rect2(game.camera_x,0,960,540)
	for actor in actors:
		if game.has_method("swarm_hunt_bounds"): actor.hunt_bounds = game.swarm_hunt_bounds(actor)
	super.step(game,delta)
	# Transformation tells are visual cues, not immunity to touching a living swarm.
	for actor in actors:
		if actor.hp > 0 and hero_cooldown <= 0 and game.invulnerable <= 0 \
				and game.life_state == "alive" and overlaps(actor,Rect2(game.player,game.PLAYER_SIZE)):
			game.hurt_player()
			hero_cooldown = definition.contact.per_target_cooldown_seconds

func clear_with_radius(start: Vector2, finish: Vector2, bounds: Rect2,
		solids: Array[Rect2], radius: float) -> bool:
	if not bounds.grow(-radius).has_point(finish): return false
	for solid in solids:
		var expanded := solid.grow(radius+0.01)
		if expanded.has_point(finish) or segment_hit(start,finish,expanded) >= 0: return false
	return true

func clear_path(start: Vector2, finish: Vector2, bounds: Rect2, solids: Array[Rect2]) -> bool:
	return clear_with_radius(start,finish,bounds,solids,motion_radius)

func room_for_weapon(actor: Dictionary, solids: Array[Rect2]) -> bool:
	return clear_with_radius(actor.pos,actor.pos,actor.bounds,solids,TERRAIN_RADIUS)

func position_goal(actor: Dictionary, solids: Array[Rect2]) -> Vector2:
	var best := Vector2.INF
	var nearest := INF
	for distance in [24.0,48.0,72.0,96.0,144.0]:
		for index in range(16):
			var candidate: Vector2 = actor.pos+Vector2.from_angle(index*TAU/16)*distance
			if not clear_with_radius(candidate,candidate,actor.bounds,solids,visual_radius): continue
			if not clear_with_radius(actor.pos,candidate,actor.bounds,solids,48): continue
			var score: float = distance+candidate.distance_to(target)*0.05
			if score < nearest:
				nearest = score
				best = candidate
	return best

func start_morph(actor: Dictionary) -> void:
	actor.morph_from = fly_offsets(actor)
	actor.morph_clock = actor.clock
	actor.weapon_form = ["sword","arrow","spear","spiked_mace"][actor.rng.randi_range(0,3)]
	actor.locked_target = target
	actor.hunt_state = "acquire"
	actor.hunt_clock = 0.0
	actor.warning = ACQUIRE_SECONDS
	actor.heading = (actor.locked_target-actor.pos).angle()

func start_reform(actor: Dictionary) -> void:
	actor.reform_from = fly_offsets(actor)
	actor.reform_clock = actor.clock
	actor.hunt_state = "reform"
	actor.hunt_clock = 0.0
	actor.formed = false
	actor.desired = actor.heading+actor.rng.randf_range(-PI,PI)

func wander_motion(actor: Dictionary, delta: float, solids: Array[Rect2]) -> void:
	actor.decision -= delta
	if actor.decision <= 0:
		actor.desired = actor.heading+actor.rng.randf_range(-1.2,1.2)
		actor.decision = actor.rng.randf_range(0.4,1.0)
	actor.heading = rotate_toward(actor.heading,actor.desired,2.5*delta)
	var direction := Vector2.from_angle(actor.heading)
	var finish: Vector2 = actor.pos+direction*WANDER_SPEED*delta
	if not clear_path(actor.pos,finish,actor.bounds,solids):
		# Turn immediately at a solid edge instead of decelerating into a stationary hover.
		actor.heading = recovery_heading(actor,solids)
		actor.desired = actor.heading
		finish = actor.pos+Vector2.from_angle(actor.heading)*WANDER_SPEED*delta
		if not clear_path(actor.pos,finish,actor.bounds,solids):
			for index in range(32):
				var angle := index*TAU/32
				var candidate: Vector2 = actor.pos+Vector2.from_angle(angle)*WANDER_SPEED*delta
				if clear_path(actor.pos,candidate,actor.bounds,solids):
					finish = candidate
					actor.heading = angle
					actor.desired = angle
					break
	var before: Vector2 = actor.pos
	if clear_path(actor.pos,finish,actor.bounds,solids): actor.pos = finish
	actor.velocity = (actor.pos-before)/delta
	actor.blocked = actor.velocity.is_zero_approx()

func step_motion(actor: Dictionary, delta: float, solids: Array[Rect2]) -> void:
	if delta <= 0: return
	actor.clock += delta
	if step_entry(actor,delta): return
	actor.flash = maxf(0,actor.flash-delta)
	if actor.hp <= 0:
		actor.death += delta
		return
	motion_radius = TERRAIN_RADIUS
	actor.solids = solids
	var visible := viewport.has_area() and viewport.intersects(Rect2(
		actor.pos-Vector2.ONE*visual_radius,Vector2.ONE*visual_radius*2))
	var distance: float = actor.pos.distance_to(target)
	actor.reacquire_wait = maxf(0,actor.get("reacquire_wait",0.0)-delta)
	if actor.hunt_state == "wander":
		wander_motion(actor,delta,solids)
		if visible and distance <= NOTICE_DISTANCE and actor.get("warning",0.0) <= 0 and actor.reacquire_wait <= 0:
			actor.bounds = actor.get("hunt_bounds",actor.bounds)
			var bounds: Rect2 = actor.bounds
			if bounds.size.y < visual_radius*2+2:
				bounds = bounds.grow_individual(0,visual_radius,0,visual_radius)
			actor.bounds = bounds.intersection(Rect2(bounds.position.x,0,bounds.size.x,440))
			if room_for_weapon(actor,solids): start_morph(actor)
			else: actor.hunt_state = "position"
	elif actor.hunt_state == "position":
		actor.warning = ACQUIRE_SECONDS
		var goal := position_goal(actor,solids)
		if goal != Vector2.INF: actor.desired = (goal-actor.pos).angle()
		actor.decision = 1.0
		wander_motion(actor,delta,solids)
		if room_for_weapon(actor,solids): start_morph(actor)
	elif actor.hunt_state == "acquire":
		# The visible tell keeps drifting; it never parks a completed weapon in midair.
		wander_motion(actor,delta,solids)
		actor.heading = (actor.locked_target-actor.pos).angle()
		if visible: actor.hunt_clock += delta
		actor.morph = minf(1,actor.hunt_clock/REFORM_SECONDS)
		actor.warning = maxf(0,ACQUIRE_SECONDS-actor.hunt_clock)
		if actor.hunt_clock >= ACQUIRE_SECONDS:
			actor.formed = true
			actor.hunt_state = "pursue"
			actor.hunt_clock = 0.0
			actor.heading = (actor.locked_target-actor.pos).angle()
	elif actor.hunt_state == "pursue":
		# Aim at the captured location: a dodge does not bend the charge after launch.
		var destination: Vector2 = actor.locked_target
		var finish: Vector2 = actor.pos.move_toward(destination,HUNT_SPEED*delta)
		if clear_path(actor.pos,finish,actor.bounds,solids):
			actor.velocity = (finish-actor.pos)/delta
			actor.pos = finish
			actor.blocked = false
			if actor.pos.is_equal_approx(destination): start_reform(actor)
		else:
			# A wall/floor ends this charge; immediately drift away while reforming, never phase through it.
			start_reform(actor)
			wander_motion(actor,delta,solids)
	elif actor.hunt_state == "reform":
		wander_motion(actor,delta,solids)
		actor.hunt_clock += delta
		actor.morph = 1-minf(1,actor.hunt_clock/REFORM_SECONDS)
		if actor.hunt_clock >= REFORM_SECONDS:
			actor.hunt_state = "wander"
			actor.morph = 0.0
			actor.reacquire_wait = 0.8
	select_animation(actor)

func orbit_at(index: int, clock_value: float) -> Vector2:
	var phase := clock_value*TAU*(1.2+float(index%7)*0.2)+index*2.399963
	return Vector2(cos(phase),sin(phase))*float(formations.micro_motion.amplitude_pixels)

func fly_offsets(actor: Dictionary) -> Array[Vector2]:
	var output: Array[Vector2] = []
	var cloud: Array = formations.formations.cloud.anchors
	var weapon: Array = formations.formations[actor.weapon_form].anchors
	var blend: float = smoothstep(0,1,actor.morph)
	for index in range(int(formations.fly_count)):
		var orbit := orbit_at(index,actor.clock)*lerpf(1,WEAPON_SCALE,blend)
		var base := Vector2(cloud[index][0],cloud[index][1])-Vector2(64,64)
		if actor.hunt_state in ["wander","position"]: output.append(base+orbit)
		elif actor.hunt_state == "reform":
			var origin: Vector2 = actor.reform_from[index]-orbit_at(index,actor.reform_clock)*WEAPON_SCALE
			output.append(base.lerp(origin,blend)+orbit)
		else:
			var target_offset := (Vector2(weapon[index][0],weapon[index][1])-Vector2(64,64)).rotated(actor.heading)*WEAPON_SCALE
			var origin: Vector2 = actor.get("morph_from",[])[index] if actor.has("morph_from") else base
			if actor.has("morph_from"): origin -= orbit_at(index,actor.get("morph_clock",actor.clock))
			output.append(origin.lerp(target_offset,blend)+orbit)
	for index in range(output.size()):
		output[index] = terrain_offset(actor,output[index])
	return output

func terrain_offset(actor: Dictionary, offset: Vector2) -> Vector2:
	# A swarm flows against a surface; its oversized silhouette must not stop its center above the hero.
	var point: Vector2 = actor.pos+offset
	var half_size := 4*lerpf(1,WEAPON_SCALE,smoothstep(0,1,actor.morph))
	for solid: Rect2 in actor.get("solids",[]):
		var boundary := solid.grow(half_size+0.01)
		if not boundary.has_point(point): continue
		var options := [Vector2(boundary.position.x,point.y),Vector2(boundary.end.x,point.y),
			Vector2(point.x,boundary.position.y),Vector2(point.x,boundary.end.y)]
		var nearest: Vector2 = options[0]
		for candidate: Vector2 in options:
			if candidate.distance_squared_to(point) < nearest.distance_squared_to(point): nearest = candidate
		point = nearest
	if actor.get("clogfather_reinforcement",false) and not entry_active(actor):
		# The boss promises an empty center lane; keep every rendered/contact glyph in its flank.
		var interior: Rect2 = actor.bounds.grow(-half_size-0.01)
		point = point.clamp(interior.position,interior.end)
	return point-actor.pos

func overlaps(actor: Dictionary, rect: Rect2) -> bool:
	if entry_active(actor): return false
	if not actor.get("clogfather_reinforcement",false) and super.overlaps(actor,rect): return true
	if not actor.has("hunt_state"): return false
	var half_size := 4*lerpf(1,WEAPON_SCALE,smoothstep(0,1,actor.morph))
	for offset in fly_offsets(actor):
		if Rect2(actor.pos+offset-Vector2.ONE*half_size,Vector2.ONE*half_size*2).intersects(rect): return true
	return false

func damage(index: int, amount: float) -> void:
	var actor: Dictionary = actors[index]
	if actor.hp > 0 and amount >= actor.hp:
		actor.death_origin = fly_offsets(actor)
		actor.death_clock = actor.clock
	super.damage(index,amount)

func draw(canvas: Node2D, show_bars: bool) -> void:
	for actor in actors:
		var offsets := fly_offsets(actor)
		var alpha := 1.0
		if actor.hp <= 0:
			var progress := clampf(float(actor.death)/0.64,0,1)
			if progress >= 1: continue
			alpha = 1-smoothstep(0.2,1,progress)
			var origins: Array = actor.get("death_origin",offsets)
			for index in range(offsets.size()):
				var origin: Vector2 = origins[index]
				offsets[index] = origin+Vector2.from_angle(index*2.399963)*(18*(1-pow(1-progress,2))) \
					+Vector2(0,12*progress*progress) \
					+(orbit_at(index,actor.clock)-orbit_at(index,actor.get("death_clock",actor.clock))) \
					*lerpf(1,WEAPON_SCALE,smoothstep(0,1,actor.morph))*(1-progress)
		for offset in offsets:
			var tint := Color(2,2,2,alpha) if actor.flash > 0 else Color(1,1,1,alpha)
			var scale := lerpf(1,WEAPON_SCALE,smoothstep(0,1,actor.morph))
			canvas.draw_texture_rect(fly_texture,Rect2(actor.pos+offset-Vector2(4,4)*scale,Vector2(8,8)*scale),false,tint)
		if show_bars and actor.hp > 0 and not entry_active(actor):
			canvas.draw_rect(Rect2(actor.pos+Vector2(-16,-57),Vector2(32,3)),Color("172432"))
			canvas.draw_rect(Rect2(actor.pos+Vector2(-16,-57),Vector2(32*actor.hp/definition.health.max_hp,3)),Color("7ce4bc"))
