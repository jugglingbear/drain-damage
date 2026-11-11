extends Node2D

const Buttons = preload("res://scripts/plumbing_buttons.gd")
const BuildVersion = preload("res://scripts/build_version.gd")
const PlaytestLaunch = preload("res://scripts/playtest_launch.gd")
## Illustrated Drain Damage opening; gameplay is created only after Start.

const MusicDirector = preload("res://scripts/music_director.gd")
var music_director: Node
const CLOCK_IN_RECT := Rect2(806, 430, 128, 34)
const PUNCH_CLOCK = preload("res://assets/selection/punch-clock-v1.png")
const PUNCH_CLOCK_SOURCE := Rect2(75, 25, 1110, 1200)
const PUNCH_CLOCK_RECT := Rect2(790, 315, 160, 160.0 * 1200.0 / 1110.0)
const EmployeePhoto = preload("res://scripts/employee_photo.gd")
const CLIPBOARD = preload("res://assets/selection/clipboard-stack-v2.png")
const ART = preload("res://assets/title/drain-damage-v2.png")
const MENU_ART = preload("res://assets/title/dripping-menu-v1.png")
const MENU_LABELS := ["START", "CONTROLS", "QUIT"]
const Crew = preload("res://scripts/crew.gd")
const Portraits = preload("res://scripts/portrait_library.gd")
const Controls = preload("res://scripts/controls_screen.gd")
const Story = preload("res://scripts/story_dialogue.gd")
const GAME = preload("res://scripts/integrated_first_call.gd")
const MINT := Color("93ffd2")
const GOLD := Color("ffe18d")
var menu_index := 0
var showing_controls := false
var controls_page := 0
var controls_focus := 0
var show_enemy_health_bars := false
const DifficultyScreen = preload("res://scripts/difficulty_screen.gd")
var difficulty_copy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/difficulty-ui.json"))
var choosing_difficulty := false
var difficulty_index := 1
var difficulty_focus := 1
var difficulty_stick := Vector2.ZERO
var difficulty_hover := -1
var confirm_blocked := false
var selecting := false
var selected := 0
var selection_focus := 0
var selection_guard := 0.0
var stick_latched := false
var game: Node2D
var clock := 0.0
var muted := false
var starting := false
var pending_game: Node2D
var loading_in_progress := false
var loading_timeout_msec := 60000
var loading_error := ""
var loading_frames := 0
var loading_started_msec := 0
var loading_max_frame_msec := 0
var loading_last_frame_msec := 0
var loading_slice_usec := 0
var loading_valve: Texture2D

var screenshot_mode := false
const ScreenshotFreeze = preload("res://scripts/screenshot_freeze.gd")
var music: AudioStreamPlayer
const NAVIGATION_CUE = preload("res://assets/audio/sfx/menu-navigation-v1/wrench-clink.wav")
var navigation_voice := AudioStreamPlayer.new()
var navigation_plays := 0
var held_navigation_buttons: Dictionary = {}

func _ready() -> void:
	prepare_loading_valve()
	var launch := PlaytestLaunch.parse(OS.get_cmdline_user_args())
	if launch.has("error"):
		printerr("Launch failed: "+launch.error)
		get_tree().quit(2)
		return
	if launch.has("list"):
		print(PlaytestLaunch.listing())
		get_tree().quit()
		return
	screenshot_mode = bool(launch.get("screenshot_mode",false))
	if not Crew.Data.load_data():
		get_tree().quit(1)
		return
	if "--verify-combat-data" in OS.get_cmdline_user_args():
		for id in Crew.Data.bundle.monsters:
			if Crew.Data.monster(id).damage_art == null: continue
			var spec: Dictionary = Crew.Data.monster(id).damage_art
			if load("res://" + spec.image) == null:
				push_error("Export missing damage texture: " + spec.image)
				get_tree().quit(1)
				return
		print("PASS: exported combat bundle, six weapon records, registered monster records, both imported atlases")
		get_tree().quit()
		return
	show_enemy_health_bars = Crew.Data.bundle.visual_policy.ordinary_enemy_bars_default
	if "--agent-test" in OS.get_cmdline_user_args():
		# Explicitly override the saved maximized mode only for agent-operated launches.
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(960, 540)
		get_window().position = Vector2i(80, 80)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	music_director = MusicDirector.new()
	add_child(music_director)
	music = music_director.player
	music_director.play_track("title")
	navigation_voice.stream = NAVIGATION_CUE.duplicate()
	navigation_voice.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	navigation_voice.volume_db = 0
	add_child(navigation_voice)
	if launch.has("target"):
		selected = 0 if launch.hero == "tony" else 1
		for index in range(difficulty_copy.options.size()):
			if difficulty_copy.options[index].id == launch.difficulty: difficulty_index = index
		call_deferred("start_game",launch)

