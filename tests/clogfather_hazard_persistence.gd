extends SceneTree
const Boss = preload("res://scripts/clogfather_encounter.gd")
const Game = preload("res://scripts/integrated_first_call.gd")
const HERO := Rect2(400,394,26,46)
var checks := 0

func _initialize() -> void: call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		quit(1)

func advance_to(boss: RefCounted, target: String, hz: int) -> void:
	for tick in range(hz*45):
		if boss.state == target: return
		boss.step(1.0/hz,HERO)
	check(false,"Unreachable state: "+target)

func run_checks() -> void:
	for mode in ["easy","normal","hard"]:
		for hz in [30,60,120]:
			var boss = Boss.new()
			boss.configure_difficulty(mode)
			boss.start(HERO)
			advance_to(boss,"pressure_active",hz)
			var initial: Array = boss.gas_targets()
			check(not initial.is_empty(),"Gas spawned")
			var id: String = initial[0].id
			var attack_index := 0
			for target in ["acid_warning","acid_fall","acid_puddle","approach","recovery","pressure_warning","pressure_active","acid_warning","acid_fall","recovery"]:
				advance_to(boss,target,hz)
				check(boss.gas_targets().size() == initial.size(),"Gas survives "+target)
				var attack_id := str(attack_index)
				attack_index += 1
				check(boss.hit_gas(id,1,attack_id) == 1,"Gas damage works in "+target)
				check(boss.hit_gas(id,1,attack_id) == 0,"Attack deduplicates")
				check(boss.hurt_rects().has(boss.gas_targets()[0].rect),"Gas remains dangerous")
			var frozen: Array = boss.hazards.duplicate(true)
			boss.step(2,HERO,true)
			check(boss.hazards == frozen and boss.gas_targets().is_empty(),"Pause freezes hazards")
			boss.step(0,HERO,false)
			check(boss.hit_gas(id,999,"kill") > 0,"Gas can be destroyed after phase changes")
			check(boss.gas_targets().size() == initial.size()-1,"Only killed gas removed")
			check(boss.drain_events().has("gas_destroyed"),"Death feedback retained")
			boss.hit(99999,"boss-kill",true)
			check(boss.hazards.is_empty(),"Boss defeat cleans up")
			boss.reset()
			check(boss.hazards.is_empty() and boss._gas_hits.is_empty(),"Retry clears hazards and hit ledger")
	check_room()
	var stress = Boss.new()
	stress.configure_difficulty("hard")
	stress.start(HERO)
	var started := Time.get_ticks_msec()
	for tick in range(120*600): stress.step(1.0/120,HERO)
	check(stress.gas_targets().size() > 60,"Long fight retains accumulated live clouds")
	print("Persistence: ",checks," checks; 600 simulated seconds in ",Time.get_ticks_msec()-started," ms; ",stress.gas_targets().size()," live clouds")
	quit()

func check_room() -> void:
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.invulnerable = 1000
	game.swarms.actors.clear()
	var room = game.clogfather
	var boss = room.encounter
	boss.start(HERO)
	boss._begin_pressure()
	boss._begin_pressure()
	boss.state = "pressure_active"
	room.spawn_reinforcements(game)
	var count: int = game.swarms.actors.size()
	check(count > 0,"Reinforcement wave spawns")
	var survivor: Dictionary = game.swarms.actors[0]
	boss._clear_pressure()
	room.flush_events(game)
	check(game.swarms.actors.has(survivor),"Phase event retains reinforcement")
	boss._begin_pressure()
	boss._begin_pressure()
	boss.state = "pressure_active"
	room.spawn_reinforcements(game)
	check(game.swarms.actors.size() == count*2,"Next wave appends without deleting survivors")
	check(game.swarms.actors.has(survivor),"Original actor survives next wave")
	for tick in range(120*30): game.swarms.step(game,1.0/120)
	check(survivor.hp > 0 and game.swarms.actors.has(survivor),"No live reinforcement lifetime expiry")
	game.swarms.damage(0,9999)
	check(survivor.hp == 0 and survivor.flash > 0,"Real reinforcement damage/death feedback retained")
	room.reset(42)
	check(game.swarms.actors.is_empty(),"Retry cleans reinforcements")
	game.free()
