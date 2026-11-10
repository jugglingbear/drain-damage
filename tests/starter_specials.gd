extends SceneTree
const Section = preload("res://scripts/section_one_two_game.gd")
const Integrated = preload("res://scripts/integrated_first_call.gd")
var failures: Array[String] = []
var checks_run := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func unlock(game: Node2D) -> void:
	game.dialogue.finish()
	game.dialogue.awaiting_release = false
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.restart_guard_device = -1
	game.paused = false
	game.life_state = "alive"
	game.grounded = true

func prepare(script: GDScript, hero: String) -> Node2D:
	var game = script.new()
	for employee in game.Crew.EMPLOYEES:
		if employee.id == hero: game.employee = employee
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	unlock(game)
	if script == Integrated:
		game.intro_input_release = false
		game.boss_intro.seen = {"cockroach-swarm":true,"clogfather":true}
	game.player = Vector2(120,394)
	game.camera_x = 0
	game.facing = 1
	game.current_aim = Vector2.RIGHT
	game.invulnerable = 1000
	return game

func dispose(game: Node2D) -> void:
	root.remove_child(game)
	game.free()

func check_budget_and_input(hero: String) -> void:
	var game := prepare(Section,hero)
	var special = game.specials
	check(special.remaining() == 2,"New run starts with two uses: "+hero)
	game.dialogue.release_guard = 0.5
	check(not special.sample_input(game,true),"Dialogue guard blocks B/K activation")
	game.dialogue.release_guard = 0
	check(not special.sample_input(game,true),"Held dialogue press cannot leak into gameplay")
	special.sample_input(game,false)
	check(special.sample_input(game,true) and special.remaining() == 1,"Fresh accepted press spends one")
	var activation: int = special.activation_id
	for tick in range(20): special.sample_input(game,true)
	check(special.activation_id == activation and special.remaining() == 1,"Held button never repeats")
	special.step(game,0.2)
	var time: float = special.elapsed
	game.paused = true
	special.step(game,1)
	check(is_equal_approx(special.elapsed,time),"Pause freezes action timeline")
	game.paused = false
	game.life_state = "dying"
	special.step(game,0.1)
	check(not special.active and special.remaining() == 1 and not game.special_audio.active,
		"Death cancels effect/audio without refund")
	game.reset_game()
	unlock(game)
	game.player = Vector2(120,394)
	check(special.remaining() == 1,"Retry preserves spent charge")
	special.sample_input(game,false)
	check(special.sample_input(game,true) and special.remaining() == 0,"Second use spends last charge")
	special.cancel("test")
	special.sample_input(game,false)
	check(not special.sample_input(game,true) and special.remaining() == 0,"Third use rejected")
	special.configure(hero,"level-two")
	check(special.remaining() == 2,"New logical level gets two")
	special.budgets["level-two:"+hero] = 1
	special.configure(hero,"level-two")
	check(special.remaining() == 1,"Same-level reconfiguration cannot refill")
	dispose(game)

