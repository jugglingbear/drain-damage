extends SceneTree
const Opening = preload("res://scripts/opening_trial_game.gd")
const Section = preload("res://scripts/three_screen_trial_game.gd")
var failures: Array[String] = []
var checks := 0

class Arena extends Opening:
	var terrain: Array[Rect2] = []
	func actor_solids() -> Array[Rect2]: return terrain

func _initialize() -> void: call_deferred("run_checks")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func prepare(game: Node2D) -> void:
	root.add_child(game)
	game.hide()
	game.set_process(false)
	game.set_physics_process(false)
	game.dispenser.cancel()
	game.dialogue.finish()
	game.dialogue.release_guard = 0
	game.life_state = "alive"
	game.player = Vector2(600,394)
	game.camera_x = 0

func actor(game: Node2D, feet: Vector2) -> Dictionary:
	game.actors.clear()
	game.create_actor({"id":"opening-09","role":"aggressive_flyer","warning_seconds":0.8},feet)
	var value: Dictionary = game.actors.back()
	value.merge({"feet":feet,"entry":{},"active":true,"attack_state":"landing","attack_clock":0.0,
		"attack_origin":Vector2(feet.x-100,190),"attack_direction":1.0,"contact_live":true},true)
	return value

func run_checks() -> void:
	var game := Arena.new()
	prepare(game)
	for hz in [30,60,120]:
		var dt: float = 1.0/hz
		game.terrain = [Rect2(0,440,1600,80)]
		var spider := actor(game,Vector2(500,370))
		for tick in range(hz):
			game.step_flyer(spider,dt)
			if spider.attack_state == "scuttle": break
		check(spider.attack_state == "scuttle","Supported descent lands")
		check(is_equal_approx(game.actor_rect(spider).end.y,440),"Feet contact floor")
		var start: Vector2 = spider.feet
		var snapshot := spider.duplicate(true)
		game.paused = true
		game.step_flyer(spider,dt)
		check(spider == snapshot,"Scuttle freezes on pause")
		game.paused = false
		var ticks := 0
		while spider.attack_state == "scuttle" and ticks < hz*2:
			game.step_flyer(spider,dt)
			ticks += 1
			check(game.actor_rect(spider).end.y <= 440.001,"No floor penetration")
		check(absf(ticks*dt-1.2) <= dt+0.001,"Ground window lasts1.2s")
		check(absf(spider.feet.x-start.x-78) <= 65*dt+0.01,"Scuttle speed65px/s")
		check(spider.attack_state == "takeoff","Grounded scuttle takes off")
		var takeoff_position: Vector2 = spider.feet
		for tick in range(int(hz*0.2)-1):
			game.step_flyer(spider,dt)
			check(spider.attack_state == "takeoff" and spider.feet == takeoff_position,"Supported takeoff hold")
		game.step_flyer(spider,dt)
		check(spider.attack_state == "recover","Takeoff lasts0.2s")
		for tick in range(hz*4): game.step_flyer(spider,dt)
		check(not spider.contact_live,"Recovery releases pattern")
		# Actual adjacent early-platform layout: partial contact used to skip landing forever.
		game.terrain = [Rect2(0,440,1600,80),Rect2(300,380,160,16),Rect2(460,320,240,16)]
		spider = actor(game,Vector2(480,280))
		spider.attack_state = "swoop"
		spider.attack_origin = spider.feet
		spider.attack_target = Vector2(380,416)
		var platform_scuttle := false
		var platform_recovered := false
		for tick in range(hz*6):
			game.step_flyer(spider,dt)
			for solid: Rect2 in game.terrain:
				check(not game.actor_rect(spider).intersects(solid),"Raised-platform dive stays outside solids")
			if spider.attack_state == "scuttle":
				platform_scuttle = true
				check(not game.flyer_support(spider.feet,0.02).is_empty(),"Raised crawl retains65% support")
			if platform_scuttle and spider.attack_state == "top_pause":
				platform_recovered = true
				break
		check(platform_scuttle and platform_recovered,"Partial platform landing crawls and returns to flight")
		game.terrain = []
		spider = actor(game,Vector2(500,370))
		for tick in range(hz+2): game.step_flyer(spider,dt)
		check(spider.attack_state == "recover","Pit never becomes midair scuttle")
		game.terrain = [Rect2(450,400,100,40)]
		spider = actor(game,Vector2(500,350))
		var scuttled := false
		for tick in range(hz*2):
			game.step_flyer(spider,dt)
			if spider.attack_state == "scuttle":
				scuttled = true
				check(not game.flyer_support(spider.feet,0.02).is_empty(),"Ledge crawl always supported")
			if scuttled and spider.attack_state == "takeoff": break
		check(scuttled and spider.attack_state == "takeoff","Ledge triggers early takeoff")
		game.terrain = [Rect2(0,440,1600,80),Rect2(555,330,40,110)]
		spider = actor(game,Vector2(500,370))
		for tick in range(hz):
			game.step_flyer(spider,dt)
			check(not game.actor_rect(spider).intersects(game.terrain[1]),"Wall blocks ground movement")
		check(spider.attack_state in ["takeoff","recover"],"Wall causes takeoff")
		spider = actor(game,Vector2(500,250))
		spider.attack_state = "swoop"
		spider.attack_origin = spider.feet
		spider.attack_target = Vector2(600,416)
		for tick in range(hz*3):
			game.step_flyer(spider,dt)
			check(not game.actor_rect(spider).intersects(game.terrain[1]),"Blocked dive/landing never penetrates wall")
		game.terrain = [Rect2(0,440,1600,80)]
		for state in ["scuttle","takeoff"]:
			spider = actor(game,Vector2(500,416))
			spider.attack_state = state
			spider.scuttle_direction = -1.0
			game.step_flyer(spider,dt)
			check(spider.feet.x <= 500,"Committed left heading supported")
			var hp: float = spider.hp
			game.shots.append({"pos":spider.feet-Vector2(50,0),"dir":Vector2.RIGHT,
				"damage":12,"speed":760,"range":320,"distance":0.0,"trial_id":"ground-test"})
			game.step_trial_shots(0.1)
			check(spider.hp == hp-12,"Ground spider remains vulnerable to ordinary shots")
			game.damage_trial_actor(spider,999)
			check(spider.hp == 0 and spider.defeat_recorded,"Ground death uses normal defeat cleanup")
			var dead := spider.duplicate(true)
			game.step_flyer(spider,dt)
			check(spider == dead,"Dead ground spider stops moving")
	game.free()
	check_section()
	print("Angel scuttle: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func check_section() -> void:
	var game := Section.new()
	prepare(game)
	game.camera_x = 1920
	for hz in [30,60,120]:
		for phase in ["landing","scuttle","takeoff"]:
			var spider := actor(game,Vector2(2500,416))
			spider.merge({"depth":"","source":spider.home,"bounds":Vector2(1810,2800),"end":2880,
				"phase":"combat","age":2.0,"volley_left":0,"post_pit_pursuit":true,
				"attack_state":phase,"scuttle_direction":1.0},true)
			game.player = Vector2(2490,394)
			game.grounded = true
			game.crossing_airborne = false
			game.crossing_until = 0
			game.health = game.employee.max_health
			game.invulnerable = 0
			game.step_trial_actors(1.0/hz)
			check(game.health == game.employee.max_health-1,"Section ground spider deals contact damage")
			game.step_trial_actors(1.0/hz)
			check(game.health == game.employee.max_health-1,"Contact respects normal immunity")
			spider.attack_state = phase
			game.player = Vector2(2300,300)
			game.grounded = false
			game.crossing_airborne = true
			game.step_trial_actors(1.0/hz)
			check(spider.attack_state == "recover" and not spider.contact_live,"Crossing cancels ground attack")
	game.free()
