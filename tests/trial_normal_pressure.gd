extends SceneTree
const Trial = preload("res://scripts/three_screen_trial_game.gd")
var failures: Array[String] = []
var checks_run := 0

func _initialize() -> void: call_deferred("checks")

func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)

func prepare(mode: String) -> Node2D:
	var game := Trial.new()
	game.difficulty = mode
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	for id in game.ledger: game.ledger[id] = "retired"
	return game

func shooters(game: Node2D) -> Array[Dictionary]:
	var living: Array[Dictionary] = []
	for actor in game.actors:
		if actor.hp > 0 and actor.role == "perched_shooter": living.append(actor)
	return living

func admit(game: Node2D) -> void:
	game.trial_clock += 0.3
	game.issue_event()

func checks() -> void:
	check_flyer_cap()
	for mode in ["normal","hard"]:
		var game := prepare(mode)
		game.player = Vector2(400,394)
		game.camera_x = 100
		game.grounded = true
		for id in ["opening-single","pressure-perched_shooter-0","pressure-perched_shooter-1"]:
			game.ledger[id] = "pending"
		admit(game)
		admit(game)
		var first_two := shooters(game)
		check(first_two.size() == 2,"Two shooters enter: "+mode)
		check(not first_two[0].active and not first_two[1].active,"Visible arrivals already count toward shooter cap")
		var existing_bolt := {"id":"existing-bolt","owner":first_two[0].event_id,
			"pos":Vector2(500,200),"previous":Vector2(500,200),"dir":Vector2.RIGHT,
			"age":1.0,"distance":220.0,"range":INF,"radius":4.0}
		game.hostile_shots.append(existing_bolt)
		for tick in range(5): admit(game)
		check(game.hostile_shots.has(existing_bolt),"Role cap does not erase an in-flight bolt")
		if mode == "normal":
			check(shooters(game).size() == 2,"Normal defers the third living shooter")
			check(game.ledger["pressure-perched_shooter-1"] == "pending","Deferred shooter remains pending")
			first_two[0].active = true
			first_two[0].winding = true
			admit(game)
			check(shooters(game).size() == 2,"Mixed active windup and inactive arrival both consume slots")
			game.camera_x = 820
			game.player = Vector2(1100,394)
			admit(game)
			check(shooters(game).size() == 2 and game.ledger["pressure-perched_shooter-1"] == "pending",
				"Moving camera does not bypass global live cap before normal retirement")
			game.camera_x = 100
			game.player = Vector2(400,394)
			admit(game)
			check(shooters(game).size() == 2,"Backtracking does not duplicate or replace admitted shooters")
			for actor in first_two:
				check(game.actors.has(actor) and actor.hp > 0,"Cap never despawns an existing visible shooter")
			game.ledger["opening-runner-a"] = "pending"
			admit(game)
			check(game.ledger["opening-runner-a"] == "warning","Shooter cap does not block a runner")
			game.ledger["pressure-aggressive_flyer-0"] = "pending"
			admit(game)
			check(game.ledger["pressure-aggressive_flyer-0"] == "warning","Shooter cap does not block a flying spider")
			game.damage_trial_actor(first_two[0],first_two[0].hp)
			check(shooters(game).size() == 1,"Death frees one shooter slot immediately")
			check(game.hostile_shots.has(existing_bolt),"Shooter death does not erase its existing bolt")
			admit(game)
			check(shooters(game).size() == 2 and game.ledger["pressure-perched_shooter-1"] == "warning",
				"Pending shooter admits after a death")
		else:
			check(shooters(game).size() == 3,"Hard retains admission above two shooters")
		root.remove_child(game)
		game.free()
	for mode in ["normal","hard"]:
		for hz in [30,120]: check_cooldown(mode,hz)
	print("Trial Normal pressure: %d checks, %d failures" % [checks_run,failures.size()])
	quit(0 if failures.is_empty() else 1)

