extends SceneTree
## Shared hunting behavior and rendered purple-bolt viewport regressions.
const Gnat = preload("res://scripts/gnatastrophe.gd")
const Trial = preload("res://scripts/three_screen_trial_game.gd")
const Opening = preload("res://scripts/opening_trial_game.gd")
const Data = preload("res://scripts/combat_data.gd")
var failures: Array[String] = []
var checks_run := 0
var lethal_signals := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func fresh(gnat: RefCounted, seed_value := 0) -> Dictionary:
	return gnat.spawn(Vector2(500,250),Rect2(0,0,4000,1000),seed_value)

func checks() -> void:
	var gnat := Gnat.new()
	check(gnat.definition.has("health"),"Shared Gnat initializes canonical creature definition")
	if not gnat.definition.has("health"):
		quit(1)
		return
	gnat.viewport = Rect2(0,0,960,540)
	var solids: Array[Rect2] = []
	var cloud_points: Array = gnat.formations.formations.cloud.anchors
	var interior_flies := 0
	var above := 0
	var below := 0
	for point in cloud_points:
		var offset := Vector2(point[0],point[1])-Vector2(64,64)
		if offset.length() < 20: interior_flies += 1
		if offset.y < -15: above += 1
		if offset.y > 15: below += 1
	check(interior_flies >= 8 and above >= 5 and below >= 5,"Default cloud has a filled rounded body, not an arch")
	var constants: Dictionary = gnat.get_script().get_script_constant_map()
	check(constants.has("REFORM_SECONDS") and constants.has("TERRAIN_RADIUS"),"Center-terrain moving reform runtime is available")
	if not constants.has("REFORM_SECONDS") or not constants.has("TERRAIN_RADIUS"):
		quit(1)
		return
	check(is_equal_approx(float(constants.get("WANDER_SPEED",0)),70),"Wander speed is seventy")
	check(is_equal_approx(Gnat.HUNT_SPEED,140),"Charge speed is twice wander speed")
	for distance in [319.0,320.0,321.0]:
		var boundary_actor := fresh(gnat)
		gnat.target = boundary_actor.pos+Vector2(distance,0)
		gnat.step_motion(boundary_actor,0.000001,solids)
		check((boundary_actor.hunt_state == "acquire") == (distance <= 320),"Acquisition boundary %s" % distance)
	var all_forms := ["sword","arrow","spear","spiked_mace"]
	for form in all_forms:
		var morph_actor := fresh(gnat)
		gnat.target = morph_actor.pos+Vector2(240,0)
		gnat.step_motion(morph_actor,0.001,solids)
		# Isolate each authored shape; separate seeded-cycle tests verify random selection.
		morph_actor.weapon_form = form
		var start: Array = gnat.fly_offsets(morph_actor)
		check(start == morph_actor.morph_from,"Morph begins at existing fly positions")
		var previous: Array = start
		var acquire_travel := 0.0
		for tick in range(98):
			var before_position: Vector2 = morph_actor.pos
			var state: String = morph_actor.hunt_state
			gnat.step_motion(morph_actor,1.0/120,solids)
			if state == "acquire":
				acquire_travel += before_position.distance_to(morph_actor.pos)
				if morph_actor.hunt_state == "acquire":
					check(absf(before_position.distance_to(morph_actor.pos)*120-70) < 0.02,"Actual acquisition moves at wander speed")
			var current: Array = gnat.fly_offsets(morph_actor)
			check(current.size() == start.size(),"Fly identities survive morph")
			for index in range(current.size()):
				check(current[index].distance_to(previous[index]) < 12,"Continuous morph and lock, form "+form)
			previous = current
		check(morph_actor.formed and morph_actor.hunt_state == "pursue","Visible moving tell completes")
		check(acquire_travel > 45,"Acquisition continues moving instead of parking")
		var formed: Array = gnat.fly_offsets(morph_actor)
		var anchors: Array = gnat.formations.formations[form].anchors
		for index in range(formed.size()):
			var original := (Vector2(anchors[index][0],anchors[index][1])-Vector2(64,64)).rotated(morph_actor.heading)
			var expected: Vector2 = (original+gnat.orbit_at(index,morph_actor.clock))*1.5
			check(formed[index].distance_to(expected) < 0.001,"Complete weapon formation is fifty percent larger")
		var before: Array = gnat.fly_offsets(morph_actor)
		morph_actor.clock += 0.1
		check(before != gnat.fly_offsets(morph_actor),"Formed weapon retains living fly motion")
		check(morph_actor.hp == gnat.definition.health.spawn_hp,"Morph preserves HP")
		var radius: float = gnat.definition.movement.contact_radius_pixels
		check(is_equal_approx(radius,48),"Damage reach remains forty-eight pixels")
		check(gnat.overlaps(morph_actor,Rect2(morph_actor.pos+Vector2(radius-0.01,0),Vector2.ONE)),"Contact inside canonical radius")
		check(not gnat.overlaps(morph_actor,Rect2(morph_actor.pos+Vector2(200,0),Vector2.ONE)),"Empty space beyond all flies is not contact")
	var actor := fresh(gnat)
	gnat.target = actor.pos+Vector2(250,0)
	gnat.step_motion(actor,0.001,solids)
	gnat.viewport = Rect2(2000,0,960,540)
	var acquisition_lock: Vector2 = actor.locked_target
	var offscreen_clock: float = actor.hunt_clock
	gnat.step_motion(actor,0.2,solids)
	check(actor.hunt_clock == offscreen_clock,"Offscreen acquisition does not consume visible tell")
	gnat.viewport = Rect2(0,0,960,540)
	for tick in range(120):
		gnat.target = actor.pos+Vector2(0,200)
		gnat.step_motion(actor,1.0/120,solids)
		if actor.hunt_state == "pursue": break
	check(actor.hunt_state == "pursue" and actor.has("locked_target"),"Completed tell creates charge lock")
	if not actor.has("locked_target"):
		quit(1)
		return
	var locked: Vector2 = actor.locked_target
	check(locked == acquisition_lock,"Target remains captured from start of moving tell")
	var arrived := false
	for tick in range(600):
		var before_position: Vector2 = actor.pos
		gnat.target = actor.pos+Vector2(0,250)
		gnat.step_motion(actor,1.0/120,solids)
		check(actor.locked_target == locked,"Moving hero cannot retarget committed charge")
		var displacement: Vector2 = actor.pos-before_position
		if actor.hunt_state != "pursue":
			arrived = actor.hunt_state == "reform"
			check(actor.pos.distance_to(locked) <= 140.0/120+1,"Reform begins at captured destination")
			break
		check(absf(displacement.length()*120-140) < 0.02,"Actual charge displacement is twice wander speed")
		check(absf(displacement.normalized().cross((locked-before_position).normalized())) < 0.0001,"Charge follows a straight captured line")
	check(arrived,"Charge arrival starts cloud reform without contact requirement")
	var reform_travel := 0.0
	var prior_offsets: Array = gnat.fly_offsets(actor)
	for tick in range(90):
		var before_position: Vector2 = actor.pos
		gnat.step_motion(actor,1.0/120,solids)
		reform_travel += before_position.distance_to(actor.pos)
		check(absf(before_position.distance_to(actor.pos)*120-70) < 0.02,"Actual reform moves at wander speed")
		var offsets: Array = gnat.fly_offsets(actor)
		for index in range(offsets.size()):
			check(offsets[index].distance_to(prior_offsets[index]) < 12,"Smooth weapon-to-cloud transition")
		prior_offsets = offsets
		if actor.hunt_state == "wander": break
	check(actor.hunt_state == "wander" and actor.morph == 0,"Reform returns to rounded cloud")
	check(reform_travel > 35,"Cloud reform keeps moving")
	for tick in range(90):
		gnat.target = actor.pos+Vector2(100,0)
		var before_position: Vector2 = actor.pos
		gnat.step_motion(actor,1.0/120,solids)
		check(absf(before_position.distance_to(actor.pos)*120-70) < 0.02,"Actual inter-cycle wander speed is seventy")
		check(actor.hunt_state == "wander","At least point-eight seconds of wander between attacks")
	var sequence_a := cycle_forms(gnat,1234)
	var sequence_b := cycle_forms(gnat,1234)
	check(sequence_a == sequence_b,"Seed reproduces weapon selection across cycles")
	check(sequence_a.size() >= 4,"Moving swarm repeats its attack cycle")
	var diversity := {}
	for form in sequence_a: diversity[form] = true
	check(diversity.size() > 1,"Repeat cycles choose varied weapon forms")
	check_blocked_charge(gnat)
	# Near-floor movement retains center clearance and keeps every rendered fly above the floor.
	var low := gnat.spawn(Vector2(600,390),Rect2(400,300,500,140),0)
	gnat.target = Vector2(500,400)
	var floor_solids: Array[Rect2] = [Rect2(0,440,4000,100)]
	var enlarged := false
	for tick in range(600):
		var previous_position: Vector2 = low.pos
		gnat.step_motion(low,1.0/120,floor_solids)
		check(previous_position.distance_to(low.pos) <= Gnat.HUNT_SPEED/120+0.001,"Positioning never teleports")
		if low.morph > 0:
			enlarged = true
			check(low.pos.y+4 <= 440,"Swarm center remains clear of solid floor")
			check_visual_clearance(gnat,low,floor_solids)
	check(enlarged,"Near-floor cloud forms a weapon without needing full circular clearance")
	gnat.actors = [actor]
	gnat.damaged.connect(func(_actor: Dictionary, lethal: bool) -> void:
		if lethal: lethal_signals += 1)
	gnat.damage(0,actor.hp)
	gnat.damage(0,100)
	check(lethal_signals == 1,"Death signal emitted once")
	var death_position: Vector2 = actor.pos
	gnat.step_motion(actor,0.2,solids)
	check(actor.pos == death_position and actor.death > 0,"Dead swarm advances death without pursuit")
	gnat.reset()
	check(gnat.hero_cooldown == 0 and gnat.actors.size() == 2,"Reset restores shared population and cooldown")
	for restored in gnat.actors:
		check(restored.hunt_state == "wander" and restored.morph == 0 and restored.hp > 0,"Reset removes hunting/death state")
	check_grounded_contact()
	check_bolts()
	print("Gnatastrophe: %d checks, %d failures" % [checks_run,failures.size()])
	quit(0 if failures.is_empty() else 1)

