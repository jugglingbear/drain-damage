extends SceneTree
const Launch = preload("res://scripts/playtest_launch.gd")

func _initialize() -> void:
	for index in range(1,14):
		assert(Launch.parse(["--level=2-%02d" % index]).has("error"))
	assert(Launch.parse(["--level=2-course"]).target.initializer == "ride-continuous")
	print("PASS: all thirteen retired encounter selectors rejected and two-wave course available")
	quit()
