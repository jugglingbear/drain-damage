extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var game := Game.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	Launch.initialize(game,Launch.parse(["--level=2-landing"]).target)
	var view = game.flush.world_view
	view.set_process(false)
	view._process(0)
	for index in range(13):
		game.flush.enter_ride(game,index)
		var model = game.flush.ride
		view.update_world()
		for actor: Node3D in view.actors.values():
			var obstacle: Dictionary = actor.get_meta("obstacle")
			if obstacle.kind not in ["gap","long_pit"]: continue
			var curtains := 0
			for child in actor.get_node("opening").get_children():
				if child is MeshInstance3D and child.material_override == view.waterfall: curtains += 1
			assert(curtains >= 8,"Every opening needs descending water on both travel edges")
			if not obstacle.has("activates_at"): continue
			view.animate_fragments(actor,-.01)
			assert(not actor.get_node("debris").visible,"No fracture before impact")
			view.animate_fragments(actor,.15)
			var debris: Node3D = actor.get_node("debris")
			assert(debris.visible and debris.get_child_count() == 18)
			var early: Array[Vector3] = []
			for fragment: Node3D in debris.get_children(): early.append(fragment.position)
			view.animate_fragments(actor,.65)
			for i in debris.get_child_count():
				assert(debris.get_child(i).position.y < early[i].y,"Fragments must descend into shaft")
			view.animate_fragments(actor,3.0)
			for fragment: Node3D in debris.get_children():
				assert(is_equal_approx(fragment.position.y,-1.9),"Rubble rests at shaft floor without disappearing")
				var bounds: Rect2 = fragment.get_meta("bounds")
				assert(bounds.grow(.001).has_point(Vector2(fragment.position.x,fragment.position.z)))
	game.free()
	print("PASS: every ride opening has inflow; bounded impact debris follows gravity and remains on shaft floor")
	quit()
