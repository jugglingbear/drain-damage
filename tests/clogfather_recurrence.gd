extends SceneTree
const Boss = preload("res://scripts/clogfather_encounter.gd")
var checks := 0
var failures := 0
func require(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
		quit(1)
func _initialize() -> void: call_deferred("run_checks")
func run_checks() -> void:
	for mode in ["easy","normal","hard"]:
		for hz in [30,60,120]:
			for band in [1.0,0.6,0.3,0.2]:
				var boss := Boss.new()
				boss.configure_difficulty(mode)
				boss.start(Rect2(400,394,26,46))
				boss.hp = int(boss.max_hp*band)
				var dt: float = 1.0/hz
				var later_shots := 0
				var groups := 0
				var rounds := {1:0,2:0}
				var first_end := -1.0
				var recovery_start := -1.0
				var previous := boss.state
				var acid_drops: Array[float] = []
				var pressure_kinds := {}
				var warnings := 1
				var warning_observed := true
				boss.drain_events()
				for tick in range(hz*80):
					var time: float = (tick+1)*dt
					var hero := Rect2(100+fposmod(time*50,450),394,26,46)
					boss.step(dt,hero)
					var events := boss.drain_events()
					if boss.state == "volley_warning" or boss._gun_warning_remaining >= 0: warning_observed = true
					warnings += events.count("volley_warning")
					if boss.state == "pressure_warning": pressure_kinds[boss.pressure_kind] = true
					if boss.state == "recovery" and previous != "recovery": recovery_start = time
					if previous == "recovery" and boss.state != "recovery":
						require(absf(time-recovery_start-5) <= dt*1.1,"Full five-second recovery")
					if boss.state == "recovery" or previous == "recovery":
						require(not events.has("projectile_spawn"),"No fresh gunfire in recovery")
					if boss.state == "acid_fall" and previous != "acid_fall": acid_drops.append(time)
					if events.has("projectile_spawn"):
						if boss.volley_round == 1 and boss._shots == 1:
							if groups > 0:
								require(rounds[1] in [1,2,3] and rounds[2] in [1,2,3],"Two bounded bursts per group")
							groups += 1
							rounds = {1:0,2:0}
							require(warnings > 0 and warning_observed,"Visible warning precedes each group")
							warning_observed = false
							warnings = 0
						rounds[boss.volley_round] += 1
						if boss.volley_round == 1 and boss._shots == boss._burst_count: first_end = time
						if boss.volley_round == 2 and boss._shots == 1:
							require(absf(time-first_end-1) <= dt*1.1,"One-second interburst gap")
						if time > 20: later_shots += 1
						var shots: Array = boss.hazards.filter(func(h: Dictionary) -> bool: return h.kind == "sludge")
						require(shots.back().velocity.normalized().dot((hero.get_center()-boss.nozzle).normalized()) > .9999,
							"Later shots aim at current hero")
					if band <= .2: require(boss.damageable(),"Enrage stays damageable")
					previous = boss.state
				require(later_shots > 8 and groups >= 3,"Sustained later firing in every health band/mode/rate")
				if band > .2: require(pressure_kinds.size() == 2,"Gas and reinforcements both recur")
				else:
					require(acid_drops.size() >= 20,"Enrage acid continues")
					for index in range(1,acid_drops.size()):
						require(absf(acid_drops[index]-acid_drops[index-1]-2) <= dt*1.1,"Acid retains two-second cadence")
				var before := boss.snapshot()
				boss.step(3,Rect2(100,394,26,46),true)
				require(boss.snapshot() == before or boss.snapshot().hazards == before.hazards,"Pause freezes hazards")
				require(boss._gun_elapsed == before.gun_elapsed,"Pause freezes gun clock")
				boss.step(0,Rect2(100,394,26,46),false)
				boss.hp = 1
				boss.hit(9999,"kill",true)
				boss.drain_events()
				boss.step(10,Rect2(100,394,26,46))
				require(not boss.drain_events().has("projectile_spawn") and boss.hazards.is_empty(),"Death cancels gun")
				boss.reset()
				require(not boss._gun_started and boss._gun_warning_remaining < 0,"Retry clears gun state")
	print("PASS: sustained Clogfather recurrence ",checks," checks")
	quit(0 if failures == 0 else 1)
