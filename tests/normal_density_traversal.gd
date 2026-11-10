extends "res://tests/difficulty_traversal.gd"
## Measure actual campaign pressure per screen without forcing admissions or a kill quota.
var bins: Dictionary = {}

func modes() -> Array[String]: return ["normal"]

func begin_observation() -> void: bins.clear()

func observe(game: Node, delta: float) -> void:
	var bin_id := int(game.player.x/960)
	if not bins.has(bin_id):
		bins[bin_id] = {"seconds":0.0,"visible_actor_seconds":0.0,"empty_seconds":0.0,
			"peak_population":0,"peak_projectiles":0,"relief_seconds":0.0}
	var visible := 0
	for actor in game.actors:
		if actor.hp > 0 and game.actor_rect(actor).intersects(Rect2(game.camera_x,0,960,540)): visible += 1
	for swarm in game.swarms.actors:
		if swarm.hp > 0 and Rect2(swarm.pos-Vector2.ONE*128,Vector2.ONE*256).intersects(Rect2(game.camera_x,0,960,540)):
			visible += 1
	var sample: Dictionary = bins[bin_id]
	sample.seconds += delta
	sample.visible_actor_seconds += visible*delta
	if visible == 0: sample.empty_seconds += delta
	if game.in_pressure_dip(): sample.relief_seconds += delta
	sample.peak_population = maxi(sample.peak_population,game.live_population())
	sample.peak_projectiles = maxi(sample.peak_projectiles,game.hostile_shots.size())

func report_observation() -> void:
	print("DENSITY per960px bin ",JSON.stringify(bins))
