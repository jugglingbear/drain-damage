extends RefCounted
const Costume = preload("res://scripts/hero_costume.gd")
## Independent body animation and aim layers share registration and muzzle geometry.
const MANIFEST := "res://assets/sprites/modular-aim-v1/runtime-manifest-beard-v2.json"
const ANIMATIONS := "res://assets/sprites/hero-animation-v2/manifest-beard-v3.json"
const RUN_OVERRIDES := {
	"tony":"res://assets/sprites/tony-run-v4/run-overrides-v1.json",
	"sean":"res://assets/sprites/sean-run-v4/run-overrides-v1.json",
}
const ANCHOR := Vector2(64, 104)
const BackpackArt = preload("res://scripts/backpack_jetter_art.gd")
var backpack := BackpackArt.new()
const HardArt = preload("res://scripts/hard_costume_art.gd")
var hard_mode := false
var costume := "normal"
var poses: Dictionary = {}
var textures: Dictionary = {}
var animations: Dictionary = {}

func _init(defer_preparation := false) -> void:
	if not defer_preparation: configure(false)

func configure(value: Variant, yield_frame := Callable()) -> void:
	var selected := Costume.mode(value)
	if not poses.is_empty() and costume == selected: return
	backpack.prepare()
	costume = selected
	hard_mode = costume == "hard"
	poses.clear()
	textures.clear()
	var pose_path := "res://assets/sprites/%s-mode/aim-manifest-v1.json" % costume if costume != "normal" else MANIFEST
	var animation_path := "res://assets/sprites/%s-mode/animation-manifest-v1.json" % costume if costume != "normal" else ANIMATIONS
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pose_path))
	for pose: Dictionary in data.poses:
		poses[pose.id] = pose
		for layer: Dictionary in pose.layers:
			if yield_frame.is_valid(): await yield_frame.call()
			load_texture(layer.path)
	animations = JSON.parse_string(FileAccess.get_file_as_string(animation_path))
	for hero_id in RUN_OVERRIDES:
		var runs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUN_OVERRIDES[hero_id]))
		animations.heroes[hero_id].phases.run = runs.costumes[costume].phase.duplicate(true)
	for pose: Dictionary in animations.additional_aim_poses:
		poses[pose.id] = pose
		for layer: Dictionary in pose.layers:
			if yield_frame.is_valid(): await yield_frame.call()
			load_texture(layer.path)
	for hero: Dictionary in animations.heroes.values():
		load_texture(hero.head_icon.path)
		for frame: Dictionary in hero.death:
			if yield_frame.is_valid(): await yield_frame.call()
			load_texture(frame.path)
		for phase: Dictionary in hero.phases.values():
			for frame: Dictionary in phase.frames:
				if yield_frame.is_valid(): await yield_frame.call()
				load_texture(frame.path)

func load_texture(path: String) -> void:
	if not textures.has(path): textures[path] = HardArt.texture(path)

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

# Fit an authored limb between its original shoulder/hand and the new hand target.
# Its cropped hand overlay receives the same transform as its parent arm.
func fit_layer(layer: Dictionary, anchor: Vector2, target: Vector2, rotation: float, scale: float) -> void:
	var pivot := backpack.vector(layer.pivot)
	var new_pivot := target + (pivot-anchor).rotated(rotation)*scale
	var dest := backpack.rectangle(layer.destination)
	dest.position = new_pivot+(dest.position-pivot)*scale
	dest.size *= scale
	layer.destination = [dest.position.x,dest.position.y,dest.size.x,dest.size.y]
	layer.pivot = [new_pivot.x,new_pivot.y]
	layer.rotation_degrees += rad_to_deg(rotation)

