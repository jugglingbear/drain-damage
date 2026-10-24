extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
class BlockedGame:
	extends "res://scripts/integrated_first_call.gd"
	func player_shot_solids() -> Array[Rect2]:
		return [Rect2(-10000,-10000,30000,30000)]

func _initialize() -> void: call_deferred("run_checks")

func prepare(game: Node2D) -> void:
	game.reset_game()
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.restart_guard_device = -1
	game.player = Vector2(1387,394)
	game.grounded = true
	game.velocity = Vector2.ZERO
	game.facing = 1
	game.current_aim = Vector2.RIGHT
	game.fire_timer = 0

func run_checks() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	var sound = game.starter_weapon_audio
	for mode in ["easy","normal","hard"]:
		for person in game.Crew.EMPLOYEES:
			game.employee = person
			game.difficulty = mode
			prepare(game)
			var before: int = sound.starts[person.id]
			Input.action_press("shoot")
			game.step_player(0)
			assert(game.shots.size() == 1 and sound.starts[person.id] == before+1)
			game.step_player(0)
			assert(sound.starts[person.id] == before+1,"Cooldown cannot retrigger the cue")
			Input.action_release("shoot")
			assert(sound.pools.tony.size() == 3 and sound.pools.sean.size() == 1)
			for voice: AudioStreamPlayer in sound.pools[person.id]:
				assert(voice.volume_db == 0 and voice.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED)
			game.set_paused(true)
			sound.play_shot(person.id)
			assert(sound.starts[person.id] == before+1)
			assert(sound.paused)
			for voice: AudioStreamPlayer in sound.pools[person.id]:
				if voice.playing: assert(voice.stream_paused)
			game.set_paused(false)
			AudioServer.set_bus_mute(0,true)
			sound.play_shot(person.id)
			assert(sound.starts[person.id] == before+1)
			AudioServer.set_bus_mute(0,false)
			sound.stop()
			for voice: AudioStreamPlayer in sound.pools[person.id]: assert(not voice.playing)
	prepare(game)
	sound.play_shot("tony")
	await create_timer(.16).timeout
	sound.play_shot("tony")
	await create_timer(.16).timeout
	sound.play_shot("tony")
	for voice: AudioStreamPlayer in sound.pools.tony: assert(voice.playing,"Three water tails may overlap")
	game.boss_intro.begin("clogfather")
	game._process(.01)
	for voice: AudioStreamPlayer in sound.pools.tony: assert(voice.stream_paused)
	game.reset_game()
	for pool: Array in sound.pools.values():
		for voice: AudioStreamPlayer in pool: assert(not voice.playing)
	game.queue_free()
	await process_frame
	var blocked = BlockedGame.new()
	root.add_child(blocked)
	blocked.hide()
	blocked.set_process(false)
	blocked.set_physics_process(false)
	for person in blocked.Crew.EMPLOYEES:
		blocked.employee = person
		prepare(blocked)
		Input.action_press("shoot")
		blocked.step_player(0)
		Input.action_release("shoot")
		assert(blocked.shots.is_empty() and blocked.starter_weapon_audio.starts[person.id] == 0)
	blocked.starter_weapon_audio.play_shot("sean")
	blocked.health = 1
	blocked.invulnerable = 0
	blocked.hurt_player()
	assert(not blocked.starter_weapon_audio.pools.sean[0].playing)
	blocked.queue_free()
	await process_frame
	print("PASS: selected cues per actual shot, all heroes/modes, blocked/cooldown silence, bounded overlap, pause/mute/intro/death/reset/disposal")
	quit()
