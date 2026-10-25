extends SceneTree
const Debris = preload("res://scripts/flush_debris.gd")
const Flow = preload("res://scripts/flush_flow.gd")

class SilentAudio extends RefCounted:
	func play(_event: String) -> void: pass

class Swimmer extends RefCounted:
	var clock := 0.0
	var position := Vector2(0,259.2)
	var jump_height := 0.0
	var last_steering := Vector2.ZERO
	var damage_taken := 0
	var audio := SilentAudio.new()
	func project(point: Vector2) -> Vector2: return Vector2(480,300)+Vector2(point.x,point.y*140.0/360)

class Host extends Node2D:
	var employee := {"move_speed":235.0}
	var health := 100000
	var invulnerable := 0.0
	var requests := 0
	func hurt_player() -> void:
		requests += 1
		if invulnerable > 0: return
		health -= 1
		invulnerable = 1.5

static func definition() -> Dictionary:
	var source := OS.get_environment("FLUSH_LAYOUT")
	if source.is_empty(): source = "res://levels/level-two-flush-v3.json"
	return JSON.parse_string(FileAccess.get_file_as_string(source))

static func prop(id: String, point: Vector2, impact: float, radius: float = 22) -> Dictionary:
	return {"id":id,"prop":"dead_hamster" if radius == 40 else "corn","radius":radius,
		"at":impact-2,"duration":2.0,"impact_at":impact,"pos":point,"impact_pos":point,
		"height":100.0,"impacted":false,"retired":false}

func require(condition: bool, message: String) -> bool:
	if condition: return true
	push_error(message)
	quit(1)
	return false