func _exit_tree() -> void:
	navigation_voice.stop()
	navigation_voice.stream = null
	if music != null: music.stop()

func _process(delta: float) -> void:
	clock += delta
	if starting:
		var now := Time.get_ticks_msec()
		if loading_last_frame_msec > 0: loading_max_frame_msec = maxi(loading_max_frame_msec,now-loading_last_frame_msec)
		loading_last_frame_msec = now
		loading_frames += 1
	selection_guard = maxf(0, selection_guard - delta)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if game != null or starting: return
	if not loading_error.is_empty(): loading_error = ""
	if is_confirm_event(event):
		if not event.pressed:
			confirm_blocked = false
		elif confirm_blocked:
			return
	var directional := false
	if event is InputEventKey:
		directional = event.pressed and not event.echo and event.physical_keycode in [
			KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_W,KEY_A,KEY_S,KEY_D,KEY_TAB]
	elif event is InputEventJoypadButton and event.button_index in [
		JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
		var token := "%d:%d" % [event.device,event.button_index]
		if not event.pressed:
			held_navigation_buttons.erase(token)
		elif held_navigation_buttons.has(token):
			return
		else:
			held_navigation_buttons[token] = true
			directional = true
	elif event is InputEventJoypadMotion:
		directional = event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y] and absf(event.axis_value) > 0.6
	var before := Vector4i(menu_index,controls_focus if showing_controls else controls_page,selection_focus if selecting else selected,difficulty_focus)
	var screen := Vector3i(int(showing_controls),int(selecting),int(choosing_difficulty))
	handle_pre_game_input(event)
	if directional and game == null and not starting and before != Vector4i(menu_index,controls_focus if showing_controls else controls_page,selection_focus if selecting else selected,difficulty_focus) \
		and screen == Vector3i(int(showing_controls),int(selecting),int(choosing_difficulty)):
		# The existing Master bus is the shared SFX route; music mute is independent.
		if not AudioServer.is_bus_mute(AudioServer.get_bus_index(navigation_voice.bus)):
			navigation_voice.play()
			navigation_plays += 1