func cycle_forms(gnat: RefCounted, seed_value: int) -> Array[String]:
	var actor := fresh(gnat,seed_value)
	var forms: Array[String] = []
	var solids: Array[Rect2] = []
	for tick in range(4800):
		gnat.viewport = Rect2(actor.pos-Vector2(480,270),Vector2(960,540))
		if actor.hunt_state == "wander": gnat.target = actor.pos+Vector2(180,0)
		var state: String = actor.hunt_state
		gnat.step_motion(actor,1.0/120,solids)
		if actor.hunt_state == "acquire" and state != "acquire": forms.append(actor.weapon_form)
		if forms.size() >= 6: break
	gnat.viewport = Rect2(0,0,960,540)
	return forms

func check_blocked_charge(gnat: RefCounted) -> void:
	var actor := fresh(gnat,4)
	var solids: Array[Rect2] = []
	gnat.target = Vector2(900,250)
	# Acquire in the clear, then place a solid between the locked charge and its destination.
	gnat.target = Vector2(750,250)
	for tick in range(180):
		gnat.step_motion(actor,1.0/120,solids)
		if actor.hunt_state == "pursue": break
	check(actor.hunt_state == "pursue","Obstacle fixture acquired charge")
	var wall := Rect2(actor.pos.x+gnat.visual_radius+35,0,100,540)
	solids.append(wall)
	var reformed := false
	var moved_after_block := 0.0
	for tick in range(180):
		var before_position: Vector2 = actor.pos
		gnat.step_motion(actor,1.0/120,solids)
		if actor.hunt_state == "reform": reformed = true
		if reformed: moved_after_block += before_position.distance_to(actor.pos)
		check(actor.pos.x+4 <= wall.position.x+0.01,"Swarm center remains outside blocking wall")
		check_visual_clearance(gnat,actor,solids)
	check(reformed,"Blocked charge switches to reform")
	check(moved_after_block > 20,"Blocked charge steers away instead of stalling")


