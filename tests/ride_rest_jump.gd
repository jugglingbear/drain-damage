extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")
const Fixture = preload("res://tests/ride_showcase_physics.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var cases := 0
	for hero in ["sean","tony"]:
		for mode in ["easy","normal","hard"]:
			for hz in [30,60,120]:
				var host := Fixture.Host.new()
				host.employee.id = hero
				host.difficulty = mode
				var model := Model.new()
				model.definition = {"encounters":[{"id":"first","obstacles":[]},
					{"id":"next","obstacles":[{"id":"distant","kind":"support","x":3000,"y":330,"width":20,"depth":20}]}]}
				model.begin(host)
				model.tick(host,Model.STEP,Vector2.ZERO,false)
				assert(model.phase == "rest" and model.rest_remaining == 3)
				var rest_start: float = model.clock
				var dt: float = 1.0/hz
				model.tick(host,dt,Vector2.RIGHT,true)
				assert(model.events.jump == 1 and model.jump_height > 0 and model.position.x > 300)
				# One accepted edge cannot repeat while flight/cooldown continue through a large rest tick.
				model.tick(host,.6-dt,Vector2.ZERO,false)
				assert(model.events.landed == 1 and model.cooldown > 0)
				model.tick(host,dt,Vector2.ZERO,true)
				model.tick(host,.2,Vector2.ZERO,false)
				assert(model.events.jump == 1 and model.events.landed == 1 and model.cooldown <= 0)
				# A press during flight is discarded rather than buffered for landing.
				model.tick(host,dt,Vector2.ZERO,true)
				model.tick(host,.1,Vector2.ZERO,false)
				model.tick(host,dt,Vector2.ZERO,true)
				model.tick(host,.7,Vector2.ZERO,false)
				assert(model.events.jump == 2 and model.events.landed == 2)
				# Start the final rest jump. The encounter starts at3s even while airborne.
				model.tick(host,model.rest_remaining-.1,Vector2.ZERO,false)
				model.tick(host,dt,Vector2.ZERO,true)
				assert(model.events.jump == 3 and model.phase == "rest")
				model.tick(host,model.rest_remaining+.05,Vector2.ZERO,false)
				assert(model.phase == "encounter" and model.encounter_index == 1)
				assert(absf(model.clock-rest_start-3.05) < .00001)
				assert(absf(model.jump_age-.15) < .00001 and model.jump_height > 0)
				assert(absf(model.last_event.clock-rest_start-3) < .00001)
				model.tick(host,.6,Vector2.ZERO,false)
				assert(model.events.jump == 3 and model.events.landed == 3 and model.jump_age < 0)
				# Model pause/death guards do not progress motion or accept an edge.
				var before_clock: float = model.clock
				host.paused = true
				model.tick(host,1,Vector2.ZERO,true)
				assert(model.clock == before_clock and model.events.jump == 3)
				host.paused = false
				host.life_state = "dead"
				model.tick(host,1,Vector2.ZERO,true)
				assert(model.clock == before_clock and model.events.jump == 3)
				host.free()
				cases += 1
	print("PASS: ",cases," rest jumps, flight/cooldown, discarded airborne edge, exact3s boundary continuity, pause/death guards")
	quit()
