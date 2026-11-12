extends SceneTree
const Rain = preload("res://scripts/main_break_rain_damage.gd")
var checks := 0
var failures := 0

class Host extends Node2D:
	var camera_x := 0.0
	var allowed := true
	var targets: Array[Dictionary] = []
	func specials_allowed(_ignore := false) -> bool: return allowed
	func main_break_rain_targets(_activation: int, _tick: int) -> Array[Dictionary]: return targets

class Opening extends "res://scripts/opening_trial_game.gd":
	func specials_allowed(_ignore := false) -> bool: return true
	func actor_projectile_rect(actor: Dictionary) -> Rect2: return actor.test_rect
	func damage_trial_actor(actor: Dictionary, amount: float) -> void: actor.hp = maxf(0,actor.hp-amount)
	func damage_enemy(index: int, amount: float, _impact: Vector2, _credit := true) -> void:
		enemies[index].hp = maxf(0,enemies[index].hp-amount)
		if enemies[index].hp == 0: enemies.remove_at(index)

class QuietClog extends "res://scripts/clogfather_room.gd":
	func flush_events(_host: Node2D) -> void: encounter.drain_events()

class Integrated extends "res://scripts/integrated_first_call.gd":
	func specials_allowed(_ignore := false) -> bool: return true

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func target(id: String, region: Rect2, integer := false, hp := 200.0) -> Dictionary:
	var state := {"hp":hp,"blocked":false,"hits":[]}
	var result := {"id":id,"hp":hp,"regions":[region],"integer":integer,"state":state}
	result.damage = func(amount: float) -> float:
		if state.blocked: return 0
		var accepted := minf(state.hp,amount)
		state.hp -= accepted
		state.hits.append(amount)
		return accepted
	return result

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var host := Host.new()
	var inside := target("inside",Rect2(100,100,10,10))
	var outside := target("outside",Rect2(1100,100,10,10))
	var edge := target("edge",Rect2(960,100,10,10))
	var integer := target("boss",Rect2(200,100,10,10),true)
	integer.regions.append(Rect2(220,100,20,20))
	host.targets.assign([inside,outside,edge,integer,integer])
	var fractions := {}
	var applied := Rain.apply(host,37.5,1,1,fractions)
	check(applied.size() == 2 and inside.state.hp == 162.5,"Only positive-area viewport intersections hit")
	check(integer.state.hits == [37.0],"Multiple regions and duplicate descriptor hit logical boss once")
	check(Rain.apply(host,37.5,1,1,fractions).is_empty(),"Repeated tick cannot hit twice")
	integer.state.blocked = true
	Rain.apply(host,37.5,1,2,fractions)
	check(integer.state.hits.size() == 1 and fractions.fractions.boss == 0.5,"Blocked hit neither spends nor banks credit")
	integer.state.blocked = false
	Rain.apply(host,37.5,1,3,fractions)
	check(integer.state.hits == [37.0,38.0],"Accepted integer hits alternate37/38")
	host.camera_x = 1000
	Rain.apply(host,37.5,1,4,fractions)
	check(outside.state.hp == 162.5 and integer.state.hits.size() == 2,"Camera moves coverage on next pulse")
	host.allowed = false
	check(Rain.apply(host,37.5,1,5,fractions).is_empty() and fractions.last_tick == 4,"Paused/ineligible host consumes no tick")
	host.allowed = true
	for amount in [0.0,-1.0,INF,NAN]:
		check(Rain.apply(host,amount,1,5,fractions).is_empty(),"Invalid damage rejected")
	host.camera_x = 0
	Rain.apply(host,37.5,2,1,fractions)
	check(integer.state.hits.back() == 37 and fractions.activation == 2,"New activation resets fractional credit")
	host.targets.erase(integer)
	host.targets.erase(integer)
	Rain.apply(host,37.5,2,2,fractions)
	check(not fractions.fractions.has("boss"),"Removed target credit is discarded")
	var lethal := target("lethal",Rect2(10,10,10,10),true,20)
	host.targets.assign([lethal])
	Rain.apply(host,37.5,3,1,fractions)
	check(lethal.state.hp == 0 and not fractions.fractions.has("lethal"),"Lethal clamp leaves no fractional residue")
	host.free()
	check_host_wrappers()
	print("Main Break rain damage: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)

func check_host_wrappers() -> void:
	var game := Opening.new()
	game.enemies.assign([{"hp":20.0,"pos":Vector2(100,200)}, {"hp":30.0,"pos":Vector2(200,200)}])
	var live := {"hp":100.0,"active":true,"test_rect":Rect2(400,100,20,20)}
	var entering := {"hp":100.0,"active":false,"test_rect":Rect2(420,100,20,20)}
	game.actors.assign([live,entering,live])
	var swarm := game.swarms.spawn(Vector2(300,250),Rect2(200,200,300,200),1)
	swarm.hp = 100.0
	game.swarms.actors.append(swarm)
	var fractions := {}
	game.special_rain_damage(37.5,1,1,fractions)
	check(game.enemies.is_empty(),"Base wrapper lethal removals do not invalidate later indices")
	check(live.hp == 62.5 and entering.hp == 100,"Actor admission and shared logical identity respected")
	check(swarm.hp == 62.5,"Many visible flies damage aggregate swarm once")
	game.swarms.begin_entry(swarm)
	entering.active = true
	game.special_rain_damage(37.5,1,2,fractions)
	check(swarm.hp == 62.5 and entering.hp == 62.5,"Entering swarm excluded; newly admitted actor eligible")
	var edge_walker := {"hp":100.0,"pos":Vector2(-500,200),"entering":true}
	game.enemies.append(edge_walker)
	game.special_rain_damage(37.5,1,3,fractions)
	check(edge_walker.hp == 100,"Base edge walker outside viewport is protected")
	edge_walker.pos.x = 100
	game.special_rain_damage(37.5,1,4,fractions)
	check(edge_walker.hp == 62.5,"Visible base edge walker is damageable despite persistent pursuit flag")
	game.free()
	var integrated := Integrated.new()
	integrated.clogfather = QuietClog.new()
	var boss = integrated.clogfather.encounter
	boss.active = true
	boss.hp = 200
	boss.state = "recovery"
	boss.recovery_index = 1
	integrated.camera_x = integrated.clogfather.ORIGIN.x
	integrated.grounded = true
	var rain_state := {}
	integrated.special_rain_damage(37.5,1,1,rain_state)
	check(boss.hp == 163,"Boss wrapper applies first integer pulse through existing damage API")
	boss.recovery_index = 2
	integrated.special_rain_damage(37.5,1,2,rain_state)
	check(boss.hp == 163 and rain_state.fractions.clogfather == 0.5,"High weak point rejects grounded rain without banking")
	integrated.grounded = false
	integrated.special_rain_damage(37.5,1,3,rain_state)
	check(boss.hp == 125,"Airborne qualification accepts remaining38 through existing gate")
	boss.state = "volley_warning"
	boss.hp = boss.max_hp
	var gas := {"id":"rain-test","kind":"gas","hp":90,"rect":Rect2(200,200,40,40),"flash":0.0}
	boss.hazards.append(gas)
	var acid := {"kind":"acid","pos":Vector2(200,200),"age":0.0}
	boss.hazards.append(acid)
	integrated.special_rain_damage(37.5,1,4,rain_state)
	check(boss.hp == boss.max_hp and gas.hp == 53,"Closed boss protected while independent destructible gas is hit")
	check(boss.hazards.has(acid),"Non-damageable acid hazard is not cleared")
	integrated.special_rain_damage(37.5,1,5,rain_state)
	check(gas.hp == 15,"Gas integer fraction retained across accepted hits")
	integrated.free()
