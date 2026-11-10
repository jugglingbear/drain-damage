extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void: call_deferred("run_checks")

func advance_to(game: Node2D, time: float) -> void:
	game.dispenser.tick(game,maxf(0,time-game.dispenser.elapsed))

func run_checks() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	var dispenser = game.dispenser
	for cue in ["inspection-pass","inspection-fail","compress-stage-one","compress-stage-two"]:
		assert(dispenser.voices.has(cue) and dispenser.voices[cue].stream != null,"Verdict and crush audio imported")
	for costume in ["easy","normal","hard"]:
		for hero in [0,1]:
			game.difficulty = costume
			game.employee = game.Crew.EMPLOYEES[hero]
			for hp in range(1,game.employee.max_health+1):
				game.reset_game()
				game.dialogue.finish()
				game.dialogue.release_guard = 0
				game.health = hp
				game.activate_checkpoint(0)
				var healthy: bool = hp == game.employee.max_health
				assert(dispenser.arrival_health == hp and game.health == hp)
				assert(dispenser.events == ["grab"] and dispenser.hides_hero())
				if hp == 1:
					var frame: Dictionary = dispenser.inspection.hero_states[costume][game.employee.id].compress_stage_two
					for viewport in [Vector2(960,540),Vector2(480,270),Vector2(160,120)]:
						for unit in [Vector2.ZERO,Vector2.ONE,Vector2(0,1),Vector2(1,0)]:
							dispenser.sample_impact(viewport,unit)
							var scale_value: float = dispenser.impact_scale*dispenser.rect(dispenser.art.heroes[game.employee.id].states.ball.destination).size.x/dispenser.rect(frame.destination).size.x
							var geometry: Dictionary = dispenser.frame_geometry(frame,
								dispenser.impact_point-dispenser.vector(frame.grip_anchor)*scale_value,scale_value)
							assert(Rect2(Vector2.ZERO,viewport).grow(.01).encloses(geometry.destination),
								"Actual thrown frame stays inside safe viewport at sampled extremes")
					dispenser.sample_impact(game.get_viewport_rect().size)
				advance_to(game,2.1)
				var verdict: String = "inspection_pass" if healthy else "inspection_fail"
				assert(dispenser.events == ["grab","inspection_arm_deploy","inspect","diagnosis",verdict])
				assert(is_equal_approx(dispenser.diagnosis_fraction(),float(hp)/game.employee.max_health))
				var before: Array = dispenser.events.duplicate()
				game.set_paused(true)
				dispenser.tick(game,10)
				assert(dispenser.events == before and is_equal_approx(dispenser.elapsed,2.1))
				game.set_paused(false)
				if healthy:
					advance_to(game,3.55)
					var pose: Dictionary = dispenser.held_pose(game)
					var feet: Vector2 = game.respawn_point+Vector2(13,46)
					assert(pose.origin.is_equal_approx(feet-Vector2(64,104)),"Same intact hero returns to supported feet")
					advance_to(game,3.76)
					assert(dispenser.stocked and dispenser.dispenses == 0 and not dispenser.overlay_visible())
					for forbidden in ["vend","compress_stage_one","compress_stage_two","throw","impact"]:
						assert(not dispenser.events.has(forbidden),"Healthy inspection cannot replace or injure hero")
				else:
					advance_to(game,3.0)
					assert(dispenser.events[-1] == "compress_stage_one")
					var first: Dictionary = dispenser.held_pose(game)
					for boundary in [2.9,3.4]:
						dispenser.elapsed = boundary+.05
						var transition: Dictionary = dispenser.held_pose(game)
						assert(transition.has("previous") and transition.blend > 0 and transition.blend < 1,
							"Crush transitions interpolate instead of instantly substituting hero")
						assert((transition.origin+dispenser.vector(transition.frame.grip_anchor)).is_equal_approx(
							transition.previous_origin+dispenser.vector(transition.previous.grip_anchor)),
							"Both transitional poses share the physical grip")
					dispenser.elapsed = 3.0
					advance_to(game,3.5)
					assert(dispenser.events[-1] == "compress_stage_two")
					var second: Dictionary = dispenser.held_pose(game)
					assert(second.frame.visible_height_px < first.frame.visible_height_px,"Second crush visibly tighter")
					advance_to(game,4.2)
					assert(dispenser.events[-1] == "throw_windup" and not dispenser.overlay_visible())
					assert(dispenser.held_pose(game).grip != second.grip,"Arm actually winds up before release")
					advance_to(game,4.4)
					assert(dispenser.events[-1] == "throw" and dispenser.overlay_visible() and dispenser.stocked)
					assert(dispenser.held_pose(game).grip.is_equal_approx(dispenser.throw_origin_grip()))
					advance_to(game,5.11)
					assert(game.health == game.employee.max_health,"Newly dispensed hero restores health")
					assert(dispenser.events[-1] == "vend" and not dispenser.stocked and dispenser.dispenses == 1)
					advance_to(game,8.06)
					assert(dispenser.events.count("vend") == 1 and dispenser.events.count("impact") == 1)
				assert(not dispenser.active and dispenser.finalizations == 1 and game.lives == 3)
				assert(dispenser.events.count("release") == 1 and dispenser.arrival_health == hp)
				# Skip and watchdog preserve the branch's stock/life semantics at every phase.
				for exit_time in [0.2,2.1,3.0,3.5,4.2,5.2]:
					for watchdog in [false,true]:
						game.reset_game()
						game.health = hp
						game.activate_checkpoint(0)
						advance_to(game,exit_time)
						if watchdog:
							dispenser.timeline = []
							dispenser.tick(game,100)
						else: dispenser.finish(game,true)
						dispenser.finish(game,true)
						assert(dispenser.finalizations == 1 and not dispenser.active and game.lives == 3)
						assert(dispenser.dispenses == (0 if healthy else 1))
						assert(dispenser.stocked == healthy and not dispenser.overlay_visible())
	game.free()
	await create_timer(.2).timeout
	print("PASS: both heroes/all costumes/arrival HP; verdicts, healthy setdown, staged crush/windup, pause, skip/watchdog and stock/lives")
	quit()
