extends SceneTree
## Continuous trigger aim keeps the painted muzzle, both hands and fired trajectory registered.
const HeroArt = preload("res://scripts/hero_aim_art.gd")
const Crew = preload("res://scripts/crew.gd")

class Rider extends Node2D:
	var employee := Crew.TONY
	var facing := 1.0
	var player := Vector2(100,200)
	var current_aim := Vector2.RIGHT
	var grounded := true
	var animation_state := "idle"
	var animation_time := 0.0
	var velocity := Vector2.ZERO
	func planted_aim() -> bool: return true

func registration(layer: Dictionary) -> Transform2D:
	var pivot := Vector2(layer.pivot[0],layer.pivot[1])
	var transform := Transform2D(deg_to_rad(layer.rotation_degrees),Vector2.ZERO)
	transform.origin = pivot-transform*pivot
	return transform

func check_pose(art: RefCounted, host: Rider) -> void:
	var pose: Dictionary = art.selected_pose(host)
	var original: Dictionary = art.poses[pose.id]
	var base: Transform2D = art.world_transform(host)
	var grip: Vector2 = art.backpack.vector(pose.grip)
	var support: Vector2 = art.backpack.vector(pose.support_hand)
	var muzzle_point: Vector2 = art.backpack.vector(pose.muzzle)
	var nozzle_bore := Vector2.ZERO
	for index in pose.layers.size():
		var layer: Dictionary = pose.layers[index]
		var source: Dictionary = original.layers[index]
		var basis := registration(layer)
		match layer.role:
			"weapon":
				nozzle_bore = basis.x
			"front_arm","back_arm","front_hand":
				# Follow the same painted hand point from the original quad into the adjusted quad.
				var expected := grip if layer.role == "front_arm" else support
				var authored: Vector2 = art.backpack.vector(original.grip if layer.role == "front_arm" else original.support_hand)
				var original_point := registration(source).affine_inverse()*authored
				var source_rect: Rect2 = art.backpack.rectangle(source.destination)
				var rect: Rect2 = art.backpack.rectangle(layer.destination)
				var uv := (original_point-source_rect.position)/source_rect.size
				assert((basis*(rect.position+uv*rect.size)).distance_to(expected) < .001)
	if art.backpack.enabled(host):
		var part: Dictionary = art.backpack.definition.parts.nozzle
		var nozzle: Transform2D = art.backpack.nozzle_transform(pose)
		assert((nozzle*art.backpack.vector(part.support_source)).distance_to(support) < .001)
		assert((nozzle*art.backpack.vector(part.muzzle_source)).distance_to(muzzle_point) < .001)
		nozzle_bore = nozzle.x.normalized()
	assert(base.basis_xform(nozzle_bore).is_equal_approx(host.current_aim))
	assert((base*muzzle_point).is_equal_approx(art.muzzle(host)))
	if host.grounded and host.current_aim.y > 0: assert(muzzle_point.y < art.ANCHOR.y)

func _initialize() -> void:
	var art := HeroArt.new(true)
	var host := Rider.new()
	var cases := 0
	for costume in ["easy","normal","hard"]:
		art.configure(costume)
		for hero: Dictionary in Crew.EMPLOYEES:
			host.employee = hero
			for grounded in [true,false]:
				host.grounded = grounded
				for facing in [-1,1]:
					host.facing = facing
					for angle in range(-90,91,3):
						host.current_aim = Vector2.from_angle(deg_to_rad(angle))
						host.current_aim.x *= facing
						check_pose(art,host)
						cases += 1
	host.free()
	print("PASS: ",cases," continuous aim registrations for both heroes and all costumes")
	quit()
