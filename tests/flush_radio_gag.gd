extends SceneTree
const Radio = preload("res://scripts/flush_radio.gd")
const Portraits = preload("res://scripts/portrait_library.gd")

func _initialize() -> void:
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-flush.json")).story
	for hero in ["tony","sean"]:
		var partner := "sean" if hero == "tony" else "tony"
		for hard in [false,true]:
			var radio := Radio.new()
			radio.configure(story.routes[hero],hard,false)
			radio.advance(0,0,false)
			assert(radio.current.who == hero)
			radio.advance(2.5,2.5,false)
			assert(radio.current.who == hero and not radio.current.radio)
			assert("chat window" in radio.current.text.to_lower())
			assert(radio.presentation().destination == Vector2(110,220))
			assert(radio.presentation().progress == 0)
			radio.advance(4.4,1.9,false)
			assert(radio.current.who == hero and radio.presentation().progress == 0)
			radio.advance(4.5,0.1,false)
			var reply: Dictionary = story.routes[hero][2]
			assert(reply.who == partner and reply.radio and reply.gag_action == "slide_bottom")
			var previous := 0.0
			for frame in range(1,70):
				var time := 4.5+frame*0.05
				radio.advance(time,0.05,false)
				var view := radio.presentation()
				assert(view.who == partner and view.text == reply.text and view.emotion == reply.emotion)
				var expected := Portraits.expression(partner,reply.emotion,hard)
				assert(view.portrait.atlas == expected.atlas and view.portrait.region == expected.region)
				assert(view.progress >= previous)
				if time < 5.9: assert(view.progress == 0)
				if time > 5.95 and time < 6.65: assert(view.progress > 0 and view.progress < 1)
				if time >= 6.7: assert(is_equal_approx(view.progress,1.0))
				previous = view.progress
				if frame == 34:
					var clock: float = radio.line_clock
					var position: Vector2 = view.destination
					radio.advance(time+30,30,true)
					assert(radio.line_clock == clock and radio.presentation().destination == position)
					assert(radio.current.who == partner)
			radio.advance(8,0.05,false)
			assert(radio.current.event == "flush" and radio.presentation().destination == Vector2(110,452))
			assert(radio.presentation().scale == 1)
			# A skipped render interval keeps relocation on the response's authored timeline.
			radio.configure(story.routes[hero],hard,false)
			radio.advance(6.3,6.3,false)
			assert(radio.current.who == partner and radio.presentation().progress > 0 and radio.presentation().progress < 1)
			radio.configure(story.routes[hero],hard,true)
			for frame in range(160): radio.advance(frame*0.05,0.05,false)
			assert(radio.current.is_empty() and radio.entries.all(func(line: Dictionary) -> bool: return line.event != "arrival"))
			radio.clear()
			assert(radio.presentation().is_empty())
			radio.free()
	print("PASS: reciprocal hero request/partner reply, exact portrait through relocation, pause, late frame, retry and bottom reset")
	quit()