func check_motion_and_geometry() -> void:
	var game := prepare(Section,"tony")
	var special = game.specials
	check(special.begin(game),"Tony begins on supported combat floor")
	var speed: float = game.employee.move_speed
	check(is_equal_approx(special.movement_speed(0,speed,Vector2.RIGHT),-30),"Idle recoil slides opposite right aim")
	check(is_equal_approx(special.movement_speed(1,speed,Vector2.RIGHT),speed*0.5),"Counterwalk is exactly half speed")
	check(is_equal_approx(special.movement_speed(-1,speed,Vector2.LEFT),-speed*0.5),"Mirrored counterwalk is half speed")
	check(is_zero_approx(special.movement_speed(0,speed,Vector2.UP)),"Upward aim adds no horizontal recoil")
	special.elapsed = 1
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2(1,-1).normalized()]:
		game.current_aim = direction
		game.facing = -1 if direction.x < 0 else 1
		var segments: Array[Dictionary] = special.water_segments(game)
		check(segments.size() == 1,"Aim produces one visible water segment")
		if segments.is_empty(): continue
		var stream: Dictionary = segments[0]
		check(is_equal_approx(stream.width,52),"Full-strength jet is Flushfiend thick")
		check((stream.end-stream.origin).normalized().is_equal_approx(direction),"Water follows live aim")
		check(is_equal_approx(stream.end.x,0) or is_equal_approx(stream.end.x,960)
			or is_equal_approx(stream.end.y,0),"Unobstructed stream reaches viewport edge")
	game.player = Vector2(1600,394)
	game.camera_x = 1200
	game.current_aim = Vector2.RIGHT
	game.facing = 1
	var clipped: Array[Dictionary] = special.water_segments(game)
	check(not clipped.is_empty(),"Stream exists before raised machinery")
	if not clipped.is_empty():
		check(clipped[0].end.x <= 1740-26+0.01,"Full width stops before blocking machinery")
		check(not special.overlaps(clipped,Rect2(1800,380,30,40)),"No damage behind blocker")
	dispose(game)
	game = prepare(Section,"sean")
	special = game.specials
	game.grounded = false
	check(not special.begin(game) and special.remaining() == 2,"Airborne pipe attempt rejected without spending")
	game.grounded = true
	check(special.begin(game),"Sean begins at supported clear pipe site")
	var anchor: Vector2 = special.anchor
	check(special.rooted() and special.water_segments(game).is_empty(),"Plant phase roots Sean without premature damage")
	special.elapsed = 1
	check(not special.rooted(),"Sean can move after release")
	game.player.x += 100
	game.camera_x += 50
	game.facing = -1
	check(special.anchor == anchor and special.locked_facing == 1,"Hero/camera/turn cannot rebase pipe or reverse sweep")
	check(special.outlet(game).direction.is_equal_approx(Vector2.UP),"Eruption starts vertically")
	special.elapsed = 1.5
	check(is_zero_approx(special.pipe_angle()),"Half a second of upright spray before tipping")
	special.elapsed = 1.6
	check(special.pipe_angle() > 0,"Pipe begins tipping immediately after upright hold")
	special.elapsed = 4.75
	check(special.outlet(game).direction.is_equal_approx(Vector2.RIGHT),"Pipe reaches locked-facing horizontal")
	check(not special.water_segments(game).is_empty(),"Horizontal pipe flow clears supporting floor")
	special.elapsed = 7
	check(special.water_width() > 0 and special.water_width() < 52,"Sputter narrows visible and damaging envelope")
	dispose(game)

func check_damage_cadence(hz: int) -> void:
	var game := prepare(Section,"tony")
	game.player = Vector2(500,394)
	game.camera_x = 180
	game.create_actor({"id":"special-test","role":"runner","warning_seconds":0},Vector2(750,440))
	var target: Dictionary = game.actors.back()
	target.active = true
	target.entry.complete = true
	target.feet = target.home
	target.hp = 10000
	target.max_hp = 10000
	Input.action_release("shoot")
	check(game.specials.sample_input(game,true),"Fresh special press begins automatic torrent")
	game.specials.sample_input(game,false)
	for tick in range(hz): game.step_player(1.0/hz)
	check(is_equal_approx(10000-target.hp,240),"Released-button automatic damage is240 at "+str(hz)+"Hz")
	check(game.shots.is_empty(),"Automatic special damage needs no ordinary shots")
	var segments: Array[Dictionary] = game.specials.water_segments(game)
	if not segments.is_empty(): segments.append(segments[0].duplicate())
	var before: float = target.hp
	game.special_damage(segments,12,99,{})
	check(is_equal_approx(before-target.hp,12),"Overlapping stream pieces cannot multiply one tick")
	check(not game.specials.overlaps(segments,Rect2(750,100,40,40)),"Off-stream enemy receives no screen-wide damage")
	dispose(game)

