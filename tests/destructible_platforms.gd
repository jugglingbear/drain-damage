extends SceneTree
const Platforms = preload("res://scripts/basement_platforms.gd")
const Campaign = preload("res://scripts/campaign_encounters.gd")
const Navigation = preload("res://scripts/flushfiend_navigation.gd")
const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0

class QuietPlatforms extends "res://scripts/basement_platforms.gd":
	var cues: Array[String] = []
	func play_cue(id: String, event: String) -> void: cues.append(id+"/"+event)

class Host extends "res://scripts/integrated_first_call.gd":
	func step_hostile_projectiles(_delta: float) -> void: pass
	func specials_allowed(_ignore := false) -> bool: return true
	func play_trial_action(_actor: Dictionary, _event: String) -> void: pass
	func stop_trial_actions(_actor: Dictionary) -> void: pass

class QuietCreature extends RefCounted:
	func play_action(_event: String, _actor: Dictionary) -> void: pass

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func fixture() -> QuietPlatforms:
	var props := QuietPlatforms.new()
	props.placements.clear()
	for family in ["water-heater","cast-iron-boiler","pressure-tank"]:
		props.placements[family] = {"id":family,"family":family,"floor_center_anchor":[500,440]}
	props.placements.permanent = {"id":"permanent","family":"pipe-stack","floor_center_anchor":[800,440]}
	props.reset()
	return props

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var props := fixture()
	for family in ["water-heater","cast-iron-boiler","pressure-tank"]:
		props.reset()
		props.cues.clear()
		check(props.frame_id(family) == 0,"Starts intact: "+family)
		check(props.damage(family,18) == 18 and props.frame_id(family) == 1,"First shot damaged frame")
		props.damage(family,18)
		check(props.frame_id(family) == 2 and props.cues.size() == 1,"Heavy frame and hit throttling")
		props.damage(family,18)
		check(props.frame_id(family) == 3 and props.cues.back() == family+"/break","Lethal break once")
		check(props.damage(family,18) == 0 and props.cues.size() == 2,"No corpse rehit/replay")
		check(not props.advance(0.219) and not props.colliders(family).is_empty(),"Support retained until release")
		check(props.advance(0.001) and props.colliders(family).is_empty(),"Support released at0.22")
		props.advance(2)
		check(props.frame_id(family) == 15 and props.colliders(family).is_empty(),"Final wreck harmless/noncolliding")
		check(props.registered_frame(family).id == 15,"Sparse atlas selects actual registered wreck frame")
		props.reset()
		check(props.states[family].hp == 54 and props.frame_id(family) == 0,"Retry restores prop")
	check(props.damage("permanent",1000) == 0,"Permanent prop cannot break")
	for amount in [-1.0,0.0,NAN,INF]:
		check(props.damage("water-heater",amount) == 0,"Invalid damage rejected")
	check(not props.advance(NAN) and not props.advance(-1),"Invalid clocks rejected")
	check_support_fall()
	check_fragments()
	check_shots()
	check_authored_reset()
	await check_arrival_release()
	print("Destructible platforms: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)

func check_fragments() -> void:
	var props := fixture()
	for family in ["water-heater","cast-iron-boiler","pressure-tank"]:
		props.reset()
		props.damage(family,54)
		props.states[family].break_age = 0.219
		check(props.piece_poses(family).is_empty(),"Rigid pieces begin only at support release")
		var previous: Array[Dictionary] = []
		var registered: Array = props.assets[family].collapse_pieces.pieces
		for tick in range(71):
			props.states[family].break_age = 0.22+float(tick)/120
			var poses := props.piece_poses(family)
			check(poses.size() == registered.size(),"All material pieces persist through settling")
			for index in range(poses.size()):
				var pose: Dictionary = poses[index]
				var size := Vector2(registered[index].destination_size[0],registered[index].destination_size[1])
				check(pose.size == size,"Rigid fragment size never squashes or fades")
				var half_height: float = (absf(sin(pose.rotation))*size.x+absf(cos(pose.rotation))*size.y)/2
				check(pose.position.y+half_height <= 0.0001,"Fragments remain above floor")
				if not previous.is_empty():
					check(pose.position.distance_to(previous[index].position) < 20,"Collapse positions remain continuous")
				if pose.settled: check(half_height*2 <= 30.001,"Settled fragments cannot read as tall platforms")
			previous = poses
		props.states[family].break_age = 2.0
		check(props.piece_poses(family) == previous,"Settled fragments never disappear at end of collapse")

func check_authored_reset() -> void:
	var campaign := Campaign.new()
	campaign.reset("normal",85,42)
	var props = campaign.level.platforms
	check(props.targets().size() == 3,"Three explicitly admitted breakables loaded")
	var original := campaign.level.plinths.duplicate()
	var decks := campaign.level.decks.duplicate()
	var support: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/three-screen-trial/campaign-support-slices-v1.json"))
	for item: Dictionary in props.supplemental:
		if item.kind == "one_way":
			check(float(item.rect[2]) >= float(support.destination_caps.left)+float(support.destination_caps.right)
				or is_equal_approx(float(item.rect[2]),float(support.narrow_pedestal.width)),
				"Every supplemental deck has a supported Art construction width")
	var stand_positions: Array[Vector2] = []
	for target: Dictionary in props.targets():
		var asset: Dictionary = props.assets[props.placements[target.id].family]
		stand_positions.append(props.anchor(target.id)-Vector2(Game.PLAYER_SIZE.x/2,asset.height+Game.PLAYER_SIZE.y))
		for rect: Rect2 in target.regions:
			check(is_zero_approx(campaign.level.pit_overlap_fraction(rect)),"Every prop footprint lies over real floor")
	for target: Dictionary in props.targets(): props.damage(target.id,54)
	check(props.advance(0.22),"Authored props release")
	campaign.level.refresh_platforms()
	check(campaign.level.decks == decks,"Permanent bypass decks survive all destruction")
	check(campaign.level.plinths.size() < original.size(),"Material geometry removed")
	for start: Vector2 in stand_positions:
		var position := start
		var velocity := Vector2.ZERO
		for tick in range(240):
			velocity.y += Game.GRAVITY/120
			var motion := campaign.level.move_body(position,velocity,Game.PLAYER_SIZE,1.0/120)
			position = motion.pos
			velocity = motion.velocity
		check(position.y+Game.PLAYER_SIZE.y <= 440.01,"Destroyed authored prop drops hero onto safe support")
	campaign.reset("normal",4650,42)
	check(campaign.level.plinths == original and props.targets().size() == 3,"Checkpoint reset restores actual geometry")

func check_arrival_release() -> void:
	var host := Host.new()
	# Exercise the real admission/physics methods without starting unrelated menu/music/audio scenes.
	host.trial_data = host.Data.bundle.opening_trial
	host.trial_state.configure(host.trial_data.layout,host.trial_data.balance)
	host.creature_audio["toilet"] = QuietCreature.new()
	host.campaign.level.platforms = QuietPlatforms.new()
	await host.campaign.level.platforms.prepare(host)
	host.player = Vector2(1900,394)
	host.camera_x = 1600
	host.invulnerable = 100
	host.grounded = true
	for target: Dictionary in host.campaign.level.platforms.targets():
		var asset: Dictionary = host.campaign.level.platforms.assets[host.campaign.level.platforms.placements[target.id].family]
		for frame: Dictionary in asset.frames:
			if frame.has("path"):
				check(host.trial_textures.get(frame.path) is Texture2D,"Separate registered rubble texture loads")
	for already_destroyed in [false,true]:
		host.actors.clear()
		host.campaign.reset("normal",85,42)
		host.ledger = host.campaign.ledger
		host.trial_level = host.campaign.level
		host.tuning = host.campaign.tuning
		host.trial_clock = 10
		host.next_warning = 0
		for id: String in host.ledger: host.ledger[id] = "excluded"
		host.ledger["campaign-entry-c-entry"] = "pending"
		if already_destroyed:
			host.campaign.level.platforms.damage("entry-machine-1",54)
			host.campaign.level.platforms.advance(0.22)
			host.campaign.level.refresh_platforms()
		host.issue_event()
		check(host.actors.size() == 1,"Background arrival admitted with intact/destroyed support")
		if host.actors.is_empty(): continue
		var actor: Dictionary = host.actors[0]
		for tick in range(600):
			if not already_destroyed and actor.active and host.campaign.level.platforms.states["entry-machine-1"].hp > 0:
				host.campaign.level.platforms.damage("entry-machine-1",54)
			if host.campaign.level.platforms.advance(1.0/120): host.campaign.level.refresh_platforms()
			host.trial_clock += 1.0/120
			host.step_trial_actors(1.0/120)
		check(actor.active and actor.feet.y > 320,"Arriving/standing runner falls after support destruction")
	dispose_detached_host(host)

func check_support_fall() -> void:
	for hero in ["sean","tony"]:
		for hz in [60,120]:
			for family in ["water-heater","cast-iron-boiler","pressure-tank"]:
				var level := Campaign.Geometry.new()
				level.platforms = fixture()
				level.platforms.placements = {family:level.platforms.placements[family]}
				level.platforms.reset()
				level.width = 2000
				level.floor_y = 440
				level.refresh_platforms()
				var size := Game.PLAYER_SIZE
				var top: float = 440-level.platforms.assets[family].height
				var position := Vector2(487,top-size.y)
				var supported := level.move_body(position,Vector2(0,10),size,1.0/hz)
				check(supported.grounded and is_equal_approx(supported.pos.y,position.y),hero+" stands on "+family)
				level.platforms.damage(family,54)
				var velocity := Vector2.ZERO
				for tick in range(hz*2):
					if level.platforms.advance(1.0/hz): level.refresh_platforms()
					velocity.y += Game.GRAVITY/hz
					var motion := level.move_body(position,velocity,size,1.0/hz)
					position = motion.pos
					velocity = motion.velocity
				check(is_equal_approx(position.y+size.y,440),hero+" falls cleanly to floor "+family)
				var requested := Navigation.velocity(Rect2(Vector2(350,440-size.y),size),Vector2(90,0),{},
					1.0/hz,level.plinths,level.move_body,Game.GRAVITY,Game.JUMP_SPEED)
				check(requested == Vector2(90,0),"Runner does not navigate removed obstacle")

func check_shots() -> void:
	var host := Host.new()
	host.campaign.level.platforms = fixture()
	host.campaign.level.platforms.placements = {"cast-iron-boiler":host.campaign.level.platforms.placements["cast-iron-boiler"]}
	host.campaign.level.platforms.reset()
	host.campaign.level.refresh_platforms()
	host.trial_level = host.campaign.level
	for hero in ["sean","tony"]:
		host.employee = {"id":hero}
		host.campaign.level.platforms.reset()
		host.campaign.level.refresh_platforms()
		host.shots.assign([{"pos":Vector2(300,360),"dir":Vector2.RIGHT,"speed":1200.0,
			"damage":18.0,"range":1000.0,"distance":0.0}])
		host.step_trial_shots(0.2)
		check(host.campaign.level.platforms.states["cast-iron-boiler"].hp == 36,"Ordinary shot damages prop: "+hero)
		check(host.shots.is_empty(),"Impact consumes shot")
		host.campaign.level.permanent_plinths.append(Rect2(320,300,20,140))
		host.campaign.level.refresh_platforms()
		host.shots.assign([{"pos":Vector2(300,360),"dir":Vector2.RIGHT,"speed":1200.0,
			"damage":18.0,"range":1000.0,"distance":0.0}])
		host.step_trial_shots(0.2)
		check(host.campaign.level.platforms.states["cast-iron-boiler"].hp == 36,"Wall occludes prop")
		host.campaign.level.permanent_plinths.clear()
		host.special_rain_damage(37.5,1,1,{})
		host.special_damage([{"origin":Vector2(300,360),"end":Vector2(800,360),"width":160.0}],24,1,{})
		check(host.campaign.level.platforms.states["cast-iron-boiler"].hp == 36,"Rain and jet exclude scenery")
	dispose_detached_host(host)

func dispose_detached_host(host: Host) -> void:
	# These isolated hosts never enter the tree, so _ready never adopts eagerly allocated nodes.
	host.boss_hud.free()
	host.boss_intro.free()
	host.flush.radio.free()
	host.free()
