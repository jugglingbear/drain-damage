extends RefCounted
## Presentation only: atlas frames stay independent of the existing collision geometry.

const DamageArt = preload("res://scripts/damage_art.gd")
var damage_art := DamageArt.new()
const HeroAimArt = preload("res://scripts/hero_aim_art.gd")
var hero_aim_art := HeroAimArt.new()

const BACKGROUND = preload("res://assets/world/basement-v1.png")
const SEAN = preload("res://assets/sprites/sean-v3.png")
const TONY = preload("res://assets/sprites/tony-v1.png")
const TOILET = preload("res://assets/sprites/toilet-v1.png")
const SEAN_HEIGHT := 72.0
# Generated poses cross uniform cell boundaries. Explicit search areas exclude neighboring limbs.
const SEAN_AREAS: Array[Rect2i] = [
	Rect2i(0, 150, 310, 460), Rect2i(312, 150, 312, 460),
	Rect2i(640, 150, 304, 460), Rect2i(945, 150, 309, 460),
	Rect2i(0, 730, 310, 430), Rect2i(340, 680, 277, 360),
	Rect2i(615, 740, 340, 420), Rect2i(956, 740, 298, 420),
]
var sean_frames: Array[Rect2] = []
var tony_frames: Array[Rect2] = []
var toilet_frames: Array[Rect2] = []

func _init() -> void:
	var image := SEAN.get_image()
	for area in SEAN_AREAS:
		sean_frames.append(opaque_region(image, area))
	tony_frames = atlas_regions(TONY, 4, 2)
	toilet_frames = atlas_regions(TOILET, 2, 2)

