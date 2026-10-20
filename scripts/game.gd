extends Node2D

const BuildVersion = preload("res://scripts/build_version.gd")
## Plumbing action prototype with pixel world art and illustrated dialogue.

signal title_requested

const BossHUD = preload("res://scripts/boss_hud.gd")
var boss_hud := BossHUD.new()

const Buttons = preload("res://scripts/plumbing_buttons.gd")
const PAUSE_MENU_ART = preload("res://assets/title/dripping-menu-v1.png")
const FlushfiendNavigation = preload("res://scripts/flushfiend_navigation.gd")
const Data = preload("res://scripts/combat_data.gd")
var weapon: Dictionary
var corpses: Array[Dictionary] = []
var show_enemy_health_bars := false

const Story = preload("res://scripts/story_dialogue.gd")
const Crew = preload("res://scripts/crew.gd")
var employee: Dictionary = Crew.SEAN

const WorldArt = preload("res://scripts/world_art.gd")
var world_art := WorldArt.new()
const WastewaterArt = preload("res://scripts/wastewater_art.gd")
var wastewater_art := WastewaterArt.new()

const Level = preload("res://scripts/first_call.gd")
const Mission = preload("res://scripts/mission_state.gd")
const WORLD_WIDTH := Level.WIDTH
var mission := Mission.new()
const SewerSwarm = preload("res://scripts/sewer_swarm.gd")
var swarms := SewerSwarm.new()
const EmployeeDispenser = preload("res://scripts/employee_dispenser.gd")
var dispenser := EmployeeDispenser.new()
const DoorAudio = preload("res://scripts/door_audio.gd")
var door_audio := DoorAudio.new()
const SwarmAudio = preload("res://scripts/swarm_audio.gd")
var swarm_audio := SwarmAudio.new()
const CreatureAudio = preload("res://scripts/creature_audio.gd")
var flushfiend_death_audio := CreatureAudio.new("toilet")
var sputtervalve_audio := CreatureAudio.new("sputtervalve")
var creature_audio := {"toilet": flushfiend_death_audio, "sputtervalve": sputtervalve_audio,
	"spider": CreatureAudio.new("spider"), "gratecrawler": CreatureAudio.new("gratecrawler"),
	"sewer-fly-swarm": CreatureAudio.new("sewer-fly-swarm")}
const HeroDeathAudio = preload("res://scripts/hero_death_audio.gd")
var hero_death_audio := HeroDeathAudio.new()
var encounter_triggered: Array[bool] = [false,false,false,false,false,false,false]
const GATE_OPEN_SECONDS := 0.9
var gate_progress: Array[float] = [0,0,0,0,0,0]
var checkpoint_index := -1
var zone_seconds: Array[float] = [0,0,0,0,0,0]
var zone_damage: Array[int] = [0,0,0,0,0,0]

const Dialogue = preload("res://scripts/dialogue.gd")


const GRAVITY := 1250.0
const JUMP_SPEED := -465.0
const FLOOR_Y := 440.0
const PLAYER_SIZE := Vector2(26, 46)
const PLATFORMS = Level.PROPS
const INK := Color("101c2a")
const MINT := Color("7ce4bc")
const GOLD := Color("ffcf70")

var dialogue: Node2D
var camera_x := 0.0
var landed_platform := -1
var checkpoint_active := false
var respawn_point := Vector2(85, 394)


var player := Vector2(85, 390)
var velocity := Vector2.ZERO
var facing := 1.0
var current_aim := Vector2.RIGHT
var grounded := false
var coyote := 0.0
var jump_buffer := 0.0
var fire_timer := 0.0
var invulnerable := 0.0
var health := 5
var lives := 3
var life_state := "alive"
var death_time := 0.0
var death_ground_time := 0.0
var death_message: Dictionary = {}
var death_popup_locked := false
var death_popup_guard := 0.0
var animation_state := "idle"
var animation_time := 0.0
var landing_time := 0.0
var hurt_time := 0.0
var trigger_state: Dictionary = {}
var start_held: Dictionary = {}
var restart_guard_device := -1
var suppress_pause_frame := false
var player_kills := 0
var kills := 0
var elapsed := 0.0
var paused := false
var pause_menu: Control
var resume_button: Button
var title_button: Button
var pause_stick_latched := false
var won := false
var shots: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var music_director: Node
var audio_player: AudioStreamPlayer
var sound_playback: AudioStreamGeneratorPlayback
var tone_time := 0.0
var tone_frequency := 180.0
var tone_phase := 0.0

