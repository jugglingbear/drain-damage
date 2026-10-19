extends SceneTree
const Encounter = preload("res://scripts/skitterling_encounter.gd")
const HERO := Rect2(96, 394, 26, 46)
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func advance_to(boss: RefCounted, target: String, hero := HERO, limit := 30.0) -> void:
	var ticks := ceili(limit*120)
	while boss.state != target and ticks > 0:
		boss.step(1.0/120, hero)
		ticks -= 1
	check(boss.state == target, "Failed to reach "+target+" from "+boss.state)

func fresh(hero := HERO) -> RefCounted:
	var boss := Encounter.new()
	boss.configure(73)
	boss.start(hero)
	return boss

func run_checks() -> void:
	var room: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/skitterling-room/manifest-v1.json"))
	var port_index := 0
	for prop in room.instances:
		if not prop.has("mouth_center"): continue
		var center: Array = prop.mouth_center
		check(Encounter.PORTS[port_index] == Vector2(center[0], center[1]),
			"Controller port must match visible pipe mouth "+str(prop.id))
		port_index += 1
	check(port_index == 4, "Four authored attack ports required")
	var boss := fresh()
	check(boss.hp == 1440 and boss.damage(9999) == 0, "Entry must be invulnerable")
	boss.step(.999, HERO)
	check(boss.state == "entry_skitter", "Entry must last one second")
	boss.step(.001, HERO)
	check(boss.state == "rat_assembly", "Assembly must follow entry")
	boss.step(1.4, HERO)
	check(boss.state == "rat_ready", "Rat assembly must last1.4 seconds")
	check(boss.damage(9999) == 900 and boss.hp == 540, "Rat overkill must clamp at phase floor")
	check(boss.damage(9999) == 0, "Repeated hit must not skip alligator")
	check(boss.state == "rat_collapse" and not boss.exit_open, "Rat death cannot open exit")
	var before: Dictionary = boss.snapshot()
	boss.step(10, HERO, true)
	check(boss.elapsed == before.elapsed and boss.hurt_regions().is_empty(), "Freeze must stop timers and hits")
	check(boss.damage(10) == 0, "Frozen encounter must ignore damage")
	boss.step(1.6, HERO)
	check(boss.state == "reskitter", "False death must last1.6 seconds")
	boss.step(1.2, HERO)
	check(boss.state == "alligator_assembly", "Skitter must last1.2 seconds")
	boss.step(1.4, HERO)
	check(boss.state == "alligator_ready" and boss.hp == 540, "Alligator must fight remaining HP")
	boss.drain_events()
	check(boss.damage(9999) == 540 and boss.hp == 0, "Alligator defeat must consume last phase")
	check(boss.damage(1) == 0, "Terminal damage must latch")
	check(boss.drain_events().count("terminal_death") == 1, "Death audio must emit once")
	boss.step(1.199, HERO)
	check(not boss.exit_open, "Death presentation must precede exit")
	boss.step(.001, HERO)
	check(boss.exit_open and not boss.active, "Final death must open exit")
	boss.reset()
	check(boss.hp == 1440 and boss.state == "idle" and not boss.exit_open, "Reset must rebuild encounter")
	check(boss.hazards.is_empty() and boss.drain_events().is_empty(), "Reset must clear hazards/events")

	# Real damage cadence must produce both required form budgets for each hero.
	for damage in [12, 18, 24, 8]:
		boss = fresh()
		advance_to(boss, "rat_ready")
		var hits := 0
		while boss.state == "rat_ready":
			boss.damage(damage)
			hits += 1
		check(hits == ceili(900.0/damage), "Rat hit accounting")
		advance_to(boss, "alligator_ready")
		while boss.state == "alligator_ready":
			boss.damage(damage)
			hits += 1
		check(hits == ceili(900.0/damage)+ceili(540.0/damage), "Combined guarded hit accounting")

	# Same seed and retry select the same pipe, lock landing and honor the full warning.
	boss = fresh()
	advance_to(boss, "rat_pipe_warning")
	var selected: int = boss.port
	var landing: Vector2 = boss.landing
	check(boss.damage(12) == 0, "Hidden rat must ignore hits")
	boss.step(1.99, Rect2(800, 394, 26, 46))
	check(boss.state == "rat_pipe_warning" and boss.landing == landing, "No warning retarget/shortening")
	boss.step(.01, HERO)
	check(boss.state == "rat_pipe_launch", "Full pipe warning")
	boss.step(1.1, HERO)
	check(boss.state == "rat_landing_recovery" and boss.position == landing, "Actual grounded landing")
	check(is_equal_approx(boss.position.y, 440), "Landing recovery must start on floor")
	boss.reset()
	boss.start(HERO)
	advance_to(boss, "rat_pipe_warning")
	check(boss.port == selected and boss.landing == landing, "Checkpoint retry must preserve seeded plan")

	# Corners and overlap skip jaw attacks rather than trapping the hero.
	for x in [32.0, 96.0, 450.0, 836.0, 900.0]:
		var hero := Rect2(x, 394, 26, 46)
		boss = fresh(hero)
		advance_to(boss, "rat_ready", hero)
		check(not boss.body_rect().intersects(hero), "Initial formation must avoid hero")
		boss.step(.6, hero)
		if x < 212 or x > 720:
			check(boss.state in ["rat_wall_approach", "rat_wall_climb"], "Corner must receive primary wall attack")
		boss = fresh(hero)
		advance_to(boss, "rat_ready", hero)
		boss.damage(999)
		advance_to(boss, "alligator_ready", hero)
		check(not boss.body_rect().intersects(hero), "Alligator formation must avoid hero")
		# Ground-level shots can intersect the supplied body bounds in both forms.
		check(boss.body_rect().has_point(Vector2(boss.position.x, 410)), "Standing shot accessibility")

	combat_revision_checks()
	charge_jump_checks()
	swim_tracking_checks()
	rat_attack_checks()
	tail_sweep_checks()
	airborne_collapse_checks()
	pipe_dodge_checks()
	random_volley_escape_checks()
	# Exercise every reachable combat state and freeze it, with both safe and corner hero positions.
	var visited: Dictionary = {}
	for x in [96.0, 450.0, 836.0]:
		var hero := Rect2(x, 394, 26, 46)
		boss = fresh(hero)
		for form in ["rat", "alligator"]:
			if form == "alligator":
				advance_to(boss, "rat_landing_recovery", hero)
				boss.damage(999)
				advance_to(boss, "alligator_ready", hero)
			for tick in range(6000):
				boss.step(1.0/120, hero)
				visited[boss.state] = true
				var saved: Dictionary = boss.snapshot()
				boss.step(.5, hero, true)
				check(boss.elapsed == saved.elapsed and boss.position == saved.position,
					"Freeze must preserve movement in "+boss.state)
				check(boss.hazards == saved.hazards and boss.hurt_regions().is_empty(),
					"Freeze must preserve debris without hurting hero")
				check(boss.damage(999) == 0, "Freeze rejects damage in "+boss.state)
				boss.step(.000001, hero, false)
	for required in ["rat_pounce_tell", "rat_pounce", "rat_pipe_launch", "alligator_charge_tell",
		"alligator_charge", "alligator_debris", "alligator_surface_recovery"]:
		check(visited.has(required), "Unexercised attack state "+required)
	# Occupancy changes after a warning must never cause damaging appearance under the hero.
	boss = fresh()
	advance_to(boss, "rat_pipe_warning")
	var old_landing: Vector2 = boss.landing
	var intruder := Rect2(old_landing.x+120, 394, 26, 46)
	boss.step(2.0, intruder)
	check(boss.state == "rat_pipe_warning" and boss.landing != old_landing,
		"Occupied full landing footprint must reselect before launch")
	check(is_zero_approx(boss.elapsed) and boss.hurt_regions().is_empty(), "Reselection restarts harmless warning")
	boss.step(1.999, intruder)
	check(boss.state == "rat_pipe_warning", "Replacement landing gets full two-second warning")
	boss.step(.001, intruder)
	check(boss.state == "rat_pipe_launch", "Safe replacement launch")
	var locked_landing: Vector2 = boss.landing
	boss.step(.1, intruder)
	intruder = Rect2(locked_landing.x-14, 394, 26, 46)
	boss.drain_events()
	boss.step(.01, intruder)
	check(boss.state == "rat_pipe_abort" and boss.hurt_regions().is_empty(), "Late intrusion aborts harmlessly")
	check(boss.damage(12) == 0 and boss.landing == locked_landing, "Return cannot retarget or accept damage")
	boss.step(.6, intruder)
	check(boss.state == "rat_inside_pipe", "Aborted launch returns inside pipe")
	check(not boss.drain_events().has("pipe_land"), "Abort must not emit a successful landing")
	advance_to(boss, "rat_pipe_warning", intruder)
	check(boss.landing != locked_landing, "Post-abort plan reselects with new warning")

	for form in ["rat", "alligator"]:
		boss = fresh()
		if form == "alligator":
			advance_to(boss, "rat_ready")
			boss.damage(900)
		advance_to(boss, form+"_assembly")
		intruder = Rect2(boss.position.x-14, 394, 26, 46)
		var fixed_anchor: Vector2 = boss.position
		boss.step(1.4, intruder)
		check(boss.state == form+"_ready", "Occupied assembly must finish exactly on time")
		check(boss.position == fixed_anchor and boss.hurt_regions().is_empty(),
			"Harmless nonblocking formation cannot push, teleport or hurt hero")
		boss.step(.6, intruder)
		check(boss.state != form+"_ready", "Standing inside formation cannot stall fight")

	boss = fresh()
	advance_to(boss, "rat_ready")
	boss.damage(900)
	advance_to(boss, "alligator_surface_warning")
	old_landing = boss.landing
	intruder = Rect2(old_landing.x+140, 394, 26, 46)
	boss.step(1.0, intruder)
	check(boss.state == "alligator_surface_swim" and boss.landing != old_landing,
		"Occupied surface footprint must reselect")
	advance_to(boss, "alligator_surface_warning", intruder)
	boss.step(.999, intruder)
	check(boss.state == "alligator_surface_warning", "Replacement surface gets full warning")
	boss.step(.001, intruder)
	check(boss.state == "alligator_surface", "Clear surface begins rising")
	boss.step(.1, intruder)
	intruder = Rect2(boss.landing.x-14, 394, 26, 46)
	boss.step(.01, intruder)
	check(boss.state == "alligator_surface_return" and boss.damage(12) == 0,
		"Late surface intrusion returns underwater harmlessly")
	check(boss.hurt_regions().is_empty(), "Surface return cannot hurt hero")
	boss.step(.6, intruder)
	check(boss.state == "alligator_surface_swim", "Returned gator must swim before warning again")
	if failures == 0: print("PASS: Skitterling wall pounce/rush/tail, room-wide stationary punishment, dodges/jumps, prior phases/reset/freeze/swim/charges")
	quit(1 if failures else 0)

