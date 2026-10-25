extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")

func _initialize() -> void:
	call_deferred("checks")

func checks() -> void:
	for hero in [0,1]:
		for mode in ["normal","hard"]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = mode
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.begin_level_two()
			var flush = game.flush
			flush.input_guard = false
			flush.process_audio(game,0.01)
			assert(not flush.music.voice.playing)
			flush.prelude_remaining = 0
			flush.process_audio(game,0.01)
			assert(flush.music.voice.playing)
			var presentation: Dictionary = flush.art.landing_presentation(game.employee.id,mode == "hard",2.0)
			assert(presentation.pose.composite_includes_board)
			assert(presentation.pose.front.size() == 1 and presentation.pose.rear.is_empty())
			assert("standing" in presentation.pose.pose if hero == 0 else "astride" in presentation.pose.pose)
			assert(Vector2(presentation.pose.contact_anchor[0],presentation.pose.contact_anchor[1]) == Vector2.ZERO)
			assert(float(flush.definition.art.frames.landing_board.destination[2]) == 110.0)
			var frame: Dictionary = presentation.pose.front[0]
			assert(absf(float(frame.destination[2])/float(frame.source_rect[2])
				-float(frame.destination[3])/float(frame.source_rect[3])) < 0.00001,"No stretched or shrunken hero")
			for index in range(241):
				var state: Dictionary = flush.art.landing_presentation(game.employee.id,mode == "hard",index/120.0)
				assert(absf(state.transform.determinant()-1.0) < 0.00001,"Shared bob/tilt preserves scale")
				assert(state.transform.origin.y >= 321 and state.transform.origin.y <= 387)
			flush.clock = 44.99
			flush.state = "drain"
			flush.tick(game,0.01,Vector2.ONE,false,false)
			assert(flush.state == "landing" and flush.clock == 45)
			assert(not flush.music.voice.playing)
			var normal_entry: Dictionary = flush.art.landing_presentation(game.employee.id,mode == "hard",
				flush.clock-43.0+flush.landing_clock)
			flush.begin(game,true)
			flush.enter_landing(game)
			flush.process_audio(game,0.01)
			assert(not flush.music.voice.playing,"Direct landing does not replay the flush score")
			var direct_entry: Dictionary = flush.art.landing_presentation(game.employee.id,mode == "hard",
				flush.clock-43.0+flush.landing_clock)
			assert(normal_entry.transform.is_equal_approx(direct_entry.transform))
			assert(normal_entry.pose == direct_entry.pose)
			game.queue_free()
			await process_frame
	print("PASS: both heroes/costumes, authored rider contact, short board, shared settle and identical landing entries")
	quit()