func _ready() -> void:
	Data.load_data()
	# Never process the damage atlas on the first visible enemy during gameplay.
	world_art.damage_art.prepare("toilet")
	assert(wastewater_art.configure(Data.bundle.wastewater))
	add_child(boss_hud)
	RenderingServer.set_default_clear_color(INK)
	add_action("left", [KEY_A, KEY_LEFT])
	add_action("right", [KEY_D, KEY_RIGHT])
	add_action("jump", [KEY_SPACE])
	add_action("aim_up", [KEY_W, KEY_UP])
	add_action("aim_down", [KEY_S, KEY_DOWN])
	add_action("shoot", [KEY_ENTER, KEY_KP_ENTER, KEY_J, KEY_X])
	add_action("dialogue_next", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	add_action("dialogue_skip", [KEY_TAB])
	if InputMap.has_action("restart"): InputMap.erase_action("restart")
	add_action("return_title", [KEY_Q])
	add_action("pause_game", [KEY_ESCAPE])
	add_pad_button("left", JOY_BUTTON_DPAD_LEFT)
	add_pad_button("right", JOY_BUTTON_DPAD_RIGHT)
	add_pad_button("jump", JOY_BUTTON_A)
	add_pad_button("aim_up", JOY_BUTTON_DPAD_UP)
	add_pad_button("aim_down", JOY_BUTTON_DPAD_DOWN)
	add_pad_button("shoot", JOY_BUTTON_X)
	add_pad_button("pause_game", JOY_BUTTON_START)
	add_pad_button("dialogue_next", JOY_BUTTON_A)
	add_pad_button("dialogue_skip", JOY_BUTTON_B)
	add_pad_axis("left", JOY_AXIS_LEFT_X, -1.0)
	add_pad_axis("right", JOY_AXIS_LEFT_X, 1.0)
	add_pad_axis("shoot", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	add_pad_axis("aim_up", JOY_AXIS_LEFT_Y, -1.0)
	add_pad_axis("aim_down", JOY_AXIS_LEFT_Y, 1.0)
	InputMap.action_set_deadzone("aim_up", 0.25)
	InputMap.action_set_deadzone("aim_down", 0.25)
	InputMap.action_set_deadzone("left", 0.25)
	InputMap.action_set_deadzone("right", 0.25)
	InputMap.action_set_deadzone("shoot", 0.25)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	audio_player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.1
	audio_player.stream = stream
	add_child(audio_player)
	audio_player.play()
	sound_playback = audio_player.get_stream_playback()
	dialogue = Dialogue.new()
	add_child(dialogue)
	create_pause_menu()
	dispenser.attach(self)
	door_audio.attach(self,Level.GATES.size())
	swarm_audio.attach(self)
	swarms.damaged.connect(_on_swarm_damaged)
	for sound in creature_audio.values(): sound.attach(self)
	hero_death_audio.attach(self)
	reset_game()

func create_pause_menu() -> void:
	pause_menu = Control.new()
	pause_menu.z_index = 30
	add_child(pause_menu)
	var buttons: Array[Button] = []
	for index in range(2):
		var button := Button.new()
		button.text = ["Resume", "Return to Main Menu"][index]
		button.position = Vector2(245, 286 + 54 * index)
		button.size = Vector2(470, 44)
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_color_override("font_color", Color("fff2cf"))
		button.add_theme_color_override("font_hover_color", Color("fff2cf"))
		button.add_theme_color_override("font_focus_color", Color("fff2cf"))
		button.add_theme_color_override("font_pressed_color", GOLD)
		button.add_theme_color_override("font_shadow_color", Color("080e15"))
		button.add_theme_constant_override("shadow_offset_x", 1)
		button.add_theme_constant_override("shadow_offset_y", 2)
		for signal_name in ["focus_entered", "focus_exited", "mouse_entered", "mouse_exited", "button_down", "button_up"]:
			button.connect(signal_name, queue_redraw)
		pause_menu.add_child(button)
		buttons.append(button)
	resume_button = buttons[0]
	title_button = buttons[1]
	resume_button.focus_neighbor_bottom = title_button.get_path()
	resume_button.focus_neighbor_top = title_button.get_path()
	title_button.focus_neighbor_bottom = resume_button.get_path()
	title_button.focus_neighbor_top = resume_button.get_path()
	resume_button.pressed.connect(resume_or_retry)
	title_button.pressed.connect(request_title)
	add_action("ui_up", [KEY_W])
	add_action("ui_down", [KEY_S])
	pause_menu.hide()

func set_paused(value: bool) -> void:
	paused = value
	door_audio.set_paused(value)
	for sound in creature_audio.values(): sound.set_paused(value)
	# The death popup pauses gameplay automatically, but lets the flush finish.
	hero_death_audio.set_paused(value and life_state not in ["death_popup","game_over"])
	pause_stick_latched = false
	pause_menu.visible = value
	if music_director != null: music_director.set_paused(value)
	if value:
		if not resume_button.disabled: resume_button.grab_focus()
	else:
		resume_button.release_focus()
		title_button.release_focus()
		# A confirmation press must be released before gameplay can use it.
		dialogue.awaiting_release = true
		dialogue.release_guard = 0.2
		dispenser.skip_armed = false
	queue_redraw()

func resume_or_retry() -> void:
	if death_popup_locked: return
	if life_state == "game_over":
		reset_game()
	elif life_state == "death_popup":
		respawn_after_death()
		set_paused(false)
		restore_pause_buttons()
	else:
		set_paused(false)

func restore_pause_buttons() -> void:
	resume_button.text = "Resume"
	resume_button.show()
	title_button.show()
	resume_button.position = Vector2(245, 255)
	title_button.position = Vector2(245, 345)
	style_pause_buttons()
	resume_button.disabled = false
	title_button.disabled = false

func style_pause_buttons() -> void:
	for button: Button in [resume_button, title_button]:
		button.size = Vector2(470, 48)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color.TRANSPARENT
		normal.border_color = MINT
		normal.set_border_width_all(0)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, normal)
		var pressed_style := normal.duplicate() as StyleBoxFlat
		pressed_style.content_margin_top = 2
		button.add_theme_stylebox_override("pressed", pressed_style)
		button.add_theme_color_override("font_disabled_color", Buttons.MUTED)
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = GOLD
		focus.set_border_width_all(2)
		button.add_theme_stylebox_override("focus", focus)

func draw_pause_plates() -> void:
	for button: Button in [resume_button, title_button]:
		if not button.visible: continue
		var chosen := button.has_focus() and not button.disabled
		Buttons.plate(self, Rect2(button.position - Vector2(20,13),Vector2(510,85)),
			chosen,button.is_hovered(),button.is_pressed(),button.disabled)
		if chosen:
			var pointer := button.position + Vector2(20,24)
			draw_colored_polygon(PackedVector2Array([
				pointer + Vector2(-4,-6), pointer + Vector2(5,0), pointer + Vector2(-4,6)
			]), MINT)

func update_death_popup_guard(delta: float) -> void:
	if not death_popup_locked: return
	var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	for action in ["shoot", "jump", "dialogue_next", "dialogue_skip", "pause_game", "return_title"]:
		held = held or Input.is_action_pressed(action)
	if held:
		death_popup_guard = 0.35
	else:
		death_popup_guard = maxf(0, death_popup_guard - delta)
	if death_popup_guard == 0:
		death_popup_locked = false
		resume_button.disabled = false
		title_button.disabled = false
		resume_button.grab_focus()

func restart_inputs_held() -> bool:
	for state: Vector2 in trigger_state.values():
		if state.x > 0.7 and state.y > 0.7: return true
	return restart_guard_device >= 0

func handle_developer_restart(event: InputEvent) -> bool:
	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		var triggers: Vector2 = trigger_state.get(event.device, Vector2.ZERO)
		if event.axis == JOY_AXIS_TRIGGER_LEFT: triggers.x = event.axis_value
		else: triggers.y = event.axis_value
		trigger_state[event.device] = triggers
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
		var was_held: bool = start_held.get(event.device, false)
		start_held[event.device] = event.pressed
		var triggers: Vector2 = trigger_state.get(event.device, Vector2.ZERO)
		if event.pressed and not was_held and triggers.x > 0.7 and triggers.y > 0.7:
			if not paused and not won and life_state == "alive" and not dialogue.active and restart_guard_device < 0:
				restart_guard_device = event.device
				reset_game()
				suppress_pause_frame = true
				return true
	if restart_guard_device >= 0:
		var triggers: Vector2 = trigger_state.get(restart_guard_device, Vector2.ZERO)
		if triggers.x < 0.25 and triggers.y < 0.25 and not start_held.get(restart_guard_device, false):
			restart_guard_device = -1
	return false

func _input(event: InputEvent) -> void:
	if handle_developer_restart(event):
		get_viewport().set_input_as_handled()
		return
	if not paused and not (won and pause_menu.visible): return
	if death_popup_locked or (won and (dialogue.awaiting_release or dialogue.release_guard > 0)):
		get_viewport().set_input_as_handled()
		return
	var navigate := false
	var confirm := false
	if event is InputEventJoypadButton and event.pressed:
		navigate = event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]
		confirm = event.button_index == JOY_BUTTON_A
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		if absf(event.axis_value) < 0.25: pause_stick_latched = false
		elif absf(event.axis_value) > 0.6 and not pause_stick_latched:
			navigate = true
			pause_stick_latched = true
	if navigate:
		if not resume_button.visible or resume_button.has_focus(): title_button.grab_focus()
		else: resume_button.grab_focus()
	if confirm:
		if title_button.has_focus(): request_title()
		else: resume_or_retry()
	if navigate or confirm: get_viewport().set_input_as_handled()

