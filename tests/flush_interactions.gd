extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("checks")

func checks() -> void:
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	var flush = game.flush
	flush.clock = 10
	flush.position = Vector2(250,0)
	var hard := {"id":"test-hard","at":8.0,"warning_seconds":1.0,"lifetime_seconds":20.0,
		"radius_pixels":22.0,"kind":"hard","pos":Vector2(250,0),"hp":999999}
	flush.hazards.append(hard)
	game.invulnerable = 0
	flush.jump_height = 25
	var health: int = game.health
	flush.step_hazards(game,0)
	assert(game.health == health,"Jump clearance avoids low debris")
	flush.jump_height = 0
	flush.step_hazards(game,0)
	assert(game.health == health-1,"Grounded contact takes exactly one damage")
	flush.step_hazards(game,0)
	assert(game.health == health-1,"Shared immunity prevents repeated contact damage")
	flush.shots.append({"pos":Vector2(200,0),"dir":Vector2.RIGHT,"distance":0.0})
	flush.step_shots(game,0.2)
	assert(hard.hp == 999999 and flush.shots.is_empty(),"Hard debris absorbs shots without breaking")
	flush.hazards.clear()
	flush.move_hero(game,0.1,Vector2.ZERO,true)
	assert(flush.jump_height > 24 and not flush.position.is_equal_approx(Vector2(250,0)))
	flush.audio.advance(0.1,false,true,true)
	assert(flush.audio.voices.size() == 4 and flush.audio.voices.current.playing)
	var audio_clock: float = flush.audio.clock
	flush.audio.advance(1,true,true,true)
	assert(flush.audio.clock == audio_clock and flush.audio.voices.current.stream_paused)
	var starts: int = flush.audio.starts.get("debris_impact",0)
	flush.audio.play("debris_impact")
	assert(flush.audio.starts.get("debris_impact",0) == starts)
	AudioServer.set_bus_mute(0,true)
	flush.audio.advance(0.1,false,true,false)
	assert(flush.audio.voices.values().all(func(voice: AudioStreamPlayer) -> bool: return not voice.playing))
	AudioServer.set_bus_mute(0,false)
	flush.audio.advance(0.1,false,true,false)
	assert(flush.audio.voices.current.playing)
	flush.enter_landing(game)
	assert(flush.audio.voices.values().all(func(voice: AudioStreamPlayer) -> bool: return not voice.playing or voice == flush.audio.voices.radio))
	game.queue_free()
	await process_frame
	print("PASS: flush jump clearance, shared contact immunity, hard debris, current and bounded pause/mute audio")
	quit()
