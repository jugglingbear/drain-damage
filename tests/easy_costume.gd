extends SceneTree
## Runtime costume routing checks; rendered registration still requires visual acceptance.
const Costume = preload("res://scripts/hero_costume.gd")
const Portraits = preload("res://scripts/portrait_library.gd")
var failures: Array[String] = []
var checked_frames := 0

func _initialize() -> void: call_deferred("checks")

func require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func frames(value: Variant, mode: String, context: String) -> void:
	if value is Dictionary:
		if value.has("path") and value.has("source_rect"):
			var path := str(value.path)
			if not path.begins_with("assets/weapons/"):
				require(path.contains("/easy-mode/") == (mode == "easy"),context+": Easy isolation: "+path)
				# These presentations keep Normal/Hard cells in historical world atlases.
				if context not in ["Held", "Portal", "Flush", "Landing/ride rider"]:
					require(path.contains("/hard-mode/") == (mode == "hard"),context+": Hard isolation: "+path)
			var texture := load("res://"+path) as Texture2D
			require(texture != null,context+": missing texture "+path)
			if texture != null:
				var r: Array = value.source_rect
				require(Rect2(Vector2.ZERO,texture.get_size()).encloses(Rect2(r[0],r[1],r[2],r[3])),
					context+": source crop outside atlas "+path)
			checked_frames += 1
		for child in value.values(): frames(child,mode,context)
	elif value is Array:
		for child in value: frames(child,mode,context)

func checks() -> void:
	for name in ["aim", "animation", "dispenser"]:
		require(FileAccess.file_exists("res://assets/sprites/easy-mode/"+name+"-manifest-v1.json"),
			"Pending Easy registration: "+name+" manifest")
	if not failures.is_empty():
		quit(1)
		return
	require(Costume.mode(false) == "normal" and Costume.mode(true) == "hard","Legacy boolean routing")
	var game = load("res://scripts/integrated_first_call.gd").new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var base_bundle := JSON.stringify(game.Data.bundle.dispenser.art)
	var weapons: Dictionary = {}
	var normal_presentations: Dictionary = {}
	var inspected_heroes: Dictionary = {}
	for mode in ["normal", "easy", "hard", "easy", "normal"]:
		for employee in game.Crew.EMPLOYEES:
			game.employee = employee
			game.difficulty = mode
			game.reset_game()
			var hero: String = employee.id
			var art = game.world_art.hero_aim_art
			require(art.costume == mode and game.dispenser.costume == mode,"Reset costume propagation")
			frames(art.animations.heroes[hero],mode,hero+" animation/death/HUD")
			if mode == "easy": check_motion_contacts(art.animations.heroes[hero],hero)
			for pose in art.poses.values():
				if str(pose.id).begins_with(hero+"-"): frames(pose.layers,mode,"Aim "+str(pose.id))
			frames(game.dispenser.art.heroes[hero],mode,"Dispenser")
			frames(game.dispenser.art.sleeping_heroes.heroes[hero],mode,"Sleeping")
			frames(game.dispenser.inspection.hero_states[mode][hero],mode,"Held")
			frames(game.ending.hero_frame(game),mode,"Portal")
			frames(game.flush.art.manifest.animations[hero+"_"+mode].frames,mode,"Flush")
			var landing: Dictionary = game.flush.art.landing_presentation(hero,mode,1.0).pose
			frames(landing.front,mode,"Landing/ride rider")
			var presentations := {
				"held": game.dispenser.inspection.hero_states[mode][hero],
				"portal": game.ending.hero_frame(game),
				"flush": game.flush.art.manifest.animations[hero+"_"+mode].frames,
				"landing": landing.front}
			for presentation in presentations:
				var key: String = hero+presentation
				var signature := JSON.stringify(presentations[presentation])
				if mode == "normal": normal_presentations[key] = signature
				else: require(signature != normal_presentations[key],"Normal registration fallback: "+mode+key)
			game.flush.world_view.rebuild_rider()
			require(game.flush.world_view.hero_key == hero+mode,"World camera rider mode key")
			require(game.flush.world_view.rider.get_child_count() > 0,"World camera rider missing")
			var weapon := JSON.stringify(game.weapon)
			if not weapons.has(hero): weapons[hero] = weapon
			require(weapons[hero] == weapon,"Costume changed weapon mechanics: "+hero)
			for emotion in Portraits.manifest.emotions:
				var expected: Texture2D = Portraits.TEXTURES[hero]
				if mode == "easy": expected = Portraits.EASY_TEXTURES[hero]
				if mode == "hard": expected = Portraits.HARD_TEXTURES[hero]
				require(Portraits.expression(hero,emotion.name,mode).atlas == expected,"Portrait selection")
				require(Portraits.expression("BJ",emotion.name,mode).atlas == Portraits.BJ,"BJ costume isolation")
			var conversation: Array[Dictionary] = [
				{"who":hero,"text":"Keep moving.","emotion":"neutral"},
				{"who":"BJ","text":"Keep moving.","emotion":"neutral"}]
			game.dialogue.start(conversation)
			require(game.dialogue.current_text() == ("KEEP MOVING." if mode == "hard" else "Keep moving."),
				"Hard-only hero uppercase")
			game.dialogue.line_index = 1
			require(game.dialogue.current_text() == "Keep moving.","BJ text unchanged")
			require(game.dialogue.costume == mode,"Dialogue costume propagation")
			game.lives = 2
			game.respawn_after_death()
			require(art.costume == mode and game.dispenser.costume == mode,"Respawn costume persistence")
			if mode == "easy" and not inspected_heroes.has(hero):
				check_inspection(game)
				inspected_heroes[hero] = true
	require(JSON.stringify(game.Data.bundle.dispenser.art) == base_bundle,"Shared Normal art mutated")
	game.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: Easy costume routing, both heroes/all modes, ",checked_frames," registered frames")
	else: print("FAIL: ",failures.size()," costume checks")
	quit(0 if failures.is_empty() else 1)

