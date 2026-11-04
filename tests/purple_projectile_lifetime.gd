extends SceneTree
## A visible purple bolt has no distance/age expiry; geometry and lifecycle still retire it.
const Opening = preload("res://scripts/opening_trial_game.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func bolt(position: Vector2, direction := Vector2.RIGHT) -> Dictionary:
	return {"id":"lifetime-fixture","pos":position,"dir":direction,"age":0.0}
func run_checks() -> void:
	var game := Opening.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dispenser.cancel()
	game.actors.clear()
	game.trial_level.plinths.clear()
	game.trial_level.decks.clear()
	game.player = Vector2(20,394)
	game.hostile_shots = [bolt(Vector2(450,200))]
	for tick in range(1200):
		game.camera_x = tick*150.0/120
		game.step_hostile_projectiles(1.0/120)
	check(game.hostile_shots.size() == 1,"Following camera keeps a ten-second visible bolt alive")
	if not game.hostile_shots.is_empty():
		check(game.hostile_shots[0].pos.x > 1900,"Purple bolt travels beyond former finite ranges")
		var age: float = game.hostile_shots[0].age
		game.paused = true
		game.step_hostile_projectiles(1)
		check(game.hostile_shots[0].age == age,"Paused projectile does not advance")
		game.paused = false
		game.camera_x = 0
		game.step_hostile_projectiles(1.0/120)
		check(game.hostile_shots.is_empty(),"Camera reversal retires a fully offscreen bolt")
	game.camera_x = 0
	var shape := game.purple_bolt_rect(Vector2.ZERO)
	for entry in [
		[Vector2(-shape.end.x+0.1,200),Vector2.LEFT],
		[Vector2(960-shape.position.x-0.1,200),Vector2.RIGHT],
		[Vector2(400,-shape.end.y+0.1),Vector2.UP],
		[Vector2(400,540-shape.position.y-0.1),Vector2.DOWN]]:
		game.hostile_shots = [bolt(entry[0],entry[1])]
		game.step_hostile_projectiles(0.0001)
		check(game.hostile_shots.size() == 1,"Partially visible sprite survives at viewport edge")
		game.step_hostile_projectiles(0.01)
		check(game.hostile_shots.is_empty(),"Fully exited sprite retires at viewport edge")
	game.player = Vector2(300,190)
	game.health = game.employee.max_health
	game.invulnerable = 0
	game.trial_level.plinths = [Rect2(200,100,30,200)]
	game.hostile_shots = [bolt(Vector2(100,210))]
	game.step_hostile_projectiles(2)
	check(game.hostile_shots.is_empty() and game.health == game.employee.max_health,
		"Nearest solid absorbs bolt before hero behind wall")
	game.trial_level.plinths.clear()
	game.hostile_shots = [bolt(Vector2(250,210))]
	game.step_hostile_projectiles(0.5)
	check(game.hostile_shots.is_empty() and game.health < game.employee.max_health,
		"Unobstructed hero impact retires bolt and damages once")
	game.hostile_shots = [bolt(Vector2(100,200))]
	game.reset_observation()
	check(game.hostile_shots.is_empty(),"Retry clears previous run projectiles")
	game.queue_free()
	await process_frame
	print("Purple projectile lifetime: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
