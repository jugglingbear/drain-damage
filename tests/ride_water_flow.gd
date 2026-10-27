extends SceneTree
const Game = preload("res://scripts/integrated_first_call.gd")
const Water = preload("res://scripts/ride_water.gd")

func _initialize() -> void: call_deferred("checks")

func checks() -> void:
	var started := Time.get_ticks_usec()
	var game = Game.new()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.begin_level_two()
	game.flush.enter_ride(game,11)
	var ride = game.flush.ride
	var manifest: Dictionary = ride.obstacle_art.manifest
	var before := Water.surface_rows(manifest,ride.clock,0)
	game.paused = true
	ride.tick(game,1.0,Vector2.ZERO,false)
	assert(Water.surface_rows(manifest,ride.clock,0) == before,"Pause freezes water")
	game.paused = false
	ride.tick(game,0.5,Vector2.ZERO,false)
	var after := Water.surface_rows(manifest,ride.clock,0)
	assert(after != before,"Water must move even with world scroll held fixed")
	assert(is_equal_approx(after[0].phase-before[0].phase,17))
	var phase: Array = Water.surface_rows(manifest,ride.clock,0)
	ride._start_encounter(12)
	assert(Water.surface_rows(manifest,ride.clock,0) == phase,"Zero-rest transition cannot reset flow")
	var cache_size: int = ride.obstacle_art.prepared_textures.size()
	for id in ["surface_ripples","surface_swirl","inflow_foam","strainer_rail"]:
		var frame: Dictionary = manifest.frames[id]
		var texture: Texture2D = ride.obstacle_art.textures[frame.runtime_texture_key]
		var image := texture.get_image()
		var transparent := 0
		var visible := 0
		for y in range(0,image.get_height(),3):
			for x in range(0,image.get_width(),3):
				var alpha := image.get_pixel(x,y).a
				if alpha == 0: transparent += 1
				if alpha > 0.1: visible += 1
		assert(transparent > 0 and visible > 0,"Authored patches must retain marks and genuinely transparent gaps")
		if id.begins_with("surface_"):
			for y in range(image.get_height()):
				assert(image.get_pixel(0,y).a == 0 and image.get_pixel(image.get_width()-1,y).a == 0)
	for id in ["strainer_gap_60","strainer_gap_130"]:
		var core: Dictionary = manifest.frames[id].layers[0]
		var image: Image = ride.obstacle_art.textures[core.runtime_texture_key].get_image()
		for y in range(0,image.get_height(),3):
			for x in range(0,image.get_width(),3): assert(image.get_pixel(x,y).a == 1)
		assert(manifest.obstacle_overlays[id].is_empty(),"Old waterfall panels must not draw over new apertures")
	var loop_started := Time.get_ticks_usec()
	for frame in range(10000):
		Water.surface_rows(manifest,frame/120.0,frame*560/120.0)
	assert(ride.obstacle_art.prepared_textures.size() == cache_size,"Animation cannot allocate more textures")
	print("PASS: continuous independent water, pause/transition continuity, transparent patches, opaque pit cores; setup_us=",
		loop_started-started," 10000_layouts_us=",Time.get_ticks_usec()-loop_started," cached_textures=",cache_size)
	game.queue_free()
	await process_frame
	quit()