func check_motion_contacts(animation: Dictionary, hero: String) -> void:
	var registration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/sprites/easy-mode/registration-v1.json"))
	var source_frames: Dictionary = {}
	for sheet in registration.sheets.values():
		for frame in sheet.frames:
			source_frames[str(sheet.path)+JSON.stringify(frame.source_rect)] = frame
	var counts := {"grounded":0,"run-flight":0,"airborne":0}
	var common_scale := -1.0
	for phase in animation.phases.values():
		for frame in phase.frames:
			var key: String = str(frame.path)+JSON.stringify(frame.source_rect)
			require(source_frames.has(key),hero+": missing motion source registration")
			if not source_frames.has(key): continue
			var marks: Dictionary = source_frames[key].landmarks
			var rect: Array = frame.source_rect
			var destination: Array = frame.destination
			var scale := float(destination[3])/float(rect[3])
			if common_scale < 0: common_scale = scale
			require(is_equal_approx(scale,common_scale),hero+": motion must not resize between phases")
			require(is_equal_approx(float(destination[2])/float(rect[2]),scale),hero+": anisotropic motion scale")
			var shoulder_y := float(destination[1])+(float(marks.front_shoulder[1])-float(rect[1]))*scale
			require(is_equal_approx(shoulder_y,64.0+float(frame.attachment_offset[1])),hero+": detached aim shoulder")
			var state: String = marks.contact_state
			counts[state] += 1
			if state == "airborne": continue
			require(state in ["grounded","run-flight"],hero+": unknown contact state")
			var contact_y := float(destination[1])+(float(marks.ground_plane_anchor[1])-float(rect[1]))*scale
			var expected_y := 104.0-float(marks.suggested_run_flight_clearance_canvas_px)
			require(is_equal_approx(contact_y,expected_y),hero+": contact baseline mismatch in "+str(source_frames[key].id))
	for state in counts: require(counts[state] > 0,hero+": contact coverage missing "+state)

func check_inspection(game: Node2D) -> void:
	var dispenser = game.dispenser
	for hp in range(1,game.employee.max_health):
		game.reset_game()
		game.dialogue.finish()
		game.dialogue.release_guard = 0
		game.health = hp
		game.activate_checkpoint(0)
		require(game.health == game.employee.max_health and dispenser.arrival_health == hp,"Easy preheal snapshot")
		require(is_equal_approx(dispenser.diagnosis_fraction(),float(hp)/game.employee.max_health),"Easy diagnosis")
		require(dispenser.events == ["grab"] and dispenser.hides_hero(),"Easy grab")
		dispenser.tick(game,1.65)
		require(dispenser.events == ["grab","inspection_arm_deploy","inspect","diagnosis"],"Easy inspection order")
		var before: Array = dispenser.events.duplicate()
		game.set_paused(true)
		dispenser.tick(game,10)
		require(dispenser.events == before and is_equal_approx(dispenser.elapsed,1.65),"Easy inspection pause")
		game.set_paused(false)
		dispenser.tick(game,1.51)
		require(dispenser.events[-1] == "throw" and dispenser.overlay_visible() and dispenser.stocked,"Easy throw")
		dispenser.tick(game,.70)
		require(dispenser.events[-1] == "vend" and not dispenser.stocked,"Easy vend")
		dispenser.tick(game,2.95)
		require(not dispenser.active and dispenser.finalizations == 1 and game.lives == 3,"Easy completion accounting")
		require(dispenser.events.count("vend") == 1 and dispenser.events.count("release") == 1,"Easy once-only events")
		require(dispenser.costume == "easy" and dispenser.hero == game.employee.id,"Easy lifecycle costume")
		require(dispenser.arrival_health == hp,"Easy diagnosis preserved")