func check_boss_damage() -> void:
	var game := prepare(Integrated,"tony")
	game.skitterling.restore_completed()
	var boss = game.clogfather.encounter
	boss.active = true
	boss.state = "recovery"
	boss.recovery_index = 1
	game.camera_x = game.clogfather.ORIGIN.x
	game.player = game.clogfather.ORIGIN+Vector2(300,394)
	check(game.specials.begin(game),"Sustained boss damage test begins")
	var before: int = boss.hp
	for tick in range(900): game.specials.step(game,1.0/120)
	check(before-boss.hp == 888,"Full eligible Tony stream applies888 boss damage, beyond old250 cap")
	check(not game.specials.active,"Action ends after7.5s")
	boss.hp = boss.max_hp # Closed-state check must stay above the173 enraged threshold.
	boss.state = "warning"
	var region: Rect2 = boss.weak_point
	region.position += game.clogfather.ORIGIN
	var segments: Array[Dictionary] = [{"origin":region.position-Vector2(50,0),"end":region.end,"width":100}]
	before = boss.hp
	game.special_damage(segments,12,100,{"clogfather":12})
	check(boss.hp == before,"Closed boss remains invulnerable")
	for hero in ["tony","sean"]:
		game.specials.configure(hero,"first-call")
		var tuning: Dictionary = game.specials.definition.initial_tuning.hero_overrides[hero]
		boss.hp = boss.max_hp
		boss.state = "recovery"
		boss.recovery_index = 1
		var rat = game.skitterling.encounter
		rat.active = true
		rat.phase = "rat"
		rat.state = "rat_ready"
		rat.position = Vector2(600,440)
		rat.hp = rat.MAX_HP
		var rat_regions: Array[Rect2] = game.skitterling.target_regions()
		check(not rat_regions.is_empty(),"Rat exposes a real target for "+hero)
		var both: Array[Dictionary] = segments.duplicate(true)
		for rect: Rect2 in rat_regions:
			both.append({"origin":rect.position-Vector2(50,0),"end":rect.end,"width":300})
		for tick in range(30):
			game.specials.tick_serial += 1
			var applied: Dictionary = game.special_damage(both,tuning.damage_per_tick,200 if hero == "tony" else 201,
				{"skitterling":tuning.boss_damage_per_tick,"clogfather":tuning.boss_damage_per_tick})
			check(applied.get("skitterling",0) == 12 and applied.get("clogfather",0) == 12,
				"Both bosses receive12 every eligible tick, including after250: "+hero)
		check(rat.MAX_HP-rat.hp == 360 and boss.max_hp-boss.hp == 360,"Both bosses take360 in30 ticks: "+hero)
		rat.state = "rat_inside_pipe"
		boss.recovery_index = 2
		var rat_before: int = rat.hp
		var boss_before: int = boss.hp
		game.specials.tick_serial += 1
		game.special_damage(both,24,202,{"skitterling":12,"clogfather":12})
		check(rat.hp == rat_before and boss.hp == boss_before,"Hidden rat and grounded high-window hits remain blocked")
	dispose(game)

func check_sean_damage_parity(hz: int) -> void:
	var game := prepare(Section,"sean")
	game.create_actor({"id":"sean-water-target","role":"runner","warning_seconds":0},Vector2(177,240))
	var target: Dictionary = game.actors.back()
	target.active = true
	target.entry.complete = true
	target.feet = target.home
	target.hp = 10000
	target.max_hp = 10000
	check(game.specials.begin(game),"Sean comparison begins")
	game.specials.step(game,1.05)
	target.hp = 10000
	for tick in range(hz): game.step_player(1.0/hz)
	check(is_equal_approx(10000-target.hp,240),"Sean matches Tony at240DPS at "+str(hz)+"Hz")
	dispose(game)

func check_physical_recoil(hz: int) -> void:
	var game := prepare(Section,"tony")
	game.player = Vector2(1900,334)
	game.facing = -1
	game.current_aim = Vector2.LEFT
	check(game.specials.begin(game),"Wall recoil fixture begins")
	for tick in range(2*hz):
		game.step_player(1.0/hz)
		for solid: Rect2 in game.trial_level.plinths:
			check(not Rect2(game.player,game.PLAYER_SIZE).grow(-0.001).intersects(solid),
				"Physical recoil cannot embed hero at "+str(hz)+"Hz")
	check(game.player.x > 1900 and game.player.x+26 <= 1940.01,
		"Recoil moves hero into wall then stops at actual contact")
	dispose(game)
	game = prepare(Section,"tony")
	game.player = Vector2(game.trial_level.pit.y+10,394)
	check(game.specials.begin(game),"Pit recoil fixture begins")
	for tick in range(3*hz):
		game.step_player(1.0/hz)
		if game.pit_falling: break
	check(game.pit_falling,"Recoil retains real pit-fall physics at "+str(hz)+"Hz")
	check(game.player.x > game.trial_level.pit.x,"Recoil cannot teleport across pit")
	dispose(game)
	game = prepare(Section,"tony")
	check(game.specials.begin(game),"Counterwalk fixture begins")
	Input.action_press("right")
	for tick in range(hz): game.step_player(1.0/hz)
	Input.action_release("right")
	check(is_equal_approx(game.velocity.x,float(game.employee.move_speed)*0.5),
		"Actual step_player reaches half-speed counterwalk at "+str(hz)+"Hz")
	dispose(game)

func check_actual_respawn(script: GDScript) -> void:
	var game := prepare(script,"tony")
	check(game.specials.begin(game),"Respawn fixture consumes a use")
	game.life_state = "dying"
	game.specials.step(game,0.01)
	game.checkpoint_active = true
	game.checkpoint_index = 0
	game.respawn_point = Vector2(120,394)
	game.respawn_after_death()
	check(game.specials.remaining() == 1 and not game.specials.active,
		"Actual checkpoint respawn preserves one remaining use")
	game.reset_game()
	check(game.specials.remaining() == 1,"Actual reset_game preserves same-run budget")
	dispose(game)

