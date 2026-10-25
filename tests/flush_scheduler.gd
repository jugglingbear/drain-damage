extends SceneTree
const Debris = preload("res://scripts/flush_debris.gd")
const Flow = preload("res://scripts/flush_flow.gd")

class SilentAudio extends RefCounted:
	func play(_event: String) -> void: pass

class Swimmer extends RefCounted:
	var clock := 0.0
	var position := Vector2(0,259.2)
	var jump_height := 0.0
	var last_steering := Vector2.ZERO
	var damage_taken := 0
	var audio := SilentAudio.new()
	func project(point: Vector2) -> Vector2: return Vector2(480,300)+Vector2(point.x,point.y*140.0/360)

class Host extends Node2D:
	var employee := {"move_speed":235.0}
	var health := 100000
	var invulnerable := 0.0
	func hurt_player() -> void:
		if invulnerable > 0: return
		health -= 1
		invulnerable = 1.5

func _initialize() -> void:
	var source := OS.get_environment("FLUSH_LAYOUT")
	var layout: Dictionary
	if source.is_empty():
		layout = JSON.parse_string(FileAccess.get_file_as_string("res://data/level-two-flush.json")).layout
	else:
		layout = JSON.parse_string(FileAccess.get_file_as_string(source))
	var cases := 0
	var damage_totals := {}
	for mode in ["easy","normal","hard"]:
		for seed_value in range(20):
			for behavior in range(3):
				var model := Swimmer.new()
				var host := Host.new()
				var debris := Debris.new()
				debris.configure(layout,mode,seed_value)
				var observed: Dictionary = {}
				var last_falling := 0
				for frame in range(35*60+1):
					model.clock = float(frame)/60
					var steering := Vector2.ZERO
					if behavior == 1: steering = Vector2.from_angle(model.clock*0.7+seed_value)
					if behavior == 2: steering = -Vector2(-model.position.y,model.position.x).normalized()
					model.last_steering = steering
					model.position += (steering*235+Flow.velocity(model.position,model.clock,layout.difficulty[mode].flow))/60
					model.position = model.position.normalized()*clampf(model.position.length(),162,316.8)
					host.invulnerable = maxf(0,host.invulnerable-1.0/60)
					debris.advance(model,host,1.0/60)
					assert(debris.safety_failures == 0,"Every complete cohort needs a safe route")
					var falling := debris.falling_count(model.clock)
					if model.clock >= 8 and model.clock < 35: assert(falling >= 1 and falling <= 5)
					last_falling = falling
					for item: Dictionary in debris.items:
						observed[item.prop] = true
						assert(item.height > 0 and item.height <= 220)
						if not item.impacted: assert(item.pos == item.impact_pos)
				assert(last_falling == 0 and observed.size() == 8)
				assert(debris.spawned == {"easy":16,"normal":36,"hard":60}[mode])
				assert(debris.ledger.size() == layout.difficulty[mode].waves.size())
				var key: String = mode+"/"+str(behavior)
				damage_totals[key] = int(damage_totals.get(key,0))+(100000-host.health)
				host.free()
				cases += 1
	print("Damage totals over20seeds per mode/policy (0idle,1rotating,2countercurrent): "+JSON.stringify(damage_totals))
	print("PASS: %d seeded swimming paths, continuous falling counts, all eight props, safe whole cohorts and exact totals" % cases)
	quit()
