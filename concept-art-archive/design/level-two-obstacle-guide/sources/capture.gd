extends SceneTree
var game: Node2D
const OUTPUT := "/Users/sfoley/repos/drain_damage/.scratch/obstacle-grid/captures/"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960,540)
	root.unfocusable = true
	AudioServer.set_bus_mute(0,true)
	game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	while not game.startup_complete:
		await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	for index in range(13):
		game.employee = game.Crew.EMPLOYEES[0]
		game.difficulty = "normal"
		game.flush.active = false
		game.reset_game()
		game.begin_level_two()
		game.flush.ride.continuous = false
		game.flush.enter_ride(game,index)
		game.flush.input_guard = false
		var ride: RefCounted = game.flush.ride
		var world: Node3D = game.flush.world_view
		world.yaw = 18
		world.target_yaw = 18
		for stamp in [2.9,3.2,3.5,3.8,4.2,4.7]:
			ride.clock = stamp
			ride.encounter_clock = stamp
			ride.encounter_scroll = stamp*560.0
			ride.position = Vector2(180,395)
			ride.sync_hero(game)
			game.queue_redraw()
			world._process(0)
			await process_frame
			await process_frame
			RenderingServer.force_draw(false)
			var target := OUTPUT+"encounter-%02d-%02d.png" % [index+1,int(stamp*10)]
			assert(root.get_texture().get_image().save_png(target)==OK)
		print("CAPTURED ",index+1)
	game.free()
	await process_frame
	print("GRID_CAPTURE_COMPLETE ",ProjectSettings.get_setting("application/config/version"))
	quit()
