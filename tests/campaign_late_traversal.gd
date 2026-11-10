extends SceneTree
## Continuous later-route physics; actual route traversal is not balance acceptance.
const Game = preload("res://scripts/integrated_first_call.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value and message not in failures:
		failures.append(message)
		push_error(message)

func run_checks() -> void:
	for hero in [0,1]:
		for hz in [60,120]:
			var game = Game.new()
			game.employee = game.Crew.EMPLOYEES[hero]
			game.difficulty = "normal"
			game.seed_override = 42
			root.add_child(game)
			game.hide()
			game.set_process(false)
			game.set_physics_process(false)
			game.checkpoint_index = 0
			game.checkpoint_active = true
			game.post_skitterling_checkpoint = true
			game.respawn_point = Vector2(7650,394)
			game.respawn_origin = 7650
			game.reset_observation()
			game.dispenser.cancel()
			game.dialogue.finish()
			game.dialogue.release_guard = 0
			game.dialogue.awaiting_release = false
			game.player = Vector2(9450,394)
			game.camera_x = 9130
			game.velocity = Vector2.ZERO
			game.grounded = true
			game.invulnerable = 0
			game.campaign.expire(9450)
			var seen := {}
			var devil_active := false
			var surfaces := {}
			var damage_hits := 0
			var damage_total := 0
			var pit_airborne := false
			var pit_landed := false
			var peak := 0
			Input.action_press("right")
			Input.action_press("shoot")
			for tick in range(hz*90):
				if game.grounded:
					for pit in game.campaign.level.pits:
						if game.player.x+game.PLAYER_SIZE.x >= pit.x-15 and game.player.x < pit.y:
							game.jump_buffer = 0.14
					var supports: Array = game.trial_level.plinths.duplicate()
					supports.append_array(game.trial_level.decks)
					for solid: Rect2 in supports:
						var gap: float = solid.position.x-game.player.x-game.PLAYER_SIZE.x
						if gap >= 0 and gap < 70 and solid.position.y < game.player.y+game.PLAYER_SIZE.y:
							game.jump_buffer = 0.14
				var health_before: int = game.health
				game._physics_process(1.0/hz)
				if game.health < health_before:
					damage_hits += 1
					damage_total += health_before-game.health
				peak = maxi(peak,game.live_population())
				check(game.live_population() <= 10,"Normal shared population cap")
				check(game.hostile_shots.size() <= int(game.tuning.hostile_projectiles_max),"Projectile cap")
				for actor in game.actors:
					seen[actor.event_id] = true
					if actor.get("variant","") == "devil" and actor.active: devil_active = true
				for swarm in game.swarms.actors:
					if swarm.has("event_id"): seen[swarm.event_id] = true
				if game.grounded:
					for section in game.campaign.contract.sections:
						for item in section.geometry:
							if item.kind not in ["solid","one_way"]: continue
							var rect := Rect2(item.rect[0],item.rect[1],item.rect[2],item.rect[3])
							if absf(game.player.y+game.PLAYER_SIZE.y-rect.position.y) < 0.1 \
								and game.player.x+game.PLAYER_SIZE.x > rect.position.x and game.player.x < rect.end.x:
								surfaces[item.id] = true
				if game.player.x > 13200 and game.player.x < 13320 and not game.grounded: pit_airborne = true
				if pit_airborne and game.player.x >= 13320 and game.grounded: pit_landed = true
				if game.player.x >= 13710 or game.life_state != "alive": break
			check(game.player.x >= 13710 and game.life_state == "alive","Late route completed "+game.employee.id+str(hz))
			check(devil_active,"Devil entrance completes "+game.employee.id+str(hz))
			check(surfaces.has("approach-deck-0"),"Optional deck supported "+game.employee.id+str(hz))
			check(pit_airborne and pit_landed,"Late pit crossed and landed "+game.employee.id+str(hz))
			for id in ["approach-machine-0-1","approach-machine-1-1","approach-machine-2-1"]:
				check(surfaces.has(id),"Climb physically supported "+id+game.employee.id+str(hz))
			print("LATE ",game.employee.id," ",hz,"Hz x",game.player.x," life",game.life_state,
				" damage_hits",damage_hits," damage_total",damage_total," health_topup=false peak",peak,
				" devil_active",devil_active," pit_landed",pit_landed," surfaces",surfaces.keys()," seen",seen.keys())
			Input.action_release("right")
			Input.action_release("shoot")
			game.queue_free()
			await process_frame
			await physics_frame
	print("Late campaign: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