func combat_revision_checks() -> void:
	for speed in [270.0, 235.0]:
		for x in [120.0, 450.0, 814.0]:
			for dodge in [false, true]:
				var hero := Rect2(x, 394, 26, 46)
				var boss := fresh(hero)
				advance_to(boss, "rat_ready", hero)
				boss.damage(9999)
				advance_to(boss, "alligator_water_warning", hero)
				var targets: Array = boss.volley_targets.duplicate()
				check(is_equal_approx(targets[2], hero.get_center().x), "Aimed arc locks current hero at warning")
				check(absf(targets[2]-boss.column_x) > 1, "Aimed shot must have horizontal arc")
				var time := 0.0
				var release_times: Array[float] = []
				var max_live := 0
				var hit := false
				var aimed_hit := false
				var landed: Dictionary = {}
				var direction := 1 if x < 200 else -1
				var dodge_x := clampf(x+direction*180, 120, 814)
				boss.drain_events()
				while boss.state in ["alligator_water_warning", "alligator_debris"] and time < 5:
					if dodge and time >= .2:
						hero.position.x = move_toward(hero.position.x, dodge_x, speed/120)
					boss.step(1.0/120, hero)
					time += 1.0/120
					check(boss.volley_targets == targets, "No retarget after warning")
					if boss.drain_events().has("debris_release"): release_times.append(time)
					max_live = maxi(max_live, boss.hazards.size())
					for hurt in boss.hurt_regions():
						if hurt.intersects(hero): hit = true
					for rock in boss.hazards:
						check(rock.position.y >= 149, "Volley stays below HUD")
						if rock.id == 1: check(is_zero_approx(rock.vx), "First shot vertical")
						if rock.id == 3 and rock.descending:
							if Rect2(rock.position-Vector2(14,14),Vector2(28,28)).intersects(hero): aimed_hit = true
						if rock.age > 1.58:
							check(absf(rock.position.x-float(rock.target_x)) <= absf(float(rock.vx))*.02+.01,
								"Arc must reach committed floor landing")
							landed[rock.id] = true
				check(release_times.size() == 3 and max_live == 3 and landed.size() == 3, "Three overlapping complete shots")
				check(absf(release_times[2]-release_times[0]-.44) < .02, "Rapid volley spans .44 seconds")
				check(not hit if dodge else aimed_hit, "Moving hero dodges; stationary hero takes aimed landing "+str([speed,x,dodge]))
				check(boss.hazards.is_empty(), "Wait for all three before surface")
				advance_to(boss, "alligator_surface_recovery", hero)
				check(boss.damageable(), "Surface recovery remains vulnerable")
				boss.reset()
				check(boss.hp == 1440 and boss.volley_targets.is_empty(), "Reset clears volley and HP")
	# Random trajectory is reproducible for a checkpoint retry, not redrawn every frame.
	var boss := fresh()
	advance_to(boss, "rat_ready")
	boss.damage(9999)
	advance_to(boss, "alligator_water_warning")
	var first: Array = boss.volley_targets.duplicate()
	boss.reset()
	boss.start(HERO)
	advance_to(boss, "rat_ready")
	boss.damage(9999)
	advance_to(boss, "alligator_water_warning")
	check(boss.volley_targets == first, "Seeded random arc must repeat on reset")

