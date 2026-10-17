extends Node2D
## Agent-only damage atlas preview; launch explicitly after permission for a visible window.
const Data = preload("res://scripts/combat_data.gd")
const Art = preload("res://scripts/damage_art.gd")
var art := Art.new()
var time := 0.0

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(960, 540)
	get_window().position = Vector2i(80, 80)
	art.prepare("toilet")
	art.prepare("spider")

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540), Color("172632"))
	draw_string(ThemeDB.fallback_font, Vector2(28,35), "DAMAGE ART REVIEW — Widow gutters / anchors provisional", 0, -1, 20)
	for row in range(2):
		var id: String = ["toilet", "spider"][row]
		for column in range(6):
			var enemy := Data.spawn(id, Vector2(0,404))
			enemy.hp = enemy.max_hp * [1.0, 0.75, 0.5, 0.25, 0.1, 0.0][column]
			enemy.phase = time * 4.5
			enemy.death_time = maxf(0, fmod(time, 3.0) - 0.5)
			enemy.flash = 0.04 if fmod(time, 1.5) < 0.06 else 0.0
			var anchor := Vector2(78 + column * 158, 195 + row * 235)
			art.draw(self, enemy, anchor, 0.48)
			art.draw(self, enemy, anchor + Vector2(0,60), 43.0 / 195.0)
			draw_string(ThemeDB.fallback_font, Vector2(anchor.x - 55, anchor.y - 115),
				Data.damage_state(enemy.hp, enemy.max_hp), 0, -1, 15)
