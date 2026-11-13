extends SceneTree
## Continuous mode keeps normal game death, retry, pause and completion ownership.
const Game = preload("res://scripts/integrated_first_call.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var game := Game.new()
	root.add_child(game)
	while not game.startup_complete: await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	for hero in game.Crew.EMPLOYEES:
		for mode in ["easy","normal","hard"]:
			game.employee = hero
			game.difficulty = mode
			game.flush.active = false
			game.reset_game()
			Launch.initialize(game,{"initializer":"ride-continuous"})
			var ride: RefCounted = game.flush.ride
			assert(ride.continuous and game.flush.state == "ride")
			assert(game.health == hero.max_health and game.lives == 3)
			for checkpoint in [0,1,2]:
				ride.begin(game,checkpoint)
				var saved_clock: float = ride.clock
				game.paused = true
				ride.tick(game,1,Vector2.ONE,true)
				assert(ride.clock == saved_clock)
				game.paused = false
				game.lives = 3
				game.health = 1
				game.invulnerable = 0
				game.hurt_player()
				assert(game.life_state != "alive" and game.lives == 2)
				game.respawn_after_death()
				assert(ride.continuous and ride.checkpoint_index == checkpoint)
				assert(is_equal_approx(ride.clock,saved_clock))
				assert(ride.position == Vector2(300,330) and ride.jump_age < 0 and ride.cooldown == 0)
				assert(ride.contact_latches.is_empty() and ride.hit_ids.is_empty() and ride.fractured.is_empty())
				assert(game.health == hero.max_health and game.lives == 2)
			# Exercise each composed lethal opening through the real collision/death path, even during immunity.
			for pit_instance in ["slice-caps","slice-strainer"]:
				var checkpoint := 1 if pit_instance == "slice-caps" else 2
				ride.begin(game,checkpoint)
				game.lives = 3
				game.health = hero.max_health
				game.life_state = "alive"
				game.invulnerable = 3
				for obstacle: Dictionary in ride.course.obstacles:
					if obstacle.instance_id != pit_instance or obstacle.kind != "gap": continue
					ride.encounter_scroll = float(obstacle.x)-300-(240 if pit_instance == "slice-caps" else 0)
					ride.clock = ride.encounter_scroll/ride.scroll_speed
					ride.encounter_clock = ride.clock
					ride.position.y = 330
				ride.tick(game,1.0/60,Vector2.ZERO,false)
				assert(game.life_state != "alive" and game.lives == 2 and ride.events.has("fall"))
				game.respawn_after_death()
				assert(ride.checkpoint_index == checkpoint and game.health == hero.max_health)
			# Game-over retry follows reset_game, not respawn_after_death.
			game.lives = 0
			game.life_state = "dead"
			game.reset_game()
			assert(ride.continuous and ride.checkpoint_index == 2 and game.lives == 3)
			assert(game.health == hero.max_health and game.flush.state == "ride")
			game.invulnerable = 0
			var health: int = game.health
			game.hurt_player()
			assert(game.health == health-1 and game.lives == 3)
			# Safe runout completes only at the explicit course finish.
			ride.begin(game,2)
			ride.encounter_scroll = float(ride.definition.world_finish)-300-10
			ride.clock = ride.encounter_scroll/ride.scroll_speed
			ride.encounter_clock = ride.clock
			ride.tick(game,1.0/120,Vector2.ZERO,false)
			assert(not ride.complete)
			ride.tick(game,1.0/30,Vector2.ZERO,false)
			assert(ride.complete and game.won)
			print("PASS CONTINUOUS INTEGRATION ",hero.id," ",mode)
	game.begin_level_two()
	game.flush.enter_ride(game,0)
	assert(not game.flush.ride.continuous and game.flush.ride.definition.encounters.size() == 13)
	game.free()
	await process_frame
	print("PASS: continuous game lifecycle, six hero/mode cases")
	quit()
