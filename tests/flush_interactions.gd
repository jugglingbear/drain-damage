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
	flush.prelude_remaining = 0
	flush.clock = 10
	flush.position = Vector2(250,0)
	var item := {"id":"impact-test","prop":"corn","at":8.0,"duration":2.0,"impact_at":10.0,
		"pos":Vector2(250,0),"impact_pos":Vector2(250,0),"height":150.0,"impacted":false}
	flush.hazards.append(item)
	game.invulnerable = 0
	var health: int = game.health
	flush.debris.next_wave = flush.definition.layout.difficulty.normal.waves.size()
	flush.debris.advance(flush,game,0)
	assert(game.health == health-1,"Water impact takes exactly one damage")
	flush.debris.advance(flush,game,0)
	assert(game.health == health-1,"Shared immunity prevents repeated contact damage")
	flush.clock = 10.36
	game.invulnerable = 0
	flush.debris.advance(flush,game,0.36)
	assert(game.health == health-2,"Floating debris remains harmful after its splash animation")
	flush.clock = 35.1
	game.invulnerable = 0
	flush.debris.advance(flush,game,0.1)
	assert(game.health == health-2,"Damage ends when automatic descent removes control")
	assert(flush.hazards.size() == 1 and item.pos.length() < 250,"Final drain retains and pulls floating objects")
	flush.audio.advance(0.1,false,true,true)
	assert(flush.audio.voices.size() == 5 and flush.audio.voices.current.playing)
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
	flush.begin(game,true)
	flush.prelude_remaining = 0
	flush.clock = 34.99
	flush.position = Vector2(180,0)
	flush.tick(game,0.02,Vector2.RIGHT,false,false)
	assert(flush.drain_origin.distance_to(Vector2(180,0)) < 4,"Only the pre35 control interval may move the capture origin")
	flush.clock = 39.99
	flush.state = "drain"
	var burbles: int = flush.audio.starts.get("suction_burble",0)
	flush.tick(game,0.02,Vector2.ZERO,true,true)
	assert(flush.sink_depth > 0 and flush.audio.starts.suction_burble == burbles+1)
	var depth: float = flush.sink_depth
	var water: float = flush.water_clock
	game.set_paused(true)
	flush.tick(game,1,Vector2.ONE,true,true)
	assert(flush.sink_depth == depth and flush.water_clock == water)
	game.set_paused(false)
	for frame in range(360): flush.tick(game,1.0/120,Vector2.ZERO,true,true)
	assert(flush.sink_depth == 1 and flush.audio.starts.suction_burble == burbles+1)
	assert(flush.shots_fired == 0 and game.shots.is_empty())
	assert(game.life_state == "alive" and game.lives == 3)
	var weapon_id: String = game.weapon.id
	flush.reset()
	game.reset_game()
	assert(not flush.active and game.weapon.id == weapon_id)
	game.queue_free()
	await process_frame
	print("PASS: persistent float damage, shared immunity, automatic descent, bounded audio and preserved loadout")
	quit()
