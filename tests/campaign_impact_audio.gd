extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	while not game.startup_complete: await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.dialogue.finish()
	game.dispenser.cancel()
	game.player = Vector2(500,394)
	game.camera_x = 0
	game.invulnerable = 10
	game.hostile_shots.assign([{"pos":Vector2(480,410),"dir":Vector2.RIGHT,"distance":0.0,"age":0.0}])
	var bank = game.creature_audio["sputtervalve"].actions
	var before: int = bank.starts.get("impact",0)
	game.step_hostile_projectiles(.2)
	assert(bank.starts.get("impact",0) == before+1,"Campaign collision dispatches approved impact")
	assert(game.hostile_shots.is_empty(),"Hit projectile retires")
	game.free()
	await create_timer(.3).timeout
	print("PASS: campaign impact hook")
	quit()
