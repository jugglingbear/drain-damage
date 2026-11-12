extends SceneTree
## Pure scheduler checks; target eligibility and host weapon input have separate integration owners.
const Specials = preload("res://scripts/starter_specials.gd")
class Audio extends RefCounted:
	var active := false
	func begin(_hero: String) -> void: active = true
	func begin_from_cinematic(_hero: String, _controller = null) -> void: active = true
	func advance(_delta: float) -> void: pass
	func stop() -> void: active = false
	func empty() -> void: pass
class Art extends RefCounted:
	func spent_variant(_state: Dictionary, _solids: Array[Rect2]) -> String: return "normal"
class Host extends Node2D:
	var player := Vector2(120,394)
	var facing := 1.0
	var grounded := true
	var life_state := "alive"
	var paused := false
	var cinematic := false
	var world_art := {"hero_aim_art":{"costume":"normal"}}
	var cinematic_audio = null
	var special_art := Art.new()
	var special_audio := Audio.new()
	func special_solids() -> Array[Rect2]: return []
	var calls: Array[Dictionary] = []
	func specials_allowed(_ignore_active := false) -> bool:
		return not paused and not cinematic and life_state == "alive"
	func special_pipe_clear(_point: Vector2) -> bool: return true
	func start_special_cinematic() -> void: cinematic = true
	func cancel_special_cinematic() -> void: cinematic = false
	func special_rain_damage(amount: float, activation: int, tick: int, _remainders: Dictionary) -> Dictionary:
		calls.append({"amount":amount,"activation":activation,"tick":tick})
		return {}

var failures: Array[String] = []
var checks_run := 0
func check(value: bool, message: String) -> void:
	checks_run += 1
	if not value:
		failures.append(message)
		push_error(message)
func _initialize() -> void: call_deferred("run_checks")

func start(host: Host) -> RefCounted:
	var special := Specials.new()
	special.configure("sean","rain-test")
	check(special.begin(host,true),"Accepted grounded activation")
	check(special.remaining() == 1,"Activation spends exactly one charge")
	special.step(host,4)
	check(special.elapsed == 0 and host.calls.is_empty(),"Cinematic freezes effect and damage")
	host.cinematic = false
	special.resume_from_cinematic(host)
	check(special.elapsed == 0 and host.calls.is_empty(),"Handoff starts fresh seven-and-half-second clock")
	return special

func run_checks() -> void:
	for rate in [30,60,120]:
		var host := Host.new()
		var special := start(host)
		check(not special.rooted(),"Sean moves immediately after cinematic")
		check(special.movement_speed(-1,235,Vector2.RIGHT) == -235,"Sean keeps ordinary movement speed")
		for frame in range(rate*15/2):
			special.step(host,1.0/rate)
			var expected := mini(7,int(floor((frame+1)/float(rate)+0.000001)))
			check(host.calls.size() == expected,"Integer rain cadence at %d Hz frame%d" % [rate,frame])
		check(not special.active and is_equal_approx(special.elapsed,7.5),"Expiry exactly7.5 after handoff")
		check(host.calls.size() == 7,"Seven full ticks, no partial final tick")
		for index in range(host.calls.size()):
			check(host.calls[index].tick == index+1 and host.calls[index].amount == 37.5,
				"Sequential whole ticks carry37.5 damage")
			check(host.calls[index].activation == special.activation_id,"Stable activation identity")
		special.step(host,10)
		check(host.calls.size() == 7,"No damage after expiry")
		host.free()
	var host := Host.new()
	var special := start(host)
	special.step(host,0.999)
	check(host.calls.is_empty(),"No immediate damage or early first tick")
	host.paused = true
	special.step(host,20)
	check(is_equal_approx(special.elapsed,0.999) and host.calls.is_empty(),"Pause does not advance rain")
	host.paused = false
	special.step(host,0.001)
	check(host.calls.size() == 1,"First tick exactly one second")
	special.cancel("retry")
	check(not special.active and special.remaining() == 1,"Cancellation never refunds charge")
	special.step(host,20)
	check(host.calls.size() == 1,"Cancelled rain cannot dispatch later")
	host.calls.clear()
	check(special.begin(host,true),"Second activation accepted")
	host.cinematic = false
	special.resume_from_cinematic(host)
	special.step(host,3.25)
	check(host.calls.size() == 3,"Large gameplay delta processes each genuinely elapsed interval once")
	for index in range(host.calls.size()):
		check(host.calls[index].tick == index+1,"Large delta retains distinct ordered tick identities")
	var delivered := host.calls.size()
	for frame in range(10): special.step(host,0.01)
	check(host.calls.size() == delivered,"Already processed intervals cannot replay on following frames")
	host.life_state = "dying"
	special.step(host,0.1)
	check(not special.active and special.remaining() == 0,"Death cancels without refund")
	host.free()
	print("Main Break rain timeline: %d checks, %d failures" % [checks_run,failures.size()])
	quit(0 if failures.is_empty() else 1)
