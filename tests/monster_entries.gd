extends SceneTree
const Trial = preload("res://scripts/three_screen_trial_game.gd")
const Section = preload("res://scripts/section_one_two_game.gd")
const Roaches = preload("res://scripts/skitterling_roach_body.gd")
const Entry = preload("res://scripts/monster_entry.gd")
var failures: Array[String] = []
var checks_run := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func prepare(script: GDScript) -> Node2D:
	var game = script.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	return game

func stage(game: Node2D, spec: Dictionary) -> void:
	game.reset_observation()
	for id in game.ledger: game.ledger[id] = "retired"
	game.ledger[spec.id] = "pending"
	game.grounded = true
	for x in range(int(spec.trigger),int(spec.end),20):
		game.player = Vector2(x,394)
		game.camera_x = clampf(x-320,0,1920)
		game.issue_event()
		if not game.actors.is_empty() or not game.swarms.actors.is_empty(): break

func entry_visible_fraction(game: Node2D, actor: Dictionary, camera: float) -> float:
	var entry: Dictionary = actor.entry
	var bounds := Rect2()
	if actor.role in ["runner","rear_runner"]:
		var renderer = game.world_art.damage_art
		var enemy: Dictionary = actor.runner.duplicate()
		enemy.phase = actor.age*4.5
		enemy.hp = actor.hp
		enemy.max_hp = actor.max_hp
		enemy.grounded = true
		var index: int = renderer.frame_for(enemy)
		var source: Rect2 = renderer.regions.toilet[index]
		var pivot: Vector2 = renderer.anchors.toilet[index]
		var scale: float = entry.scale*game.FlushfiendGeometry.RENDER_HEIGHT / game.Data.monster("toilet").damage_art.runtime_preparation.reference_body_height_pixels
		bounds = Rect2(entry.pos-pivot*scale,source.size*scale)
		if actor.facing > 0: bounds.position.x = entry.pos.x-(source.size.x-pivot.x)*scale
	else:
		var art: Dictionary = game.trial_data.role_art.roles[game.ROLE_KEYS[actor.role]]
		for frame_id in art.states.idle.frames:
			var frame: Dictionary = art.frames[frame_id]
			var rect: Rect2 = game.region(frame.destination)
			rect.position -= Vector2(art.anchor[0],art.anchor[1])
			if actor.facing > 0: rect.position.x = -rect.end.x
			rect = Rect2(entry.pos+rect.position*entry.scale,rect.size*entry.scale)
			bounds = bounds.merge(rect) if bounds.has_area() else rect
	return bounds.intersection(Rect2(camera,0,960,540)).get_area()/bounds.get_area()

func check_actor(game: Node2D, spec: Dictionary, hz: int) -> void:
	stage(game,spec)
	check(game.actors.size() == 1,"Authored actor admits: "+spec.id)
	if game.actors.is_empty(): return
	var actor: Dictionary = game.actors[0]
	check(Entry.active(actor) and not actor.active,"Admission begins in transit")
	check(game.live_population() == 1,"Arrival consumes population immediately")
	var entry: Dictionary = actor.entry
	var radius: float = game.ceiling_shooter_art.radius() if entry.mode == "ceiling" else game.actor_render_radius(actor.role)
	check(is_equal_approx(radius,entry.radius),"Entry envelope comes from all rendered frames")
	if entry.mode == "foreground":
		check(entry.scale == 3 and entry.pos.y-radius*entry.scale > 540,"Entire enlarged creature starts below viewport")
	elif entry.mode == "top":
		check(entry.pos.y+radius < 0,"Entire flying silhouette starts above viewport")
	elif entry.mode == "background":
		check(entry.clip == Rect2(entry.mouth-Vector2(32,32),Vector2(64,64)),"Zero-time pipe entry is masked")
		check(entry.pos.y-radius*entry.scale >= entry.clip.end.y,"Pipe creature initially lies wholly behind mouth mask")
	if entry.mode in ["floor","ceiling"]:
		check(entry.clip.has_area(),"Floor/ceiling actor starts occluded by its support")
	if entry.mode in ["left","right"]:
		check(entry.home.distance_to(entry.start) < radius*2+40,"Side arrivals finish immediately inside viewport")
		check(actor.facing == (1.0 if entry.mode == "left" else -1.0),"Side entrants face their direction of travel")
	check(game.foreground_entry(actor) == (entry.mode == "foreground"),"Only near-camera arrivals use foreground pass")
	if entry.mode == "background":
		check(radius*entry.pocket_scale < 32,"Complete pipe silhouette fits mouth before clipping handoff")
	var previous: Vector2 = entry.pos
	var initial_scale: float = entry.scale
	var age: float = actor.age
	var large_visible_seconds := 0.0
	for tick in range(5*hz):
		var arriving := Entry.active(actor)
		game.camera_x = clampf(game.camera_x+(2 if tick%2 == 0 else -2),0,1920)
		var position_before_camera: Vector2 = entry.pos
		check(position_before_camera == previous,"Camera/backtracking never rebases arrival")
		game.trial_clock += 1.0/hz
		game.step_trial_actors(1.0/hz)
		check(entry.pos.distance_to(previous) < 80,"Arrival has bounded continuous displacement")
		previous = entry.pos
		if entry.mode == "foreground" and entry.scale >= 2.5 and entry_visible_fraction(game,actor,game.camera_x) >= 0.8:
			large_visible_seconds += 1.0/hz
		if Entry.active(actor):
			check(not actor.active and not actor.contact_live and not actor.winding and actor.volley_left == 0,
				"No attack or contact before reaching playable plane")
			check(game.hostile_shots.is_empty(),"No projectile is born during entry")
			check(actor.age > age and actor.clock > 0,"Animation clock advances throughout travel")
		if arriving and not Entry.active(actor):
			check(entry.pos.is_equal_approx(actor.home) and is_equal_approx(entry.scale,1),"Entry ends at exact native pivot and scale")
			check(actor.feet.distance_to(actor.home) <= 300.0/hz+2,"Activation introduces no center teleport: "+spec.id)
			break
	check(actor.active,"Arrival eventually activates without waiting for hero movement")
	if entry.mode == "foreground":
		check(large_visible_seconds >= 0.12,"Recognizable rendered creature remains visibly large before shrinking")
	check(initial_scale > 1 if entry.mode == "foreground" else true,"Ground entry visibly recedes from viewer")

