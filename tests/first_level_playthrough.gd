extends SceneTree
const Crew = preload("res://scripts/crew.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var failures: Array[String] = []
	for person in Crew.EMPLOYEES:
		var game = load("res://scripts/game.gd").new()
		game.employee=person
		root.add_child(game)
		game.set_process(false)
		game.set_physics_process(false)
		game.dialogue.release_guard=0
		game.dialogue.awaiting_release=false
		Input.action_press("shoot")
		var frames := 0
		for frame in range(36000):
			frames=frame
			if game.life_state == "game_over": break
			if game.life_state == "death_popup" and not game.death_popup_locked:
				game.resume_or_retry()
			if game.life_state in ["dying", "death_popup"] or game.dialogue.awaiting_release \
				or game.dispenser.active or game.dispenser.actions_locked:
				Input.action_release("shoot")
			else: Input.action_press("shoot")
			var direction := 1.0
			var fight := false
			var target_distance := INF
			var target_height := 0.0
			for enemy in game.enemies:
				var distance: float = enemy.pos.x-game.player.x
				if absf(distance)<game.weapon.projectile.max_travel_distance_pixels-50 and absf(enemy.pos.y-game.player.y)<180:
					direction=signf(distance)
					fight=true
					target_distance = distance
					target_height = enemy.pos.y-game.player.y
					break
			Input.action_release("left")
			Input.action_release("right")
			if not fight: Input.action_press("right")
			else: game.facing=int(direction)
			Input.action_release("aim_down")
			if fight and absf(target_distance) < 135 and game.grounded:
				game.jump_buffer = 0.14
			if fight and not game.grounded and target_height > 40:
				Input.action_press("aim_down")
				if absf(target_distance) > 30:
					Input.action_press("right" if direction > 0 else "left")
			if game.grounded and not fight:
				for rect in game.Level.PROPS:
					var edge: float = rect.position.x-game.player.x-26
					if edge>=-1 and edge<8 and game.player.y+46>rect.position.y+1:
						game.jump_buffer=0.14
			game._process(1.0/60)
			game._physics_process(1.0/60)
			if game.won: break
		print("FINISH STATE ",person.id," position=",game.player," kills=",game.kills," stage=",game.mission.current_zone," enemies=",game.enemies.size())
		if not (game.won and game.kills == 30): failures.append(person.id)
		print("BOT ",person.id," seconds=",frames/60.0," zone_seconds=",game.zone_seconds," damage=",game.zone_damage)
		Input.action_release("shoot")
		Input.action_release("right")
		Input.action_release("left")
		Input.action_release("aim_down")
		game.queue_free()
		await process_frame
	if not failures.is_empty():
		print("FAIL: scripted full-route completion: ",failures)
		quit(1)
		return
	print("PASS: both heroes complete all30 using real movement, projectiles, gates and checkpoints")
	quit()
