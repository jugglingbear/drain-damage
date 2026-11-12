extends SceneTree
const HeroArt = preload("res://scripts/hero_aim_art.gd")
class Host extends Node2D:
	var employee := {"id":"tony","weapon_id":"pressure-gun"}
	var life_state := "alive"
	var player := Vector2(170,310)
	var facing := 1.0
	var current_aim := Vector2.RIGHT
	var grounded := true
	var animation_state := "idle"
	var animation_time := 0.0
	var velocity := Vector2.ZERO
var count := 0
var failures: Array[String] = []
var support_gap := 0.0
func check(ok: bool, message: String) -> void:
	count += 1
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var host := Host.new()
	var art := HeroArt.new(true)
	for costume in ["easy","normal","hard"]:
		art.configure(costume)
		var pack = art.backpack
		for hero in ["tony","sean"]:
			host.employee = {"id":hero,"weapon_id":"pressure-gun" if hero == "tony" else "heavy-plunger"}
			check(pack.enabled(host) == (hero == "tony"),"Only existing pressure gun receives equipment")
			for phase: String in art.animations.heroes[hero].phases:
				host.animation_state = phase
				var time := 0.0
				for frame: Dictionary in art.animations.heroes[hero].phases[phase].frames:
					host.animation_time = time+float(frame.duration)*.5
					time += float(frame.duration)
					for facing in [-1.0,1.0]:
						host.facing = facing
						host.velocity.x = facing*100
						for grounded in [true,false]:
							host.grounded = grounded
							for aim in [Vector2.RIGHT,Vector2.UP,Vector2(1,-1),Vector2.DOWN,Vector2(1,1)]:
								host.current_aim = aim
								var pose := art.selected_pose(host)
								var original: Dictionary = art.poses[pose.id]
								var offset := pack.vector(art.body_frame(host).attachment_offset)
								var base := art.world_transform(host)
								check((base*art.ANCHOR).is_equal_approx(host.player+Vector2(13,46)),
									"Feet registration survives facing and locomotion")
								check(pack.vector(pose.muzzle).is_equal_approx(pack.vector(original.muzzle)+offset),
									"Muzzle attachment offset applied exactly once")
								check(art.muzzle(host).is_equal_approx(base*pack.vector(pose.muzzle)),
									"Projectile muzzle remains authored world anchor")
								var nozzle := pack.nozzle_transform(pose)
								check((nozzle*pack.vector(pack.definition.parts.nozzle.grip_source)).is_equal_approx(
									pack.vector(pose.grip)),"Nozzle meets original grip")
								check((nozzle*pack.vector(pack.definition.parts.nozzle.muzzle_source)).is_equal_approx(
									pack.vector(pose.muzzle)),"Nozzle meets original muzzle")
								check(is_equal_approx(nozzle.x.length(),nozzle.y.length()) and
									is_zero_approx(nozzle.x.dot(nozzle.y)),"Nozzle uses uniform orthogonal scale")
								var mount := pack.pack_transform(hero,costume,offset)
								check((mount*pack.vector(pack.definition.parts.pack.mount_source)).is_equal_approx(
									pack.vector(pack.definition.hero_registrations[hero][costume].pack_mount)+offset),
									"Pack mount receives one locomotion offset")
								check(is_equal_approx(mount.x.length(),mount.y.length()),"Pack scale stays uniform")
								if hero == "tony":
									support_gap = maxf(support_gap,(nozzle*pack.vector(
										pack.definition.parts.nozzle.support_source)).distance_to(pack.vector(pose.support_hand)))
		host.employee = {"id":"tony","weapon_id":"pressure-gun"}
		host.life_state = "dying"
		check(pack.enabled(host),"Tony retains equipment during death")
		for hero in ["tony","sean"]:
			var frames: Array = pack.definition.death_adapters.heroes[hero][costume].frames
			check(frames.size() == 4,"Each hero and costume has four death registrations")
			for stage in range(frames.size()):
				var frame: Dictionary = frames[stage]
				var transforms: Dictionary = pack.death_transforms(hero,costume,stage)
				for facing in [-1.0,1.0]:
					host.facing = facing
					var base := art.world_transform(host)
					check((base*transforms.pack*pack.vector(pack.definition.parts.pack.mount_source)).is_equal_approx(
						base*pack.vector(frame.pack_mount)),"Death pack uses absolute authored mount in either facing")
					check((base*transforms.nozzle*pack.vector(pack.definition.parts.nozzle.grip_source)).is_equal_approx(
						base*pack.vector(frame.released_nozzle_grip)),"Death nozzle uses released grip without locomotion offset")
				for part in ["pack","nozzle"]:
					var basis: Transform2D = transforms[part]
					check(is_equal_approx(basis.x.length(),basis.y.length()) and is_zero_approx(basis.x.dot(basis.y)),
						"Death equipment retains uniform orthogonal scale")
				check(is_equal_approx(transforms.pack.get_rotation(),deg_to_rad(frame.pack_rotation_degrees)),
					"Death pack uses authored rotation")
				check(is_equal_approx(transforms.nozzle.get_rotation(),deg_to_rad(frame.released_nozzle_rotation_degrees)),
					"Death nozzle uses authored rotation")
				check(is_equal_approx((transforms.nozzle*pack.vector(pack.definition.parts.nozzle.grip_source)).distance_to(
					transforms.nozzle*pack.vector(pack.definition.parts.nozzle.muzzle_source)),
					frame.released_nozzle_native_grip_to_muzzle),"Death nozzle retains authored length")
		host.life_state = "alive"
	host.free()
	print("Backpack jetter: %d checks, %d failures; max Tony support-hand gap %.3f px" % [
		count,failures.size(),support_gap])
	quit(0 if failures.is_empty() else 1)
