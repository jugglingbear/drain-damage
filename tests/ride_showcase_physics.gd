extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
class Host extends Node2D:
	var employee := {"id":"sean"}
	var difficulty := "normal"
	var health := 5
	var lives := 3
	var invulnerable := 0.0
	var paused := false
	var life_state := "alive"
	var won := false
	func hurt_player() -> void:
		if invulnerable > 0 or life_state != "alive": return
		health -= 1
		invulnerable = 1.5
		if health <= 0:
			lives -= 1
			life_state = "dead"

func obstacle(id: String, kind: String, x: float, width: float, y := 330.0, depth := 200.0) -> Dictionary:
	return {"id":id,"kind":kind,"x":x,"y":y,"width":width,"depth":depth}

func setup(obstacles: Array) -> Array:
	var host := Host.new()
	root.add_child(host)
	var model := Model.new()
	model.definition = {"encounters":[{"id":"test","obstacles":obstacles}]}
	model.begin(host)
	return [host,model]

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	# Edge grazing, quarter-area corner overlap and 64% overlap remain safe in both pit types.
	for kind in ["gap","long_pit"]:
		for point in [Vector2(355,330),Vector2(399,330),Vector2(400,280),Vector2(400,330),Vector2(412.6,330),Vector2(413.5,330)]:
			var probe := setup([obstacle("threshold",kind,500,200,330,100)])
			var rider: Host = probe[0]
			var simulation = probe[1]
			simulation.position = point
			simulation.scroll_speed = 0
			simulation.tick(rider,.01,Vector2.ZERO,false)
			assert((rider.life_state == "dead") == (point == Vector2(413.5,330)),
				"Only the 65%-area footprint may trigger the fall")
			rider.free()
		for hz in [30,60,120,144]:
			var probe := setup([obstacle("sweep",kind,500,200)])
			var rider: Host = probe[0]
			var simulation = probe[1]
			for frame in range(hz):
				if rider.life_state == "dead": break
				simulation.tick(rider,1.0/hz,Vector2.RIGHT,false)
			assert(rider.life_state == "dead")
			assert(absf(simulation.position.x+simulation.encounter_scroll-413.5) < .001)
			rider.free()
	# A single long traversal cannot repeatedly hurt after immunity expires.
	var pair := setup([obstacle("wide","support",1000,1800),obstacle("later","support",2600,50)])
	var host: Host = pair[0]
	var model = pair[1]
	model.tick(host,3.1,Vector2.ZERO,false)
	assert(host.health == 4 and model.events.hit == 1)
	model.tick(host,1.2,Vector2.ZERO,false)
	assert(host.health == 3 and model.events.hit == 2)
	host.free()
	# Immune entry consumes traversal without a delayed hit.
	pair = setup([obstacle("immune","support",500,900)])
	host = pair[0]; model = pair[1]
	host.invulnerable = .1
	model.tick(host,1,Vector2.ZERO,false)
	assert(host.health == 5 and not model.events.has("hit"))
	host.free()
	# Every unsupported gap/pit fall uses normal death once, regardless of HP or impact immunity.
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for kind in ["gap","long_pit"]:
				for hp in [1,5]:
					for immunity in [0.0,1.0]:
						pair = setup([obstacle("water",kind,320,80)])
						host = pair[0]; model = pair[1]
						host.employee.id = hero
						host.difficulty = mode
						host.health = hp
						host.invulnerable = immunity
						model.tick(host,.1,Vector2.ZERO,false)
						assert(host.lives == 2 and host.life_state == "dead" and model.events.fall == 1)
						assert(not model.events.has("recovered") and model.recovery_clock == 0)
						model.tick(host,1,Vector2.ZERO,false)
						assert(host.lives == 2)
						model.definition.encounters.append({"id":"retry","obstacles":[obstacle("retry-gap",kind,2600,100)]})
						host.health = 5
						host.life_state = "alive"
						model.begin(host,1)
						assert(model.checkpoint_index == 1 and model.position == Vector2(300,330))
						assert(model.events.get("fall",0) == 0 and host.lives == 2)
						host.free()
	# Ordinary water is safe; solid, overhead and spike impacts remain normal nonlethal damage.
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for kind in ["support","overhead","low_barrier"]:
				var impact := obstacle("impact",kind,300,100)
				impact.bottom_z = 64
				pair = setup([impact])
				host = pair[0]; model = pair[1]
				host.employee.id = hero
				host.difficulty = mode
				model.tick(host,.01,Vector2.ZERO,false)
				assert(host.health == 4 and host.lives == 3 and host.life_state == "alive")
				host.free()
	pair = setup([obstacle("distant","support",3000,20)])
	host = pair[0]; model = pair[1]
	model.tick(host,1,Vector2.ZERO,false)
	assert(host.health == 5 and host.lives == 3 and not model.events.has("fall"))
	host.free()
	# Fatal contact freezes the exact failed water-plane position for the wrapper's falling animation.
	pair = setup([obstacle("edge","gap",400,100)])
	host = pair[0]; model = pair[1]
	model.tick(host,.1,Vector2.RIGHT,false)
	assert(host.life_state == "dead" and model.events.fall == 1)
	assert(absf(model.position.x+model.encounter_scroll-363.5) < .001)
	assert(absf(model.clock-63.5/960.0) < .00001)
	var frozen_position: Vector2 = model.position
	var frozen_scroll: float = model.encounter_scroll
	model.tick(host,1,Vector2.RIGHT,true)
	assert(model.position == frozen_position and model.encounter_scroll == frozen_scroll and host.lives == 2)
	host.free()
	# Only the uncovered footprint over the pit counts toward the65% fall threshold.
	for width in [30,40,80,100]:
		pair = setup([obstacle("water","gap",300,200),obstacle("deck","deck",300,width)])
		host = pair[0]; model = pair[1]
		model.tick(host,.001,Vector2.ZERO,false)
		assert(host.health == (0 if width == 30 else 5))
		assert(host.lives == (2 if width == 30 else 3))
		host.free()
	# Both head envelopes hit low ceilings while grounded; jump cannot bypass overhead.
	for hero in ["sean","tony"]:
		var ceiling := obstacle("ceiling","overhead",300,100)
		ceiling.bottom_z = 64
		pair = setup([ceiling])
		host = pair[0]; model = pair[1]
		host.employee.id = hero
		model.tick(host,.01,Vector2.ZERO,true)
		assert(host.health == 4)
		host.free()
	# Rest begins only after all components pass the leftmost permitted board anchor.
	pair = setup([obstacle("first","support",500,20,100,20),obstacle("last","support",1800,20,100,20)])
	host = pair[0]; model = pair[1]
	model.definition.encounters.append({"id":"second","obstacles":[obstacle("next","support",2600,20)]})
	while model.phase != "rest": model.tick(host,.01,Vector2.ZERO,false)
	assert(1810-model.encounter_scroll < 135 and model.course.obstacles.is_empty())
	var rest_start: float = model.clock
	model.tick(host,2.99,Vector2.ZERO,false)
	assert(model.phase == "rest" and model.encounter_index == 0)
	model.tick(host,.02,Vector2.ZERO,false)
	assert(model.encounter_index == 1 and model.clock-rest_start >= 3)
	model.begin(host,1)
	assert(model.checkpoint_index == 1 and model.position == Vector2(300,330))
	host.free()
	# Ramp surface/boost: grounded only, locked x, continuous height/pitch, 1.25s airtime.
	var ramp := obstacle("ramp","ramp",2500,200)
	ramp.rise = 40
	ramp.launch_x = 2600
	var course := [ramp,obstacle("pit","long_pit",2915,540),obstacle("catch","deck",3417.5,465)]
	pair = setup(course)
	host = pair[0]; model = pair[1]
	model.position.x = 650
	var previous_height := 0.0
	var previous_pitch := 0.0
	var launched := false
	var locked_x := -1.0
	for frame in range(1100):
		model.tick(host,.005,Vector2.RIGHT,false)
		if model.ramp_active or model.boosted:
			if locked_x < 0: locked_x = model.position.x
			assert(absf(model.position.x-locked_x) < .001)
			assert(absf(model.render_height-previous_height) < 3)
			assert(absf(model.render_pitch-previous_pitch) < .06)
		previous_height = model.render_height
		previous_pitch = model.render_pitch
		if model.boosted:
			launched = true
			assert(is_equal_approx(model.active_jump_duration,1.25))
		if launched and model.jump_age < 0: break
	assert(launched and host.health == 5 and host.life_state == "alive")
	assert(model.position.x+model.encounter_scroll-45 > 3185)
	host.free()
	# A late ordinary jump over the entry does not earn an automatic boost.
	pair = setup(course)
	host = pair[0]; model = pair[1]
	model.encounter_scroll = 2040
	model.tick(host,.01,Vector2.ZERO,true)
	model.tick(host,1.5,Vector2.ZERO,false)
	assert(not model.events.has("ramp") and host.life_state == "dead")
	host.free()
	# Even with the 65% grace margin, a wider pit exceeds the fastest normal jump.
	for takeoff in range(2400,2601,20):
		pair = setup([obstacle("pit","long_pit",2915,600)])
		host = pair[0]; model = pair[1]
		model.position.x = 180
		model.encounter_scroll = takeoff-180
		model.tick(host,.001,Vector2.RIGHT,true)
		model.tick(host,2,Vector2.RIGHT,false)
		assert(host.life_state == "dead" and host.lives == 2)
		host.free()
	# A moving obstacle crossing the board between outer frames must still hit.
	pair = setup([obstacle("moving","support",600,100,230,20)])
	host = pair[0]; model = pair[1]
	model.course.obstacles[0].motion = {"axis":"y","amplitude":100,"period":.4,"phase":0}
	model.position.x = 600
	model.scroll_speed = 0
	model.tick(host,.4,Vector2.ZERO,false)
	assert(host.health == 4 and model.events.hit == 1)
	host.free()
	# Event-time immunity: an early contact while immune cannot hurt later in a large outer frame.
	pair = setup([obstacle("early","support",350,20)])
	host = pair[0]; model = pair[1]
	host.invulnerable = .03
	model.tick(host,.3,Vector2.ZERO,false)
	assert(host.health == 5)
	host.free()
	# Grounded ramp works at every permitted extreme and with either hero's head envelope.
	for hero in ["sean","tony"]:
		for anchor in [180,300,650]:
			for bank in [260,330,400]:
				pair = setup(course)
				host = pair[0]; model = pair[1]
				host.employee.id = hero
				model.position = Vector2(anchor,bank)
				model.tick(host,7,Vector2.ZERO,false)
				assert(host.health == 5 and host.life_state == "alive")
				assert(model.events.ramp == 1 and model.events.landed >= 1)
				host.free()
	# Include the landing frame: visual pitch must settle without an angle snap at either frame rate.
	for hz in [60,120]:
		for hero in ["sean","tony"]:
			for bank in [260,400]:
				pair = setup(course)
				host = pair[0]; model = pair[1]
				host.employee.id = hero
				model.position.y = bank
				var prior_height := 0.0
				var prior_pitch := 0.0
				var was_boosted := false
				var landed := false
				for frame in range(8*hz):
					model.tick(host,1.0/hz,Vector2.ZERO,false)
					# Maximum ballistic speed is below265px/s; pitch settling stays below5rad/s.
					assert(absf(model.render_height-prior_height) <= 265.0/hz)
					assert(absf(model.render_pitch-prior_pitch) <= 5.0/hz)
					if was_boosted and not model.boosted:
						assert(model.render_height == 12 and model.render_pitch == 0)
						landed = true
						break
					prior_height = model.render_height
					prior_pitch = model.render_pitch
					was_boosted = model.boosted
				assert(landed and host.health == 5)
				host.free()
	# The rendered110px rigid board's actual transformed underside endpoints touch the surface.
	pair = setup(course)
	host = pair[0]; model = pair[1]
	model.active_ramp = ramp
	for center in range(2345,2601):
		model._ramp_pose(center)
		var transform := Transform2D(model.render_pitch,Vector2(center,-model.render_height))
		for local_x in [-55.0,55.0]:
			var endpoint: Vector2 = transform*Vector2(local_x,0)
			assert(absf(-endpoint.y-model._surface(endpoint.x)) < .001)
		# Convex ramp remains below the full straight underside, including its interior.
		for local_x in range(-55,56,5):
			var contact: Vector2 = transform*Vector2(local_x,0)
			assert(-contact.y >= model._surface(contact.x)-.001)
	model.position.x = 300
	model.encounter_scroll = 2300
	model._launch(true)
	print("RAMP EXACT height=",model.launch_height," velocity=",model.launch_velocity,
		" coefficient=",model.launch_gravity," peak=",model.active_jump_apex)
	host.free()
	# Narrow ramp requires the whole board inside its actual bank footprint, including at the edges.
	var narrow_ramp := ramp.duplicate(true)
	narrow_ramp.depth = 100
	var narrow_course := [narrow_ramp,obstacle("pit","long_pit",2915,540),obstacle("catch","deck",3417.5,465)]
	for hero in ["sean","tony"]:
		for anchor in [180,300,650]:
			for bank in [260.0,293.99,294.0,330.0,366.0,366.01,400.0]:
				pair = setup(narrow_course)
				host = pair[0]; model = pair[1]
				host.employee.id = hero
				model.position = Vector2(anchor,bank)
				model.tick(host,7,Vector2.ZERO,false)
				var aligned: bool = bank >= 294 and bank <= 366
				assert(host.life_state == ("alive" if aligned else "dead"))
				assert(model.events.get("ramp",0) == (1 if aligned else 0))
				assert(absf(model.position.y-bank) < .001)
				host.free()
	# Sliding off during ascent cancels eligibility; steering back cannot reacquire it.
	pair = setup(narrow_course)
	host = pair[0]; model = pair[1]
	while not model.ramp_active: model.tick(host,.005,Vector2.ZERO,false)
	model.tick(host,.25,Vector2.DOWN,false)
	assert(not model.ramp_active and model.events.get("ramp",0) == 0)
	model.tick(host,.2,Vector2.UP,false)
	model.tick(host,2,Vector2.ZERO,false)
	assert(host.life_state == "dead" and model.events.get("ramp",0) == 0)
	host.free()
	print("PASS: showcase traversal immunity, fatal unsupported gaps/pits, full deck, heads, multipart rest, ramp continuity and missed ramp")
	quit()