func planted_pose(game: Node2D, stance: String) -> Dictionary:
	var local_aim: Vector2 = Vector2(game.current_aim.x*game.facing,game.current_aim.y).normalized()
	var angle := local_aim.angle()
	var prefix: String = game.employee.id+"-"+stance+"-"
	var pose: Dictionary = poses[prefix+"right"].duplicate(true)
	var grip := backpack.vector(pose.grip)
	var support := backpack.vector(pose.support_hand)
	var muzzle_point := backpack.vector(pose.muzzle)
	# Blend the authored reach between registers while the bore follows the exact stick angle.
	var vertical := "up" if local_aim.y < 0 else "down"
	var diagonal_grip := backpack.vector(poses[prefix+vertical+"_right"].grip)
	var vertical_grip := backpack.vector(poses[game.employee.id+"-airborne-"+vertical].grip)
	var sector := clampf(absf(angle)/(PI*.25),0,2)
	var new_grip := grip.lerp(diagonal_grip,sector) if sector <= 1 else diagonal_grip.lerp(vertical_grip,sector-1)
	var muzzle_delta := (muzzle_point-grip).rotated(angle)
	var support_delta := (support-grip).rotated(angle)
	if backpack.enabled(game):
		var nozzle: Dictionary = backpack.definition.parts.nozzle
		muzzle_delta = local_aim*grip.distance_to(muzzle_point)
		var support_ratio := backpack.vector(nozzle.grip_source).distance_to(backpack.vector(nozzle.support_source)) \
			/ backpack.vector(nozzle.grip_source).distance_to(backpack.vector(nozzle.muzzle_source))
		support_delta = muzzle_delta*support_ratio
	if game.grounded and local_aim.y > 0:
		# Leave the muzzle above the supporting floor even at the bottom of the idle cycle.
		new_grip.y = minf(new_grip.y,ANCHOR.y-4-muzzle_delta.y)
	var new_support := new_grip+support_delta
	var new_muzzle := new_grip+muzzle_delta
	for layer: Dictionary in pose.layers:
		match layer.role:
			"weapon":
				fit_layer(layer,grip,new_grip,angle,1.0)
			"back_arm","front_hand","front_arm":
				var shoulder := backpack.vector(layer.pivot)
				var old_reach := (grip if layer.role == "front_arm" else support)-shoulder
				var new_reach := (new_grip if layer.role == "front_arm" else new_support)-shoulder
				fit_layer(layer,shoulder,shoulder,old_reach.angle_to(new_reach),new_reach.length()/old_reach.length())
	pose.grip = [new_grip.x,new_grip.y]
	pose.support_hand = [new_support.x,new_support.y]
	pose.muzzle = [new_muzzle.x,new_muzzle.y]
	return pose

func selected_pose(game: Node2D) -> Dictionary:
	var aim: Vector2 = game.current_aim
	var direction := "right"
	if aim.y < 0: direction = "up" if is_zero_approx(aim.x) else "up_right"
	elif aim.y > 0 and (not game.grounded or not is_zero_approx(aim.x)):
		direction = "down" if is_zero_approx(aim.x) else "down_right"
	var stance := "standing" if game.grounded else "airborne"
	var pose: Dictionary
	if not aim.is_zero_approx() and game.has_method("planted_aim") and game.planted_aim():
		pose = planted_pose(game,stance)
	else:
		pose = poses[game.employee.id + "-" + stance + "-" + direction].duplicate(true)
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

func draw(game: Node2D, tint := Color.WHITE) -> void:
	var base := world_transform(game)
	base.origin.x -= floorf(game.camera_x)
	var pose := selected_pose(game)
	var layers: Array = [death_frame(game)] if game.life_state != "alive" else pose.layers
	var equipment := backpack.enabled(game)
	var body := body_frame(game)
	var offset := Vector2.ZERO if body.is_empty() else Vector2(body.attachment_offset[0],body.attachment_offset[1])
	var death_equipment: Dictionary = {}
	if equipment:
		if game.life_state == "alive":
			backpack.draw_back(game,base,game.employee.id,costume,pose,offset,tint)
		else:
			var stage: int = animations.heroes[game.employee.id].death.find(layers[0])
			death_equipment = backpack.death_transforms(game.employee.id,costume,stage)
			backpack.draw_death_back(game,base,death_equipment,tint)
	for layer: Dictionary in layers:
		if equipment and layer.get("role","") == "weapon":
			backpack.draw_nozzle(game,base,pose,tint)
			continue
		var pivot := Vector2(layer.pivot[0], layer.pivot[1])
		var rotation := Transform2D(deg_to_rad(layer.rotation_degrees), Vector2.ZERO)
		rotation.origin = pivot - rotation * pivot
		game.draw_set_transform_matrix(base * rotation)
		var dest: Array = layer.destination
		var source: Array = layer.source_rect
		game.draw_texture_rect_region(textures[layer.path],
			Rect2(dest[0], dest[1], dest[2], dest[3]),
			Rect2(source[0], source[1], source[2], source[3]),tint)
		if equipment and game.life_state == "alive" and layer.get("role","") == "body":
			backpack.draw_strap(game,base,game.employee.id,costume,offset,tint)
	if not death_equipment.is_empty():
		backpack.draw_part(game,"nozzle",base*death_equipment.nozzle,tint)
	game.draw_set_transform(Vector2(-floorf(game.camera_x), 0))

func draw_lives(game: Node2D, origin: Vector2) -> void:
	var icon: Dictionary = animations.heroes[game.employee.id].head_icon
	var source: Array = icon.source_rect
	var size := Vector2(source[2], source[3])
	size *= 24.0 / maxf(size.x, size.y)
	for index in range(game.lives):
		game.draw_texture_rect_region(textures[icon.path], Rect2(origin + Vector2(index * 28, 24 - size.y), size),
			Rect2(source[0], source[1], source[2], source[3]))