func check_visual_clearance(gnat: RefCounted, actor: Dictionary, solids: Array[Rect2]) -> void:
	var half_size := Vector2.ONE*4*lerpf(1,1.5,smoothstep(0,1,float(actor.morph)))
	for offset: Vector2 in gnat.fly_offsets(actor):
		var rendered := Rect2(actor.pos+offset-half_size,half_size*2)
		for solid in solids:
			check(not rendered.intersects(solid),"Terrain-adjusted fly glyph does not penetrate a solid")

func check_grounded_contact() -> void:
	var game := Trial.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.actors.clear()
	game.enemies.clear()
	game.swarms.actors.clear()
	game.player = Vector2(2400,394)
	game.grounded = true
	game.camera_x = 1920
	game.invulnerable = 100
	var center: Vector2 = game.player+game.PLAYER_SIZE*0.5
	check(center.y == 417,"Fixture uses actual grounded hero center above floor440")
	var hunter: Dictionary = game.swarms.spawn(Vector2(2550,300),Rect2(2520,220,150,200),42)
	hunter.merge({"event_id":"outside-pocket","warning":0.0,"additive":true,"contact_ready":false,"pattern_live":false})
	game.swarms.actors.append(hunter)
	var reached := false
	for tick in range(900):
		game.step_trial_swarms(1.0/120)
		check(hunter.pos.y+4 <= 440,"Grounded charge center never enters floor")
		check_visual_clearance(game.swarms,hunter,game.actor_solids())
		if hunter.pos.distance_to(center) < 1.2:
			reached = true
			break
	check(reached,"Authored narrow-pocket swarm reaches stationary grounded hero center outside its pocket")
	# Saturate attack slots: physical contact must not become harmless because shots own the budget.
	game.hostile_shots.clear()
	for index in range(int(game.tuning.active_patterns_max)):
		game.hostile_shots.append({"owner":"occupied-%d" % index})
	for shared_step in [true,false]:
		for state in ["wander","acquire","pursue","reform"]:
			game.player = Vector2(2400,394)
			game.health = game.employee.max_health
			game.invulnerable = 0
			game.life_state = "alive"
			game.swarms.hero_cooldown = 0
			var actor: Dictionary = game.swarms.spawn(game.player+game.PLAYER_SIZE*0.5,Rect2(0,0,2880,440),7)
			actor.merge({"event_id":"contact-"+state,"warning":1.0,"additive":true,"contact_ready":false,
				"pattern_live":false})
			game.swarms.target = actor.pos+Vector2(100,0)
			if state != "wander":
				game.swarms.start_morph(actor)
				if state in ["pursue","reform"]:
					actor.morph = 1.0
					actor.formed = true
					actor.hunt_state = "pursue"
				if state == "reform": game.swarms.start_reform(actor)
			game.swarms.actors.clear()
			game.swarms.actors.append(actor)
			var hp: int = game.health
			if shared_step: game.swarms.step(game,0.001)
			else: game.step_trial_swarms(0.001)
			check(game.health == hp-1,"Live "+state+" contact deals damage in "+("shared" if shared_step else "trial"))
			if shared_step: game.swarms.step(game,0.001)
			else: game.step_trial_swarms(0.001)
			check(game.health == hp-1,"Repeated contact respects invulnerability and cooldown")
			game.invulnerable = 0
			if shared_step: game.swarms.step(game,0.001)
			else: game.step_trial_swarms(0.001)
			check(game.health == hp-1,"Swarm cooldown independently prevents repeated damage")
			game.swarms.hero_cooldown = 0
			game.invulnerable = 1
			if shared_step: game.swarms.step(game,0.001)
			else: game.step_trial_swarms(0.001)
			check(game.health == hp-1,"Hero invulnerability independently prevents repeated damage")
	# Find a visible outer fly whose target rectangle lies wholly outside the core damage circle.
	var weapon: Dictionary = game.swarms.spawn(Vector2(2500,240),Rect2(0,0,2880,440),1)
	weapon.merge({"event_id":"outer-fly","pattern_live":false,"warning":0.0,"additive":true,"contact_ready":false})
	game.swarms.target = weapon.pos+Vector2(100,0)
	game.swarms.start_morph(weapon)
	weapon.weapon_form = "spear"
	weapon.morph = 1.0
	weapon.formed = true
	weapon.hunt_state = "pursue"
	weapon.heading = 0.0
	weapon.locked_target = weapon.pos+Vector2(100,0)
	weapon.solids = game.actor_solids()
	var outer := Vector2.INF
	for offset: Vector2 in game.swarms.fly_offsets(weapon):
		var point: Vector2 = weapon.pos+offset
		# Touch a glyph edge, rather than placing the whole hero around its center,
		# which can also overlap the core circle and fail to isolate this regression.
		for position in [Vector2(point.x+5,point.y-game.PLAYER_SIZE.y*0.5),
			Vector2(point.x-5-game.PLAYER_SIZE.x,point.y-game.PLAYER_SIZE.y*0.5),
			Vector2(point.x-game.PLAYER_SIZE.x*0.5,point.y+5),
			Vector2(point.x-game.PLAYER_SIZE.x*0.5,point.y-5-game.PLAYER_SIZE.y)]:
			var hero_rect := Rect2(position,game.PLAYER_SIZE)
			if weapon.pos.distance_to(weapon.pos.clamp(hero_rect.position,hero_rect.end)) > 48.1 \
				and game.swarms.overlaps(weapon,hero_rect):
				outer = position
				break
		if outer != Vector2.INF: break
	check(outer != Vector2.INF,"Weapon has a contact-test fly beyond core circle")
	if outer != Vector2.INF:
		game.player = outer
		game.health = game.employee.max_health
		game.invulnerable = 0
		game.swarms.hero_cooldown = 0
		game.swarms.actors.clear()
		game.swarms.actors.append(weapon)
		var hp: int = game.health
		game.step_trial_swarms(0.001)
		check(game.health == hp-1,"Outer rendered weapon fly causes actual HP damage")
		weapon.hp = 0
		game.invulnerable = 0
		game.swarms.hero_cooldown = 0
		game.step_trial_swarms(0.001)
		game.swarms.step(game,0.001)
		check(game.health == hp-1,"Dead swarm cannot deal contact damage through either update path")
	root.remove_child(game)
	game.free()


func check_bolts() -> void:
	Data.load_data()
	var game := Opening.new()
	game.trial_data = Data.bundle.opening_trial
	for camera in [0.0,700.0]:
		game.camera_x = camera
		var shape: Rect2 = game.purple_bolt_rect(Vector2.ZERO)
		for pair in [
			[Vector2(camera-shape.end.x+0.1,250),Vector2(camera-shape.end.x-0.1,250)],
			[Vector2(camera+960-shape.position.x-0.1,250),Vector2(camera+960-shape.position.x+0.1,250)],
			[Vector2(camera+400,-shape.end.y+0.1),Vector2(camera+400,-shape.end.y-0.1)],
			[Vector2(camera+400,540-shape.position.y-0.1),Vector2(camera+400,540-shape.position.y+0.1)]]:
			check(not game.purple_bolt_offscreen(pair[0]),"Last visible sprite sliver retains purple bolt")
			check(game.purple_bolt_offscreen(pair[1]),"Fully exited sprite retires purple bolt")
	check(not game.purple_shot_allowed(Vector2.ZERO,Vector2.ZERO),"Reject stationary infinite bolt")
	game.free()
