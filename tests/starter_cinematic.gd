extends SceneTree
const Cinematic = preload("res://scripts/starter_cinematic.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/specials/activation-cinematics-v1/candidate-timeline.json"))
	for hero in ["tony","sean"]:
		var duration: float = candidate[hero].duration
		for hz in [30,60,120]:
			var clock := Cinematic.new()
			check(clock.begin(hero),"Valid activation accepted")
			var frames := roundi(duration*hz)
			for frame in range(frames-1):
				clock.advance(1.0/hz)
				check(clock.active and clock.take_completion().is_empty(),"No early frame completion")
			clock.advance(1.0/hz)
			check(not clock.active and clock.elapsed == duration,"Exact final frame clamps to authored duration")
			check(not clock.begin(hero),"Unconsumed completion cannot be overwritten")
			check(clock.take_completion() == hero,"Completion identifies hero once")
			clock.advance(100)
			check(clock.elapsed == duration and clock.take_completion().is_empty(),"No overshoot or duplicate completion")
			check(clock.begin(hero) and clock.elapsed == 0,"Next activation has a fresh clock")
		var clock := Cinematic.new()
		clock.begin(hero)
		clock.advance(0.21)
		check(not clock.begin("sean" if hero == "tony" else "tony"),"Active activation rejects another hero")
		check(clock.hero_id == hero and clock.elapsed == 0.21,"Rejected begin preserves current activation")
		clock.advance(100,true)
		check(clock.active and clock.elapsed == 0.21,"Pause freezes presentation without queuing time")
		for delta in [0.0,-1.0,INF,-INF,NAN]: clock.advance(delta)
		check(clock.active and clock.elapsed == 0.21,"Invalid deltas cannot advance or poison clock")
		for delta in [0.013,0.071,0.6,0.005]: clock.advance(delta)
		check(clock.active and is_equal_approx(clock.elapsed,0.899),"Variable frame steps accumulate presentation only")
		clock.advance(100)
		check(not clock.active and clock.elapsed == duration,"Large step discards overshoot")
		check(clock.take_completion() == hero and clock.take_completion().is_empty(),"Large-step completion consumed once")
		clock.begin(hero)
		clock.advance(duration-0.000001)
		check(clock.active and clock.take_completion().is_empty(),"Sub-frame time before endpoint stays active")
		clock.advance(0.000001)
		check(clock.elapsed == duration and clock.take_completion() == hero,"Remainder completes at endpoint")
		for cancel_at in [0.0,0.5,duration]:
			clock.begin(hero)
			clock.advance(cancel_at)
			clock.cancel()
			clock.advance(100)
			check(not clock.active and clock.elapsed == 0 and clock.hero_id.is_empty(),"Cancel resets presentation")
			check(clock.take_completion().is_empty(),"Cancel suppresses even pending handoff")
			clock.cancel()
		var fresh := Cinematic.new()
		check(not fresh.begin("") and not fresh.begin("unknown"),"Unknown heroes rejected")
		check(not fresh.active and fresh.hero_id.is_empty() and fresh.elapsed == 0,"Invalid begin leaves idle state intact")
	print("Starter cinematic: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
