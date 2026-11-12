extends SceneTree
const Specials = preload("res://scripts/starter_specials.gd")
const Campaign = preload("res://scripts/campaign_encounters.gd")
var checks := 0
var failures := 0
class Audio extends RefCounted:
	func begin(_hero: String) -> void: pass
	func advance(_delta: float) -> void: pass
	func stop() -> void: pass
class Art extends RefCounted:
	func spent_variant(_state: Dictionary, _solids: Array[Rect2]) -> String: return "rain_compact"
class Host extends Node2D:
	var campaign := Campaign.new()
	var player := Vector2(1993,274)
	var facing := 1.0
	var grounded := true
	var life_state := "alive"
	var paused := false
	var special_audio := Audio.new()
	var special_art := Art.new()
	var world_art := {"hero_aim_art":{"costume":"normal"}}
	var ticks: Array[float] = []
	func specials_allowed(_ignore := false) -> bool: return not paused
	func special_pipe_clear(_point: Vector2) -> bool: return true
	func special_solids() -> Array[Rect2]:
		var result := campaign.level.projectile_solids()
		result.append_array(campaign.level.floor_solids())
		return result
	func actor_solids() -> Array[Rect2]: return campaign.level.actor_solids()
	func special_rain_damage(amount: float, _activation: int, _tick: int, _remainders: Dictionary) -> Dictionary:
		ticks.append(amount)
		return {}

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run_checks")
func run_checks() -> void:
	for spent in [false,true]:
		for rate in [30,60,120]:
			var host := Host.new()
			host.campaign.reset("normal",85,42)
			var special := Specials.new()
			special.configure("sean","test")
			check(special.begin(host),"Accepted fixture cast")
			special.step(host,0.2)
			check(special.anchor == Vector2(2050,320),"Intact live support keeps pipe anchored")
			if spent:
				special.retire_pipe(host)
				special.active = false
			var props = host.campaign.level.platforms
			props.damage("entry-machine-1",54)
			props.advance(0.219)
			host.campaign.level.refresh_platforms()
			special.step(host,0.01)
			check((special.spent_pipes[0].anchor if spent else special.anchor).y == 320,"No fall before actual support release")
			props.advance(0.001)
			host.campaign.level.refresh_platforms()
			host.paused = true
			special.step(host,1)
			check((special.spent_pipes[0].anchor if spent else special.anchor).y == 320,"Pause freezes unsupported pipe")
			host.paused = false
			special.presentation_host = weakref(host)
			special.step(host,1)
			check((special.spent_pipes[0].anchor if spent else special.anchor).y == 320,"Cinematic freezes unsupported pipe")
			special.presentation_host = null
			special.step(host,1.0/rate)
			var first: Vector2 = special.spent_pipes[0].anchor if spent else special.anchor
			check(first.y > 320 and first.y < 322 and first.x == 2050,"Release starts a continuous vertical fall")
			for tick in range(rate): special.step(host,1.0/rate)
			var final: Vector2 = special.spent_pipes[0].anchor if spent else special.anchor
			check(final == Vector2(2050,440),"Active/spent pipe lands on real floor without tunneling")
			if spent:
				check(special.spent_pipes[0].spent_variant == "rain_compact" and special.spent_pipes[0].facing == 1,
					"Falling preserves collapse variant and facing")
			else:
				special.step(host,8)
				check(host.ticks == [37.5,37.5,37.5,37.5,37.5,37.5,37.5],"Pipe falling leaves rain cadence/damage unchanged")
			check(special.remaining() == 1,"Support loss never refunds a special")
			host.free()
	check_retirement()
	print("Pipe support release: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)

func check_retirement() -> void:
	var host := Host.new()
	host.campaign.reset("normal",85,42)
	var special := Specials.new()
	special.configure("sean","test")
	special.begin(host)
	host.campaign.level.platforms.damage("entry-machine-1",54)
	host.campaign.level.platforms.advance(0.22)
	host.campaign.level.refresh_platforms()
	special.elapsed = 7.45
	special.tick_serial = 7
	special.pipe_fall_speed = 100
	special.step(host,0.1)
	var pipe: Dictionary = special.spent_pipes[0]
	check(not special.active and is_equal_approx(pipe.fall_speed,225),"Retirement transfers velocity and integrates overshoot")
	check(is_equal_approx(pipe.anchor.y,336.25) and is_equal_approx(pipe.spent_age,0.05),"Retirement preserves continuous fall and collapse age")
	var state := {"anchor":Vector2(500,100),"fall_speed":0.0}
	var narrow: Array[Rect2] = [Rect2(490,150,20,20),Rect2(0,440,1000,100)]
	special.fall_pipe(state,2,narrow)
	check(state.anchor == Vector2(500,440),"Tiny partial shelf cannot suspend wide pipe; large step clamps to floor")
	var joined: Array[Rect2] = [Rect2(450,200,50,20),Rect2(500,200,50,20)]
	state = {"anchor":Vector2(500,100),"fall_speed":0.0}
	special.fall_pipe(state,1,joined)
	check(state.anchor == Vector2(500,200),"Adjacent real solids jointly support registered base")
	host.free()
