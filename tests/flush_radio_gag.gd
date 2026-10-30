extends SceneTree
const Radio = preload("res://scripts/flush_radio.gd")
const Portraits = preload("res://scripts/portrait_library.gd")

func _initialize() -> void:
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-flush.json")).story
	for hero in ["tony","sean"]:
		var partner := "sean" if hero == "tony" else "tony"
		for hard in ["easy","normal","hard"]:
			var radio := Radio.new()
			radio.configure(story.routes[hero],hard,false)
			radio.advance(0,0,false)
			assert(radio.presentations().size() == 1)
			assert(radio.current.who == partner and radio.presentation().destination == Vector2(110,220))
			radio.advance(5,5,false)
			assert(radio.current.who == hero and not radio.current.radio)
			assert("chat window" in radio.current.text.to_lower())
			assert(radio.presentation().destination == Vector2(110,220))
			var views := radio.presentations()
			assert(views.size() == 1 and views[0].who == hero)
			assert(views[0].destination == Vector2(110,220))
			if hero == "tony": assert(radio.current.text == "Big enough. Move the chat window down!")
			radio.advance(8.8,3.8,false)
			assert(radio.current.who == hero and radio.presentations().size() == 1)
			radio.advance(9,0.2,false)
			var reply: Dictionary = story.routes[hero][2]
			assert(reply.who == partner and reply.radio and reply.gag_action == "slide_bottom")
			var previous := 0.0
			for frame in range(1,140):
				var time := 9+frame*0.05
				radio.advance(time,0.05,false)
				assert(radio.presentations().size() == 1)
				var view := radio.presentation()
				assert(view.who == partner and view.text == reply.text and view.emotion == reply.emotion)
				var expected := Portraits.expression(partner,reply.emotion,hard)
				assert(view.portrait.atlas == expected.atlas and view.portrait.region == expected.region)
				assert(view.progress >= previous)
				if time < 11.8: assert(view.progress == 0)
				if time > 11.9 and time < 13.3: assert(view.progress > 0 and view.progress < 1)
				if time >= 13.4: assert(is_equal_approx(view.progress,1.0))
				previous = view.progress
				if frame == 68:
					var clock: float = radio.line_clock
					var position: Vector2 = view.destination
					radio.advance(time+30,30,true)
					assert(radio.line_clock == clock and radio.presentation().destination == position)
					assert(radio.current.who == partner)
			radio.advance(16,0.05,false)
			assert(radio.current.event == "flush" and radio.presentation().destination == Vector2(110,452))
			assert(radio.presentation().scale == 1 and radio.presentations().size() == 1)
			# A skipped render interval keeps relocation on the response's authored timeline.
			radio.configure(story.routes[hero],hard,false)
			radio.advance(12.6,12.6,false)
			assert(radio.current.who == partner and radio.presentation().progress > 0 and radio.presentation().progress < 1)
			radio.configure(story.routes[hero],hard,true)
			for frame in range(320): radio.advance(frame*0.05,0.05,false)
			assert(radio.current.is_empty() and radio.entries.all(func(line: Dictionary) -> bool: return line.event != "arrival"))
			assert(radio.presentations().is_empty(),"Retry does not retain an invisible opening card")
			radio.clear()
			assert(radio.presentation().is_empty())
			radio.free()
	print("PASS: one shared panel across both heroes and all costumes; hero request/partner reply, exact portrait through relocation, pause, late frame, retry and bottom reset")
	quit()
