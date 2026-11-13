extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
class FlatGame extends Game:
	func move_player_body(position: Vector2, motion: Vector2, size: Vector2, delta: float) -> Dictionary:
		var destination := position+motion*delta
		var landed := destination.y+size.y >= FLOOR_Y
		if landed:
			destination.y = FLOOR_Y-size.y
			motion.y = 0
		return {"pos":destination,"velocity":motion,"grounded":landed}
	func player_shot_solids() -> Array[Rect2]: return []
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func unlock(game: Node2D) -> void:
	game.dialogue.finish()
	game.dispenser.cancel()
	game.dispenser.actions_locked = false
	game.restart_guard_device = -1
	game.life_state = "alive"
	game.paused = false
	game.player = Vector2(85,394)
	game.velocity = Vector2.ZERO
	game.grounded = true
	game.fire_timer = 0
	game.shots.clear()
func run() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	var game := FlatGame.new()
	root.add_child(game)
	while not game.startup_complete: await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	for hero in game.Crew.EMPLOYEES:
		game.employee = hero
		game.flush.reset()
		game.reset_game()
		unlock(game)
		check(game.health == (4 if hero.id == "tony" else 6),"Selected hero maximum health")
		check(game.specials.remaining() == 2,"Fresh hero starts with both specials")
		check(hero.swim_speed == (270.0 if hero.id == "tony" else 235.0),"Swimming speed unchanged")
		check(hero.jump_height_multiplier == (1.25 if hero.id == "tony" else 1.0),"Requested jump-height ratio")
		var base_weapon: Dictionary = game.Data.weapon(hero.weapon_id,hero.id)
		if hero.id == "sean":
			check(is_equal_approx(base_weapon.attack_interval_seconds,4.0/3.0),"Original-mode rate also reduced25percent")
		var interval := 0.16 if hero.id == "tony" else 0.32
		check(is_equal_approx(game.weapon.attack_interval_seconds,interval),"Actual campaign cadence")
		check(game.weapon.damage == (12 if hero.id == "tony" else 18),"Ordinary shot damage unchanged")
		for hz in [30,60,120]:
			var dt: float = 1.0/hz
			unlock(game)
			Input.action_press("right")
			for tick in range(hz): game.step_player(dt)
			Input.action_release("right")
			check(is_equal_approx(game.velocity.x,310.5 if hero.id == "tony" else 235.0),"Actual running speed")
			unlock(game)
			game.jump_buffer = 0.14
			var apex := 394.0
			var expected_y := 394.0
			var expected_apex := expected_y
			var expected_velocity := game.JUMP_SPEED*sqrt(float(hero.jump_height_multiplier))
			for tick in range(hz):
				game.step_player(dt)
				apex = minf(apex,game.player.y)
				expected_velocity += game.GRAVITY*dt
				expected_y += expected_velocity*dt
				expected_apex = minf(expected_apex,expected_y)
			check(absf(apex-expected_apex) < 0.01,"Actual jump follows height-scaled ballistic path")
			var ideal := pow(game.JUMP_SPEED,2)/(2*game.GRAVITY)*float(hero.jump_height_multiplier)
			check(absf((394-apex)-ideal) <= absf(expected_velocity)*dt+1,"Measured jump apex within integration tolerance")
			unlock(game)
			Input.action_press("shoot")
			var previous := -1.0
			var shot_count := 0
			for tick in range(hz*3):
				game.step_player(dt)
				if game.shots.size() > shot_count:
					var now: float = tick*dt
					if previous >= 0:
						check(now-previous >= interval-0.0001 and now-previous <= interval+dt+0.0001,
							"Actual ordinary firing interval within one physics tick")
					previous = now
					shot_count = game.shots.size()
			Input.action_release("shoot")
			check(shot_count > 5,"Actual firing produces repeated projectiles")
		game.health = 1
		game.lives = 2
		game.specials.budgets["first-call:"+hero.id] = 0
		game.specials.budgets["level-two:"+hero.id] = 0
		game.begin_level_two()
		check(game.health == hero.max_health and game.lives == 2,"New level heals without granting lives")
		check(game.specials.remaining() == 2,"New level refills both charges")
		game.specials.budgets["level-two:"+hero.id] = 1
		game.health = 2
		game.flush.enter_ride(game,0)
		game.flush.ride.begin(game,1)
		check(game.health == 2 and game.specials.remaining() == 1,"Ride sections do not refill health or specials")
		game.life_state = "death_popup"
		game.respawn_after_death()
		check(game.specials.remaining() == 1,"Checkpoint retry preserves spent charge")
		check(game.lives == 2,"Respawn itself does not grant extra lives")
	game.free()
	await process_frame
	print("Hero balance: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
