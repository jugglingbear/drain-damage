extends SceneTree
const Fixtures = preload("res://tests/flush_scheduler.gd")
const Debris = preload("res://scripts/flush_debris.gd")
const Flow = preload("res://scripts/flush_flow.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	var layout := Fixtures.definition()
	for mode in ["easy","normal","hard"]:
		check(layout.difficulty[mode].total_spawn_count == {"easy":30,"normal":48,"hard":85}[mode],"Approved cohort totals")
		for speed in [235.0,270.0]:
			for seed_value in range(4):
				var debris := Debris.new()
				debris.configure(layout,mode,seed_value)
				var model := Fixtures.Swimmer.new()
				model.clock = 8
				model.position = Vector2(290,0).rotated(seed_value*PI/2)
				var origin: Vector2 = model.position
				var wave: Dictionary = layout.difficulty[mode].waves[0]
				var admitted := debris.spawn_wave(model,wave,0,speed)
				if not admitted: print("TARGET FAILURE ",mode," ",speed," ",seed_value," ",origin," ",debris.last_failure)
				check(admitted,"Complete targeted group has verified escape")
				if debris.ledger.is_empty(): continue
				var entry: Dictionary = debris.ledger.back()
				check(entry.positions[0] == origin and entry.target_origin == origin,"Primary locks exact current position")
				check(entry.target_kinds.slice(0,3) == ["hero","sidestep","sidestep"],"Every wave includes one plus two")
				check(entry.count == wave.count,"No unapproved extra density")
				check(entry.duration == {"easy":2.7,"normal":2.25,"hard":1.8}[mode],"Warning intervals unchanged")
				for index in [1,2]:
					var offset: Vector2 = entry.positions[index]-origin
					check(is_zero_approx(offset.x) != is_zero_approx(offset.y),"Nearby target on cardinal sidestep axis")
					check(offset.length() >= 80 and offset.length() <= 176.001,"Sidestep distance remains nearby")
					check(not Flow.drain_contact(entry.positions[index],debris.drain_radii,debris.drain_projection,debris.drain_depth,debris.drain_footprint_radius),"No sidestep anchor inside drain")
				check(entry.positions[1] != entry.positions[2],"Two distinct sidestep targets")
				var before: Array = entry.positions.duplicate()
				model.position += Vector2(50,50)
				for item: Dictionary in debris.items:
					debris.move_hazard(item,8,0.5)
					check(item.pos == item.impact_pos,"Falling targets never home toward moved hero")
				check(entry.positions == before,"Warning anchors immutable")
				var witness := {"positions":entry.witness_positions,"commands":entry.witness}
				check(debris.incoming_clear(witness,8,debris.items),"Actual new hazards clear full-horizon witness")
				var second := Debris.new()
				second.configure(layout,mode,seed_value)
				model.position = origin
				check(second.spawn_wave(model,wave,0,speed) and second.ledger == debris.ledger,"Retry deterministic targets and escape")
				debris.configure(layout,mode,seed_value)
				check(debris.items.is_empty() and debris.ledger.is_empty(),"Reset clears all target state")
	# Rim cases preserve two distinct valid locations rather than dropping an object.
	var debris := Debris.new()
	debris.configure(layout,"normal",0)
	for time in [8.0,17.0,26.0,32.75]:
		for direction in range(16):
			var origin := Vector2.from_angle(direction*TAU/16)*(Flow.annulus(time).y-1)
			var points := debris.targeted_points(origin,time+2.25,["dead_hamster","corn","dead_hamster"])
			if points.size() != 3: print("RIM FAILURE ",time," ",direction," ",origin)
			check(points.size() == 3,"Mixed-size rim group remains feasible")
	print("Flush targeted groups: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func check(value: bool, message: String) -> void:
	checks += 1
	if not value and message not in failures:
		failures.append(message)
		push_error(message)
