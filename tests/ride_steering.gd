extends SceneTree
## Measure board acceleration, release, reversal and resets in the same model used by the game.
const Model = preload("res://scripts/ride_showcase_model.gd")
const Host = preload("res://tests/ride_showcase_course.gd").Host

func _initialize() -> void:
	for hz: int in [30,60,120]:
		var host := Host.new()
		var model := Model.new()
		model.definition = {"encounters":[{"id":"steering","obstacles":[
			{"id":"end","kind":"support","x":10000,"y":330,"width":40,"depth":40}],"end_x":10000,"rest_after_seconds":0}]}
		model.begin(host)
		var dt := 1.0/hz
		for i in hz/5: model.tick(host,dt,Vector2.RIGHT,false)
		assert(is_equal_approx(model.steering_velocity.x,model.x_speed))
		assert(is_equal_approx(model.position.x,300+model.x_speed*.125))
		var release_x: float = model.position.x
		for i in hz/10: model.tick(host,dt,Vector2.ZERO,false)
		assert(model.steering_velocity.is_zero_approx())
		assert(is_equal_approx(model.position.x-release_x,model.x_speed*.05))
		model.begin(host)
		model.tick(host,.15,Vector2.DOWN,true)
		assert(model.jump_age >= 0 and is_equal_approx(model.steering_velocity.y,model.bank_speed))
		var reversal_y: float = model.position.y
		model.tick(host,.045,Vector2.UP,false)
		assert(model.steering_input == Vector2.UP and model.steering_velocity.length() < .001)
		assert(is_equal_approx(model.position.y-reversal_y,model.bank_speed*.045/2))
		model.tick(host,.15,Vector2.UP,false)
		assert(is_equal_approx(model.steering_velocity.y,-model.bank_speed) and model.jump_age >= 0)
		model.tick(host,1,Vector2.UP,false)
		assert(model.position.y == 260 and model.steering_velocity.y == 0)
		model.tick(host,dt,Vector2.DOWN,false)
		assert(model.position.y > 260)
		model.tick(host,.2,Vector2.RIGHT,false)
		model.active_ramp = {"x":model.position.x+model.encounter_scroll-100,"width":200,"rise":40}
		model._launch(true)
		assert(model.steering_velocity.x == 0)
		var locked_x: float = model.position.x
		model.tick(host,dt,Vector2.RIGHT,false)
		assert(model.position.x == locked_x)
		model.begin(host)
		assert(model.steering_input == Vector2.ZERO and model.steering_velocity == Vector2.ZERO)
		model.course.obstacles = [{"id":"drain","kind":"gap","x":400,"y":330,"width":100,"depth":200}]
		model.tick(host,.15,Vector2.RIGHT,false)
		assert(host.life_state != "alive" and model.steering_velocity == Vector2.ZERO and model.steering_input == Vector2.ZERO)
		host.free()
	print("PASS: steering envelope, air reversal, wall release, boost lock and restart at 30/60/120 Hz")
	quit()