func handle_pre_game_input(event: InputEvent) -> void:
	if game != null or starting:
		return
	if choosing_difficulty:
		handle_difficulty(event)
		get_viewport().set_input_as_handled()
		return
	if showing_controls:
		handle_controls(event)
		get_viewport().set_input_as_handled()
		return
	if not selecting and handle_menu(event):
		get_viewport().set_input_as_handled()
		return
	if selecting and handle_selection(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			request_start()
		elif event.physical_keycode == KEY_M:
			toggle_sound()
		elif event.physical_keycode == KEY_ESCAPE:
			get_tree().quit()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
			request_start()
		elif event.button_index == JOY_BUTTON_Y:
			toggle_sound()

func menu_rect(index: int) -> Rect2:
	# The decorative coating and drips never extend the interactive rectangle.
	return Rect2(54, 300 + index * 58, 355, 46)

func menu_at_point(point: Vector2) -> int:
	for index in range(MENU_LABELS.size()):
		if menu_rect(index).has_point(point):
			return index
	return -1

func handle_menu(event: InputEvent) -> bool:
	var direction := 0
	var confirm := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_UP, KEY_W]: direction = -1
		if event.physical_keycode in [KEY_DOWN, KEY_S]: direction = 1
		confirm = event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_UP: direction = -1
		if event.button_index == JOY_BUTTON_DPAD_DOWN: direction = 1
		confirm = event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		if absf(event.axis_value) < 0.25: stick_latched = false
		elif absf(event.axis_value) > 0.6 and not stick_latched:
			direction = int(signf(event.axis_value))
			stick_latched = true
	elif event is InputEventMouseMotion:
		var hovered := menu_at_point(get_global_mouse_position())
		if hovered >= 0:
			menu_index = hovered
			return true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked := menu_at_point(get_global_mouse_position())
		if clicked >= 0:
			menu_index = clicked
			confirm = true
	if direction != 0:
		menu_index = posmod(menu_index + direction, MENU_LABELS.size())
		return true
	if confirm:
		match menu_index:
			0:
				request_start()
			1:
				showing_controls = true
				controls_focus = controls_page
				stick_latched = false
			2: get_tree().quit()
		return true
	return false

func handle_controls(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE: showing_controls = false
		if event.physical_keycode == KEY_H: show_enemy_health_bars = not show_enemy_health_bars
		if event.physical_keycode in [KEY_LEFT, KEY_A]: move_controls_focus(-1)
		if event.physical_keycode in [KEY_RIGHT, KEY_D]: move_controls_focus(1)
		if event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and controls_focus == 2:
			showing_controls = false
		if event.physical_keycode == KEY_M: toggle_sound()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_B: showing_controls = false
		if event.button_index == JOY_BUTTON_BACK: show_enemy_health_bars = not show_enemy_health_bars
		if event.button_index == JOY_BUTTON_DPAD_LEFT: move_controls_focus(-1)
		if event.button_index == JOY_BUTTON_DPAD_RIGHT: move_controls_focus(1)
		if event.button_index in [JOY_BUTTON_A,JOY_BUTTON_START] and controls_focus == 2:
			showing_controls = false
		if event.button_index == JOY_BUTTON_Y: toggle_sound()
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
		if absf(event.axis_value) < 0.25: stick_latched = false
		elif absf(event.axis_value) > 0.6 and not stick_latched:
			move_controls_focus(int(signf(event.axis_value)))
			stick_latched = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = event.position
		for index in range(2):
			if Controls.tab_rect(index).has_point(point):
				controls_page = index
				controls_focus = index
		if Controls.BACK_RECT.has_point(point): showing_controls = false
		if Controls.setting_at_point(point) == "health": show_enemy_health_bars = not show_enemy_health_bars
		if Controls.setting_at_point(point) == "music": toggle_sound()

func move_controls_focus(direction: int) -> void:
	controls_focus = posmod(controls_focus+direction,3)
	if controls_focus < 2: controls_page = controls_focus

func move_selection_focus(direction: Vector2i) -> void:
	if direction.y > 0: selection_focus = 2
	elif direction.y < 0: selection_focus = selected
	elif selection_focus >= 2:
		selection_focus = 2 if direction.x < 0 else 3
	else:
		selected = 0 if direction.x < 0 else 1
		selection_focus = selected

func handle_selection(event: InputEvent) -> bool:
	var direction := Vector2i.ZERO
	var confirm := false
	var back := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_A,KEY_LEFT]: direction.x = -1
		if event.physical_keycode in [KEY_D,KEY_RIGHT]: direction.x = 1
		if event.physical_keycode in [KEY_W,KEY_UP]: direction.y = -1
		if event.physical_keycode in [KEY_S,KEY_DOWN]: direction.y = 1
		back = event.physical_keycode == KEY_ESCAPE
		confirm = event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_LEFT: direction.x = -1
		if event.button_index == JOY_BUTTON_DPAD_RIGHT: direction.x = 1
		if event.button_index == JOY_BUTTON_DPAD_UP: direction.y = -1
		if event.button_index == JOY_BUTTON_DPAD_DOWN: direction.y = 1
		back = event.button_index == JOY_BUTTON_B
		confirm = event.button_index in [JOY_BUTTON_A,JOY_BUTTON_START]
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
		if absf(event.axis_value) < 0.25: stick_latched = false
		elif absf(event.axis_value) > 0.6 and not stick_latched:
			direction[event.axis] = int(signf(event.axis_value))
			stick_latched = true
		else: return true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = event.position
		if Rect2(28,473,100,35).has_point(point):
			selection_focus = 2
			back = true
		for index in range(2):
			if Rect2(65+index*765,260,65,80).has_point(point):
				selected = index
				selection_focus = index
				return true
		if CLOCK_IN_RECT.has_point(point):
			selection_focus = 3
			confirm = true
		if not back and not confirm: return true
	if back or (confirm and selection_focus == 2):
		selecting = false
		return true
	if direction != Vector2i.ZERO:
		move_selection_focus(direction)
		return true
	if confirm:
		request_start()
		return true
	return false