func check_skitterling_transition() -> void:
	var game := prepare(Integrated,"tony")
	game.skitterling.entered = true
	var boss = game.skitterling.encounter
	boss.active = true
	boss.state = "rat_ready"
	boss.phase = "rat"
	boss.position = Vector2(600,440)
	boss.hp = boss.PHASE_HP+12
	game.player = game.skitterling.ORIGIN+Vector2(300,394)
	game.camera_x = game.skitterling.ORIGIN.x
	check(game.specials.begin(game),"Rat transition special begins")
	var before: int = boss.hp
	var collapsed := false
	var changed := false
	for tick in range(900):
		game.specials.step(game,1.0/120)
		if boss.state == "rat_collapse": collapsed = true
		game.skitterling.advance(game,1.0/120)
		if boss.phase == "alligator":
			changed = true
			check(float(game.specials.boss_used.get("skitterling",0)) >= 12,
				"Rat damage accounting survives actual alligator transition")
		if not game.specials.active: break
	check(collapsed and changed,"Actual encounter performs rat collapse and alligator assembly")
	check(before-boss.hp > 12,"Same activation also reaches vulnerable alligator")
	check(is_equal_approx(float(before-boss.hp),float(game.specials.boss_used.get("skitterling",0))),
		"Telemetry records actual applied damage across both forms")
	dispose(game)

func check_spent_pipes() -> void:
	var game := prepare(Section,"sean")
	var special = game.specials
	check(special.begin(game),"Spent-pipe test begins")
	special.step(game,7.5)
	check(not special.active and special.spent_pipes.size() == 1,"Expiry retains one spent main")
	check(special.water_segments(game).is_empty() and not game.special_audio.active,"Spent main has no water or audio")
	var first: Dictionary = special.spent_pipes[0].duplicate()
	check(is_equal_approx(first.angle,PI*0.5),"Completed main retains horizontal angle")
	game.player.x += 120
	check(special.begin(game),"Second use begins separately")
	special.step(game,0.6)
	game.life_state = "dying"
	special.step(game,0.01)
	check(special.spent_pipes.is_empty(),"Death clears both expired and interrupted mains")
	check(not special.active and special.water_segments(game).is_empty(),"Death stops water immediately")
	check(special.remaining() == 0,"Death does not refund either spent use")
	special.cancel("repeated death")
	check(special.spent_pipes.is_empty(),"Repeated cancellation keeps props cleared")
	game.reset_game()
	check(special.spent_pipes.is_empty() and special.remaining() == 0,"Reset clears props without refund")
	special.configure("sean","another-level")
	unlock(game)
	check(special.begin(game),"Fresh logical level can activate")
	special.step(game,0.2)
	special.cancel("death before emergence")
	check(special.spent_pipes.is_empty(),"Pre-emergence death does not conjure a pipe")
	dispose(game)

func check_regular_fire_during_special() -> void:
	for hero in ["tony","sean"]:
		var game := prepare(Section,hero)
		game.player = Vector2(500,394)
		check(game.specials.begin(game),"Fire fixture activates "+hero)
		game.specials.step(game,1.2)
		Input.action_press("shoot")
		game.fire_timer = 0
		game.step_player(1.0/60)
		check((not game.shots.is_empty()) == (hero == "sean"),"Sean fires regular weapon during active special")
		check(game.specials.active and game.specials.remaining() == 1,"Regular fire preserves special and budget")
		var count: int = game.shots.size()
		game.step_player(1.0/60)
		check(game.shots.size() == count,"Ordinary weapon cooldown remains enforced")
		Input.action_release("shoot")
		dispose(game)

func checks() -> void:
	check_regular_fire_during_special()
	for hero in ["tony","sean"]: check_budget_and_input(hero)
	check_motion_and_geometry()
	for hz in [30,60,120]: check_damage_cadence(hz)
	for hz in [30,60,120]: check_sean_damage_parity(hz)
	check_boss_damage()
	for hz in [30,120]: check_physical_recoil(hz)
	for script in [Section,Integrated]: check_actual_respawn(script)
	check_skitterling_transition()
	check_spent_pipes()
	print("Starter specials: %d checks, %d failures" % [checks_run,failures.size()])
	# Let the audio mixer release disposed voices before shutting down the test tree.
	await create_timer(0.2).timeout
	quit(0 if failures.is_empty() else 1)