func charge_jump_checks() -> void:
	for x in [120.0, 450.0, 814.0]:
		for jumping in [false, true]:
			var hero := Rect2(x, 394, 26, 46)
			var boss := fresh(hero)
			advance_to(boss, "rat_ready", hero)
			boss.damage(9999)
			advance_to(boss, "alligator_charge", hero, 60)
			var jumped := false
			var velocity := 0.0
			var touched := false
			while boss.state == "alligator_charge":
				var leading: float = boss.position.x+boss.facing*144
				var gap: float = hero.position.x-leading if boss.facing > 0 else leading-hero.end.x
				if jumping and not jumped and gap <= 85:
					jumped = true
					velocity = -465
				if jumped:
					velocity += 1250.0/120
					hero.position.y = minf(394, hero.position.y+velocity/120)
				boss.step(1.0/120, hero)
				for hurt in boss.hurt_regions():
					if hurt.intersects(hero): touched = true
			check(touched != jumping, "Stationary charge must hit; timed standard jump must clear jaws at "+str(x))

func swim_tracking_checks() -> void:
	for speed in [270.0, 235.0]:
		for direction in [-1, 1]:
			var hero := Rect2(450, 394, 26, 46)
			var boss := fresh(hero)
			advance_to(boss, "rat_ready", hero)
			boss.damage(9999)
			advance_to(boss, "alligator_swim", hero)
			var heading: int = direction
			var ticks := 2400
			var changed_target := false
			var initial_target: float = boss.swim_target
			while boss.state == "alligator_swim" and ticks > 0:
				hero.position.x += heading*speed/120
				if hero.position.x <= 120 or hero.position.x >= 814:
					hero.position.x = clampf(hero.position.x, 120, 814)
					heading *= -1
				var previous: Vector2 = boss.position
				boss.step(1.0/120, hero)
				check(absf(boss.position.x-previous.x) <= Encounter.SWIM_SPEED/120+.001,
					"Tracking must remain continuous")
				changed_target = changed_target or not is_equal_approx(boss.swim_target, initial_target)
				ticks -= 1
			check(ticks > 0 and changed_target and boss.state == "alligator_water_warning",
				"Swimmer must reacquire and catch a moving hero before committing")
			check(absf(boss.column_x-hero.get_center().x) <= 80.1, "Commit must remain near hero with space for an actual arc")
			var committed: float = boss.column_x
			var origin: Vector2 = boss.position
			hero.position.x = 814 if hero.position.x < 450 else 120
			boss.step(.79, hero)
			check(boss.position == origin and boss.column_x == committed,
				"Warning must hold position despite new hero location")
			boss.step(.02, hero)
			check(boss.state == "alligator_debris" and boss.column_x == committed,
				"Release must retain committed column")

