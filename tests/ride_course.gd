extends SceneTree
## Real runtime input replay of the authored course, including each horizontal bound.
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("checks")

func fail(message: String) -> void:
	push_error(message)
	quit(1)

func target_y(witness: Dictionary, time: float) -> float:
	var value := 330.0
	for transition: Dictionary in witness.bank_transitions:
		if time < float(transition.at): break
		if time <= float(transition.until):
			return lerpf(float(transition.from_y),float(transition.to_y),
				(time-float(transition.at))/(float(transition.until)-float(transition.at)))
		value = float(transition.to_y)
	return value

func checks() -> void:
	AudioServer.set_bus_mute(0,true)
	var handoff: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://handoffs/level-two-ride-layout.json"))
	var cases := 0
	for hero in [0,1]:
		for witness: Dictionary in handoff.witnesses:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = witness.mode
			game.seed_override = 42
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.begin_level_two()
			game.flush.enter_landing(game)
			game.flush.enter_ride(game)
			game.flush.input_guard = false
			var ride = game.flush.ride
			# Fixed-bound witnesses start at the chosen allowed anchor; all subsequent motion is input-driven.
			ride.position.x = float(witness.anchor_x)
			var health: int = game.health
			var lives: int = game.lives
			var weapon: String = game.weapon.id
			var next_jump := 0
			for frame in range(5401):
				if ride.complete: break
				var dt := minf(1.0/120,45.0-float(ride.clock))
				var steer_y := clampf((target_y(witness,ride.clock+dt)-ride.position.y)/(140.0*dt),-1,1)
				var jump := false
				if next_jump < witness.jump_presses.size() and ride.clock+dt >= float(witness.jump_presses[next_jump].at):
					jump = true
					next_jump += 1
				game.flush.tick(game,dt,Vector2(0,steer_y),jump,false)
				if game.health != health or game.lives != lives or game.life_state != "alive":
					fail("Ride witness hit: %s %s x%s t%s events%s" %
						[game.employee.name,witness.mode,witness.anchor_x,ride.clock,ride.events])
					return
			if not ride.complete or not game.won or next_jump != 4 or int(ride.events.get("jump",0)) != 4:
				fail("Ride witness did not complete with four distinct jumps")
				return
			if game.weapon.id != weapon or game.flush.shots_fired != 0:
				fail("Ride witness changed weapon or fired")
				return
			print("PASS RIDE ",game.employee.name," ",witness.mode," x",witness.anchor_x,
				" no damage;4 jumps;45s completion")
			cases += 1
			game.queue_free()
			await process_frame
	print("PASS: ",cases," real-runtime course witnesses;both heroes/all modes/three horizontal anchors")
	quit()