func check_foreground_edges(game: Node2D) -> void:
	for x in [40.0,920.0]:
		game.reset_observation()
		game.camera_x = 0
		game.player = Vector2(467,394)
		game.create_actor({"id":"edge","role":"runner","warning_seconds":0.9},Vector2(x,440))
		var actor: Dictionary = game.actors.back()
		game.start_actor_entry(actor,"foreground")
		var entry: Dictionary = actor.entry
		var staging: Vector2 = entry.staging
		check(absf(staging.x-480) >= 240,"Large foreground staging avoids centered hero")
		Entry.advance(entry,entry.duration*0.4)
		check(is_equal_approx(entry.scale,3) and entry.pos.is_equal_approx(staging),"Staging is reached at full threefold scale")
		check(entry_visible_fraction(game,actor,0) >= 0.8,"Near-edge destination still gets a recognizable large entrance")
		game.camera_x = 80
		Entry.advance(entry,entry.duration*0.3)
		check(entry.staging == staging and entry.home == Vector2(x,440),"Camera movement never replans staging or landing")
		check(entry.scale < 3 and entry.scale > 1,"Recession shrinks continuously after visible staging")
		Entry.advance(entry,entry.duration)
		check(entry.pos == Vector2(x,440) and entry.scale == 1,"Edge entrance settles at original native landing")

func check_swarm(game: Node2D, spec: Dictionary, hz: int) -> void:
	stage(game,spec)
	check(game.swarms.actors.size() == 1,"Authored swarm admits")
	if game.swarms.actors.is_empty(): return
	var actor: Dictionary = game.swarms.actors[0]
	check(game.live_population() == 1,"Arriving swarm consumes population")
	for offset: Vector2 in game.swarms.fly_offsets(actor):
		check(not Rect2(game.camera_x,0,960,540).grow(4).has_point(actor.pos+offset),
			"Every individual fly starts outside viewport")
	var previous: Vector2 = actor.pos
	var offsets: Array = game.swarms.fly_offsets(actor)
	var moved_flies := false
	var original_hp: int = game.health
	for tick in range(hz*8):
		game.player = actor.pos-game.PLAYER_SIZE*0.5
		game.invulnerable = 0
		game.step_trial_swarms(1.0/hz)
		check(actor.pos.distance_to(previous) < 25,"Swarm entry moves continuously")
		previous = actor.pos
		moved_flies = moved_flies or game.swarms.fly_offsets(actor) != offsets
		if game.swarms.entry_active(actor):
			check(not game.swarms.overlaps(actor,Rect2(game.player,game.PLAYER_SIZE)),"Transit swarm cannot contact hero")
			check(game.health == original_hp and actor.hunt_state == "wander","No damage or charge in transit")
			check(game.swarms.shot_hit(actor.pos,actor.pos,0,2) < 0,"Off-plane swarm is not a projectile target")
		else: break
	check(moved_flies,"Individual flies keep moving during the entrance")
	check(actor.pos.is_equal_approx(actor.entry.home),"Swarm reaches exact authored endpoint")
	check(game.swarms.overlaps(actor,Rect2(actor.pos-Vector2.ONE*10,Vector2.ONE*20)),"Normal contact resumes only after arrival")
	for tick in range(hz):
		var before: Vector2 = actor.pos
		game.step_trial_swarms(1.0/hz)
		check(actor.pos.distance_to(before) < 25,"Entry-to-wander handoff does not clamp or teleport")

