extends SceneTree
const Boss = preload("res://scripts/clogfather_encounter.gd")

func _initialize() -> void: call_deferred("run_checks")

func advance_to(boss: RefCounted, target: String, hero: Rect2, dt: float) -> void:
	for tick in range(int(40/dt)):
		if boss.state == target: return
		boss.step(dt,hero)
	assert(false,"Unreachable state: "+target)

func check_pressure(boss: RefCounted, hero: Rect2, dt: float, wave: int) -> void:
	assert(boss.state == "pressure_warning" and not boss.damageable())
	assert(boss.pressure_wave == wave)
	var kind := "gas" if wave % 2 == 1 else "reinforcements"
	assert(boss.pressure_kind == kind)
	var surviving_gas: Array = boss.gas_targets().map(func(g: Dictionary) -> String: return g.id)
	var lane: Rect2 = boss.safe_corridor
	assert(lane.size.x == 180 and lane.position.x >= 80 and lane.end.x <= 700)
	var destination := clampf(hero.position.x,lane.position.x,lane.end.x-hero.size.x)
	assert(absf(destination-hero.position.x) <= 235*(boss.PRESSURE_WARNING-0.15))
	for mark in boss.warnings: assert(not mark.intersects(lane))
	var before: Dictionary = boss.snapshot()
	boss.step(2,hero,true)
	assert(boss.elapsed == before.elapsed and boss.hazards == before.hazards)
	assert(boss.reinforcement_requests == before.reinforcement_requests and boss.hurt_rects().is_empty())
	boss.step(0,hero,false)
	assert(boss.hit(9999,"closed-%d" % wave,true) == 0)
	var events: Array = boss.drain_events()
	assert(events.count("gas_warning" if kind == "gas" else "reinforcements_warning") == 1)
	advance_to(boss,"pressure_active",hero,dt)
	events = boss.drain_events()
	assert(events.count("gas_started" if kind == "gas" else "reinforcements_spawn") == 1)
	var requests: Array = boss.reinforcement_requests.duplicate(true)
	before = boss.snapshot()
	boss.step(3,hero,true)
	assert(boss.elapsed == before.elapsed and boss.hazards == before.hazards)
	assert(boss.reinforcement_requests == requests and boss.hurt_rects().is_empty())
	boss.step(0,hero,false)
	if kind == "reinforcements":
		assert(requests.size() == 2)
		var ids: Dictionary = {}
		for request in requests:
			assert(not ids.has(request.id) and request.hp == 24)
			ids[request.id] = true
			var bounds: Rect2 = request.bounds
			assert(bounds.position.x >= 80 and bounds.end.x <= 700 and bounds.end.y == 440)
			assert(bounds.grow(-48).has_point(request.center))
			var low_center := Vector2(request.center.x,bounds.end.y-48-0.01)
			var grounded_hero := Rect2(request.center.x-13,394,26,46)
			assert(Rect2(low_center-Vector2(48,48),Vector2(96,96)).intersects(grounded_hero),
				"Reinforcements must be able to threaten a grounded hero")
			assert(not bounds.intersects(lane))
	else:
		assert(requests.is_empty() and boss.gas_targets().size() == surviving_gas.size()+1)
	var first_rect := Rect2()
	var last_rect := Rect2()
	var active_ticks := 0
	while boss.state == "pressure_active" and active_ticks < int(5/dt):
		boss.step(dt,hero)
		active_ticks += 1
		for hazard in boss.hazards:
			if hazard.kind != "gas": continue
			assert(hazard.kind == "gas" and hazard.rect.size == Vector2(100,64))
			assert(hazard.rect.position.x >= 80 and hazard.rect.end.x <= 700)
			if not surviving_gas.has(hazard.id):
				assert(not hazard.rect.grow(20).intersects(lane),"New gas must avoid its warned safe lane")
			assert(absf(hazard.velocity.x) == 30 and hazard.velocity.y == 0)
			if not surviving_gas.has(hazard.id):
				if not first_rect.has_area(): first_rect = hazard.rect
				last_rect = hazard.rect
		if boss.state == "pressure_active":
			assert(boss.reinforcement_requests == requests,"No mid-wave refill")
	assert(boss.state == "acid_warning")
	assert(absf(active_ticks*dt-(2.0-boss.acid_warning_seconds())) <= dt*2)
	assert(boss.gas_targets().size() == surviving_gas.size()+(1 if kind == "gas" else 0))
	for id in surviving_gas:
		assert(boss.gas_targets().any(func(g: Dictionary) -> bool: return g.id == id))
	assert(boss.reinforcement_requests.is_empty())
	assert(boss.drain_events().count("pressure_cleared") == 1)
	boss.step(boss.acid_warning_seconds(),hero)
	assert(boss.state == "acid_fall")

func run_checks() -> void:
	create_timer(45).timeout.connect(func() -> void: quit(1))
	for hz in [60,120]:
		var dt: float = 1.0/hz
		for x in [80.0,300.0,674.0]:
			var hero := Rect2(x,394,26,46)
			var boss = Boss.new()
			assert(boss.max_hp == 1080)
			boss.start(hero)
			for wave in range(1,9):
				advance_to(boss,"recovery",hero,dt)
				assert(boss.recovery_index == wave)
				assert(boss.gas_targets().size() == int((boss.pressure_wave+1)/2),"Unkilled gas survives recovery")
				assert(boss.pressure_kind == "" and boss.reinforcement_requests.is_empty())
				assert(boss.snapshot().weak_point_level == ("low" if wave % 2 else "high"))
				if wave in [3,5]: assert(boss.hit(400,"phase-%d" % wave,true) == 400)
				var phase: int = boss.phase
				boss.step(4.8,hero)
				assert(boss.state == "recovery" and boss.phase == phase,"Preserve useful full damage window")
				boss.step(0.21,hero)
				if wave % 2 == 1:
					check_pressure(boss,hero,dt,int((wave+1)/2))
				else:
					assert(boss.state == "volley_warning","Interleave warned gun groups between pressure waves")
			assert(boss.phase == 3)
			advance_to(boss,"recovery",hero,dt)
			boss.drain_events()
			assert(boss.hit(10000,"terminal",true) > 0)
			assert(boss.drain_events() == ["death_started"])
			assert(boss.hazards.is_empty() and boss.reinforcement_requests.is_empty())
			boss.step(2,hero)
			assert(boss.exit_open and boss.drain_events() == ["boss_defeated"])
			boss.reset(42)
			boss.start(hero)
			advance_to(boss,"pressure_active",hero,dt)
			boss.reset(42)
			assert(boss.state == "idle" and boss.hp == 1080 and boss.pressure_wave == 0)
			assert(boss.pressure_kind == "" and boss.hazards.is_empty() and boss.reinforcement_requests.is_empty())
			assert(boss.drain_events().is_empty())
			boss.start(hero)
			advance_to(boss,"pressure_active",hero,dt)
			advance_to(boss,"recovery",hero,dt)
			advance_to(boss,"pressure_active",hero,dt)
			assert(boss.pressure_kind == "reinforcements" and not boss.reinforcement_requests.is_empty())
			boss.reset(42)
			assert(boss.reinforcement_requests.is_empty() and boss.drain_events().is_empty())
	print("PASS: alternating drifting gas/capped reinforcements, safe reachable lane, all phases60/120Hz, full windows, freeze/reset/terminal")
	quit()