func rat_attack_checks() -> void:
	# Sample the entire legal standing interval, including exact wall positions, for multiple cycles.
	for x in range(120, 815, 20):
		passive_rat_checks(float(x))
	passive_rat_checks(814)
	for speed in [270.0, 235.0]:
		for x in [120.0, 450.0, 814.0]:
			var hero := Rect2(x, 394, 26, 46)
			var boss := fresh(hero)
			advance_to(boss, "rat_pounce_tell", hero)
			var committed: Vector2 = boss.attack_target
			boss.step(.999, hero)
			check(boss.state == "rat_pounce_tell", "Full one-second pounce warning")
			advance_to(boss, "rat_pounce", hero)
			var destination := clampf(hero.position.x+(210 if x < 480 else -210), 120, 814)
			var touched := false
			while boss.state == "rat_pounce":
				hero.position.x = move_toward(hero.position.x, destination, speed/120)
				boss.step(1.0/120, hero)
				check(boss.attack_target == committed, "Pounce must not home after commitment")
				for hurt in boss.hurt_regions():
					if hurt.intersects(hero): touched = true
			check(not touched, "Both heroes can run under committed pounce from corners/center")
			check(boss.state == "rat_pounce_recovery" and boss.damageable(), "Pounce recovery is shooting window")
			advance_to(boss, "rat_rush_tell", hero)
			boss.step(.799, hero)
			check(boss.state == "rat_rush_tell", "Full rush warning")
			advance_to(boss, "rat_rush", hero)
			var jumped := false
			var velocity := 0.0
			touched = false
			while boss.state == "rat_rush":
				var leading: float = boss.position.x+boss.facing*128
				var gap: float = hero.position.x-leading if boss.facing > 0 else leading-hero.end.x
				if not jumped and gap <= 85:
					jumped = true
					velocity = -465
				if jumped:
					velocity += 1250.0/120
					hero.position.y = minf(394, hero.position.y+velocity/120)
				var previous_speed: float = boss.snapshot().rush_speed
				boss.step(1.0/120, hero)
				check(boss.snapshot().rush_speed >= previous_speed, "Rush visibly accelerates")
				for hurt in boss.hurt_regions():
					if hurt.intersects(hero): touched = true
			check(jumped and not touched, "Standard jump clears rushing bite")

