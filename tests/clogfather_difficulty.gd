extends SceneTree
const Boss = preload("res://scripts/clogfather_encounter.gd")

func _initialize() -> void: call_deferred("run_checks")

func until(boss: RefCounted, state: String, hero: Rect2, dt: float) -> void:
	for tick in range(int(50/dt)):
		if boss.state == state: return
		boss.step(dt,hero)
	assert(false,"Missing state "+state)

func run_checks() -> void:
	create_timer(40).timeout.connect(func() -> void: quit(1))
	for mode in ["easy","normal","hard"]:
		if mode != "easy":
			var rounds = Boss.new()
			rounds.configure_difficulty(mode,12)
			var first_hero := Rect2(80,394,26,46)
			var moved_hero := Rect2(540,394,26,46)
			rounds.start(first_hero)
			var first_aim: Vector2 = rounds.snapshot().aim
			until(rounds,"volley",first_hero,1.0/120)
			until(rounds,"volley_warning",moved_hero,1.0/120)
			assert(rounds.snapshot().volley_round == 2 and rounds.hazards.is_empty())
			assert(rounds.snapshot().aim != first_aim and not rounds.damageable())
			var second_aim: Vector2 = rounds.snapshot().aim
			rounds.step(0.5,first_hero)
			assert(rounds.state == "volley_warning" and rounds.hazards.is_empty())
			assert(rounds.snapshot().aim == second_aim,"Second round locks its separately warned aim")
			until(rounds,"recovery",first_hero,1.0/120)
			var round_events: Array = rounds.drain_events()
			assert(round_events.count("volley_warning") == 2 and round_events.count("projectile_spawn") == 6)
		for phase in [2,3]:
			var later = Boss.new()
			later.configure_difficulty(mode,12)
			later.phase = phase
			later.start(Rect2(390,394,26,46))
			until(later,"recovery",Rect2(390,394,26,46),1.0/120)
			assert(later.drain_events().count("projectile_spawn") == (4 if mode == "easy" else 8))
		for damage in [12,18]:
			for hz in [60,120]:
				var dt: float = 1.0/hz
				for x in [80.0,200.0,390.0,540.0,674.0]:
					var hero := Rect2(x,394,26,46)
					var boss = Boss.new()
					boss.configure_difficulty(mode,damage)
					boss.start(hero)
					until(boss,"recovery",hero,dt)
					assert(boss.drain_events().count("projectile_spawn") == (3 if mode == "easy" else 6))
					boss.step(4.9,hero)
					assert(boss.damageable())
					until(boss,"pressure_warning",hero,dt)
					var lane: Rect2 = boss.safe_corridor
					var target := clampf(hero.position.x,lane.position.x,lane.end.x-hero.size.x)
					assert(absf(target-hero.position.x) <= 235*(boss.pressure_warning_seconds()-0.15))
					until(boss,"pressure_active",hero,dt)
					var cloud_count := 1 if mode == "easy" else 4 if mode == "normal" else 6
					assert(boss.hazards.size() == cloud_count and boss.gas_targets().size() == cloud_count)
					var before: Dictionary = boss.snapshot()
					boss.step(1,hero,true)
					assert(boss.gas_targets().is_empty() and boss.hazards == before.hazards)
					assert(boss.hit_gas(boss.hazards[0].id,damage,"frozen") == 0)
					boss.step(0,hero,false)
					var cloud: Dictionary = boss.hazards[0]
					assert(cloud.hp == damage*5 and cloud.max_hp == damage*5)
					for hit in range(5):
						assert(boss.hit_gas(cloud.id,damage,"hit-%d" % hit) == damage)
						assert(boss.hit_gas(cloud.id,damage,"hit-%d" % hit) == 0)
						assert(cloud.hp == damage*(4-hit))
					assert(boss.hazards.size() == cloud_count-1)
					var feedback: Array = boss.drain_events()
					assert(feedback.count("gas_destroyed") == 1 and feedback.count("gas_damaged") == 4)
					for rect in boss.hurt_rects(): assert(rect != cloud.rect,"Destroyed gas cannot hurt")
					while boss.state == "pressure_active":
						boss.step(dt,hero)
						for gas in boss.hazards:
							assert(not gas.rect.grow(20).intersects(lane))
							assert(gas.rect.position.x >= 100 and gas.rect.end.x <= 680)
					assert(boss.gas_targets().is_empty())
					until(boss,"acid_warning",hero,dt)
					var acid_lane: Rect2 = boss.safe_corridor
					assert(acid_lane.size.x == (180 if mode == "easy" else 140 if mode == "normal" else 120))
					target = clampf(hero.position.x,acid_lane.position.x,acid_lane.end.x-hero.size.x)
					assert(absf(target-hero.position.x) <= 235*(boss.acid_warning_seconds()-0.15))
					assert(boss.warnings.size() >= (1 if mode == "easy" else 3 if mode == "normal" else 4))
					for mark in boss.warnings: assert(not mark.intersects(acid_lane))
					until(boss,"recovery",hero,dt)
					assert(boss.recovery_index == 2 and boss.snapshot().weak_point_level == "high")
					until(boss,"pressure_warning",hero,dt)
					lane = boss.safe_corridor
					target = clampf(hero.position.x,lane.position.x,lane.end.x-hero.size.x)
					assert(absf(target-hero.position.x) <= 235*(1.2-0.15))
					var count := 2 if mode == "easy" else 4 if mode == "normal" else 8
					assert(boss.reinforcement_requests.size() == count)
					var centers: Array[Vector2] = []
					for request in boss.reinforcement_requests:
						assert(not centers.has(request.center))
						centers.append(request.center)
						assert(request.bounds.grow(-48).grow(0.001).has_point(request.center))
						assert(not Rect2(request.center-Vector2(64,64),Vector2(128,128)).intersects(lane))
						assert(request.hp == 24)
					until(boss,"pressure_active",hero,dt)
					assert(boss.drain_events().count("reinforcements_spawn") == 1)
					until(boss,"recovery",hero,dt)
					assert(boss.reinforcement_requests.is_empty() and boss.hazards.is_empty())
					boss.drain_events()
					boss.hit(9999,"lethal",true)
					assert(boss.hp == 0 and boss.gas_targets().is_empty())
					boss.reset(7)
					assert(boss.hp == 1080 and boss.hazards.is_empty() and boss.reinforcement_requests.is_empty())
	print("PASS: all modes/weapons60/120Hz, volleys, exact gas/add counts, five hits/dedup/freeze, escape lanes and cleanup")
	quit()
