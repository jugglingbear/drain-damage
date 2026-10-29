extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Radio = preload("res://scripts/flush_radio.gd")

func _initialize() -> void:
	call_deferred("checks")

func checks() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-flush.json"))
	for hero in ["tony","sean"]:
		var expected: Array = [5,4,7,6,5,7,4] if hero == "tony" else [5,4,7,6,6,4]
		var lines: Array = data.story.routes[hero]
		var radio := Radio.new()
		radio.configure(lines,false,false)
		var seen := {}
		for frame in range(6500):
			radio.advance(float(frame)/100.0,0.01,false)
			if not radio.current.is_empty():
				var key := str(radio.current.at)
				seen[key] = int(seen.get(key,0))+1
		for index in range(lines.size()):
			assert(float(lines[index].duration) == float(expected[index]))
			assert(absf(float(seen[str(lines[index].at)])/100.0-float(expected[index])) <= 0.02)
		assert(data.story.landing_routes[hero][0].duration == 6)
		radio.free()
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
			game.begin_level_two()
			var flush = game.flush
			flush.input_guard = false
			flush.process_audio(game,0)
			assert(not flush.music.voice.playing and flush.audio.voices.current.playing)
			for frame in range(3120): flush.tick(game,1.0/120,flush.position.normalized(),false,false)
			assert(flush.prelude_remaining == 0 and absf(flush.clock) < 0.00001)
			assert(flush.hazards.is_empty() and flush.debris.spawned == 0)
			flush.process_audio(game,0.01)
			assert(flush.music.voice.playing and flush.music.seek_time < 0.01)
			var reading: float = flush.radio.line_clock
			game.set_paused(true)
			flush.tick(game,10,Vector2.ONE,false,false)
			assert(flush.clock == 0 and flush.radio.line_clock == reading)
			game.set_paused(false)
			for frame in range(959): flush.tick(game,1.0/120,flush.position.normalized(),false,false)
			assert(flush.debris.spawned == 0)
			flush.tick(game,1.0/120,flush.position.normalized(),false,false)
			assert(flush.debris.spawned > 0 and flush.radio.current.is_empty())
			# Isolate later presentation boundaries from the independently tested debris planner.
			flush.hazards.clear()
			flush.debris.next_wave = flush.definition.layout.difficulty[mode].waves.size()
			flush.clock = 35.0-1.0/120
			flush.tick(game,1.0/120,flush.position.normalized(),false,false)
			assert(flush.radio.current.event == "drain" and flush.radio.current.duration == 4)
			for frame in range(1199): flush.tick(game,1.0/120,flush.position.normalized(),false,false)
			flush.tick(game,1.0/120,flush.position.normalized(),false,false)
			assert(flush.state == "landing" and flush.clock == 45 and flush.checkpoint_saved)
			assert(flush.radio.current.duration == 6 and not flush.music.voice.playing)
			for frame in range(719): flush.tick(game,1.0/120,flush.position.normalized(),false,false)
			assert(flush.state == "landing")
			for frame in range(2): flush.tick(game,1.0/120,flush.position.normalized(),false,false)
			assert(flush.state == "ride")
			game.queue_free()
			await process_frame
	print("PASS: all 15 reading durations doubled, no overlap/truncation, 26s prelude, music26..71, hazards34, drain61 and landing71..77; both heroes/all modes")
	quit()
