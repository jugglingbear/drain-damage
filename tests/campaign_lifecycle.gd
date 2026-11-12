extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
class CheckedGame extends Game:
	var invalid_action_cleanup := 0
	func stop_trial_actions(actor: Dictionary) -> void:
		if not actor.has("role"): invalid_action_cleanup += 1
		super.stop_trial_actions(actor)

var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run_checks")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value and message not in failures:
		failures.append(message)
		push_error(message)
func unlock(game) -> void:
	game.dispenser.cancel()
	game.dispenser.just_finished = false
	game.dispenser.actions_locked = false
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.dialogue.awaiting_release = false
	game.restart_guard_device = -1
	game.paused = false
	game.life_state = "alive"
	game.invulnerable = 1000
	game.boss_intro.seen = {"cockroach-swarm":true,"clogfather":true}
	game.intro_input_release = false
func run_checks() -> void:
	for hero in [0,1]:
		var game = CheckedGame.new()
		game.employee = game.Crew.EMPLOYEES[hero]
		game.seed_override = 42
		root.add_child(game)
		game.hide()
		game.set_process(false)
		game.set_physics_process(false)
		unlock(game)
		game.camera_x = 1000
		for index in range(2):
			var swarm: Dictionary = game.swarms.spawn(Vector2(100+index*100,200),Rect2(0,80,2000,340),42+index)
			swarm.merge({"event_id":"retirement-test-"+str(index),"seen":true})
			game.ledger[swarm.event_id] = "active"
			game.swarms.actors.append(swarm)
		game.step_campaign_swarms(1.0/60)
		check(game.invalid_action_cleanup == 0,"Swarms never enter ordinary creature action-audio cleanup")
		check(game.swarms.actors.is_empty(),"Offscreen swarms retire without ordinary creature role metadata")
		for index in range(2):
			check(game.ledger["retirement-test-"+str(index)] == "retired","Swarm retirement updates its ledger")
		game.swarm_audio.tick(game,1.0/60)
		check(not game.swarm_audio.voice.playing,"Shared swarm audio stops after the last swarm retires")
		for origin in [85.0,4650.0,7650.0,13800.0]:
			game.reset_game()
			unlock(game)
			game.specials.budgets["first-call:"+game.employee.id] = 1
			game.respawn_point = Vector2(origin,394)
			game.post_skitterling_checkpoint = origin == 7650
			game.checkpoint_active = origin > 85
			game.checkpoint_index = 1 if origin == 13800 else 0 if origin > 85 else -1
			game.health = 1
			game.invulnerable = 0
			game.hurt_player()
			check(game.life_state == "dying","Actual damage starts death")
			game.respawn_after_death()
			check(game.specials.remaining() == 1,"Retry never refills specials")
			check(game.actors.is_empty() and game.swarms.actors.is_empty() and game.hostile_shots.is_empty(),"Retry clears threats")
			for spec: Dictionary in game.event_specs():
				check((game.ledger[spec.id] == "excluded") == (float(spec.owner_origin) < origin),"Actual retry owner filtering")
			if origin >= 7650: check(game.skitterling.released,"Post-boss retry keeps defeated boss completed")
		game.reset_game()
		unlock(game)
		game.player = Vector2(6690,394)
		game.skitterling.advance(game,1.0/120)
		check(game.skitterling.entered,"Actual Skitterling entry commits")
		game.issue_event()
		check(game.actors.is_empty() and game.swarms.actors.is_empty(),"No ordinary admissions in boss room")
		game.skitterling.restore_completed()
		game.player = Vector2(14230,394)
		game.clogfather.advance(game,1.0/120)
		check(game.clogfather.entered,"Actual Clogfather entry commits")
		for tick in range(120*45):
			game.clogfather.advance(game,1.0/120)
			if not game.swarms.actors.is_empty(): break
		var boss_adds: int = game.swarms.actors.size()
		check(boss_adds > 0 and game.live_population() == 0,"Boss adds excluded from ordinary budget")
		game.step_campaign_swarms(1.0/60)
		check(game.swarms.actors.size() == boss_adds,"Boss adds survive ordinary tick")
		for hz in [30,60,120]:
			game.reset_game()
			unlock(game)
			game.player = Vector2(250,394)
			Input.action_press("shoot")
			for tick in range(hz*12):
				game._physics_process(1.0/hz)
				check(game.live_population() <= game.crowd_limit(),"Actual mixed physics budget")
				check(game.life_state == "alive","Invulnerable mixed physics remains live")
			Input.action_release("shoot")
			check(game.trial_clock > 11.9,"Actual physics advanced for both heroes")
			check(not game.arrival_log.is_empty(),"Actual physics admits and settles monsters")
			game.player = Vector2(900,394)
			game.velocity = Vector2.ZERO
			game._physics_process(1.0/hz)
			check(game.pit_falling and game.life_state == "dying","Actual pit starts death")
			for tick in range(hz*2): game.step_death(1.0/hz)
			check(game.life_state == "death_popup","Pit fall reaches retry popup")
		game.free()
	print("Campaign lifecycle: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
