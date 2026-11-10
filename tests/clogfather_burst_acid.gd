extends SceneTree
const Boss = preload("res://scripts/clogfather_encounter.gd")
const HERO := Rect2(400,394,26,46)
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _initialize() -> void:
	for mode in ["easy","normal","hard"]:
		var boss := Boss.new()
		boss.configure_difficulty(mode)
		boss.start(HERO)
		var sizes := {}
		for seed_value in range(24):
			boss.reset(seed_value)
			boss.start(HERO)
			var time := 0.0
			var first_end := -1.0
			var counts := {1:0,2:0}
			for tick in range(120*8):
				var hero := Rect2(100+fposmod(tick*1.7,450),394,26,46)
				boss.step(1.0/120,hero)
				time += 1.0/120
				if boss.drain_events().has("projectile_spawn"):
					check(boss.volley_round in [1,2],"No third burst")
					counts[boss.volley_round] = int(counts.get(boss.volley_round,0))+1
					check(boss._burst_count >= 1 and boss._burst_count <= 3,"Random burst size bounded")
					sizes[boss._burst_count] = true
					if boss.volley_round == 1 and boss._shots == boss._burst_count: first_end = time
					if boss.volley_round == 2 and boss._shots == 1:
						check(absf(time-first_end-1) < .00001,"Exactly one second between bursts")
					var shots: Array = boss.hazards.filter(func(h: Dictionary) -> bool: return h.kind == "sludge")
					var newest: Dictionary = shots.back()
					check(newest.velocity.normalized().dot((hero.get_center()-boss.nozzle).normalized()) > .9999,
						"Each emitted shot aims at current hero")
				if boss.state == "approach": break
			check(boss.state == "approach" and not boss._gun_started,"Second burst stops gun and advances")
			check(counts[1] >= 1 and counts[1] <= 3 and counts[2] >= 1 and counts[2] <= 3,
				"Exactly two complete bursts of one to three shots")
			boss.step(12,HERO)
			check(not boss.drain_events().has("projectile_spawn"),"No continued gunfire in recovery or pressure/acid")
			check(not boss._gun_started and boss.volley_round == 2,"Finished volley stays stopped")
		check(sizes.size() == 3,"Seeded encounters exercise all three random sizes")
		var time := 0.0
		for kind in ["gas","reinforcements"]:
			boss.reset()
			boss.active = true
			boss.pressure_wave = 0 if kind == "gas" else 1
			boss._begin_pressure()
			while boss.state != "pressure_active": boss.step(1.0/120,HERO)
			boss.step(2.0-1.0/120,HERO)
			check(not boss.hazards.any(func(h: Dictionary) -> bool: return h.kind == "acid"),"No early acid")
			boss.step(1.0/120,HERO)
			check(boss.state == "acid_fall","Actual acid starts2s after pressure appearance")
		boss.hp = int(boss.max_hp/5)+1
		check(not boss.enraged() and not boss.damageable(),"Above20percent retains window policy")
		boss.hp = int(boss.max_hp/5)
		var drops: Array[float] = []
		time = 0
		var previous := boss.state
		for tick in range(120*9):
			boss.step(1.0/120,HERO)
			time += 1.0/120
			if boss.state == "acid_fall" and previous != "acid_fall": drops.append(time)
			previous = boss.state
			check(boss.damageable(),"Low-health loop remains killable")
			check(boss.hazards.filter(func(h: Dictionary) -> bool: return h.kind == "acid").size() <= 6,"Acid lifetime bounded")
		check(drops.size() >= 4,"Low-health volleys repeat")
		for index in range(1,drops.size()): check(absf(drops[index]-drops[index-1]-2) < .009,"Drop-to-drop cooldown exactly2s")
		var snapshot := boss.snapshot()
		boss.step(3,HERO,true)
		check(boss.hazards == snapshot.hazards,"Pause freezes hazards")
		boss.step(0,HERO,false)
		check(boss.hit(999999,"kill",true) > 0,"Can kill during acid loop")
		boss.step(3,HERO)
		check(boss.hazards.is_empty() and boss.exit_open,"Death clears hazards and stops attacks")
	print("Clogfather burst/acid: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
