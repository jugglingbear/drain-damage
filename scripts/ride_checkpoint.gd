extends RefCounted
## Formal checkpoint beyond the second wave. Only a finished departure commits the respawn.
const DOCK := Vector2(455,330)
const PICKUP_MIN_X := 350.0
const PICKUP_MAX_X := 600.0
const LIFT_DELAY := 0.25
const LIFT_SECONDS := 3.5
const DEPARTURE_SECONDS := LIFT_DELAY + LIFT_SECONDS + 0.35
const DOCK_SECONDS := 0.65
const DISPENSER_ID := 200
var phase := ""
var age := 0.0
var saved := false
var course_finish := 0.0
var injured := false
var restored := false
var rocket_cleared := false
var pickup_point := DOCK
var throw_origin_screen := Vector2(480,260)

func enter_phase(next: String) -> void:
	phase = next
	age = 0

func stage(ride: RefCounted, host: Node2D) -> void:
	if course_finish == 0: course_finish = float(ride.definition.world_finish)
	ride.wave_three = false
	if not saved: host.dispenser.spent_checkpoints.erase(DISPENSER_ID)
	rocket_cleared = false
	ride.complete = false
	host.won = false
	ride.course = {"obstacles":[]}
	ride.visual_obstacles.clear()
	ride.encounter_scroll = course_finish-300
	ride.encounter_clock = ride.encounter_scroll/ride.scroll_speed
	ride.clock = ride.encounter_clock
	ride.jump_age = -1
	ride.render_height = 0
	ride.render_pitch = 0
	ride.ground_height = 0
	ride.cooldown = 0
	ride.jump_height = 0
	ride.ramp_active = false
	ride.boosted = false
	ride.steering_input = Vector2.ZERO
	ride.steering_velocity = Vector2.ZERO
	enter_phase("approach")

func restore(ride: RefCounted, host: Node2D) -> void:
	stage(ride,host)
	restored = true
	host.specials.refill_level(host.employee.id,"level-two")
	ride.position = DOCK
	host.life_state = "alive"
	host.health = host.employee.max_health
	host.checkpoint_active = true
	ride.obstacle_knockoff = false
	ride.sync_hero(host)
	begin_runout(ride)

func steer(ride: RefCounted, input: Vector2, dt: float) -> void:
	ride.steering_input = input.limit_length()
	var motion: Vector4 = ride.steer_motion(dt)
	ride.position = Vector2(motion.x,motion.y)
	ride.steering_velocity = Vector2(motion.z,motion.w)

func tick(ride: RefCounted, host: Node2D, dt: float, input: Vector2) -> void:
	host.invulnerable = maxf(0,host.invulnerable-dt)
	age += dt
	ride.clock += dt
	match phase:
		"approach":
			ride.position.x = move_toward(ride.position.x,minf(320,ride.position.x),dt*160)
			if age >= 3.0: enter_phase("waiting")
		"waiting":
			steer(ride,input,dt)
			if ride.jump_age < 0 and ride.position.x >= PICKUP_MIN_X and ride.position.x <= PICKUP_MAX_X:
				pickup_point = ride.position
				ride.steering_velocity = Vector2.ZERO
				ride.steering_input = Vector2.ZERO
				enter_phase("docking")
		"docking":
			ride.position = pickup_point.lerp(DOCK,smoothstep(0,DOCK_SECONDS,age))
			if age >= DOCK_SECONDS:
				injured = host.health < host.employee.max_health
				host.dispenser.start(host,"injured" if injured else "full_health",DISPENSER_ID)
				enter_phase("replacement")
		"replacement":
			if not host.dispenser.active:
				host.dispenser.just_finished = false
				enter_phase("departure")
		"departure":
			if rocket_cleared: steer(ride,input,dt)
			if age >= DEPARTURE_SECONDS:
				host.specials.refill_level(host.employee.id,"level-two")
				saved = true
				host.checkpoint_active = true
				begin_runout(ride)
	ride.sync_hero(host)

func rider_controls_active() -> bool:
	return phase in ["","approach","waiting","runout"] or (phase == "departure" and rocket_cleared)

func begin_runout(ride: RefCounted) -> void:
	enter_phase("runout")
	ride.phase = "rest"
	ride.rest_remaining = 5.0
