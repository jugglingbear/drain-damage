extends SceneTree
const HUD = preload("res://scripts/special_hud.gd")
const Crew = preload("res://scripts/crew.gd")
class Budget extends RefCounted:
	var count := 2
	func remaining() -> int: return count
class Host extends Node2D:
	var employee: Dictionary
	var specials := Budget.new()

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var host := Host.new()
	var hud := HUD.new()
	var checks_run := 0
	for hero in Crew.EMPLOYEES:
		host.employee = hero
		for theme in ["dispenser","chain","rubber-ducks"]:
			var origin := Vector2(630,8) if theme == "dispenser" else Vector2(550,4)
			var bounds := Rect2(origin+Vector2(-40,0),Vector2(40,54))
			for count in range(3):
				host.specials.count = count
				var commands := hud.commands(host,origin,theme)
				assert(commands.size() == 5)
				assert(commands[2].weapon == (hero.weapon_id if theme == "dispenser" else "fidget"))
				var filled := 0
				for command in commands:
					assert(bounds.encloses(command.rect))
					assert(not command.rect.intersects(Rect2(origin,Vector2(160,56))))
					assert(command.texture is Texture2D and command.texture.get_width() > 0)
					if command.kind == "charge" and command.filled: filled += 1
					checks_run += 3
				assert(filled == count)
				assert(is_equal_approx(commands[3].rect.end.y,commands[4].rect.end.y))
				checks_run += 4
	host.free()
	print("Special HUD: %d checks, both heroes/all themes/2-1-0 states PASS" % checks_run)
	quit()
