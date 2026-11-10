extends SceneTree
var failures: Array[String] = []
var checks := 0

class Probe extends "res://scripts/starter_specials.gd":
	func water_segments(_host: Node2D) -> Array[Dictionary]:
		var result: Array[Dictionary] = []
		if water_width() > .01: result.append({"time":elapsed,"angle":pipe_angle()})
		return result

class Audio extends RefCounted:
	func advance(_dt: float) -> void: pass
	func stop() -> void: pass

class Art extends RefCounted:
	func spent_variant(_state: Dictionary, _solids: Array[Rect2]) -> String: return "normal"

class Host extends Node2D:
	var life_state := "alive"
	var special_audio := Audio.new()
	var special_art := Art.new()
	var total := 0.0
	var boss_damage := 0.0
	var times: Array[float] = []
	func specials_allowed(_active := false) -> bool: return true
	func special_solids() -> Array[Rect2]: return []
	func special_damage(segments: Array[Dictionary], amount: float, _activation: int, budget: Dictionary) -> Dictionary:
		total += amount
		times.append(segments[0].time)
		var accepted := float(budget.skitterling)
		boss_damage += accepted
		return {"skitterling":accepted}

func _initialize() -> void:
	for hero in ["tony","sean"]:
		for steps in [[1.0/30],[1.0/60],[1.0/120],[.017,.24,.043,.6],[7.5]]:
			var probe := Probe.new()
			var host := Host.new()
			probe.hero_id = hero
			probe.active = true
			var index := 0
			while probe.active and index < 1000:
				probe.step(host,steps[index%steps.size()])
				index += 1
			var label: String = hero+" "+str(steps)
			check(not probe.active,"Ends on time: "+label)
			check(probe.tick_serial == 75,"75 scheduled ticks: "+label)
			check(host.times.size() == (74 if hero == "tony" else 65),"Visible tick count: "+label)
			check(host.total == (1776 if hero == "tony" else 1560),"Uncapped potential independent of timestep: "+label)
			check(host.boss_damage == host.total*0.5 and probe.boss_used.skitterling == host.boss_damage,
				"Uncapped boss damage stays at half regular damage beyond250: "+label)
			check(is_equal_approx(host.times[0],.1 if hero == "tony" else 1.0),"First eligible tick boundary: "+label)
			check(is_equal_approx(host.times.back(),7.4),"Zero-width endpoint does not hit: "+label)
			for tick in range(1,host.times.size()):
				check(is_equal_approx(host.times[tick]-host.times[tick-1],.1),"Every eligible tick stays0.10s apart")
			host.free()
	print("Special tick boundaries: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)
