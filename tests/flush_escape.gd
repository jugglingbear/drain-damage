extends SceneTree
const Fixtures = preload("res://tests/flush_scheduler.gd")
const Debris = preload("res://scripts/flush_debris.gd")
const Flow = preload("res://scripts/flush_flow.gd")

func idle_counterfactual(layout: Dictionary, mode: String, speed: float, ledger: Array) -> Dictionary:
	var model := Fixtures.Swimmer.new()
	var host := Fixtures.Host.new()
	host.employee.move_speed = speed
	var debris := Debris.new()
	debris.configure(layout,mode,0)
	debris.next_wave = layout.difficulty[mode].waves.size()
	var next := 0
	var travel := 0.0
	for frame in range(35*120+1):
		var before: float = model.clock
		model.clock = frame/120.0
		var dt: float = model.clock-before
		var old: Vector2 = model.position
		if dt > 0: model.position = Flow.swim(model.position,Vector2.ZERO,speed,model.clock,dt,layout.difficulty[mode].flow)
		travel += old.distance_to(model.position)
		host.invulnerable = maxf(0,host.invulnerable-dt)
		while next < ledger.size() and model.clock+0.000001 >= float(ledger[next].at):
			var wave: Dictionary = ledger[next]
			for index in range(wave.props.size()):
				var id := str(wave.props[index])
				for canonical in Debris.PROP_NAMES:
					if Debris.PROP_NAMES[canonical] == id: id = canonical
				var item := Fixtures.prop(str(wave.id)+"-"+str(index),wave.positions[index],
					float(wave.at)+float(wave.duration),debris.radius_for(id))
				item.at = wave.at
				item.duration = wave.duration
				debris.items.append(item)
			next += 1
		debris.advance(model,host,dt)
	var result := {"damage":100000-host.health,"travel":travel,"end":model.position,
		"displacement":model.position.distance_to(Vector2(0,259.2))}
	host.free()
	return result