func is_confirm_event(event: InputEvent) -> bool:
	return (event is InputEventKey and event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]) \
		or (event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_A,JOY_BUTTON_START]) \
		or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)

func focus_difficulty(control: int) -> void:
	difficulty_focus = control
	if control < 3: difficulty_index = control
	difficulty_hover = -1

func handle_difficulty(event: InputEvent) -> void:
	var direction := Vector2i.ZERO
	var tab_direction := 0
	var back := false
	var confirm := false
	if event is InputEventMouseMotion:
		difficulty_hover = DifficultyScreen.control_at(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_UP,KEY_W]: direction.y = -1
		if event.physical_keycode in [KEY_DOWN,KEY_S]: direction.y = 1
		if event.physical_keycode in [KEY_LEFT,KEY_A]: direction.x = -1
		if event.physical_keycode in [KEY_RIGHT,KEY_D]: direction.x = 1
		if event.physical_keycode == KEY_TAB: tab_direction = -1 if event.shift_pressed else 1
		back = event.physical_keycode == KEY_ESCAPE
		confirm = is_confirm_event(event)
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_UP: direction.y = -1
		if event.button_index == JOY_BUTTON_DPAD_DOWN: direction.y = 1
		if event.button_index == JOY_BUTTON_DPAD_LEFT: direction.x = -1
		if event.button_index == JOY_BUTTON_DPAD_RIGHT: direction.x = 1
		back = event.button_index == JOY_BUTTON_B
		confirm = is_confirm_event(event)
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
		if event.axis == JOY_AXIS_LEFT_X: difficulty_stick.x = event.axis_value
		else: difficulty_stick.y = event.axis_value
		if maxf(absf(difficulty_stick.x),absf(difficulty_stick.y)) < 0.25: stick_latched = false
		elif maxf(absf(difficulty_stick.x),absf(difficulty_stick.y)) > 0.6 and not stick_latched:
			if absf(difficulty_stick.x) > absf(difficulty_stick.y): direction.x = int(signf(difficulty_stick.x))
			else: direction.y = int(signf(difficulty_stick.y))
			stick_latched = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var control := DifficultyScreen.control_at(event.position)
		if control >= 0: focus_difficulty(control)
		back = control == 3
		confirm = control == 4
	if tab_direction != 0:
		focus_difficulty(posmod(difficulty_focus+tab_direction,5))
	elif direction != Vector2i.ZERO:
		focus_difficulty(DifficultyScreen.neighbor(difficulty_focus,direction))
	if confirm and difficulty_focus == 3: back = true
	if back:
		choosing_difficulty = false
		difficulty_hover = -1
		selection_guard = 0.3
		confirm_blocked = is_confirm_event(event)
		stick_latched = false
	elif confirm:
		if difficulty_focus < 3:
			focus_difficulty(4)
			confirm_blocked = true
		else: request_start()

