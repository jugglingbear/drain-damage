extends SceneTree
const Fixtures = preload("res://tests/flush_scheduler.gd")
const Debris = preload("res://scripts/flush_debris.gd")
const Flow = preload("res://scripts/flush_flow.gd")

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func _initialize() -> void:
	var debris := Debris.new()
	debris.configure(Fixtures.definition(),"normal",42)
	if not require(debris.drain_crossing(Vector2(0,170),Vector2(0,170)),
		"Projected near lip extends beyond the old inner annulus"): return
	if not require(not debris.drain_crossing(Vector2(0,-70),Vector2(0,-70)),
		"Projected far side must not become a circular world-space exclusion"): return
	if not require(debris.drain_crossing(Vector2(-80,0),Vector2(80,0)),
		"A sweep with safe endpoints must still reject crossing the opening"): return
	# Check the conservative segment test against dense samples around the curved projected lip.
	for index in range(720):
		var angle := index*TAU/720
		for radius in [40.0,60.0,100.0,170.0,182.0,200.0]:
			var a: Vector2 = Vector2.from_angle(angle)*radius
			var b: Vector2 = a+Vector2.from_angle(angle+1.7)*4
			for sample in range(17):
				if Flow.drain_contact(a.lerp(b,sample/16.0),debris.drain_radii,debris.drain_projection,debris.drain_depth):
					if not require(debris.drain_crossing(a,b),"Dense lip sample escaped conservative sweep"): return
	var unsafe := debris.safe_route(Vector2(0,183),[],34,PI/2,Vector2.UP,235,true,1.5)
	if not require(not unsafe.safe,"Reaction and immunity cannot waive drain contact in a clear tail"): return
	var pending := Fixtures.prop("pending",Vector2(1000,0),34.5)
	if not require(not debris.safe_route(Vector2(0,183),[pending],34,PI/2,Vector2.UP,235,true,1.5).safe,
		"Active hazard branch cannot waive drain contact during recovery"): return
	var clear := debris.safe_route(Vector2(220,0),[],34,PI/2,Vector2.ZERO,235)
	if not require(clear.safe,"Clear tail should route around opening"): return
	for index in range(clear.commands.size()):
		if not require(not debris.drain_crossing(clear.positions[index],clear.positions[index+1]),
			"Hazard-free tail crosses drain"): return
	var corrupted: Dictionary = clear.duplicate(true)
	corrupted.positions[1] = Vector2.ZERO
	if not require(not debris.incoming_clear(corrupted,34,[]),"Empty incoming set cannot bypass drain validation"): return
	if not require(not debris.incoming_clear(corrupted,34,[Fixtures.prop("later",Vector2(1000,0),34.8)]),
		"Pre-impact route prefix cannot bypass drain validation"): return
	var fixed: Array = []
	for index in range(120): fixed.append(Vector2.LEFT)
	var replay := debris.safe_route(Vector2(80,0),[],34,0,Vector2.LEFT,235,true,1.5,fixed)
	if not require(not replay.safe,"Fixed continuation cannot cross drain"): return
	print("PASS: projected drain sweeps, reaction, fixed continuation, clear tails and pre-impact prefixes")
	quit()