func _initialize() -> void:
	var layout := Fixtures.definition()
	var seed_count := maxi(1,int(OS.get_environment("FLUSH_SEEDS")))
	var mode_filter := OS.get_environment("FLUSH_MODE")
	var policy := OS.get_environment("FLUSH_POLICY")
	var planning_usec: Array[int] = []
	var hz := 60 if OS.get_environment("FLUSH_HZ") == "60" else 120
	for mode in ["easy","normal","hard"]:
		if not mode_filter.is_empty() and mode_filter != mode: continue
		for speed in [235.0,270.0]:
			for seed_value in range(seed_count):
				var model := Fixtures.Swimmer.new()
				var host := Fixtures.Host.new()
				host.employee.move_speed = speed
				var debris := Debris.new()
				debris.configure(layout,mode,seed_value)
				var observed := {}
				var guided_travel := 0.0
				var proof_health := host.health
				var proof_entry: Dictionary = {}
				# Outer cadence matches the host; physical steps and witness commands remain120Hz.
				for outer_frame in range(35*hz+1):
					for substep in range(120/hz):
						var frame := outer_frame*(120/hz)+substep
						if frame > 35*120: continue
						var before: float = model.clock
						var command := Vector2.ZERO
						if not debris.ledger.is_empty():
							var wave: Dictionary = debris.ledger[-1]
							var index := roundi((before-float(wave.witness_start))*120)
							if index < wave.witness.size(): command = wave.witness[maxi(0,index)]
						if policy == "idle": command = Vector2.ZERO
						if policy == "recovery" and not debris.ledger.any(func(w: Dictionary) -> bool: return w.admission == "recovery"):
							command = Vector2.ZERO
						if policy == "outward": command = model.position.normalized()
						if policy == "rotate": command = Vector2.from_angle(before*0.7+seed_value)
						model.clock = float(frame)/120
						var dt: float = model.clock-before
						model.last_steering = command
						var old_position: Vector2 = model.position
						if dt > 0: model.position = Flow.swim(model.position,command,speed,model.clock,dt,layout.difficulty[mode].flow)
						guided_travel += old_position.distance_to(model.position)
						host.invulnerable = maxf(0,host.invulnerable-dt)
						# Deliberate old-warning mistake ensures recovery remains exercised even if idle is safe.
						if policy == "recovery" and frame == 8*120:
							var old_contact := Fixtures.prop("recovery-old-contact",model.position,8)
							old_contact.source_prop = "corn"
							old_contact.height = 0.0
							debris.items.append(old_contact)
						var prior_wave := debris.next_wave
						var began := Time.get_ticks_usec()
						debris.advance(model,host,dt)
						if debris.next_wave != prior_wave: planning_usec.append(Time.get_ticks_usec()-began)
						if debris.safety_failures > 0 or (policy.is_empty() and host.health != 100000):
							print("FAIL ",mode," speed",speed," seed",seed_value," time",model.clock,
								" cohort",debris.next_wave," damage",100000-host.health," position",model.position," details",debris.last_failure)
							if not policy.is_empty():
								for old in debris.items:
									if float(old.impact_at) > model.clock+0.000001: continue
									var gap: float = model.position.distance_to(old.pos)-float(old.radius)-14
									if gap < 15: print("OLD HAZARD ",old.id," pos",old.pos," impact",old.impact_at," radius",old.radius," gap",gap)
								var diagnostics := {}
								for option in range(9):
									var input := Vector2.ZERO if option == 8 else Vector2.from_angle(option*TAU/8)
									var proof := debris.safe_route(model.position,[],model.clock,model.position.angle(),input,speed)
									diagnostics[str(option)] = proof.safe
								print("BASELINE ONLY immediate-input diagnostics ",diagnostics)
							host.free()
							quit(1)
							return
						if not debris.ledger.is_empty() and debris.ledger[-1] != proof_entry:
							if policy == "recovery" and not proof_entry.is_empty() and proof_entry.admission == "recovery":
								if proof_health-host.health > int(proof_entry.projected_hits):
									push_error("Recovery replay exceeded projected damage")
									quit(1)
									return
							proof_entry = debris.ledger[-1]
							proof_health = host.health
							if proof_entry.admission == "recovery":
								if proof_entry.projected_hits > proof_entry.baseline_hits or proof_entry.projected_hits > proof_entry.paired_baseline_hits:
									push_error("Recovery introduces additional baseline damage")
									quit(1)
									return
						var expected := 0
						for wave in layout.difficulty[mode].waves:
							if model.clock+0.000001 >= float(wave.at) and model.clock < float(wave.at)+float(wave.duration)-0.000001:
								expected = int(wave.count)
						if debris.falling_count(model.clock) != expected:
							push_error("Incorrect full cohort occupancy")
							quit(1)
							return
						for item in debris.items:
							observed[item.prop] = true
							if model.project(item.impact_pos).y-float(item.height)-debris.prop_extent(item.source_prop) < 72-0.001:
								push_error("Prop starts behind HUD")
								quit(1)
								return
				if policy == "recovery" and not proof_entry.is_empty() and proof_entry.admission == "recovery":
					if proof_health-host.health > int(proof_entry.projected_hits):
						push_error("Final recovery replay exceeded projected damage")
						quit(1)
						return
				if policy == "recovery" and not debris.ledger.any(func(w: Dictionary) -> bool: return w.admission == "recovery"):
					push_error("Recovery fixture did not exercise recovery admission")
					quit(1)
					return
				if policy.is_empty() and not debris.ledger.any(func(w: Dictionary) -> bool: return w.reused_previous_route):
					push_error("Guided replay did not exercise fixed prior-route reuse")
					quit(1)
					return
				if debris.spawned != int(layout.difficulty[mode].total_spawn_count) or observed.size() != 9:
					push_error("Missing cohort or prop type")
					quit(1)
					return
				if policy.is_empty():
					var idle := idle_counterfactual(layout,mode,speed,debris.ledger)
					print("FIXED LEDGER ",mode," speed",speed," seed",seed_value," idle_damage",idle.damage,
						" guided_travel",snappedf(guided_travel,0.01)," idle_travel",snappedf(idle.travel,0.01),
						" guided_displacement",snappedf(model.position.distance_to(Vector2(0,259.2)),0.01),
						" idle_displacement",snappedf(idle.displacement,0.01),
						" endpoint_separation",snappedf(model.position.distance_to(idle.end),0.01))
				print("PASS REPLAY ",mode," speed",speed," seed",seed_value," spawned",debris.spawned," hz",hz," policy",policy," damage",100000-host.health)
				host.free()
	planning_usec.sort()
	if not planning_usec.is_empty():
		print("PLANNING waves=",planning_usec.size()," median_ms=",planning_usec[planning_usec.size()/2]/1000.0,
			" max_ms=",planning_usec[-1]/1000.0)
	print("PASS: policy coverage completed" if not policy.is_empty() else "PASS: full remaining-danger witnesses replayed through every persistent float without damage or exemptions")
	quit()
