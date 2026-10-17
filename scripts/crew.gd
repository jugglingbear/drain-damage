extends RefCounted
## Shared selection copy and weapon balance; character movement and contact-hit health are explicit per employee.

const COMPANY_NAME := "Mainframe Plumbing & Supply"

const Data = preload("res://scripts/combat_data.gd")

const TONY := {
	"id": "tony", "name": "TONY",
	"role": "4TH-GENERATION PLUMBER", "weapon": "PRESSURE GUN",
	"weapon_id": "pressure-gun",
	"max_health": 4, "move_speed": 270.0,
	"biography": "A fourth-generation plumber with decades of experience installing, building, and keeping essential systems running.",
	"traits": ["Agile", "Faster attacks", "Lower health"],
	"strength": "Fast shots. Quick corrections.", "weakness": "Light hits. Keep the pressure on.",
	"quote": "Fourth-generation plumber.\nLimitless experience.",
}
const SEAN := {
	"id": "sean", "name": "SEAN",
	"role": "IDIOT APPRENTICE", "weapon": "HEAVY PLUNGER",
	"weapon_id": "heavy-plunger-launcher",
	"max_health": 5, "move_speed": 235.0,
	"biography": "Sean wandered in looking for work. Tony gave him a chance. He’s still figuring out which tools are which.",
	"traits": ["Strong", "Slower attacks", "Higher health"],
	"strength": "One big hit. One dead toilet.", "weakness": "Slow reload. Make it count.",
	"quote": "Qualified to be here. Probably.",
}
const EMPLOYEES := [TONY, SEAN]

static func draw_boss(canvas: Node2D, area: Rect2, time: float) -> void:
	# An original CRT-faced company robot, drawn in the same chunky UI vocabulary as the logo.
	var unit := area.size / Vector2(100, 100)
	var shapes := [
		[Rect2(46, 1, 8, 17), Color("dca75e")],
		[Rect2(6, 19, 88, 65), Color("62798a")],
		[Rect2(11, 24, 78, 52), Color("111c2c")],
		[Rect2(17, 29, 66, 42), Color("183c42")],
		[Rect2(16, 85, 68, 15), Color("334555")],
		[Rect2(43, 85, 14, 15), Color("c36e64")],
	]
	for shape in shapes:
		var r: Rect2 = shape[0]
		canvas.draw_rect(Rect2(area.position + r.position * unit, r.size * unit), shape[1])
	var blink := fmod(time, 4.0) > 3.85
	for x in [28, 61]:
		canvas.draw_rect(Rect2(area.position + Vector2(x, 40) * unit,
			Vector2(12, 2 if blink else 8) * unit), Color("93ffd2"))
	canvas.draw_rect(Rect2(area.position + Vector2(34, 60) * unit, Vector2(32, 3) * unit), Color("93ffd2"))