func atlas_regions(texture: Texture2D, columns: int, rows: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var image := texture.get_image()
	var cell := Vector2i(image.get_width() / columns, image.get_height() / rows)
	for row in range(rows):
		for column in range(columns):
			var origin := Vector2i(column, row) * cell
			result.append(opaque_region(image, Rect2i(origin, cell)))
	return result

func opaque_region(image: Image, area: Rect2i) -> Rect2:
	# Ignore nearly transparent generation fringes when aligning frames to their feet.
	var minimum := area.end
	var maximum := area.position
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if image.get_pixel(x, y).a > 0.2:
				minimum = minimum.min(Vector2i(x, y))
				maximum = maximum.max(Vector2i(x + 1, y + 1))
	return Rect2(minimum, maximum - minimum)

func sprite(game: Node2D, texture: Texture2D, region: Rect2, feet: Vector2,
		scale: float, flip: bool, tint := Color.WHITE) -> void:
	var size := region.size * scale
	var destination := Rect2(Vector2(floorf(feet.x - size.x / 2), floorf(feet.y - size.y)), size)
	# Negative destination width mirrors the atlas region without changing its foot anchor.
	if flip:
		destination.size.x = -destination.size.x
	game.draw_texture_rect_region(texture, destination, region, tint)

func draw_sean(game: Node2D) -> void:
	var feet: Vector2 = game.player + Vector2(13, 46)
	game.draw_ellipse_shadow(feet, Vector2(23, 3))
	hero_aim_art.draw(game)

func draw_toilet(game: Node2D, enemy: Dictionary) -> void:
	game.draw_ellipse_shadow(Vector2(enemy.pos.x + 19, 440), Vector2(20, 3))
	damage_art.draw(game, enemy, enemy.pos + Vector2(19, 36), 43.0 / game.Data.monster(enemy.id).damage_art.runtime_preparation.reference_body_height_pixels)
	var bar: Dictionary = game.Data.monster(enemy.id).health.bar
	if enemy.hp > 0 and bar.enabled and (game.show_enemy_health_bars or bar.visible_by_default):
		game.box(enemy.pos.x, enemy.pos.y - 14, 38, 4, Color("243447"))
		game.box(enemy.pos.x, enemy.pos.y - 14, 38 * enemy.hp / enemy.max_hp, 4, game.MINT)

func draw_room(game: Node2D) -> void:
	# Background moves more slowly than the walkable world, giving the room depth.
	var offset: float = game.camera_x * 0.65
	for tile in range(int(game.camera_x * 0.35 / 720) - 1, int(game.camera_x * 0.35 / 720) + 3):
		game.draw_texture_rect(BACKGROUND, Rect2(tile * 720 + offset, -40, 720, 480), false)
	for x in range(20, int(game.WORLD_WIDTH), 480):
		game.box(x, 70, 9, 370, Color("152b32"))
		game.box(x + 2, 70, 2, 370, Color("496064"))
		for y in [160, 290, 420]:
			game.box(x - 3, y, 15, 7, Color("657572"))
	# A single company sign; subsequent markers describe their location.
	for index in range(3):
		var x := 105 + index * 820
		game.box(x, 205, 220, 43, Color("080f17"))
		game.box(x + 2, 207, 216, 39, Color("263c43"))
		game.box(x + 5, 210, 2, 2, game.GOLD)
		game.box(x + 213, 239, 2, 2, game.GOLD)
		game.label_at([game.Crew.COMPANY_NAME, "02 / PRESSURE WORKS", "03 / MAINTENANCE →"][index],
			Vector2(x + 12, 223), 10 if index == 0 else 12, game.MINT)
		game.label_at(["NO JOB TOO SHITTY.", "CAUTION: BAD PRESSURE", "KEEP THE EXIT CLEAR"][index],
			Vector2(x + 12, 239), 11, game.GOLD)
	game.box(0, 440, int(game.WORLD_WIDTH), 100, Color("101d25"))
	game.box(0, 440, int(game.WORLD_WIDTH), 3, Color("aac1b1"))
	game.box(0, 443, int(game.WORLD_WIDTH), 9, Color("536a68"))
	game.box(0, 452, int(game.WORLD_WIDTH), 3, Color("090f18"))
	for x in range(0, int(game.WORLD_WIDTH), 24):
		game.box(x + 2, 445, 12, 3, Color("a69054"))
		game.box(x + 3, 461, 18, 2, Color("26353d"))
		game.box(x + 4, 470, 2, 7, Color("1d2b33"))
	for x in range(90, int(game.WORLD_WIDTH), 340):
		game.box(x, 489, 96, 3, Color("264751"))
		game.box(x + 13, 487, 53, 2, Color("3b666c"))
		game.box(x + 22, 494, 79, 1, Color("213640"))
	game.dispenser.draw_machines(game)
	game.draw_set_transform(Vector2(9450-2300-floorf(game.camera_x),0))
	game.box(2295, 313, 85, 127, Color("536a67"))
	game.box(2300, 318, 75, 122, Color("172c33"))
	game.box(2307, 326, 60, 114, Color("30484b"))
	for y in range(340, 390, 8):
		game.box(2314, y, 45, 3, Color("1b3035"))
	game.box(2311, 296, 50, 15, Color("1d4d42"))
	game.label_at("EXIT →", Vector2(2315, 307), 10, game.MINT)
	game.box(2354, 400, 5, 4, game.GOLD)
	game.draw_set_transform(Vector2(-floorf(game.camera_x),0))
	# Small animated drips stay behind actors and do not imply a damaging hazard.
	for index in range(9):
		var x := 180 + index * 257
		var y := 110 + fmod(game.elapsed * 75 + index * 47, 315)
		game.box(x, y, 1, 4, Color(0.4, 0.75, 0.78, 0.35))

func draw_platform(game: Node2D, platform: Rect2) -> void:
	var x := platform.position.x
	var y := platform.position.y
	game.draw_rect(platform, Color("25373c"))
	game.box(x, y, platform.size.x, 3, Color("b2d3bd"))
	game.box(x, y + 3, platform.size.x, 4, Color("5d8b82"))
	game.box(x, y + 14, platform.size.x, 2, Color("0c171f"))
	for bolt_x in range(int(x) + 6, int(platform.end.x) - 5, 18):
		game.box(bolt_x, y + 8, 3, 3, Color("83948a"))
		game.box(bolt_x + 5, y + 8, 7, 4, Color("101f28"))
	for brace_x in [x + 8, platform.end.x - 16]:
		game.box(brace_x, y + 16, 6, 14, Color("35494b"))
		game.box(brace_x + 1, y + 16, 2, 11, Color("697c73"))
