extends RefCounted
## Independent body animation and aim layers share registration and muzzle geometry.
const MANIFEST := "res://assets/sprites/modular-aim-v1/runtime-manifest-beard-v2.json"
const ANIMATIONS := "res://assets/sprites/hero-animation-v2/manifest-beard-v3.json"
const ANCHOR := Vector2(64, 104)
var poses: Dictionary = {}
var textures: Dictionary = {}
var animations: Dictionary = {}

func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for pose: Dictionary in data.poses:
		poses[pose.id] = pose
		for layer: Dictionary in pose.layers:
			load_texture(layer.path)
	animations = JSON.parse_string(FileAccess.get_file_as_string(ANIMATIONS))
	for pose: Dictionary in animations.additional_aim_poses:
		poses[pose.id] = pose
		for layer: Dictionary in pose.layers: load_texture(layer.path)
	for hero: Dictionary in animations.heroes.values():
		load_texture(hero.head_icon.path)
		for frame: Dictionary in hero.death: load_texture(frame.path)
		for phase: Dictionary in hero.phases.values():
			for frame: Dictionary in phase.frames: load_texture(frame.path)

func load_texture(path: String) -> void:
	if not textures.has(path): textures[path] = load("res://" + path)

func body_frame(game: Node2D) -> Dictionary:
	var phases: Dictionary = animations.heroes[game.employee.id].phases
	if not phases.has(game.animation_state): return {}
	var phase: Dictionary = phases[game.animation_state]
	var total := 0.0
	for frame: Dictionary in phase.frames: total += frame.duration
	var clock: float = game.animation_time
	if phase.loop:
		if game.velocity.x * game.facing < 0: clock = -clock
		clock = fposmod(clock, total)
	for frame: Dictionary in phase.frames:
		if clock < frame.duration: return frame
		clock -= frame.duration
	return phase.frames.back()

func death_frame(game: Node2D) -> Dictionary:
	var frames: Array = animations.heroes[game.employee.id].death
	if game.death_time < frames[0].duration: return frames[0]
	if not game.grounded: return frames[1]
	return frames[2] if game.death_ground_time < frames[2].duration else frames[3]

func selected_pose(game: Node2D) -> Dictionary:
	var aim: Vector2 = game.current_aim
	var direction := "right"
	if aim.y < 0: direction = "up" if is_zero_approx(aim.x) else "up_right"
	elif aim.y > 0 and (not game.grounded or not is_zero_approx(aim.x)):
		direction = "down" if is_zero_approx(aim.x) else "down_right"
	var stance := "standing" if game.grounded else "airborne"
	var pose: Dictionary = poses[game.employee.id + "-" + stance + "-" + direction].duplicate(true)
	var frame := body_frame(game)
	if frame.is_empty(): return pose
	var offset := Vector2(frame.attachment_offset[0], frame.attachment_offset[1])
	for index in range(pose.layers.size()):
		var layer: Dictionary = pose.layers[index]
		if layer.role == "body":
			pose.layers[index] = frame.duplicate(true)
			pose.layers[index].role = "body"
		else:
			layer.destination[0] += offset.x
			layer.destination[1] += offset.y
			layer.pivot[0] += offset.x
			layer.pivot[1] += offset.y
	for key in ["grip", "support_hand", "muzzle"]:
		pose[key][0] += offset.x
		pose[key][1] += offset.y
	pose.body_frame = frame.id
	return pose

func world_transform(game: Node2D) -> Transform2D:
	var flip := -1.0 if game.facing < 0 else 1.0
	var basis := Transform2D(Vector2(flip, 0), Vector2(0, 1), Vector2.ZERO)
	basis.origin = game.player + Vector2(13, 46) - basis * ANCHOR
	return basis

func muzzle(game: Node2D) -> Vector2:
	var point: Array = selected_pose(game).muzzle
	return world_transform(game) * Vector2(point[0], point[1])

func draw(game: Node2D) -> void:
	var base := world_transform(game)
	base.origin.x -= floorf(game.camera_x)
	var layers: Array = [death_frame(game)] if game.life_state != "alive" else selected_pose(game).layers
	for layer: Dictionary in layers:
		var pivot := Vector2(layer.pivot[0], layer.pivot[1])
		var rotation := Transform2D(deg_to_rad(layer.rotation_degrees), Vector2.ZERO)
		rotation.origin = pivot - rotation * pivot
		game.draw_set_transform_matrix(base * rotation)
		var dest: Array = layer.destination
		var source: Array = layer.source_rect
		game.draw_texture_rect_region(textures[layer.path],
			Rect2(dest[0], dest[1], dest[2], dest[3]),
			Rect2(source[0], source[1], source[2], source[3]))
	game.draw_set_transform(Vector2(-floorf(game.camera_x), 0))

func draw_lives(game: Node2D, origin: Vector2) -> void:
	var icon: Dictionary = animations.heroes[game.employee.id].head_icon
	var source: Array = icon.source_rect
	var size := Vector2(source[2], source[3])
	size *= 24.0 / maxf(size.x, size.y)
	for index in range(game.lives):
		game.draw_texture_rect_region(textures[icon.path], Rect2(origin + Vector2(index * 28, 24 - size.y), size),
			Rect2(source[0], source[1], source[2], source[3]))