func check_pipe_roaches() -> void:
	var pipe := {"mode":"launch","arrival":true,"mouth":Vector2(480,258),"radius":Vector2(115,105),"progress":0.0}
	for index in range(Roaches.COUNT):
		var target := Vector2(250+index*3,420)
		var first: Dictionary = Roaches.pipe_sample(index,target,pipe)
		var transform := Transform2D(Vector2(24,0),Vector2(0,24),first.position)
		check(first.clip and Roaches.clipped_insect(transform,pipe.mouth,pipe.radius).is_empty(),
			"Every Skitterling insect is fully hidden at zero time")
		var previous: Vector2 = first.position
		var scale: float = first.scale
		for tick in range(1,121):
			pipe.progress = float(tick)/120
			var sample: Dictionary = Roaches.pipe_sample(index,target,pipe)
			check(sample.position.distance_to(previous) < 20 and absf(sample.scale-scale) < 0.04,
				"Pipe reveal and handoff preserve continuous position and scale")
			if sample.get("clip",false):
				transform.origin = sample.position
				for polygon: PackedVector2Array in Roaches.clipped_insect(transform,pipe.mouth,pipe.radius):
					for vertex in polygon:
						check(((vertex-pipe.mouth)/pipe.radius).length() <= 1.0001,"Revealed pixels stay inside real aperture")
			previous = sample.position
			scale = sample.scale
		check(previous.is_equal_approx(target) and is_equal_approx(scale,1),"Roach reaches original body target unchanged")
		pipe.progress = 0.0

func check_side_handoff(game: Node2D) -> void:
	var spec: Dictionary
	for candidate in game.event_specs():
		if candidate.role == "runner" and candidate.entry.mode == "left":
			spec = candidate
			break
	stage(game,spec)
	check(game.actors.size() == 1,"Side regression admits runner")
	if game.actors.is_empty(): return
	var actor: Dictionary = game.actors[0]
	game.player = Vector2(actor.home.x+100,394)
	check(game.player.x < spec.feet.x,"Hero stands between ingress and original home")
	game.invulnerable = 0
	var hp: int = game.health
	for tick in range(600):
		game.trial_clock += 1.0/120
		game.step_trial_actors(1.0/120)
		if actor.active:
			check(actor.feet.x < spec.feet.x,"Runner becomes dangerous before remote home")
		if game.health < hp: break
	check(game.health < hp,"Edge walker hits intervening hero instead of passing harmlessly through")

func check_ceiling(game: Node2D) -> void:
	for spec in game.event_specs():
		if spec.entry.mode != "ceiling": continue
		stage(game,spec)
		check(game.actors.size() == 1,"Ceiling shooter admits")
		if game.actors.is_empty(): return
		var actor: Dictionary = game.actors[0]
		Entry.advance(actor.entry,actor.entry.duration)
		actor.feet = actor.entry.home
		actor.active = true
		for target in [Vector2(200,400),Vector2(2800,400),Vector2(actor.feet.x,400)]:
			game.player = target
			actor.winding = true
			var direction: Vector2 = game.ceiling_direction(actor)
			var pivot: Vector2 = game.ceiling_shooter_art.pivot(actor.feet)
			var muzzle: Vector2 = game.shot_origin(actor)
			check((muzzle-pivot).normalized().is_equal_approx(direction),"Ceiling muzzle follows actual aim ray")
			var body: Rect2 = game.actor_projectile_rect(actor)
			for point in game.ceiling_shooter_art.barrel_corners(actor.feet,direction):
				check(body.grow(0.01).has_point(point),"Projectile hitbox includes rotated barrel")
			check(body.grow(0.01).encloses(game.ceiling_shooter_art.body_rect(actor.feet)),
				"Ceiling collision includes hanging body")

func checks() -> void:
	check_pipe_roaches()
	var pipe := Entry.create(Vector2(500,440),50,1.5,"background",Vector2(500,180))
	check(pipe.clip.has_area(),"Background helper masks the very first frame before any tick")
	for script in [Trial,Section]:
		var game := prepare(script)
		check_foreground_edges(game)
		check_side_handoff(game)
		check_ceiling(game)
		for spec in game.event_specs():
			stage(game,spec)
			check(not game.actors.is_empty() or not game.swarms.actors.is_empty(),
				"Authored event has a safe admission in its window: "+spec.id)
		var selected := {}
		for spec in game.event_specs():
			var key: String = spec.role+spec.entry.mode
			if not selected.has(key): selected[key] = spec
		for hz in [30,120]:
			for spec: Dictionary in selected.values():
				if spec.role == "swarm": check_swarm(game,spec,hz)
				else: check_actor(game,spec,hz)
		game.reset_observation()
		check(game.actors.is_empty() and game.swarms.actors.is_empty(),"Retry discards unfinished arrivals")
		root.remove_child(game)
		game.free()
	print("Monster entries: %d checks, %d failures" % [checks_run,failures.size()])
	quit(0 if failures.is_empty() else 1)