func passive_rat_checks(x: float) -> void:
	var hero := Rect2(x, 394, 26, 46)
	var boss := fresh(hero)
	var hits := 0
	var pounces := 0
	var rushes := 0
	var pipes := 0
	var previous_state := ""
	var cooldown := 0.0
	for tick in range(120*60):
		boss.step(1.0/120, hero)
		if boss.state != previous_state:
			if boss.state == "rat_pounce": pounces += 1
			if boss.state == "rat_rush": rushes += 1
			if boss.state == "rat_pipe_launch": pipes += 1
		previous_state = boss.state
		cooldown = maxf(0, cooldown-1.0/120)
		if cooldown <= 0:
			for hurt in boss.hurt_regions():
				if hurt.intersects(hero):
					hits += 1
					cooldown = 1.5
					break
	check(hits >= 5, "No passive rat safe spot at x="+str(x))
	check(pounces >= 4 and rushes >= 2 and pipes >= 1 and pounces > pipes,
		"Primary pounce/rush with secondary pipes across repeated cycles")

func tail_sweep_checks() -> void:
	for jumping in [false, true]:
		var hero := Rect2(450, 394, 26, 46)
		var boss := fresh(hero)
		advance_to(boss, "rat_ready", hero)
		boss.damage(9999)
		advance_to(boss, "alligator_jaw_recovery", hero, 60)
		# Stand behind the final charge facing, inside the actual rear silhouette.
		hero.position.x = boss.position.x-boss.facing*100-13
		advance_to(boss, "alligator_tail_tell", hero)
		boss.step(.999, hero)
		check(boss.state == "alligator_tail_tell" and boss.hurt_regions().is_empty(), "Full harmless tail warning")
		var elapsed_jump := .2 if jumping else 0.0
		var touched := false
		for tick in range(44):
			if jumping:
				elapsed_jump += 1.0/120
				hero.position.y = minf(394, 394-465*elapsed_jump+625*elapsed_jump*elapsed_jump)
			boss.step(1.0/120, hero)
			for hurt in boss.hurt_regions():
				if hurt.intersects(hero): touched = true
		check(touched != jumping, "Tail hits stationary rear hero but is jumpable")
		check(boss.state == "alligator_tail_recovery" and boss.damageable(), "Tail has vulnerable recovery")

