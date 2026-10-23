extends SceneTree
const Boss = preload("res://scripts/clogfather_encounter.gd")
const HERO := Rect2(400,394,26,46)

func _initialize() -> void:
	call_deferred("run_checks")

func advance_to(boss: RefCounted, target: String, hero := HERO, hz := 120) -> void:
	for tick in range(hz*30):
		if boss.state == target: return
		boss.step(1.0/hz,hero)
	assert(false,"Unreachable state: "+target)

func run_checks() -> void:
	for hz in [60,120]:
		for damage in [12,18]:
			var boss = Boss.new()
			assert(boss.hp == 1080 and boss.max_hp == 1080)
			boss.start(HERO)
			assert(boss.state == "volley_warning" and boss.hazards.is_empty())
			boss.drain_events()
			boss.step(0.89,HERO)
			assert(boss.hazards.is_empty())
			advance_to(boss,"volley",HERO,hz)
			assert(boss.hazards.size() == 1)
			var aim: Vector2 = boss.snapshot().aim
			boss.step(0.5,Rect2(50,394,26,46))
			assert(boss.snapshot().aim == aim,"Volleys never retarget after their warning")
			assert(boss.hazards.size() == 2)
			advance_to(boss,"recovery",HERO,hz)
			assert(boss.hazards.is_empty() and boss.hurt_rects().is_empty())
			assert(boss.weak_point_rect() == Rect2(626,377,48,42) and boss.recovery_index == 1)
			var saved_hp: int = boss.hp
			assert(boss.hit(damage,"one-shot") == damage)
			assert(boss.hit(damage,"one-shot") == 0 and boss.hp == saved_hp-damage)
			boss.hit(400,"phase-crossing")
			assert(boss.phase == 1)
			boss.step(4.9,HERO)
			assert(boss.state == "recovery" and boss.phase == 1,"Threshold cannot truncate a window")
			boss.step(0.11,HERO)
			assert(boss.phase == 2 and boss.state == "pressure_warning")
			advance_to(boss,"acid_warning",HERO,hz)
			# Death bypasses every queued attack and emits only death, then one completion.
			advance_to(boss,"recovery",HERO,hz)
			boss.drain_events()
			boss.hit(10000,"lethal",true)
			assert(boss.hp == 0 and boss.state == "collapse")
			assert(boss.hazards.is_empty() and boss.warnings.is_empty() and boss.hurt_rects().is_empty())
			assert(boss.drain_events() == ["death_started"])
			boss.step(1.19,HERO)
			assert(not boss.exit_open)
			boss.step(0.02,HERO)
			assert(boss.exit_open and not boss.active and boss.drain_events() == ["boss_defeated"])
			boss.step(10,HERO)
			assert(boss.drain_events().is_empty())
			boss.reset(42)
			assert(boss.hp == 1080 and boss.phase == 1 and boss.state == "idle")
	for x in [0.0,80.0,300.0,500.0,674.0]:
		for seed_value in range(10):
			var hero := Rect2(x,394,26,46)
			var boss = Boss.new()
			boss.reset(seed_value)
			boss.start(hero)
			advance_to(boss,"recovery",hero)
			boss.step(5.01,hero)
			advance_to(boss,"acid_warning",hero)
			assert(boss.state == "acid_warning")
			assert(boss.warnings.size() == 2 and boss.safe_corridor.size.x == 180)
			var marked_hero := false
			for mark: Rect2 in boss.warnings:
				assert(not mark.intersects(boss.safe_corridor))
				assert(mark.position.x >= 0 and mark.end.x <= 700)
				if mark.intersects(hero): marked_hero = true
			assert(marked_hero,"A stationary corner hero cannot remain safe from every pattern")
			var safe_x: float = clampf(hero.position.x,boss.safe_corridor.position.x,boss.safe_corridor.end.x-hero.size.x)
			assert(absf(safe_x-x) <= 235*(1.2-0.15))
			assert(boss.warnings.size()*64 <= 700*0.35)
			var locked: Array = boss.warnings.duplicate()
			boss.step(0.2,Rect2(safe_x,394,26,46))
			assert(boss.warnings == locked)
			# Pause suppresses damage, hits and timers without discarding the active pattern.
			var time: float = boss.elapsed
			boss.step(10,hero,true)
			assert(boss.elapsed == time and boss.hurt_rects().is_empty() and boss.hit(100,"pause") == 0)
			boss.step(0,hero,false)
			advance_to(boss,"acid_fall",hero)
			advance_to(boss,"acid_puddle",hero)
			boss.step(0.01,hero)
			assert(not boss.hurt_rects().is_empty())
			advance_to(boss,"recovery",hero)
			assert(boss.hazards.is_empty() and boss.warnings.is_empty() and boss.hurt_rects().is_empty())
	var final_phase = Boss.new()
	final_phase.hp = 300
	final_phase.phase = 3
	final_phase.start(HERO)
	var fired := 0
	for tick in range(1200):
		final_phase.step(1.0/120,HERO)
		for event in final_phase.drain_events():
			if event == "projectile_spawn": fired += 1
		if final_phase.state == "recovery": break
	assert(fired == 4)
	final_phase.step(5.01,HERO)
	advance_to(final_phase,"acid_warning")
	assert(final_phase.state == "acid_warning" and final_phase.warnings.size() == 3)
	for damage in [12,18]:
		var boss = Boss.new()
		boss.start(HERO)
		var hits := 0
		var cooldown := 0.0
		var saw_acid := false
		for tick in range(120*120):
			boss.step(1.0/120,HERO)
			if boss.state == "acid_warning": saw_acid = true
			cooldown = maxf(0,cooldown-1.0/120)
			if boss.damageable() and cooldown <= 0:
				assert(boss.hit(damage,"shot-%d" % hits,true) > 0)
				hits += 1
				cooldown = 0.16 if damage == 12 else 0.24
			if boss.hp == 0: break
		assert(hits == (90 if damage == 12 else 60) and saw_acid)
	var paused = Boss.new()
	paused.start(HERO)
	for target in ["volley_warning","volley","approach","recovery","acid_warning","acid_fall","acid_puddle"]:
		advance_to(paused,target)
		var before: Dictionary = paused.snapshot()
		paused.step(10,HERO,true)
		assert(paused.elapsed == before.elapsed and paused.hazards == before.hazards)
		assert(paused.hurt_rects().is_empty() and paused.hit(100,"paused-"+target) == 0)
		paused.step(0,HERO,false)
		paused.step(1.0/120,HERO)
	# Same seed/input produces exactly the same warning positions and hazard state.
	var first = Boss.new()
	var second = Boss.new()
	first.reset(77)
	second.reset(77)
	first.start(HERO)
	second.start(HERO)
	for tick in range(2400):
		first.step(1.0/120,HERO)
		second.step(1.0/120,HERO)
		assert(first.snapshot() == second.snapshot())
	print("PASS: Clogfather60/120Hz, both starter damage, locked aim, full windows,50 acid/corner plans, pause, dedup, death/reset and determinism")
	quit()
