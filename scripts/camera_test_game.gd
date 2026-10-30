extends "res://scripts/integrated_first_call.gd"
## Separate proof entry; the existing Level 2 renderer and encounter sequence remain selectable.
const CameraModel = preload("res://scripts/camera_test_model.gd")
const CameraView = preload("res://scripts/camera_test_view.gd")
var camera_model := CameraModel.new()
var camera_view: Node3D
var turn_button: Button

func _ready() -> void:
	super._ready()
	dialogue.finish()
	dialogue.release_guard = 0
	dispenser.cancel()
	var container := SubViewportContainer.new()
	container.size = Vector2(960,540)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = -1
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960,540)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	camera_view = CameraView.new()
	viewport.add_child(camera_view)
	camera_view.configure(camera_model,flush.art.manifest,employee.id,difficulty,
		flush.ride.obstacle_art.manifest.rider_contacts)
	turn_button = Button.new()
	turn_button.text = "Turn camera"
	turn_button.hide()
	turn_button.position = Vector2(655,490)
	turn_button.size = Vector2(285,34)
	turn_button.z_index = 5
	turn_button.pressed.connect(turn_camera)
	add_child(turn_button)
	add_action("camera_test_turn",[KEY_C])
	add_pad_button("camera_test_turn",JOY_BUTTON_RIGHT_SHOULDER)

func reset_game() -> void:
	super.reset_game()
	camera_model.reset()
	if camera_view != null:
		camera_view.yaw = camera_view.FIRST_YAW
		camera_view.target_yaw = camera_view.FIRST_YAW
		camera_view.turn_start = camera_view.FIRST_YAW
		camera_view.turn_age = 1.2
	dialogue.finish()
	dialogue.release_guard = 0
	dispenser.cancel()

func respawn_after_death() -> void:
	super.respawn_after_death()
	camera_model.reset()
	dialogue.finish()
	dialogue.awaiting_release = false
	dialogue.release_guard = 0
	dispenser.cancel()

func turn_camera() -> void:
	if not paused and life_state == "alive": camera_view.request_turn(camera_model)

func _physics_process(delta: float) -> void:
	if camera_view == null or paused: return
	if life_state == "dying":
		# Retain the shared death/retry controls while the 3D rider descends into the hole.
		player = Vector2(85,FLOOR_Y-PLAYER_SIZE.y)
		grounded = true
		death_ground_time = maxf(death_ground_time,.5)
		super.step_death(delta)
	elif life_state == "alive":
		if Input.is_action_just_pressed("camera_test_turn"): turn_camera()
		if not camera_view.turning():
			camera_model.tick(delta,Input.get_vector("left","right","aim_up","aim_down"),
				Input.is_action_pressed("jump"))
		if camera_model.dead:
			health = 1
			invulnerable = 0
			hurt_player()
	camera_view.update_view(camera_model,delta,paused,death_time if life_state != "alive" else 0)
	if turn_button != null: turn_button.disabled = life_state != "alive" or camera_view.turning()

func _draw() -> void:
	if camera_view == null: return
	box(0,0,960,76,Color(0.025,.055,.075,.94))
	label_at("LEVEL 2.1 — CAMERA TEST",Vector2(24,30),22,MINT)
	draw_vitals(Vector2(625,12))
	box(0,466,960,74,Color(0.025,.055,.075,.94))
	label_at("%s  ·  %s  ·  camera %.0f°" % [employee.name,camera_model.surface,camera_view.yaw],
		Vector2(24,490),15,GOLD)
	BuildVersion.draw(self)
	if paused: draw_pause_panel()
