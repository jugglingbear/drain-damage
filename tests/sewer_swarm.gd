extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var swarm = game.swarms
	assert(swarm.actors.size() == 2)
	assert(swarm.texture != null)
	for animation: Dictionary in swarm.definition.animation.animations.values():
		for frame: Dictionary in animation.frames:
			var rect: Array = frame.source_rect
			assert(rect[0] >= 0 and rect[1] >= 0 and rect[0]+rect[2] <= swarm.texture.get_width()
				and rect[1]+rect[3] <= swarm.texture.get_height())
	for actor in swarm.actors:
		assert(actor.pos.x-32 > 960)
	game.mission.current_zone = 1
	game.player.x = 2100
	game.step_encounters(0)
	assert(not game.encounter_triggered[1])
	game.player.x = 2270
	game.step_encounters(0)
	assert(game.encounter_triggered[1])
	game.reset_game()
	var region := Rect2(0,0,260,220)
	var paths := 0
	for seed_value in range(20):
		var a: Dictionary = swarm.spawn(Vector2(40,40),region,seed_value)
		var b: Dictionary = swarm.spawn(Vector2(40,40),region,seed_value)
		for tick in range(7200):
			# Door opens midway, presenting changed geometry without changing the RNG stream.
			var solids: Array[Rect2] = [Rect2(120,80,30,140 if tick < 3600 else 40)]
			swarm.step_motion(a,1.0/120,solids)
			swarm.step_motion(b,1.0/120,solids)
			assert(a.pos == b.pos and a.animation == b.animation)
			assert(region.grow(-16).has_point(a.pos))
			assert(not solids[0].grow(16).has_point(a.pos), str([seed_value,tick,a.pos,a.velocity,solids]))
			assert(a.velocity.length() <= 35.01)
		paths += 1
	var trapped: Dictionary = swarm.spawn(Vector2(50,50),Rect2(0,0,100,100),1)
	var walls: Array[Rect2] = [Rect2(25,0,5,100),Rect2(70,0,5,100),Rect2(0,25,100,5),Rect2(0,70,100,5)]
	for tick in range(240): swarm.step_motion(trapped,1.0/120,walls)
	assert(trapped.blocked)
	var old: Vector2 = trapped.pos
	var empty: Array[Rect2] = []
	for tick in range(240): swarm.step_motion(trapped,1.0/120,empty)
	assert(trapped.pos.distance_to(old) > 4 and not trapped.blocked)
	var phase: Dictionary = swarm.spawn(Vector2(50,50),region,1)
	phase.clock = 0.3
	phase.velocity = Vector2(20,21)
	swarm.select_animation(phase)
	assert(phase.animation == "move_right" and phase.clock == 0.3)
	phase.velocity = Vector2(20,25)
	swarm.select_animation(phase)
	assert(phase.animation == "move_down" and phase.clock == 0.3)
	phase.velocity = Vector2(1,1)
	swarm.select_animation(phase)
	assert(phase.animation == "hover")
	game.player = Vector2(1100,394)
	game.invulnerable = 0
	game.health = 5
	var overlap: Vector2 = game.player+Vector2(13,5)
	swarm.actors.assign([swarm.spawn(overlap,Rect2(1000,200,330,240),1),
		swarm.spawn(overlap,Rect2(1000,200,330,240),2)])
	swarm.step(game,0)
	assert(game.health == 4 and swarm.hero_cooldown == 1.5)
	game.player = Vector2(1100,394)
	game.invulnerable = 0
	swarm.step(game,0)
	assert(game.health == 4)
	# A living monster has one cooldown shared across both overlapping swarms.
	game.enemies.clear()
	var living: Dictionary = game.Data.spawn("toilet",Vector2(1100,390))
	game.enemies.append(living)
	game.invulnerable = 10
	swarm.step(game,0)
	assert(living.hp == 34)
	swarm.step(game,0)
	assert(living.hp == 34)
	living.swarm_cooldown = 0.01
	swarm.step(game,0.005)
	assert(living.hp == 34)
	swarm.step(game,0.006)
	assert(living.hp == 28)
	living.swarm_cooldown = 0
	living.invulnerable = 1.0
	swarm.step(game,0)
	assert(living.hp == 28)
	living.invulnerable = 0.0
	living.is_boss = true
	swarm.step(game,0)
	assert(living.hp == 28)
	# Environmental kills go through encounter accounting without player kill credit.
	game.enemies.clear()
	var enemy: Dictionary = game.Data.spawn("toilet",Vector2(1100,390))
	enemy.mission_id = game.mission.register_spawn()
	enemy.hp = 6
	game.enemies.append(enemy)
	game.invulnerable = 10
	swarm.step(game,0)
	assert(game.enemies.is_empty() and game.mission.defeated[0] == 1 and game.player_kills == 0)
	assert(swarm.actors[0].hp == 12 and swarm.actors[1].hp == 12)
	swarm.damage(0,6)
	assert(swarm.actors[0].hp == 6)
	swarm.damage(0,6)
	assert(swarm.actors[0].hp == 0 and swarm.shot_hit(overlap,overlap,0,2) < 0)
	swarm.damage(1,24)
	assert(swarm.actors[1].hp == 0)
	game.respawn_after_death()
	assert(swarm.actors[0].hp == 0)
	game.set_paused(true)
	var clock: float = swarm.actors[0].clock
	game._physics_process(1)
	assert(swarm.actors[0].clock == clock)
	game.reset_game()
	# Actual projectiles damage one shared core, with current hero damage and range.
	for person in game.Crew.EMPLOYEES:
		game.employee = person
		game.reset_game()
		var actor: Dictionary = swarm.actors[0]
		var hits := 1 if person.id == "sean" else 2
		for hit in range(hits):
			game.shots.append({"pos":actor.pos-Vector2(50,0), "dir":Vector2.RIGHT, "damage":game.weapon.damage,
				"speed":1000, "distance":0.0, "range":game.weapon.projectile.max_travel_distance_pixels})
			game.step_combat(0.1)
			assert(game.shots.is_empty())
		assert(actor.hp == 0 and game.kills == 0 and game.mission.current_zone == 0)
		var solids: Array[Rect2] = []
		swarm.step_motion(actor,0.65,solids)
		assert(actor.death >= 0.64)
	game.reset_game()
	assert(swarm.actors.size() == 2 and swarm.actors[0].hp == 12)
	print("PASS: ",paths," seeded 60-second paths, doors/corners, animation, contact sharing, gate credit, death and lifecycle")
	game.queue_free()
	quit()
