extends SceneTree
const Spider = preload("res://scripts/devil_spider_state.gd")
var failures: Array[String] = []
var checked := 0

func _initialize() -> void: call_deferred("run_checks")

func check(ok: bool, message: String) -> void:
	checked += 1
	if not ok:
		failures.append(message)
		push_error(message)

func make_spider(overrides: Dictionary = {}) -> RefCounted:
	var spider = Spider.new(overrides)
	spider.start(Vector2(200,20),Vector2(100,300))
	spider.drain_events()
	return spider

func fire(spider: RefCounted, hz := 120) -> Dictionary:
	for tick in range(hz*10):
		spider.step(1.0/hz,Vector2(500,400))
		for event in spider.drain_events():
			if event.event == "web_fired": return event
	check(false,"Spider must release a web")
	return {"id":-1}

func advance(spider: RefCounted, seconds: float, hz: int) -> void:
	for tick in range(roundi(seconds*hz)): spider.step(1.0/hz,Vector2(500,400))

func run_checks() -> void:
	for hz in [30,60,120]:
		var spider := make_spider()
		advance(spider,1,hz)
		check(spider.state == "windup" and is_equal_approx(spider.position.x,235),"Crawl speed and duration")
		advance(spider,0.5,hz)
		check(spider.drain_events().is_empty(),"No premature projectile")
		spider.step(0.2,Vector2(10,100))
		var shot: Dictionary = spider.drain_events()[0]
		check(shot.event == "web_fired","Windup releases at0.7s")
		check(shot.direction.is_equal_approx(spider.mouth_position().direction_to(Vector2(10,100))),
			"Aim uses hero at release, not windup start")
		check(is_equal_approx(shot.velocity.length(),240),"Web speed")
		check(spider.projectile_hit_player(shot.id,spider.mouth_position()),"Direct hit captures")
		check(not spider.projectile_hit_player(shot.id,Vector2.ZERO),"Duplicate callback cannot recapture")
		advance(spider,1,hz)
		check(spider.movement_locked() and spider.state == "haul","No instant mouth hit at close range")
		check(not spider.drain_events().any(func(e: Dictionary) -> bool: return e.event == "ordinary_hit"),
			"Minimum two-second haul")
		advance(spider,1,hz)
		var events: Array = spider.drain_events()
		check(events.filter(func(e: Dictionary) -> bool: return e.event == "ordinary_hit").size() == 1,
			"Mouth emits exactly one ordinary hit")
		check(not spider.movement_locked() and spider.release_immunity > 0.99,"Mouth releases with immunity")
		check(not events.any(func(e: Dictionary) -> bool: return e.event == "web_fired"),"No shot during haul")
		advance(spider,1,hz)
		check(not spider.drain_events().any(func(e: Dictionary) -> bool: return e.event == "ordinary_hit"),
			"Released victim cannot receive repeat mouth damage")
		spider = make_spider()
		shot = fire(spider,hz)
		var start: Vector2 = spider.mouth_position()+Vector2(0,300)
		spider.projectile_hit_player(shot.id,start)
		advance(spider,1,hz)
		check(is_equal_approx(start.distance_to(spider.captive_position),60),"Haul speed60 at each frame rate")
		var before: Vector2 = spider.captive_position
		var time: float = spider.state_time
		spider.step(20,Vector2.ZERO,true)
		check(spider.captive_position == before and spider.state_time == time,"Pause freezes haul")
		check(not spider.escape_press() and spider.presses == 0,"Paused presses ignored")
		spider.step(0,Vector2.ZERO,false)
		for press in range(5): check(spider.escape_press() and spider.movement_locked(),"Five presses retain cocoon")
		check(is_equal_approx(spider.tear_progress(),5.0/6),"Tear progress exposed")
		check(spider.escape_press() and not spider.movement_locked(),"Sixth distinct press escapes")
		check(not spider.escape_press(),"Extra press has no effect")
		shot = fire(spider,hz)
		check(not spider.projectile_hit_player(shot.id,Vector2.ZERO,false),"Root rejects another owner's capture")
		spider.clear("retry")
		check(spider.projectiles.is_empty() and spider.traps.is_empty(),"Retry purges owned entities")
	# Fast configurable cadence isolates trap lifetime/cap without waiting out the default cooldown.
	var spider := make_spider({"crawl_seconds":0.1,"windup_seconds":0.1,"recover_seconds":0.1})
	var ids: Array[int] = []
	for index in range(3):
		var shot := fire(spider)
		ids.append(spider.projectile_hit_solid(shot.id,Vector2(index*100,440)))
	check(spider.traps.size() == 2 and int(spider.traps[0].id) == ids[1],"Trap cap retires oldest")
	check(not spider.trigger_floor_trap(ids[0],Vector2.ZERO),"Retired trap cannot capture")
	check(spider.trigger_floor_trap(ids[1],Vector2(100,440)),"Floor contact snares")
	var held_position: Vector2 = spider.captive_position
	advance(spider,0.1,120)
	check(spider.captive_position == held_position and spider.movement_locked(),"Snare immobilizes without hauling")
	check(not spider.trigger_floor_trap(ids[2],Vector2.ZERO),"Already captured hero cannot recapture")
	spider.escape_press()
	spider.escape_press()
	check(spider.movement_locked(),"Two presses retain floor snare")
	spider.escape_press()
	check(not spider.movement_locked(),"Third press frees snare")
	check(not spider.trigger_floor_trap(ids[2],Vector2.ZERO),"Release immunity blocks immediate capture")
	spider.step(1.01,Vector2.ZERO)
	check(spider.trigger_floor_trap(ids[2],Vector2.ZERO),"Capture allowed after immunity")
	spider.step(6,Vector2.ZERO)
	check(spider.traps.is_empty() and not spider.movement_locked(),"Six-second expiry releases snare")
	for reason in ["hero_death","retry","teardown","owner_killed"]:
		spider = make_spider()
		var shot := fire(spider)
		spider.projectile_hit_player(shot.id,Vector2(200,400))
		if reason == "owner_killed": spider.owner_killed()
		else: spider.clear(reason)
		check(not spider.alive and not spider.movement_locked() and spider.projectiles.is_empty()
			and spider.traps.is_empty(),reason)
		var events: Array = spider.drain_events()
		check(events.filter(func(e: Dictionary) -> bool: return e.event == "released").size() == 1,
			"Cleanup releases exactly once")
		spider.clear(reason)
		check(not spider.drain_events().any(func(e: Dictionary) -> bool: return e.event == "released"),
			"Repeated cleanup idempotent")
		spider.step(30,Vector2.ZERO)
		check(spider.drain_events().is_empty(),"Inactive owner cannot spawn")
	spider = make_spider()
	var wall_shot := fire(spider)
	check(spider.projectile_hit_solid(wall_shot.id,Vector2.ZERO,false) == -1 and spider.traps.is_empty(),
		"Wall collision consumes web without inventing floor trap")
	var floor_shot := fire(spider)
	var trap_id: int = spider.projectile_hit_solid(floor_shot.id,Vector2(100,440))
	var remaining: float = spider.traps[0].remaining
	spider.step(100,Vector2.ZERO,true)
	check(spider.traps[0].remaining == remaining,"Pause freezes trap expiry")
	check(not spider.trigger_floor_trap(trap_id,Vector2.ZERO),"Paused collision cannot snare")
	spider.step(0,Vector2.ZERO,false)
	spider.owner_killed()
	check(spider.traps.is_empty() and not spider.trigger_floor_trap(trap_id,Vector2.ZERO),
		"Owner death removes uncaptured traps")
	print("Devil spider state: %d checks, %d failures" % [checked,failures.size()])
	quit(0 if failures.is_empty() else 1)
