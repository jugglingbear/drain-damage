extends SceneTree
const Data = preload("res://scripts/combat_data.gd")
const Art = preload("res://scripts/damage_art.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	assert(Data.load_data())
	for pair in [[40,"healthy"],[30,"mild"],[20,"moderate"],[10,"severe"],[4,"near_death"],[0,"dead"],[-1,"dead"],[50,"healthy"]]:
		assert(Data.damage_state(pair[0],40) == pair[1])
	for pair in [[30.001,"healthy"],[20.001,"mild"],[10.001,"moderate"],[4.001,"severe"],[0.001,"near_death"]]:
		assert(Data.damage_state(pair[0],40) == pair[1])
	assert(Data.weapon("pressure-gun", "tony").damage == 6)
	assert(Data.weapon("pressure-gun", "sean").is_empty())
	assert(Data.weapon("missing", "tony").is_empty())
	assert(Data.weapon("pipe-wrench", "tony").is_empty())
	assert(Data.monster("missing").is_empty())
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	assert(game.health == 5 and not game.show_enemy_health_bars)
	for x in [680,1370,2150]: game.enemies.append(Data.spawn("toilet",Vector2(x,404)))
	game.damage_enemy(0,1,Vector2.ZERO)
	assert(game.enemies[0].hp == 39 and game.enemies[0].flash > 0)
	game.enemies[0].flash = 0
	game.damage_enemy(0,1,Vector2.ZERO)
	assert(game.enemies[0].hp == 38 and game.enemies[0].flash > 0)
	game.damage_enemy(0,100,Vector2.ZERO)
	assert(game.kills == 1 and game.corpses[0].hp == 0 and game.enemies.size() == 2)
	game.corpses[0].pos.y = 360
	game._process(0.5)
	assert(game.corpses[0].pos.y == 404, "Airborne deaths settle on the floor")
	var art := Art.new()
	for id in ["toilet", "spider"]:
		art.prepare(id)
		assert(art.regions[id].size() == 24)
		var dead := Data.spawn(id,Vector2.ZERO)
		dead.hp = 0
		dead.death_time = 0
		assert(art.frame_for(dead) == 20)
		dead.death_time = 100
		assert(art.frame_for(dead) == 23, "Death holds final frame instead of looping")
	game.reset_game()
	assert(game.corpses.is_empty() and game.enemies.is_empty())
	game.enemies.clear()
	game.shots.append({"pos":Vector2(100,100),"dir":1.0,"damage":6,"speed":760.0,"range":500.0,"distance":0.0})
	game.step_combat(0.5)
	assert(game.shots[0].distance == 380 and game.shots[0].pos.x == 480)
	game.step_combat(0.5)
	assert(game.shots.is_empty(), "Projectile expires at cumulative distance cap")
	game.enemies.append(Data.spawn("toilet",Vector2(650,404)))
	game.enemies[0].direction = 1.0
	game.shots.append({"pos":Vector2(100,420),"dir":1.0,"damage":40,"speed":760.0,"range":500.0,"distance":0.0})
	game.step_combat(1.0)
	assert(game.enemies[0].hp == 40, "Cannot hit beyond maximum range")
	game.enemies[0].pos = Vector2(300,404)
	game.enemies[0].home = 300
	game.shots.append({"pos":Vector2(100,420),"dir":1.0,"damage":40,"speed":760.0,"range":500.0,"distance":0.0})
	game.step_combat(0.5)
	assert(game.enemies.is_empty(), "Swept projectile hits crossed enemy")
	game.shots.append({"pos":Vector2(100,380),"dir":1.0,"damage":40,"speed":760.0,"range":500.0,"distance":0.0})
	game.step_combat(0.5)
	assert(game.shots.is_empty(), "Solid platform blocks projectile")
	game.queue_free()
	await process_frame
	print("PASS: metadata, ownership rejection, exact thresholds, hit feedback, death, reset, range, sweep, solids, atlas load")
	quit()
