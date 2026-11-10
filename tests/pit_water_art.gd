extends SceneTree
const Art = preload("res://scripts/pit_water_art.gd")
class SampleProfile extends RefCounted:
	var amount := 1.0
	func sample(_x: float) -> Dictionary:
		return {"water":amount, "flow":30.0}
class Water extends RefCounted:
	var profile := SampleProfile.new()
	var assets := {"water-a":{"source":Rect2(0, 0, 480, 56)}}
var checks := 0
func check(value: bool) -> void:
	checks += 1
	assert(value)
func _initialize() -> void:
	var art := Art.new()
	var water := Water.new()
	var opening := Vector2(1000, 1120)
	var exclusions := art.channel_exclusions([opening])
	check(exclusions.size() == 1 and exclusions[0].x == opening.y)
	check(is_equal_approx(exclusions[0].y, opening.y + 167.0894308943))
	for amount in [0.0, 0.02, 0.5, 1.0]:
		water.profile.amount = amount
		for clock in [0.0, 0.0799, 0.08, 0.4799, 0.48, 10.0]:
			var plan: Array = art.commands(water, opening, clock)
			check(plan == art.commands(water, opening, clock))
			if amount == 0:
				check(plan.is_empty())
				continue
			check(not plan.is_empty())
			check(plan[-1].id == "front")
			for command: Dictionary in plan:
				check(command.rect.position.y >= 440 and command.rect.end.y <= 540.001)
				check(command.alpha > 0 and command.alpha <= 1)
				if command.id == "left_spill":
					check(command.rect.position.x >= 988 and command.rect.end.x <= 1026.001)
	water.profile.amount = 1
	# Full-bore discharge stays continuous from the aperture into the downstream channel.
	var stream_end := -1.0
	var stream_count := 0
	for command: Dictionary in art.commands(water, opening, 0.0):
		if command.id != "water-a": continue
		if stream_end >= 0: check(is_equal_approx(command.rect.position.x, stream_end))
		stream_end = command.rect.end.x
		stream_count += 1
	check(stream_count == 96)
	var outlet: Dictionary = art.manifest.right_outlet
	check(is_equal_approx(float(outlet.mouth_aperture_source[3]) * outlet.uniform_scale, 56.0))
	var full_pipe: Rect2 = art.commands(water, opening, 0.0)[-1].rect
	water.profile.amount = 0.5
	check(art.commands(water, opening, 0.0)[-1].rect == full_pipe)
	check(full_pipe.position.x > opening.y)
	water.profile.amount = 1
	var before := art.commands(water, opening, 0.479999)
	var after := art.commands(water, opening, 0.48)
	var before_alpha := 0.0
	var after_alpha := 0.0
	for command: Dictionary in before:
		if command.id == "left_spill": before_alpha += command.alpha
	for command: Dictionary in after:
		if command.id == "left_spill": after_alpha += command.alpha
	check(absf(before_alpha - after_alpha) < 0.001)
	var paths := [art.manifest.left_spill.path, art.manifest.right_outlet.path]
	var hashes := []
	for path: String in paths: hashes.append(FileAccess.get_sha256("res://" + path))
	var host := Node.new()
	await art.prepare(host)
	for index in paths.size():
		check(hashes[index] == FileAccess.get_sha256("res://" + paths[index]))
	check(art.textures.size() == 3)
	check(art.textures.front.get_size() == art.textures.right_outlet.get_size())
	host.free()
	print("PIT_WATER_ART checks=", checks, " failures=0; visual acceptance pending")
	quit()