func draw_selection() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("0d1526"))
	draw_texture_rect(Portraits.expression("bj", "neutral"), Rect2(30, 8, 95, 95), false)
	caption("BJ", Vector2(140, 27), 20, MINT)
	caption(Crew.COMPANY_NAME, Vector2(180, 27), 14, MINT)
	caption("There’s something chewing through the pipes downstairs.", Vector2(140, 52), 15, Color.WHITE)
	caption("Pick someone before it gets to the expensive ones.", Vector2(140, 74), 15, Color.WHITE)
	caption("Who’s going down there?", Vector2(140, 105), 23, GOLD)
	# Preserve the art's aspect ratio; keep ink inside its quiet paper region.
	draw_rect(Rect2(264, 205, 422, 190), Color("eee6d2"))
	draw_texture_rect(CLIPBOARD, Rect2(180, 110, 600, 400), false)
	var person: Dictionary = Crew.EMPLOYEES[selected]
	var ink := Color("263634")
	caption("EMPLOYEE FILE", Vector2(266, 219), 14, ink)
	caption("%d / %d" % [selected + 1, Crew.EMPLOYEES.size()], Vector2(640, 219), 14, ink)
	# Employee files keep their standard portraits regardless of the next job's difficulty.
	EmployeePhoto.draw(self, Portraits.expression(person.id, "afraid" if person.id == "sean" else "neutral"),
		person.name)
	caption(person.name, Vector2(430, 247), 23, ink)
	caption("Fourth-generation plumber" if selected == 0 else "Apprentice", Vector2(430, 270), 14, ink)
	# TextServer wraps the biography to the profile column.
	var paragraph := TextParagraph.new()
	paragraph.width = 245
	paragraph.add_string(person.biography, ThemeDB.fallback_font, 14)
	paragraph.draw(get_canvas_item(), Vector2(430, 281), ink)
	# Trait lists use the same checked-row layout for every employee.
	var checked_icon := ThemeDB.get_default_theme().get_icon("checked", "CheckBox")
	var trait_y := maxf(365, 281 + paragraph.get_size().y + 10)
	for feature: String in person.traits:
		var row := TextParagraph.new()
		row.width = 223
		row.add_string(feature, ThemeDB.fallback_font, 14)
		draw_texture_rect(checked_icon, Rect2(430, trait_y + 2, 14, 14), false, ink)
		row.draw(get_canvas_item(), Vector2(452, trait_y), ink)
		trait_y += maxf(22, row.get_size().y + 4)
	for index in range(2):
		Buttons.compact(self,Rect2(65+index*765,260,65,80),"<" if index == 0 else ">",selection_focus == index,20,false,26)
	draw_rect(Rect2(0, 510, 960, 30), Color("0d1526"))
	Buttons.compact(self,Rect2(28,473,100,35),"BACK",selection_focus == 2)
	# The punch clock stays outside the clipboard and shares its button bounds with input.
	draw_texture_rect_region(PUNCH_CLOCK, PUNCH_CLOCK_RECT, PUNCH_CLOCK_SOURCE)
	Buttons.prop_focus(self,CLOCK_IN_RECT,selection_focus == 3,selection_guard > 0 or confirm_blocked)
	var font := ThemeDB.fallback_font
	var label_size := font.get_string_size("CLOCK IN", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	var baseline := 448.0 + (font.get_ascent(18) - font.get_descent(18)) / 2.0
	caption("CLOCK IN", Vector2(870 - label_size.x / 2.0, baseline), 18, Color("172725"))
	caption("Arrows / D-pad: navigate     Enter / A: confirm     Esc / B: back", Vector2(230, 526), 13, MINT)

func toggle_sound() -> void:
	muted = not muted
	music_director.set_muted(muted)

func request_start() -> void:
	if starting or game != null:
		return
	if not selecting:
		selecting = true
		selected = 0
		selection_focus = 0
		stick_latched = false
		difficulty_index = 1
		difficulty_hover = -1
		confirm_blocked = true
		selection_guard = 0.3
		get_viewport().set_input_as_handled()
		return
	if selection_guard > 0:
		return
	if not choosing_difficulty:
		choosing_difficulty = true
		difficulty_focus = difficulty_index
		difficulty_stick = Vector2.ZERO
		difficulty_hover = -1
		confirm_blocked = true
		selection_guard = 0.3
		stick_latched = false
		get_viewport().set_input_as_handled()
		return
	starting = true
	get_viewport().set_input_as_handled()
	call_deferred("start_game")

func prepare_loading_valve() -> void:
	var source: Texture2D = load("res://assets/ui/job-loading-v1/valve-source-v1.png")
	if source == null: return
	var pixels := source.get_image().get_region(Rect2i(48,48,1152,1152))
	pixels.convert(Image.FORMAT_RGBA8)
	var bytes := pixels.get_data()
	for index in range(3,bytes.size(),4):
		if bytes[index] < 240: bytes[index] = 0
	pixels = Image.create_from_data(1152,1152,false,Image.FORMAT_RGBA8,bytes)
	pixels.resize(112,112,Image.INTERPOLATE_LANCZOS)
	loading_valve = ImageTexture.create_from_image(pixels)

func loading_frame() -> void:
	if Time.get_ticks_usec()-loading_slice_usec < 4000: return
	await get_tree().process_frame
	loading_slice_usec = Time.get_ticks_usec()

func create_job() -> Node2D:
	return GAME.new()

func fail_loading() -> void:
	loading_error = "Couldn’t prepare the job. Please try again."
	if is_instance_valid(pending_game): pending_game.queue_free()
	pending_game = null
	starting = false
	confirm_blocked = true
	queue_redraw()

func prepare_job() -> bool:
	loading_error = ""
	loading_frames = 0
	loading_max_frame_msec = 0
	loading_last_frame_msec = Time.get_ticks_msec()
	loading_started_msec = loading_last_frame_msec
	queue_redraw()
	# Let the already-requested overlay reach the renderer before starting preparation.
	await get_tree().process_frame
	await get_tree().process_frame
	var hero_preparation = load("res://scripts/hero_aim_art.gd").new(true)
	await hero_preparation.configure("normal",loading_frame)
	var costume_preparation = load("res://scripts/hero_aim_art.gd").new(true)
	await costume_preparation.configure(difficulty_copy.options[difficulty_index].id,loading_frame)
	pending_game = create_job()
	if pending_game == null:
		fail_loading()
		return false
	await get_tree().process_frame
	pending_game.employee = Crew.EMPLOYEES[selected]
	pending_game.difficulty = difficulty_copy.options[difficulty_index].id
	pending_game.music_director = music_director
	pending_game.startup_yield = loading_frame
	pending_game.process_mode = Node.PROCESS_MODE_DISABLED
	pending_game.hide()
	add_child(pending_game)
	while is_instance_valid(pending_game) and not pending_game.startup_complete:
		if Time.get_ticks_msec()-loading_started_msec > loading_timeout_msec:
			fail_loading()
			return false
		await get_tree().process_frame
	return is_instance_valid(pending_game) and pending_game.dialogue != null

func start_game(launch: Dictionary = {}) -> void:
	if loading_in_progress or game != null: return
	var staged := starting and launch.is_empty()
	if staged:
		loading_in_progress = true
		var prepared := await prepare_job()
		loading_in_progress = false
		if not prepared:
			fail_loading()
			return
	navigation_voice.stop()
	held_navigation_buttons.clear()
	var initializer: String = launch.get("target",{}).get("initializer","")
	if staged:
		game = pending_game
		pending_game = null
	elif initializer == "three-screen-trial":
		game = load("res://scripts/three_screen_trial_game.gd").new()
	elif initializer == "section-one-two":
		game = load("res://scripts/section_one_two_game.gd").new()
	elif initializer == "camera-test":
		game = load("res://scenes/level_two_camera_test.tscn").instantiate()
	else:
		game = GAME.new()
	if launch.has("target"): game.seed_override = launch.seed
	game.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	game.music_director = music_director
	game.employee = Crew.EMPLOYEES[selected]
	game.difficulty = difficulty_copy.options[difficulty_index].id
	game.show_enemy_health_bars = show_enemy_health_bars
	game.title_requested.connect(return_to_title, CONNECT_DEFERRED)
	if not game.is_inside_tree(): add_child(game)
	if screenshot_mode:
		var freeze := ScreenshotFreeze.new()
		freeze.name = "ScreenshotFreeze"
		freeze.host = game
		game.add_child(freeze)
	# Only a fresh run enters here; retries and checkpoint respawns never replay the opening.
	if launch.has("target"):
		PlaytestLaunch.initialize(game,launch.target)
		if launch.verify:
			print("PASS: playtest launch "+JSON.stringify(PlaytestLaunch.summary(game,launch)))
			get_tree().quit()
	else:
		game.dialogue.start(Story.OPENING)
		game.dialogue.release_guard = 0.4
	game.show()
	music_director.play_track("level")
	game.process_mode = Node.PROCESS_MODE_INHERIT
	set_process(false)
	# Hide only this node's drawing; hiding the parent would also hide the gameplay child.
	queue_redraw()
	starting = false

func return_to_title() -> void:
	if game == null:
		return
	remove_child(game)
	game.queue_free()
	game = null
	clock = 0
	selecting = false
	choosing_difficulty = false
	difficulty_hover = -1
	confirm_blocked = false
	showing_controls = false
	menu_index = 0
	stick_latched = false
	set_process(true)
	music_director.play_track("title")
	queue_redraw()

func caption(text: String, point: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if game != null:
		return
	draw_menu_content()
	if starting or not loading_error.is_empty():
		draw_rect(Rect2(0,0,960,540),Color(0.015,0.025,0.035,0.78))
		if starting and loading_valve != null:
			draw_set_transform(Vector2(480,236),fmod(clock*PI,TAU))
			draw_texture_rect(loading_valve,Rect2(-28,-28,56,56),false)
			draw_set_transform(Vector2.ZERO)
		var text := "Preparing the job…" if starting else loading_error
		draw_string(ThemeDB.fallback_font,Vector2(180,300),text,HORIZONTAL_ALIGNMENT_CENTER,600,24,GOLD)

func draw_menu_content() -> void:
	if game != null:
		return
	if showing_controls:
		Controls.draw(self, controls_page, muted, show_enemy_health_bars, controls_focus)
		return
	if choosing_difficulty:
		DifficultyScreen.draw(self)
		return
	if selecting:
		draw_selection()
		return
	draw_texture_rect(ART, Rect2(0, 0, 960, 540), false)
	for index in range(MENU_LABELS.size()):
		var hit_area := menu_rect(index)
		var chosen := menu_index == index
		var decoration := Rect2(hit_area.position - Vector2(10, 8), Vector2(375, 64))
		var hovered := hit_area.has_point(get_local_mouse_position())
		var pressed := hovered and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var state := Buttons.appearance(chosen,hovered,pressed,starting)
		Buttons.plate(self,decoration,chosen,hovered,pressed,starting)
		if chosen and not starting:
			var focus := StyleBoxFlat.new()
			focus.bg_color = Color.TRANSPARENT
			focus.border_color = GOLD
			focus.set_border_width_all(2)
			focus.set_corner_radius_all(8)
			draw_style_box(focus, hit_area)
			var pointer := hit_area.position + Vector2(20, 23)
			draw_colored_polygon(PackedVector2Array([
				pointer + Vector2(-4, -6), pointer + Vector2(5, 0), pointer + Vector2(-4, 6)
			]), MINT)
		var baseline := hit_area.position + Vector2(52, 32 + state.offset)
		caption(MENU_LABELS[index], baseline + Vector2(1, 2), 27, Color("080e15"))
		caption(MENU_LABELS[index], baseline, 27, state.label)
	BuildVersion.draw(self)
