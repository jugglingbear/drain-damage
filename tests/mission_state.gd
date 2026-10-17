extends SceneTree
const Mission = preload("res://scripts/mission_state.gd")
func _initialize() -> void:
	var mission := Mission.new()
	# Finale is two separate finite waves, not a boss.
	mission.configure([3, 5, 5, 6, 6, 3, 2])
	assert(mission.remaining() == 30 and not mission.completed())
	for zone in range(7):
		while mission.current_zone == zone:
			while mission.can_spawn():
				assert(mission.register_spawn() >= 0)
			assert(mission.alive.size() <= 4 and not mission.alive.is_empty())
			assert(mission.register_spawn() == -1)
			var id: int = mission.alive.keys()[0]
			assert(mission.register_defeat(id))
			assert(not mission.register_defeat(id), "Duplicate deaths cannot consume queued enemies")
	assert(mission.completed() and mission.remaining() == 0)
	mission.reset()
	assert(mission.remaining() == 30 and mission.current_zone == 0 and mission.alive.is_empty())
	print("PASS: finite30, active cap4, sequential zones, finale3+2, duplicate death and full restart")
	quit()
