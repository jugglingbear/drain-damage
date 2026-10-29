extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	for hero in [0,1]:
		for jump_entry in [false,true]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.begin_level_two()
			game.flush.enter_ride(game,6)
			var ride = game.flush.ride
			var triggers: Array = [2290,2732,3182,3640] if jump_entry else [2732,3182,3640]
			var next_jump := 0
			for frame in range(870):
				var world_x: float = ride.position.x+ride.encounter_scroll
				var jump: bool = ride.encounter_index == 6 and next_jump < triggers.size() and world_x >= triggers[next_jump]
				if jump: next_jump += 1
				ride.audio.advance(1.0/120,false,true)
				ride.tick(game,1.0/120,Vector2.ZERO,jump)
				assert(game.life_state == "alive","Authored cap route must remain supported")
				if ride.audio.starts.get("ride_land",0) == 1: break
			assert(next_jump == triggers.size())
			assert(ride.audio.starts.get("metal_impact",0) == (3 if jump_entry else 2),"Each cap jump lands once; riding on stays silent")
			assert(ride.audio.starts.get("porcelain_contact",0) == 0,"Next encounter must not color a water landing")
			assert(ride.audio.starts.get("ride_land",0) == 1,"Cap-to-water landing plays wet cue")
			assert(ride.encounter_index == 7 and ride.landing_material == "water")
			# Check actual porcelain support, and reset stale material on retry.
			game.flush.enter_ride(game,7)
			ride.position = Vector2(300,280)
			ride.encounter_scroll = 2690-300
			ride.jump_age = ride.active_jump_duration-1.0/120
			ride.audio.advance(1,false,true)
			ride.tick(game,1.0/120,Vector2.ZERO,false)
			assert(ride.audio.starts.get("porcelain_contact",0) == 1)
			game.flush.enter_ride(game,6)
			assert(ride.landing_material == "water")
			game.queue_free()
			await process_frame
	print("PASS: both heroes, ride/jump entry, cap hops, water across encounter boundary, porcelain support and retry")
	quit()
