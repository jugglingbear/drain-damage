extends SceneTree
## Real staged startup must keep yielding and protect the menu from duplicate launches.
class MissingJob:
	extends "res://scripts/title_screen.gd"
	func create_job() -> Node2D: return null

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var title = load("res://scripts/title_screen.gd").new()
	root.add_child(title)
	title.starting = true
	title.start_game()
	await process_frame
	assert(title.loading_in_progress and title.game == null)
	title.request_start()
	title.start_game()
	var deadline := Time.get_ticks_msec()+60000
	while title.loading_in_progress and Time.get_ticks_msec() < deadline:
		assert(title.music_director.requested == "title", "Menu music must survive hidden preparation")
		await process_frame
	assert(not title.loading_in_progress and title.game != null,"Staged startup must finish")
	assert(title.loading_frames > 10,"Preparation must yield instead of freezing the menu")
	assert(title.game.startup_complete and title.game.dialogue.active)
	assert(title.game.visible and title.pending_game == null and not title.starting)
	assert(title.music_director.requested == "level", "Reveal must request level music")
	print("PASS: staged startup, duplicate guard, dialogue readiness; frames=",title.loading_frames,
		" max_frame_ms=",title.loading_max_frame_msec)
	title.queue_free()
	await process_frame
	var missing := MissingJob.new()
	root.add_child(missing)
	missing.starting = true
	await missing.start_game()
	assert(missing.game == null and missing.pending_game == null)
	assert(not missing.starting and not missing.loading_in_progress and not missing.loading_error.is_empty())
	assert(missing.music_director.requested == "title", "Failed loading must retain menu music")
	missing.queue_free()
	await process_frame
	print("PASS: failed preparation returns control to the menu")
	quit()