func _initialize() -> void:
	var layout := definition()
	var debris := Debris.new()
	debris.configure(layout,"hard",42)
	# A hazard-free tail still supplies commands through cutoff; future impacts must be simulated.
	var clear := debris.safe_route(Vector2(220,0),[],34,0,Vector2.ZERO,235,false,0.5)
	if not require(clear.safe and clear.commands.size() == 120 and clear.ending_immunity == 0,
		"Hazard-free tail preserves horizon and immunity"): return
	if not require(clear.commands.slice(18).any(func(command: Vector2) -> bool: return command != Vector2.ZERO),
		"Hazard-free tail must guide active steering rather than protect passive drift"): return
	var final_bounds := Flow.annulus(35)
	if not require(clear.positions[-1].distance_to(Vector2.RIGHT*(final_bounds.x+final_bounds.y)*0.5) < 48,
		"Active tail must reach adaptive pocket"): return
	var incoming_contact := prop("new-contact",clear.positions[1],34+1.0/120)
	if not require(not debris.incoming_clear(clear,34,[incoming_contact]),
		"Incoming impact must not touch fixed witness regardless of immunity"): return
	if not require(not incoming_contact.impacted,"Incoming proof cannot mutate runtime prop"): return
	if not require(debris.incoming_clear(clear,34,[prop("far",Vector2(10000,0),34.2)]),
		"Separated incoming wave may use fixed witness"): return
	if not require(not debris.incoming_clear({"positions":[Vector2.ZERO],"commands":[]},34,[]),
		"Truncated route cannot prove remaining danger interval"): return
	var future := prop("future",Vector2(220,0),34.01,1000)
	var pending := debris.safe_route(Vector2(220,0),[future],34,0,Vector2.ZERO,235)
	if not require(not pending.safe,"Unimpacted future prop prevents hazard-free shortcut"): return
	var unreachable := prop("unreachable",Vector2(125,0),8)
	var cache := {"simulated":[unreachable.duplicate(true)],"frames":[],"allow_cutoff":true}
	var proof := debris.proof_frame(cache,0,8,1.0/120)
	if not require(proof.all_retired and not unreachable.retired,"Proof-only cutoff leaves runtime lifecycle intact"): return
	if not require(not proof.segments.is_empty(),"Cutoff retains just-completed crossing sweep"): return
	var future_cache := {"simulated":[prop("future-cutoff",Vector2(125,0),9)],"frames":[],"allow_cutoff":true}
	if not require(not debris.proof_frame(future_cache,0,8,1.0/120).all_retired,
		"Future unlanded prop cannot retire early"): return
	var first := debris.peek_props(7)
	if not require(first == debris.peek_props(7),"Peeking must not consume types"): return
	var all_types := debris.peek_props(9)
	var unique := {}
	for id in all_types: unique[id] = true
	if not require(unique.size() == 9 and unique.has("dead_hamster"),"Full nine-type bag"): return
	# Impact must remain at the announced anchor at the exact boundary.
	var item := prop("exact",Vector2(220,0),10,40)
	var segments := debris.move_hazard(item,9.9,0.1)
	if not require(item.pos == item.impact_pos and item.impacted and segments.size() == 1,"Exact impact anchor"): return
	segments = debris.move_hazard(item,10,0.5)
	if not require(not segments.is_empty(),"Danger must persist beyond old .35 expiry"): return
	if not require(item.pos != item.impact_pos,"Floating prop must follow current"): return
	# Swept collision catches a hero crossing a stationary hazard between endpoints.
	if not require(debris.touches(Vector2(-100,0),Vector2(100,0),0,1,
		[{"from":Vector2.ZERO,"to":Vector2.ZERO,"start":0,"end":1,"radius":54.0}]),"Swept hamster contact"): return
	for radius in [22.0,40.0]:
		var swallowed := prop("capture",Vector2(65-radius,0),1,radius)
		debris.move_hazard(swallowed,1,0.01)
		if not require(swallowed.retired,"Per-size full swallow"): return
	var cutoff := prop("cutoff",Vector2(180,0),35,40)
	if not require(debris.move_hazard(cutoff,34.9,0.1).is_empty(),"Final impact is harmless"): return
	if not require(not cutoff.retired and cutoff.impacted,"Final prop remains visible"): return
	var model := Swimmer.new()
	var host := Host.new()
	debris.configure(layout,"hard",42)
	debris.next_wave = layout.difficulty.hard.waves.size()
	model.clock = 12
	model.position = Vector2(220,0)
	debris.items.assign([prop("overlap1",model.position,10),prop("overlap2",model.position,10,40)])
	debris.advance(model,host,0.01)
	if not require(host.health == 99999 and host.requests == 1,"One shared damage request for overlapping floats"): return
	debris.advance(model,host,0.01)
	if not require(host.health == 99999,"Shared immunity retained"): return
	# Even a currently immune hero overlapping prior damage cannot earn a false safe witness.
	var before_bag := debris.peek_props(7).duplicate()
	var result := debris.safe_route(model.position,[],12,0,Vector2.ZERO,235)
	if not require(not result.safe,"No inherited-contact or immunity exemption in route proof"): return
	if not require(before_bag == debris.peek_props(7),"Failed candidate cannot consume bag"): return
	host.free()
	var repeat := Debris.new()
	debris.configure(layout,"hard",913)
	repeat.configure(layout,"hard",913)
	model.clock = 8
	model.position = Vector2(220,0)
	model.last_steering = Vector2.ZERO
	var wave: Dictionary = layout.difficulty.hard.waves[0]
	if not require(debris.spawn_wave(model,wave,0,235) and repeat.spawn_wave(model,wave,0,235),"Deterministic first cohort must be feasible"): return
	if not require(debris.ledger == repeat.ledger and debris.bag == repeat.bag,"Same seed and state must reproduce full cohort and witness"): return
	var committed: Dictionary = debris.ledger[-1]
	var phase := 24
	var at := float(committed.witness_start)+phase/120.0
	var matching: Vector2 = committed.witness_positions[phase]
	if not require(debris.prior_reaction(matching,at,235) == committed.witness.slice(phase,phase+18),
		"Matching prior witness continues next18 commands"): return
	if not require(not debris.prior_reaction(matching+Vector2(0.005,0),at,235).is_empty(),
		"Within-tolerance origin may propose continuation"): return
	if not require(debris.prior_reaction(matching+Vector2(0.02,0),at,235).is_empty(),
		"Deviated origin falls back"): return
	if not require(debris.prior_reaction(matching,at+0.001,235).is_empty(),"Off-grid phase falls back"): return
	if not require(debris.prior_reaction(matching,at,270).is_empty(),"Different hero speed falls back"): return
	var tail: int = committed.witness.size()-10
	if not require(debris.prior_reaction(committed.witness_positions[tail],8+tail/120.0,235).is_empty(),
		"Short prior tail falls back"): return
	# A tolerated position offset is still simulated; it does not waive actual contact.
	debris.reaction_commands = debris.prior_reaction(matching+Vector2(0.005,0),at,235)
	var actual_contact := prop("actual-contact",matching+Vector2(0.005,0),at)
	if not require(not debris.safe_route(matching+Vector2(0.005,0),[actual_contact],at,0,Vector2.ZERO,235).safe,
		"Continuation tolerance does not exempt real contact"): return
	for first_item in debris.items:
		for second_item in debris.items:
			if first_item.id == second_item.id: continue
			if not require(first_item.pos.distance_to(second_item.pos) >= first_item.radius+second_item.radius,"Mixed-size landing disks overlap"): return
	debris.configure(layout,"hard",913)
	if not require(debris.prior_reaction(matching,at,235).is_empty(),"Reset cannot reuse stale witness"): return
	print("PASS: nine-type bag, exact impacts, persistent swept mixed-size damage, shared immunity, capture and35 cutoff")
	quit()
