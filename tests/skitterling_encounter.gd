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
	check(boss.hp == 720 and boss.damage(9999) == 0, "Entry must be invulnerable")
	boss.step(1.999, HERO)
	check(boss.state == "entry_skitter", "Entry must last two seconds")
	boss.step(.001, HERO)
	check(boss.state == "rat_assembly", "Assembly must follow entry")
	boss.step(2.5, HERO)
	check(boss.state == "rat_ready", "Rat assembly must last 2.5 seconds")
	check(boss.damage(9999) == 540 and boss.hp == 180, "Rat overkill must clamp at phase floor")
	check(boss.damage(9999) == 0, "Repeated hit must not skip alligator")
	check(boss.state == "rat_collapse" and not boss.exit_open, "Rat death cannot open exit")
	var before: Dictionary = boss.snapshot()
	boss.step(10, HERO, true)
	check(boss.elapsed == before.elapsed and boss.hurt_regions().is_empty(), "Freeze must stop timers and hits")
	check(boss.damage(10) == 0, "Frozen encounter must ignore damage")
	boss.step(4.5, HERO)
	check(boss.state == "reskitter", "False death must last 4.5 seconds")
	boss.step(4.5, HERO)
	check(boss.state == "alligator_assembly", "Skitter must last another 4.5 seconds")
	boss.step(2.5, HERO)
	check(boss.state == "alligator_ready" and boss.hp == 180, "Alligator must fight remaining HP")
	boss.drain_events()
	check(boss.damage(9999) == 180 and boss.hp == 0, "Alligator defeat must consume last phase")
	check(boss.damage(1) == 0, "Terminal damage must latch")
	check(boss.drain_events().count("terminal_death") == 1, "Death audio must emit once")
	boss.step(1.199, HERO)
	check(not boss.exit_open, "Death presentation must precede exit")
	boss.step(.001, HERO)
	check(boss.exit_open and not boss.active, "Final death must open exit")
	boss.reset()
	check(boss.hp == 720 and boss.state == "idle" and not boss.exit_open, "Reset must rebuild encounter")
	check(boss.hazards.is_empty() and boss.drain_events().is_empty(), "Reset must clear hazards/events")

	# Real damage cadence must produce both required form budgets for each hero.
	for damage in [12, 18, 24, 8]:
		boss = fresh()
		advance_to(boss, "rat_ready")
		var hits := 0
		while boss.state == "rat_ready":
			boss.damage(damage)
			hits += 1
		check(hits == ceili(540.0/damage), "Rat hit accounting")
		advance_to(boss, "alligator_ready")
		while boss.state == "alligator_ready":
			boss.damage(damage)
			hits += 1
		check(hits == ceili(540.0/damage)+ceili(180.0/damage), "Combined guarded hit accounting")

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
	boss.step(.6, HERO)
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
			check(boss.state == "rat_pipe_retreat", "Corner must skip unsafe bite")
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
			for tick in range(2400):
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
	for required in ["rat_bite_tell", "rat_bite", "rat_pipe_launch", "alligator_charge_tell",
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
			boss.damage(540)
		advance_to(boss, form+"_assembly")
		intruder = Rect2(boss.position.x-14, 394, 26, 46)
		var fixed_anchor: Vector2 = boss.position
		boss.step(3.5, intruder)
		check(boss.state == form+"_assembly" and is_equal_approx(boss.elapsed, 2.5),
			"Occupied assembly holds after exact 2.5-second presentation")
		check(boss.position == fixed_anchor and boss.damage(999) == 0 and boss.hurt_regions().is_empty(),
			"Assembly hold cannot teleport, hurt or accept damage")
		boss.step(.01, HERO)
		check(boss.state == form+"_ready", "Clear assembly proceeds to harmless ready interval")

	boss = fresh()
	advance_to(boss, "rat_ready")
	boss.damage(540)
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
	if failures == 0: print("PASS: Skitterling 540/180 HP, sequence/reset/freeze, three swim/upthrows, stationary hits, moving dodges and jumpable charges")
	quit(1 if failures else 0)

func combat_revision_checks() -> void:
	for speed in [270.0, 235.0]:
		for mode in ["easy", "normal", "hard"]:
			# Modes intentionally share this authored fight; seeds vary but combat rules do not.
			for hero_x in [32.0, 120.0, 450.0, 814.0, 900.0]:
				var hero := Rect2(hero_x, 394, 26, 46)
				for dodge in [false, true]:
					var boss := fresh(hero)
					advance_to(boss, "rat_ready", hero)
					boss.damage(9999)
					advance_to(boss, "alligator_ready", hero)
					var release_count := 0
					var upward_hits: Dictionary = {}
					var saw_swim := false
					var dodge_target := hero.position.x
					var previous_state := ""
					var ticks := 7200
					boss.drain_events()
					while boss.state != "alligator_surface_recovery" and ticks > 0:
						if boss.state == "alligator_water_warning" and previous_state != boss.state:
							dodge_target = clampf(hero.position.x+(80 if hero.position.x < 480 else -80), 32, 900)
						if dodge and boss.state in ["alligator_water_warning", "alligator_debris"]:
							hero.position.x = move_toward(hero.position.x, dodge_target, speed/120)
						previous_state = boss.state
						var before: Vector2 = boss.position
						if boss.state in ["alligator_swim", "alligator_surface_swim"]:
							saw_swim = true
							check(boss.damage(12) == 0, "Submerged swimmer invulnerable")
						boss.step(1.0/120, hero)
						if previous_state in ["alligator_swim", "alligator_surface_swim"]:
							check(absf(boss.position.x-before.x) <= Encounter.SWIM_SPEED/120+.001, "Swimming cannot teleport")
						var events: Array[String] = boss.drain_events()
						release_count += events.count("debris_release")
						check(boss.hazards.size() <= 1, "One live projectile")
						for rock in boss.hazards:
							check(rock.position.y >= 149.9, "Projectile must stay below HUD")
							check(is_equal_approx(rock.position.x, boss.column_x), "Committed throw cannot home")
							if not rock.descending:
								for hurt in boss.hurt_regions():
									if hurt.intersects(hero): upward_hits[int(rock.id)] = true
						ticks -= 1
					check(ticks > 0 and saw_swim and release_count == 3, mode+" swim/pause/three throws/surface")
					check(boss.throw_origins.size() == 3, "Three recorded distinct origins")
					for index in range(3):
						for other in range(index):
							check(absf(boss.throw_origins[index]-boss.throw_origins[other]) >= 2, "Distinct origins")
					check(upward_hits.size() == (0 if dodge else 3), "Stationary gets all three upward hits; moving dodges")
					check(boss.hazards.is_empty(), "Clear all rocks before emergence")
					advance_to(boss, "alligator_charge_tell", hero)
					check(boss.damageable(), "Charge tell is vulnerable")
					boss.step(.89, hero)
					check(boss.state == "alligator_charge_tell", "Charge gets full warning")
					advance_to(boss, "alligator_charge", hero)
					var start_x: float = boss.position.x
					advance_to(boss, "alligator_charge_turn", hero)
					check(absf(boss.position.x-start_x) > 500, "Charge must cross room, not a short lunge")
					boss.step(.89, hero)
					check(boss.state == "alligator_charge_turn", "Reversal needs full tell")
					advance_to(boss, "alligator_jaw_recovery", hero)
					advance_to(boss, "alligator_water_dive", hero)
					check(boss.throw_origins.is_empty(), "New cycle clears throw history")
					boss.reset()
					check(boss.hp == 720 and boss.hazards.is_empty() and boss.throw_origins.is_empty(), "Cleanup")

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
			check(absf(boss.column_x-hero.get_center().x) <= 14.1, "Commit must be beneath current hero footprint")
			var committed: float = boss.column_x
			var origin: Vector2 = boss.position
			hero.position.x = 814 if hero.position.x < 450 else 120
			boss.step(.79, hero)
			check(boss.position == origin and boss.column_x == committed,
				"Warning must hold position despite new hero location")
			boss.step(.02, hero)
			check(boss.state == "alligator_debris" and boss.column_x == committed,
				"Release must retain committed column")
