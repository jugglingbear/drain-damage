extends SceneTree
const Model = preload("res://scripts/ride_showcase_model.gd")

func _initialize() -> void: call_deferred("checks")

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func checks() -> void:
	var model := Model.new()
	var ball := {"x":0,"y":0,"width":100,"depth":60,"kind":"support","art_id":"float_ball"}
	var pipe := {"x":0,"y":0,"width":180,"depth":110,"kind":"support","art_id":"elbow_pipe_v2"}
	var full := Vector2(0,1)
	if not require(model._float_contact(ball,Vector2(90,40),Vector2(90,40),-1,0,.01,full) == INF,
		"Old float rectangle corner is empty space"): return
	if not require(model._float_contact(ball,Vector2.ZERO,Vector2.ZERO,-1,0,.01,full) == 0,
		"Grounded board hits the float body"): return
	# Art's round submerged float spans-55..45, centered5 below the water.
	model.render_height = 20
	if not require(is_equal_approx(model._float_distance(ball,Vector2.ZERO,Vector2.ZERO,-1,0,.01,0),.25),
		"Float vertical distance uses submerged center-5 and radius50"): return
	model.render_height = 46
	if not require(model._float_contact(ball,Vector2(-150,0),Vector2(150,0),-1,0,1,full) == INF,
		"Board above45 clears the complete float"): return
	model.render_height = 0
	if not require(model._float_contact(ball,Vector2(-150,0),Vector2(150,0),-1,0,1,full) < .5,
		"Swept crossing detects a float despite clear endpoints"): return
	ball.motion = {"axis":"y","amplitude":25,"period":2.4,"phase":0}
	if not require(model._float_contact(ball,Vector2(0,60),Vector2(0,60),-1,0,1.2,full) != INF,
		"Moving float sweeps into stationary board"): return
	for head in [72.0,84.0]:
		model.render_height = 0
		if not require(model._elbow_contact(pipe,Vector2(0,50),Vector2(0,50),-1,.01,head,full) == 0,
			"Grounded board touches visible pedestal"): return
		model.render_height = 6
		if not require(model._elbow_contact(pipe,Vector2(0,50),Vector2(0,50),-1,.01,head,full) == INF,
			"Jump clears pedestal in empty bank portion"): return
		if not require(model._elbow_contact(pipe,Vector2.ZERO,Vector2.ZERO,-1,.01,head,full) != INF,
			"Hero intersects the actual curved pipe"): return
		if not require(model._elbow_contact(pipe,Vector2(110,0),Vector2(110,0),-1,.01,head,full) == INF,
			"Space beyond finite outlet is clear above pedestal"): return
		if not require(model._elbow_contact(pipe,Vector2(100,0),Vector2(100,0),-1,.01,head,full) != INF,
			"Actual outlet lip contacts hero footprint"): return
		if not require(model._elbow_contact(pipe,Vector2(-200,0),Vector2(200,0),-1,.1,head,full) != INF,
			"Fast crossing cannot tunnel through bent pipe"): return
	ball.erase("motion")
	for hz in [30,60,120,144]:
		for airborne in [false,true]:
			var float_hit := false
			var elbow_hit := false
			model.render_height = 0
			model.jump_age = .15 if airborne else -1
			var elapsed := 0.0
			while elapsed < .3:
				var dt := minf(1.0/hz,.3-elapsed)
				var a := Vector2(-150+elapsed*1000,0)
				var b := Vector2(-150+(elapsed+dt)*1000,0)
				var age := .15+elapsed if airborne else -1.0
				float_hit = float_hit or model._float_contact(ball,a,b,age,elapsed,dt,full) != INF
				elbow_hit = elbow_hit or model._elbow_contact(pipe,a,b,age,dt,72,full) != INF
				elapsed += dt
			if not require(float_hit == not airborne,"Timed jump clears float consistently at every frame rate"): return
			if not require(elbow_hit,"Actual tall elbow remains solid during a centered jump"): return
	# Quadratic SAT retains disconnected intervals without duplicate endpoint explosion.
	var bands := Model._quadratic_band(1,-1,0,Vector2(-.1,0),full)
	if not require(bands.size() == 2 and bands[0].y < bands[1].x,"Two disconnected time bands remain distinct"): return
	print("PASS: actual float ellipsoid, moving sweep, elbow pedestal/bend/finite lip and both hero heights")
	quit()
