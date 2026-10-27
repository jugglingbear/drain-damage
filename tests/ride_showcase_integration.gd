extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void:
	call_deferred("checks")

func checks() -> void:
	for hero in [0,1]:
		for mode in ["easy","normal","hard"]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			game.seed_override = 42
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			for index in range(11):
				game.flush.reset()
				game.reset_game()
				var target: Dictionary = {}
				for candidate: Dictionary in Launch.registry().targets:
					if candidate.id == "2-%02d" % (index+1): target = candidate
				assert(not target.is_empty())
				Launch.initialize(game,target)
				var ride = game.flush.ride
				assert(game.flush.state == "ride" and ride.encounter_index == index)
				assert(ride.checkpoint_index == index and ride.clock == 0 and ride.phase == "encounter")
				assert(ride.scroll_speed == 560 and not game.flush.music.voice.playing)
				assert(game.flush.radio.current.is_empty())
				var weapon: String = game.weapon.id
				game.set_paused(true)
				ride.tick(game,4,Vector2.ONE,true)
				assert(ride.clock == 0 and ride.position == Vector2(300,330))
				game.set_paused(false)
				game.health = 1
				game.invulnerable = 0
				var lives: int = game.lives
				game.hurt_player()
				assert(game.life_state == "dying" and game.lives == lives-1)
				game.respawn_after_death()
				assert(game.flush.state == "ride" and ride.encounter_index == index and ride.clock == 0)
				assert(game.health == game.employee.max_health and game.weapon.id == weapon)
				game.lives = 0
				game.reset_game()
				assert(ride.encounter_index == index and game.lives == 3 and ride.clock == 0)
				assert(game.flush.radio.current.is_empty() and not game.flush.music.voice.playing)
			game.queue_free()
			await process_frame
	print("PASS: 66 integrated encounter entries, pause, death checkpoint, game-over retry, no flush replay or loadout change")
	quit()