func request_title() -> void:
	if death_popup_locked: return
	door_audio.stop()
	swarm_audio.stop()
	for sound in creature_audio.values(): sound.stop()
	hero_death_audio.stop()
	dispenser.cancel()
	set_paused(false)
	set_process(false)
	set_physics_process(false)
	title_requested.emit()

func _exit_tree() -> void:
	door_audio.dispose()
	swarm_audio.dispose()
	for sound in creature_audio.values(): sound.dispose()
	hero_death_audio.dispose()
	dispenser.dispose()
	audio_player.stop()
	audio_player.stream = null
	sound_playback = null

func add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key: int in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func add_pad_button(action: String, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	InputMap.action_add_event(action, event)

func add_pad_axis(action: String, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected:
		trigger_state.erase(_device)
		start_held.erase(_device)
		if restart_guard_device == _device: restart_guard_device = -1
	if not connected and not won:
		set_paused(true)

func reset_game() -> void:
	dispenser.reset_stock()
	door_audio.stop()
	swarm_audio.stop()
	for sound in creature_audio.values(): sound.stop()
	hero_death_audio.stop()
	dispenser.cancel()
	boss_hud.end_encounter()
	if music_director != null: music_director.set_paused(false)
	weapon = Data.weapon(employee.weapon_id, employee.id)
	if weapon.is_empty():
		get_tree().quit(1)
		return
	corpses.clear()
	camera_x = 0.0
	checkpoint_active = false
	checkpoint_index = -1
	mission.configure([3,5,5,6,6,3,2])
	encounter_triggered.fill(false)
	gate_progress.fill(0)
	zone_seconds = [0,0,0,0,0,0]
	zone_damage = [0,0,0,0,0,0]
	respawn_point = Vector2(85, FLOOR_Y - PLAYER_SIZE.y)
	landed_platform = -1
	player = respawn_point
	velocity = Vector2.ZERO
	grounded = false
	coyote = 0.0
	jump_buffer = 0.0
	fire_timer = 0.0
	current_aim = Vector2(facing, 0)
	health = employee.max_health
	lives = 3
	life_state = "alive"
	death_time = 0
	death_ground_time = 0
	death_message = {}
	death_popup_locked = false
	death_popup_guard = 0
	animation_state = "idle"
	animation_time = 0
	landing_time = 0
	hurt_time = 0
	kills = 0
	player_kills = 0
	swarms.reset()
	won = false
	paused = false
	if pause_menu != null: pause_menu.hide()
	if resume_button != null: restore_pause_buttons()
	invulnerable = 1.0
	shots.clear()
	particles.clear()
	enemies.clear()

	if dialogue != null:
		dialogue.finish()

func activate_checkpoint(index: int = 0) -> void:
	if index <= checkpoint_index or dispenser.active or life_state != "alive" or health <= 0 \
		or lives <= 0 or dialogue.active: return
	var kind := "injured" if health < employee.max_health else "full_health"
	checkpoint_index = index
	checkpoint_active = true
	respawn_point = Vector2(Level.CHECKPOINTS[index], FLOOR_Y - PLAYER_SIZE.y)
	health = employee.max_health
	dispenser.start(self,kind,index)

func complete_job() -> void:
	if won:
		return
	won = true
	dialogue.start(Story.completion(employee.id))
	play_tone(540.0, 0.3)

func _process(delta: float) -> void:
	update_death_popup_guard(delta)
	if paused and life_state in ["alive", "dying"] and Input.is_action_just_pressed("dialogue_skip"):
		set_paused(false)
		return
	if (paused and Input.is_action_just_pressed("return_title")) or (
		won and not paused and not dialogue.active and not dialogue.awaiting_release
		and (Input.is_action_just_pressed("return_title") or Input.is_action_just_pressed("dialogue_skip"))):
		request_title()
		return
	if not won and not dispenser.actions_locked and Input.is_action_just_pressed("pause_game") and not suppress_pause_frame and restart_guard_device < 0 and life_state in ["alive", "dying"]:
		set_paused(not paused)
	suppress_pause_frame = false
	if music_director != null:
		music_director.set_paused(paused)
		music_director.duck_db = -4.0 if dialogue.active else 0.0
	door_audio.set_paused(paused or dialogue.active or dispenser.active or life_state != "alive" or won)
	swarm_audio.tick(self,delta)
	dispenser.tick(self,delta)
	dialogue.tick(delta, paused)
	update_completion_button()
	fill_audio()
	if not paused and not dialogue.active and not dispenser.active and not dispenser.just_finished:
		elapsed += delta
		zone_seconds[mini(mission.current_zone,5)] += delta
		boss_hud.tick(delta)
		for corpse: Dictionary in corpses:
			corpse.death_time += delta
			corpse.death_velocity += GRAVITY * delta
			corpse.pos.y = minf(FLOOR_Y - 36, corpse.pos.y + corpse.death_velocity * delta)
			corpse.flash = maxf(0, corpse.flash - delta)
	queue_redraw()

func update_completion_button() -> void:
	## The completed job has one existing action: return to title, never resume a finished run.
	if not won or dialogue.active: return
	resume_button.hide()
	title_button.position = Vector2(245, 300)
	pause_menu.show()
	var locked: bool = dialogue.awaiting_release or dialogue.release_guard > 0
	var was_disabled := title_button.disabled
	title_button.disabled = locked
	if locked: title_button.release_focus()
	if not locked and (was_disabled or not title_button.has_focus()): title_button.grab_focus()

func _physics_process(delta: float) -> void:
	if dispenser.just_finished:
		dispenser.just_finished = false
		return
	if dispenser.active: return
	if paused or life_state in ["game_over", "death_popup"]: return
	if life_state == "dying":
		step_death(delta)
		return
	if restart_guard_device >= 0: return
	if paused or won or dialogue.active or dialogue.release_guard > 0:
		return
	# Small substeps keep solid traversal and reinforcement timing stable under frame stalls.
	var steps := maxi(1, ceili(delta / (1.0 / 120.0)))
	var swarm_budget := minf(delta,0.1)
	for step in range(steps):
		var dt := delta / steps
		step_gates(dt)
		step_player(dt)
		step_combat(dt)
		if life_state == "alive" and swarm_budget > 0:
			swarms.step(self,minf(dt,swarm_budget))
			swarm_budget = maxf(0,swarm_budget-dt)
		if life_state != "alive": break
		step_encounters(dt)
	if life_state != "alive": return
	for index in range(Level.CHECKPOINTS.size()):
		if player.x >= Level.CHECKPOINTS[index] and index > checkpoint_index:
			activate_checkpoint(index)
			if dispenser.active: return
	if player.x >= 9450 and mission.completed():
		complete_job()
	camera_x = move_toward(camera_x, clampf(player.x - 320.0, 0.0, WORLD_WIDTH - 960.0), 400.0 * delta)
	for index in range(particles.size() - 1, -1, -1):
		particles[index].pos += particles[index].vel * delta
		particles[index].vel.y += 350.0 * delta
		particles[index].life -= delta
		if particles[index].life <= 0:
			particles.remove_at(index)

func step_gates(delta: float) -> void:
	if paused: return
	for index in range(Level.GATES.size()):
		# The final shutter waits for both encounters in the last room, as before.
		if index < mission.current_zone and not (index == 5 and mission.current_zone == 6):
			var before := gate_progress[index]
			gate_progress[index] = minf(1, before + delta / GATE_OPEN_SECONDS)
			door_audio.transition(index,before,gate_progress[index])

func move_player_body(position: Vector2, motion: Vector2, size: Vector2, delta: float) -> Dictionary:
	return Level.move_body(position,motion,size,delta,Level.solids(mission.current_zone,gate_progress))

func actor_solids() -> Array[Rect2]:
	return Level.solids(mission.current_zone,gate_progress)

func player_shot_solids() -> Array[Rect2]:
	return Level.solids(mission.current_zone,gate_progress)

func step_player(delta: float) -> void:
	if life_state != "alive" or restart_guard_device >= 0: return
	var was_grounded := grounded
	landing_time = maxf(0, landing_time - delta)
	hurt_time = maxf(0, hurt_time - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	fire_timer = maxf(0.0, fire_timer - delta)
	coyote = 0.11 if grounded else maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if not dispenser.actions_locked and Input.is_action_just_pressed("jump"):
		jump_buffer = 0.14
	var direction := Input.get_axis("left", "right")
	velocity.x = move_toward(velocity.x, direction * employee.move_speed, 1900.0 * delta)
	if direction != 0:
		facing = signf(direction)
	if jump_buffer > 0 and coyote > 0:
		velocity.y = JUMP_SPEED
		jump_buffer = 0.0
		coyote = 0.0
		grounded = false
		play_tone(360.0, 0.08)
	if Input.is_action_just_released("jump") and velocity.y < -170:
		velocity.y = -170
	velocity.y += GRAVITY * delta
	var motion := move_player_body(player, velocity, PLAYER_SIZE, delta)
	player = motion.pos
	velocity = motion.velocity
	grounded = motion.grounded
	if grounded and not was_grounded: landing_time = 0.12
	landed_platform = -1
	current_aim = aim_direction()
	update_animation(delta)
	if not dispenser.actions_locked and Input.is_action_pressed("shoot") and fire_timer <= 0 and not restart_inputs_held():
		var aim := current_aim
		if aim == Vector2.ZERO: return
		var muzzle := world_art.hero_aim_art.muzzle(self)
		var blocked := false
		# A long barrel must not spawn shots on the far side of a wall or shutter.
		var obstacles := player_shot_solids()
		obstacles.append(Rect2(0, FLOOR_Y, WORLD_WIDTH, 100))
		for obstacle in obstacles:
			if segment_hit(player + Vector2(13, 9), muzzle, obstacle) >= 0.0:
				blocked = true
		if not blocked:
			shots.append({"pos": muzzle, "dir": aim, "damage": weapon.damage, "speed": weapon.projectile.speed_pixels_per_second,
				"distance": 0.0, "range": weapon.projectile.max_travel_distance_pixels})
		fire_timer = weapon.attack_interval_seconds
		play_tone(310.0 if employee.id == "tony" else 110.0, 0.055)

func update_animation(delta: float) -> void:
	var phase := "idle"
	if not grounded:
		if velocity.y < -380: phase = "takeoff"
		elif velocity.y < -40: phase = "rising"
		elif velocity.y <= 40: phase = "apex"
		else: phase = "falling"
	elif landing_time > 0: phase = "landing"
	elif absf(velocity.x) > 20: phase = "run"
	if hurt_time > 0 and grounded and absf(velocity.x) <= 20: phase = "hurt"
	if phase != animation_state:
		animation_state = phase
		animation_time = 0
	else: animation_time += delta

func step_combat(delta: float) -> void:
	for enemy: Dictionary in enemies:
		enemy.phase += delta * 4.5

		var pursuit: Dictionary = Data.monster(enemy.id).pursuit
		var distance: float = player.x - enemy.pos.x
		if absf(distance) < pursuit.notice_range_pixels:
			enemy.aggro = true
		var speed: float = pursuit.chase_speed_pixels_per_second if enemy.aggro else pursuit.patrol_speed_pixels_per_second
		var dx := 0.0
		if enemy.aggro:
			dx = pursuit_velocity(enemy, distance, pursuit, delta)
		elif enemy.get("entering",false):
			enemy.direction = signf(distance)
			dx = enemy.direction * speed
		else:
			if enemy.pos.x <= enemy.home - pursuit.patrol_range_pixels: enemy.direction = 1.0
			if enemy.pos.x >= enemy.home + pursuit.patrol_range_pixels: enemy.direction = -1.0
			var next_x: float = clampf(enemy.pos.x + enemy.direction * speed * delta,
				enemy.home - pursuit.patrol_range_pixels, enemy.home + pursuit.patrol_range_pixels)
			dx = (next_x-enemy.pos.x) / maxf(delta,0.00001)
		if not enemy.aggro: enemy.horizontal_speed = dx
		var obstacles := actor_solids()
		var vy: float = enemy.get("vertical_speed",0.0)
		var navigation := FlushfiendNavigation.velocity(Rect2(enemy.pos,Vector2(38,36)),
			Vector2(dx,vy),enemy,delta,obstacles,move_player_body,GRAVITY,JUMP_SPEED)
		dx = navigation.x
		vy = navigation.y
		if dx != 0: enemy.direction = signf(dx)
		vy += GRAVITY * delta
		var motion := move_player_body(enemy.pos, Vector2(dx,vy), Vector2(38,36), delta)
		enemy.pos = motion.pos
		enemy.vertical_speed = motion.velocity.y
		enemy.grounded = motion.grounded
		enemy.flash = maxf(0.0, enemy.flash - delta)
		if Rect2(player, PLAYER_SIZE).intersects(Rect2(enemy.pos, Vector2(38, 36))):
			hurt_player()
	for index in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[index]
		var start: Vector2 = shot.pos
		var remaining: float = maxf(0, shot.range - shot.distance)
		var travel: float = minf(shot.speed * delta, remaining)
		var end := start + shot_direction(shot) * travel
		# Sweep the segment, so fast shots cannot tunnel through a target or solid ledge.
		var closest := 2.0
		var target := -1
		var swarm_target := -1
		var shot_solids := player_shot_solids()
		shot_solids.append(Rect2(0,FLOOR_Y,WORLD_WIDTH,100))
		for platform in shot_solids:
			var fraction := projectile_hit(start, end, platform, shot_direction(shot))
			if fraction >= 0 and fraction < closest: closest = fraction
		for enemy_index in range(enemies.size()):
			var enemy: Dictionary = enemies[enemy_index]
			var fraction := projectile_hit(start, end, Rect2(enemy.pos - Vector2(8, 5), Vector2(54, 46)), shot_direction(shot))
			if fraction >= 0 and fraction < closest:
				closest = fraction
				target = enemy_index
		for swarm_index in range(swarms.actors.size()):
			var fraction: float = swarms.shot_hit(start,end,swarm_index,7.0 if employee.id == "sean" else 2.0)
			if fraction >= 0 and fraction < closest:
				closest = fraction
				target = -1
				swarm_target = swarm_index
		shot.pos = end
		shot.distance += travel
		if closest <= 1:
			if target >= 0: damage_enemy(target, shot.damage, start.lerp(end, closest))
			elif swarm_target >= 0: swarms.damage(swarm_target,shot.damage)
			shots.remove_at(index)
		elif shot.distance >= shot.range or end.x < 0 or end.x > WORLD_WIDTH:
			shots.remove_at(index)

func flushfiend_projectile_rect(feet: Vector2) -> Rect2:
	# world_art draws a 43px body above its feet. The 36px movement collider
	# excludes its upper body and lets correctly aligned horizontal shots pass through it.
	return Rect2(feet + Vector2(-19, -43), Vector2(38, 43))

func projectile_hit(start: Vector2, end: Vector2, target: Rect2, direction: Vector2) -> float:
	# Sweep the visible projectile thickness, not an infinitely thin centerline.
	# Rotate its cross-section with aim; use identical geometry for enemies and walls.
	var radius := 7.0 if employee.id == "sean" else 2.0
	var extent := Vector2(absf(direction.y), absf(direction.x)) * radius
	return segment_hit(start, end, Rect2(target.position - extent, target.size + extent * 2))

func pursuit_velocity(enemy: Dictionary, distance: float, pursuit: Dictionary, delta: float) -> float:
	var speed: float = pursuit.chase_speed_pixels_per_second
	var dead_zone: float = pursuit.stop_distance_pixels
	var side := signf(distance) if absf(distance) > dead_zone else 0.0
	var turn: Dictionary = pursuit.turnaround
	var elapsed_turn: float = enemy.get("turn_elapsed", -1.0)
	var horizontal: float = enemy.get("horizontal_speed", 0.0)
	if elapsed_turn < 0 and side != 0 and side != enemy.direction:
		elapsed_turn = 0.0
		enemy.turn_start_speed = horizontal
	if elapsed_turn >= 0:
		elapsed_turn += delta
		horizontal = enemy.get("turn_start_speed", 0.0) * maxf(0, 1.0 - elapsed_turn / turn.brake_seconds)
		if elapsed_turn >= turn.total_before_reverse_pursuit_seconds and side != 0:
			enemy.direction = side
			elapsed_turn = -1.0
			horizontal = 0.0
		enemy.turn_elapsed = elapsed_turn
	else:
		var target := side * minf(speed, maxf(0, absf(distance) - dead_zone) / maxf(delta, 0.00001))
		horizontal = move_toward(horizontal, target, speed * delta / turn.accelerate_seconds)
		if side == 0: horizontal = 0.0
	enemy.horizontal_speed = horizontal
	return horizontal

func aim_direction() -> Vector2:
	var x := signf(Input.get_axis("left", "right"))
	var y := signf(Input.get_axis("aim_up", "aim_down"))
	var direction := Vector2(x, y)
	if direction == Vector2.ZERO or (grounded and y > 0 and x == 0): direction = Vector2(facing, 0)
	var names := {Vector2.LEFT:"left", Vector2.RIGHT:"right", Vector2.UP:"up", Vector2.DOWN:"down",
		Vector2(-1,-1):"up_left", Vector2(1,-1):"up_right", Vector2(-1,1):"down_left", Vector2(1,1):"down_right"}
	var allowed: Array = weapon.aiming.grounded_directions if grounded else weapon.aiming.airborne_directions
	if names[direction] not in allowed:
		direction = Vector2(facing, 0)
		if names[direction] not in allowed: return Vector2.ZERO
	return direction.normalized()

func shot_direction(shot: Dictionary) -> Vector2:
	# Older test fixtures use a scalar horizontal direction.
	return shot.dir if shot.dir is Vector2 else Vector2(shot.dir,0)

func segment_hit(start: Vector2, end: Vector2, area: Rect2) -> float:
	var delta := end - start
	var near := 0.0
	var far := 1.0
	for axis in range(2):
		if is_zero_approx(delta[axis]):
			if start[axis] < area.position[axis] or start[axis] > area.end[axis]: return -1.0
		else:
			var first: float = (area.position[axis]-start[axis])/delta[axis]
			var last: float = (area.end[axis]-start[axis])/delta[axis]
			near = maxf(near,minf(first,last))
			far = minf(far,maxf(first,last))
			if near > far: return -1.0
	return near

func _on_swarm_damaged(actor: Dictionary, lethal: bool) -> void:
	var sound = creature_audio["sewer-fly-swarm"]
	if lethal: sound.play_defeat()
	else: sound.play_hit(actor, elapsed)

func damage_enemy(index: int, amount: float, impact: Vector2, player_credit := true) -> void:
	if amount <= 0 or not is_finite(amount):
		push_error("Damage must be finite and positive")
		return
	var enemy: Dictionary = enemies[index]
	enemy.hp = clampf(enemy.hp - amount, 0, enemy.max_hp)
	enemy.flash = Data.bundle.visual_policy.hit_feedback.suggested_flash_seconds
	burst(impact, MINT)
	if enemy.hp > 0: creature_audio[enemy.id].play_hit(enemy, elapsed)
	if enemy.hp == 0:
		creature_audio[enemy.id].play_defeat()
		enemy.death_time = 0.0
		enemy.death_velocity = 0.0
		enemy.aggro = false
		enemy.erase("turn_elapsed")
		enemy.erase("turn_start_speed")
		enemy.erase("horizontal_speed")
		corpses.append(enemy)
		enemies.remove_at(index)
		kills += 1
		if player_credit: player_kills += 1
		if enemy.has("mission_id"): mission.register_defeat(enemy.mission_id)

func hurt_player() -> void:
	if dispenser.active or invulnerable > 0 or life_state != "alive":
		return
	health -= 1
	zone_damage[mini(mission.current_zone,5)] += 1
	invulnerable = 1.5
	hurt_time = 0.15
	velocity.y = -220.0
	player.x = maxf(22.0, player.x - 45.0)
	if health > 0: play_tone(65.0, 0.15)
	if health <= 0:
		health = 0
		lives -= 1
		life_state = "dying"
		tone_time = 0
		hero_death_audio.play_death()
		death_message = Story.choose_death_line()
		death_time = 0
		death_ground_time = 0
		animation_state = "death"
		animation_time = 0
		shots.clear()
		velocity.x = 0

func step_death(delta: float) -> void:
	if paused or life_state != "dying": return
	death_time += delta
	animation_time = death_time
	velocity.y += GRAVITY * delta
	var motion := move_player_body(player, velocity, PLAYER_SIZE, delta)
	player = motion.pos
	velocity = motion.velocity
	grounded = motion.grounded
	if grounded: death_ground_time += delta
	if death_time < 1.0 or death_ground_time < 0.45: return
	life_state = "game_over" if lives == 0 else "death_popup"
	death_popup_locked = true
	death_popup_guard = 0.35
	resume_button.disabled = true
	title_button.disabled = true
	resume_button.release_focus()
	title_button.release_focus()
	resume_button.text = "Retry" if lives == 0 else "Continue at Checkpoint" if checkpoint_active else "Continue at Entrance"
	style_pause_buttons()
	resume_button.position = Vector2(245, 326)
	title_button.position = Vector2(245, 416)
	set_paused(true)

func respawn_after_death() -> void:
	for sound in creature_audio.values(): sound.stop()
	if lives <= 0: return
	life_state = "alive"
	health = employee.max_health
	player = respawn_point
	camera_x = clampf(player.x - 320.0, 0.0, WORLD_WIDTH - 960.0)
	invulnerable = 3.0
	velocity = Vector2.ZERO
	current_aim = Vector2(facing, 0)
	grounded = true
	animation_state = "idle"
	animation_time = 0
	hurt_time = 0
	if checkpoint_active:
		dispenser.start(self,"respawn",checkpoint_index)
	dialogue.awaiting_release = true
	dialogue.release_guard = 0.2

func burst(position: Vector2, color: Color) -> void:
	for index in range(10):
		particles.append({"pos": position, "vel": Vector2(randf_range(-100, 100), randf_range(-140, 20)),
			"life": 0.4, "color": color})

func play_tone(frequency: float, duration: float) -> void:
	tone_frequency = frequency
	tone_time = duration

func fill_audio() -> void:
	if sound_playback == null:
		return
	for index in range(sound_playback.get_frames_available()):
		var sample := 0.0
		if tone_time > 0 and not paused:
			tone_phase += tone_frequency / 22050.0
			sample = (0.075 if fmod(tone_phase, 1.0) < 0.5 else -0.075) * minf(tone_time * 30.0, 1.0)
			tone_time -= 1.0 / 22050.0
		sound_playback.push_frame(Vector2(sample, sample))

func box(x: float, y: float, width: float, height: float, color: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), width, height), color)

func label_at(text: String, position: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	draw_set_transform(Vector2(-floorf(camera_x), 0))
	draw_room()
	wastewater_art.draw(self,camera_x,elapsed)
	for platform: Rect2 in PLATFORMS:
		Level.draw_prop(self, platform)
	for index in range(Level.GATES.size()):
		Level.draw_gate(self, index, gate_progress[index])
	swarms.draw(self,show_enemy_health_bars)
	for corpse: Dictionary in corpses:
		draw_toilet(corpse)
	for enemy: Dictionary in enemies:
		draw_toilet(enemy)
	dispenser.draw_world(self)
	if not dispenser.hides_hero() and (life_state != "alive" or invulnerable <= 0 or int(elapsed * 12) % 2 == 0):
		draw_sean(player)
	for shot: Dictionary in shots:
		var p: Vector2 = shot.pos
		draw_set_transform(p - Vector2(floorf(camera_x), 0), shot_direction(shot).angle())
		if employee.id == "tony":
			box(-15, -2, 21, 4, Color("70dfff"))
			box(-4, -1, 12, 2, Color("eaffff"))
		else:
			box(-16, -1, 16, 3, Color("ad7546"))
			box(-16, -1, 16, 1, GOLD)
			box(-3, -3, 6, 7, Color("a43d38"))
			box(0, -5, 5, 11, Color("e57356"))
			box(4, -6, 2, 13, Color("ffd09b"))
		draw_set_transform(Vector2(-floorf(camera_x), 0))
	for particle: Dictionary in particles:
		box(particle.pos.x, particle.pos.y, 4, 4, particle.color)
	draw_set_transform(Vector2.ZERO)
	draw_set_transform(Vector2(0, boss_hud.reserved_height()))
	draw_hud()
	draw_set_transform(Vector2.ZERO)
	dispenser.draw_overlay(self)
	if paused or (won and not dialogue.active):
		box(0, 0, 960, 540, Color(0.03, 0.07, 0.12, 0.88))
		if life_state in ["death_popup", "game_over"]:
			draw_death_popup()
			return
		draw_pause_panel()

func draw_pause_panel() -> void:
	var heading := "JOB COMPLETE" if won else "UNION BREAK"
	var heading_x := (960 - ThemeDB.fallback_font.get_string_size(heading,HORIZONTAL_ALIGNMENT_LEFT,-1,32).x) / 2
	label_at(heading, Vector2(heading_x+1,202), 32, Color("080e15"))
	label_at(heading, Vector2(heading_x,200), 32, Color("fff2cf"))
	var message := "BJ: Adequate. Return to work." if won else "Take your time. The toilets can wait."
	var message_x := (960 - ThemeDB.fallback_font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x) / 2
	label_at(message, Vector2(message_x,229), 18, Color("fff2cf"))
	draw_pause_plates()

func draw_death_popup() -> void:
	# Art approved reuse of this menu style; all copy and expressions remain live.
	box(150, 110, 660, 420, INK)
	box(150, 110, 660, 4, MINT)
	var portrait := Dialogue.Portraits.expression("bj", death_message.emotion)
	draw_texture_rect(portrait, Rect2(170, 140, 160, 160), false)
	label_at("GAME OVER" if lives == 0 else "LIFE LOST", Vector2(350, 153), 28, MINT)
	var paragraph := TextParagraph.new()
	paragraph.width = 425
	paragraph.add_string(death_message.text, ThemeDB.fallback_font, 21)
	paragraph.draw(get_canvas_item(), Vector2(350, 175), Color("f1eee4"))
	label_at("BJ", Vector2(170, 318), 17, GOLD)
	label_at("%d %s remaining" % [lives, "life" if lives == 1 else "lives"], Vector2(245, 510), 14, MINT)
	draw_pause_plates()

func draw_ellipse_shadow(feet: Vector2, size: Vector2) -> void:
	draw_set_transform(feet - Vector2(floorf(camera_x), 0), 0, size)
	draw_circle(Vector2.ZERO, 1, Color(0.02, 0.04, 0.06, 0.4))
	draw_set_transform(Vector2(-floorf(camera_x), 0))

func draw_room() -> void:
	world_art.draw_room(self)

func draw_sean(_position: Vector2) -> void:
	world_art.draw_sean(self)

func draw_toilet(enemy: Dictionary) -> void:
	world_art.draw_toilet(self, enemy)

func draw_hud() -> void:
	box(0, 0, 960, 82, Color(0.025, 0.055, 0.075, 0.9))
	box(28, 80, 904, 1, Color("365752"))
	label_at("DRAIN DAMAGE", Vector2(28, 31), 22, MINT)
	label_at(employee.weapon, Vector2(29, 53), 13, Color("a7b9be"))
	label_at(employee.name, Vector2(630, 30), 14, GOLD)
	label_at("LIVES", Vector2(630, 63), 12, GOLD)
	world_art.hero_aim_art.draw_lives(self, Vector2(684, 43))
	for index in range(employee.max_health):
		box(684 + index * 18, 17, 12, 13, Color("ef9270") if index < health else Color("344552"))
	draw_progress()
	BuildVersion.draw(self)

func draw_progress() -> void:
	label_at("CLEARED  %d / 30" % kills, Vector2(800, 30), 16, MINT)
	label_at("ZONE %d / 6 — %d HERE / %d TOTAL REMAINING" % [mini(mission.current_zone + 1,6), 0 if mission.completed() else mission.zone_counts[mission.current_zone]-mission.defeated[mission.current_zone], mission.remaining()], Vector2(29, 73), 12, Color("7e989f"))

func entrance_radius() -> float:
	var prepared: Dictionary = Data.monster("toilet").damage_art.runtime_preparation
	var scale: float = 43.0 / prepared.reference_body_height_pixels
	var radius := 20.0
	# Bound every pose and both mirrors, not just the smaller collision body.
	for frame: Dictionary in prepared.frames:
		radius = maxf(radius, maxf(frame.anchor[0],frame.region[2]-frame.anchor[0])*scale)
	return radius

func safe_entrance(x: float) -> bool:
	var radius := entrance_radius()
	var center := x + 19
	if center-radius < 0 or center+radius > WORLD_WIDTH: return false
	if center+radius > floorf(camera_x)-24 and center-radius < floorf(camera_x)+984: return false
	var body := Rect2(x,404,38,36)
	# Never insert behind a closed shutter that would prevent reaching this encounter.
	for solid in actor_solids():
		if solid.position.y >= FLOOR_Y: continue
		if body.grow(12).intersects(solid): return false
		if solid.size.y >= 260 and solid.position.x > minf(x,player.x) and solid.end.x < maxf(x,player.x):
			return false
	for enemy in enemies:
		if absf(enemy.pos.x-x)<radius*2+16: return false
	return true

func step_encounters(_delta: float) -> void:
	if dialogue.active or mission.completed(): return
	var stage := mission.current_zone
	var lane: Vector2 = Level.LANES[mini(stage,5)]
	# Leave the first swarm alone between the cleared entrance and the next wave.
	var trigger_x: float = 2270 if stage == 1 else lane.x-280
	if player.x >= trigger_x: encounter_triggered[stage] = true
	if not encounter_triggered[stage] or not mission.can_spawn(): return
	var radius := entrance_radius()
	# Prefer the forward edge; rear entry also works when the camera includes the closed gate.
	for side in [1.0,-1.0]:
		for offset in range(0,960,48):
			var x: float = floorf(camera_x) + (960+24+radius if side>0 else -24-radius) - 19 + side*offset
			if not safe_entrance(x): continue
			var id := mission.register_spawn()
			if id < 0: return
			var enemy := Data.spawn("toilet",Vector2(x,404))
			enemy.mission_id = id
			enemy.entering = true
			enemy.direction = signf(player.x-x)
			enemies.append(enemy)
			return