func check_cooldown(mode: String, hz: int) -> void:
	var game := prepare(mode)
	game.player = Vector2(2700,394)
	game.camera_x = 1920
	game.grounded = true
	game.invulnerable = 100
	game.ledger["final-exchange"] = "pending"
	game.issue_event()
	check(game.actors.size() == 1,"Cooldown fixture admits final shooter")
	if game.actors.is_empty():
		root.remove_child(game)
		game.free()
		return
	var actor: Dictionary = game.actors[0]
	var expected := 2.2 if mode == "normal" else 1.2
	check(is_equal_approx(game.tuning.recovery_seconds,expected),"Mode recovery setting: "+mode)
	var windups_checked := 0
	for tick in range(hz*15):
		var winding: bool = actor.winding
		game.trial_clock += 1.0/hz
		game.step_trial_actors(1.0/hz)
		game.step_hostile_projectiles(1.0/hz)
		if actor.winding and not winding and not game.shot_log.is_empty():
			var gap: float = game.trial_clock-game.shot_log.back().time
			check(gap+0.00001 >= expected and gap <= expected+2.0/hz,
				"Actual recovery after last bolt is %ss before next charge: %s/%sHz" % [expected,mode,hz])
			windups_checked += 1
	check(windups_checked >= 3,"Multiple volleys exercise recovery: "+mode)
	var volleys := {}
	for shot in game.shot_log:
		if not volleys.has(shot.volley): volleys[shot.volley] = []
		volleys[shot.volley].append(shot.time)
	check(volleys.size() >= 4,"Repeated actual firing observed")
	check(volleys.get(2,[]).size() == (3 if mode == "normal" else 4),"Burst count unchanged: "+mode)
	for volley in range(2,volleys.size()+1):
		var gap: float = volleys[volley][0]-volleys[volley-1].back()
		check(gap+0.00001 >= expected+0.55 and gap <= expected+0.55+3.0/hz,
			"Inter-volley gap includes recovery plus full charge")
	root.remove_child(game)
	game.free()

func living_flyers(game: Node2D) -> Array[Dictionary]:
	var living: Array[Dictionary] = []
	for actor in game.actors:
		if actor.hp > 0 and actor.role == "aggressive_flyer": living.append(actor)
	return living

func check_flyer_cap() -> void:
	for mode in ["normal","hard"]:
		var game := prepare(mode)
		game.player = Vector2(900,394)
		game.camera_x = 400
		game.grounded = true
		for index in range(3): game.ledger["pressure-aggressive_flyer-%d" % index] = "pending"
		admit(game)
		admit(game)
		var first_two := living_flyers(game)
		check(first_two.size() == 2,"Two flying spiders admitted: "+mode)
		check(not first_two[0].active and not first_two[1].active,"Spider arrivals consume slots before activation")
		# Keep this role-cap fixture clear of the third entry's reserved landing.
		# Side arrivals now end near the edge instead of at the old remote hover point.
		for index in range(first_two.size()):
			first_two[index].home = Vector2(500+index*200,180)
			first_two[index].feet = first_two[index].home
		for tick in range(5): admit(game)
		if mode == "normal":
			check(living_flyers(game).size() == 2,"Normal defers third living flying spider")
			check(game.ledger["pressure-aggressive_flyer-2"] == "pending","Deferred spider remains pending")
			first_two[0].active = true
			first_two[0].attack_state = "windup"
			first_two[0].contact_live = true
			game.camera_x = 1200
			game.player = Vector2(1400,394)
			admit(game)
			check(living_flyers(game).size() == 2,"Spider cap includes active windup and offscreen arrivals before retirement")
			game.camera_x = 400
			game.player = Vector2(900,394)
			admit(game)
			for actor in first_two:
				check(game.actors.has(actor) and actor.hp > 0,"Backtracking preserves existing spiders without replacements")
			game.ledger["pressure-perched_shooter-0"] = "pending"
			admit(game)
			check(game.ledger["pressure-perched_shooter-0"] == "warning","Spider cap does not block a shooter")
			game.ledger["pressure-runner-3"] = "pending"
			admit(game)
			check(game.ledger["pressure-runner-3"] == "warning","Spider cap does not block a runner")
			game.damage_trial_actor(first_two[0],first_two[0].hp)
			check(living_flyers(game).size() == 1,"Spider death frees its role slot")
			admit(game)
			check(living_flyers(game).size() == 2 and game.ledger["pressure-aggressive_flyer-2"] == "warning",
				"Deferred spider admits when a role slot is freed")
		else:
			check(living_flyers(game).size() == 3,"Hard still admits three flying spiders")
		root.remove_child(game)
		game.free()
