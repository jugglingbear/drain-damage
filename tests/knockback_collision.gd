extends SceneTree
const Base = preload("res://scripts/game.gd")
const Opening = preload("res://scripts/opening_trial_game.gd")
const Integrated = preload("res://scripts/integrated_first_call.gd")
const Trial = preload("res://scripts/three_screen_trial_game.gd")
const Section = preload("res://scripts/section_one_two_game.gd")
var count := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("checks")
func check(value: bool, message: String) -> void:
	count += 1
	if not value:
		failures.append(message)
		push_error(message)
func prepare(script: GDScript, hero: String) -> Node2D:
	var game = script.new()
	for employee in game.Crew.EMPLOYEES:
		if employee.id == hero: game.employee = employee
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.awaiting_release = false
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.restart_guard_device = -1
	return game
func place(game: Node2D, point: Vector2, on_ground: bool) -> void:
	game.player = point
	game.velocity = Vector2.ZERO
	game.grounded = on_ground
	game.health = game.employee.max_health
	game.invulnerable = 0
	game.life_state = "alive"
	game.paused = false
func impact(game: Node2D) -> void:
	var hp: int = game.health
	var lives: int = game.lives
	game.hurt_player()
	check(game.health == hp-1 and game.lives == lives,"Hit still costs one HP, not a life")
	check(is_equal_approx(game.invulnerable,1.5) and is_equal_approx(game.velocity.y,-220),
		"Invulnerability and upward impulse unchanged")
	var after: Vector2 = game.player
	game.hurt_player()
	check(game.health == hp-1 and game.player == after,"Repeated protected hit cannot shove or damage again")
func verify_scene(game: Node2D, custom: bool) -> void:
	var wall := Rect2(300,340,100,100)
	if custom:
		game.trial_level.plinths.assign([wall])
		game.trial_level.decks.clear()
	else:
		wall = game.Level.PROPS[0]
	for hz in [30,60,120]:
		for airborne in [false,true]:
			place(game,Vector2(wall.end.x+5,394 if not airborne else wall.position.y+5),not airborne)
			impact(game)
			check(is_equal_approx(game.player.x,wall.end.x),"Immediate shove stops on wall")
			for tick in range(hz):
				game.step_player(1.0/hz)
				check(not Rect2(game.player,game.PLAYER_SIZE).grow(-0.001).intersects(wall),
					"Hit follow-through never embeds hero at%sHz" % hz)
			# Another real hit at the same contact cannot push through after immunity expires.
			place(game,Vector2(wall.end.x,394),true)
			impact(game)
			check(is_equal_approx(game.player.x,wall.end.x),"Repeated exposed wall hit remains outside")
		if custom:
			var ceiling := Rect2(400,290,120,16)
			game.trial_level.plinths.assign([wall,ceiling])
			place(game,Vector2(405,310),false)
			impact(game)
			for tick in range(hz):
				game.step_player(1.0/hz)
				for solid in [wall,ceiling]:
					check(not Rect2(game.player,game.PLAYER_SIZE).grow(-0.001).intersects(solid),
						"Wall/ceiling corner resolves both axes")
			game.trial_level.plinths.assign([wall])
	place(game,Vector2(40,394),true)
	impact(game)
	check(is_equal_approx(game.player.x,22),"World-edge clamp preserved")
	place(game,Vector2(wall.end.x+100,394),true)
	impact(game)
	check(is_equal_approx(game.player.x,wall.end.x+55),"Unobstructed shove stays45pixels")
	if custom:
		game.trial_level.plinths.clear()
		game.trial_level.decks.assign([Rect2(300,320,200,16)])
		for hz in [30,60,120]:
			place(game,Vector2(430,330),false)
			impact(game)
			check(is_equal_approx(game.player.x,385),"Thin one-way platform does not become side wall")
			for tick in range(int(hz*0.15)): game.step_player(1.0/hz)
			check(game.player.y < 320,"Hit impulse passes upward through thin platform")
			place(game,Vector2(430,274),true)
			impact(game)
			for tick in range(hz): game.step_player(1.0/hz)
			check(game.grounded and is_equal_approx(game.player.y,274),"Hero lands back on one-way top after hit")
func checks() -> void:
	for script in [Base,Opening,Integrated,Trial,Section]:
		for hero in ["tony","sean"]:
			var game := prepare(script,hero)
			verify_scene(game,script != Base)
			root.remove_child(game)
			game.free()
	print("Knockback collision: %d checks, %d failures" % [count,failures.size()])
	quit(0 if failures.is_empty() else 1)
