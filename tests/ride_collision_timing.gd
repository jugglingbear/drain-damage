extends SceneTree
const Ride = preload("res://scripts/level_two_ride.gd")
const STEP := 1.0/120.0

class Host extends Node2D:
	var paused := false
	var life_state := "alive"
	var health := 3
	var lives := 3
	var invulnerable := 0.0
	var hurt_time := 0.0
	var tone_time := 0.0
	var player := Vector2.ZERO
	var grounded := true
	var velocity := Vector2.ZERO
	var current_aim := Vector2.RIGHT
	var won := false
	func hurt_player() -> void:
		if invulnerable > 0 or life_state != "alive": return
		health -= 1
		invulnerable = 1.5
		if health <= 0:
			life_state = "dying"
			lives -= 1
	func play_tone(_frequency: float, _duration: float) -> void: pass

func obstacle(id: String, kind: String, x: float) -> Dictionary:
	return {"id":id,"kind":kind,"world_x":x,"y":330.0,"width":24.0,"depth":200.0}

func model(obstacles: Array) -> RefCounted:
	var ride := Ride.new()
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride.json"))
	ride.scroll_speed = float(layout.scroll_speed)
	ride.duration = float(layout.duration)
	ride.x_speed = float(layout.validation_physics.x_steer_speed)
	ride.bank_speed = float(layout.validation_physics.bank_steer_speed)
	assert(ride.scroll_speed == 280 and ride.x_speed == 200 and ride.bank_speed == 175)
	ride.course = {"obstacles":obstacles}
	return ride

func _initialize() -> void:
	# Immunity covers an overlap that ends before expiry, even though this step extends beyond expiry.
	var host := Host.new()
	var ride := model([obstacle("early","support",243.36)])
	host.invulnerable = 0.006
	ride.tick(host,STEP,Vector2.ZERO,false)
	assert(host.health == 3 and ride.events.get("hit",0) == 0)
	host.free()
	# First contact while immune latches the obstacle; expiry cannot cause a deferred hit.
	host = Host.new()
	ride = model([obstacle("continuous","support",300)])
	host.invulnerable = 0.006
	ride.tick(host,STEP,Vector2.ZERO,false)
	assert(host.health == 3 and ride.events.get("hit",0) == 0)
	assert(host.invulnerable == 0)
	host.free()
	# An earlier support hit grants immunity before the later gap recovery, regardless of array order.
	host = Host.new()
	ride = model([obstacle("gap","gap",300),obstacle("support","support",357.36)])
	ride.jump_age = 1.2-0.006
	ride.tick(host,STEP,Vector2.ZERO,false)
	assert(ride.events.hit == 1 and ride.events.recovered == 1 and host.lives == 3)
	assert(ride.hit_ids.has("support") and host.health == 2)
	ride.tick(host,STEP,Vector2.ZERO,false)
	assert(host.lives == 3 and ride.events.recovered == 1 and host.health == 2)
	host.free()
	# A low barrier becomes harmful on descent, not when its planar overlap began.
	host = Host.new()
	host.health = 1
	ride = model([obstacle("barrier","low_barrier",300),obstacle("support","support",357.36)])
	ride.jump_age = 0.6*(1.0+sqrt(1.0-28.0/72.0))-0.006
	ride.tick(host,STEP,Vector2.ZERO,false)
	assert(ride.hit_ids.has("support") and not ride.hit_ids.has("barrier"))
	assert(host.life_state == "dying" and host.lives == 2)
	host.free()
	# Exact endpoint landing over a gap triggers normal damage and recovery, never forced death.
	host = Host.new()
	ride = model([obstacle("gap","gap",300)])
	ride.jump_age = 1.2-STEP
	ride.tick(host,STEP,Vector2.ZERO,false)
	assert(host.life_state == "alive" and host.health == 2 and host.lives == 3)
	assert(ride.events.recovered == 1 and not ride.complete)
	host.free()
	# On ascent, immunity outlasting the below-barrier portion must not create a hit above the barrier.
	host = Host.new()
	ride = model([obstacle("ascending","low_barrier",300)])
	ride.jump_age = 0.6*(1.0-sqrt(1.0-28.0/72.0))-0.002
	host.invulnerable = 0.006
	ride.tick(host,STEP,Vector2.ZERO,false)
	assert(host.health == 3,"Immunity expiry after ascending clearance must not create a barrier hit")
	host.free()
	print("PASS: ride harmful-time ordering, exact gap recovery, immune traversal latch and ascending clearance")
	quit()