func airborne_collapse_checks() -> void:
	for attack in ["rat_wall_climb", "rat_pounce"]:
		var boss := fresh()
		advance_to(boss, attack)
		boss.step(.2, HERO)
		var before: Vector2 = boss.position
		check(before.y < 440, "Test must kill airborne rat")
		boss.damage(9999)
		check(boss.state == "rat_collapse" and boss.position == before, "Airborne collapse cannot teleport")
		boss.step(.4, HERO)
		check(boss.position.y == 440 and boss.hurt_regions().is_empty(), "Collapsed roaches fall harmlessly to floor")
		boss.step(1.2, HERO)
		check(boss.state == "reskitter", "Airborne death preserves1.6s phase timing")

func pipe_dodge_checks() -> void:
	for speed in [270.0, 235.0]:
		for seed_value in range(12):
			for x in [120.0, 450.0, 814.0]:
				var found_escape := false
				for destination in [120.0, 450.0, 814.0]:
					var hero := Rect2(x,394,26,46)
					var boss := fresh(hero)
					boss.configure(seed_value)
					boss.start(hero)
					advance_to(boss,"rat_ready",hero)
					boss._enter("rat_pipe_warning")
					var touched := false
					for tick in range(120*4):
						# React after300ms to the already-visible two-second pipe warning.
						if tick >= 36: hero.position.x = move_toward(hero.position.x,destination,speed/120)
						boss.step(1.0/120,hero)
						for hurt in boss.hurt_regions():
							if hurt.intersects(hero): touched = true
					found_escape = found_escape or not touched
				check(found_escape,"Pipe warning/slow flight must permit an escape for both heroes")
	check(is_equal_approx(Encounter.DURATIONS.rat_pipe_launch,1.1),"Pipe flight slowed from.6 to1.1s")

func random_volley_escape_checks() -> void:
	for seed_value in range(12):
		for speed in [270.0,235.0]:
			for x in [120.0,450.0,814.0]:
				var escaped := false
				for destination in [120.0,270.0,450.0,630.0,814.0]:
					var hero := Rect2(x,394,26,46)
					var boss := fresh(hero)
					boss.configure(seed_value)
					boss.start(hero)
					advance_to(boss,"rat_ready",hero)
					boss.damage(9999)
					advance_to(boss,"alligator_water_warning",hero)
					var touched := false
					for tick in range(360):
						if tick >= 24: hero.position.x=move_toward(hero.position.x,destination,speed/120)
						boss.step(1.0/120,hero)
						for hurt in boss.hurt_regions():
							if hurt.intersects(hero): touched=true
					escaped=escaped or not touched
				check(escaped,"Random volley must leave a reachable route: "+str([seed_value,speed,x]))
