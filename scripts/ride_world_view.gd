extends Node3D
## Presentation adapter: the existing ride model owns movement, timing, contacts and checkpoints.
const StaticBatches = preload("res://scripts/ride_static_batches.gd")
const FidgetView = preload("res://scripts/ride_fidget_view.gd")
const Proof = preload("res://scripts/camera_test_view.gd")
const Geometry = preload("res://scripts/camera_test_geometry.gd")
const Hand = preload("res://scripts/ride_world_hand.gd")
const Props = preload("res://scripts/ride_world_props.gd")
const UNIT := 100.0
# Preserve the simulation coordinates while matching the proof's four-metre waterway.
const BANK_SCALE := 2.0
const WATER_HALF := 2.0
var host: Node2D
var flush: RefCounted
var container: SubViewportContainer
var camera := Camera3D.new()
var rider := Node3D.new()
var fidget_view := FidgetView.new()
var materials: Dictionary = {}
var actors: Dictionary = {}
var actor_pool: Dictionary = {}
var actor_build_count := 0
var pooled_mesh_savings := 0
var preparation_usec := 0
var graphics_warmup_usec := 0
var manifest: Dictionary = {}
var configured := false
var hero_key := ""
var yaw := 18.0
var target_yaw := 18.0
var water: ShaderMaterial
var bed: ShaderMaterial
var waterfall: ShaderMaterial
var far_wall: ShaderMaterial
var near_wall: ShaderMaterial
var walkway: StandardMaterial3D
var course_distance := 0.0
var material_loader := Proof.new()
var helper_nodes: Array[Node] = [material_loader.camera,material_loader.rider]

func _exit_tree() -> void:
	for node in helper_nodes:
		if is_instance_valid(node): node.free()
	material_loader.free()
	if not configured:
		camera.free()
		rider.free()
		fidget_view.free()

func attach(game: Node2D, model: RefCounted) -> void:
	host = game
	flush = model
	container = SubViewportContainer.new()
	container.size = Vector2(960,540)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = -1
	container.visible = false
	host.add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960,540)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	container.add_child(viewport)
	viewport.add_child(self)
	host.add_action("ride_camera_turn",[KEY_C])
	host.add_pad_button("ride_camera_turn",JOY_BUTTON_RIGHT_SHOULDER)
	# Prepare while the game scene is being initialized, not on the live flush/ride timeline.
	configure()
	prepare_actors()
	warm_graphics()

func _process(delta: float) -> void:
	var showing: bool = flush.active and (flush.state == "ride" or flush.clock >= 43)
	container.visible = showing
	if not showing: return
	if not configured: configure()
	if not host.paused and host.life_state == "alive" and Input.is_action_just_pressed("ride_camera_turn"):
		target_yaw = -target_yaw
	if not host.paused: yaw = move_toward(yaw,target_yaw,delta*30)
	update_world()

static func world(point: Vector2, height := 0.0) -> Vector3:
	return Vector3(point.x/UNIT,height/UNIT,(point.y-330)/UNIT*BANK_SCALE)

func configure() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/ride-depth-v1/manifest.json"))
	for key: String in source.materials:
		materials[key] = material_loader.material_from(source.materials[key])
	for key in ["cast_iron","copper","rubber","bristles"]:
		materials[key].uv1_triplanar = true
		materials[key].uv1_world_triplanar = false
		materials[key].uv1_scale = Vector3.ONE*(256.0/619.0)
	materials.channel.albedo_color = Color(.52,.58,.56)
	materials.hole_wall.albedo_color = Color(.55,.57,.55)
	var support := ShaderMaterial.new()
	support.shader = preload("res://scripts/ride_support_material.gdshader")
	support.set_shader_parameter("iron_texture",materials.cast_iron.albedo_texture)
	materials["support_iron"] = support
	water = ShaderMaterial.new()
	water.shader = preload("res://scripts/ride_world_water.gdshader")
	water.set_shader_parameter("water_texture",material_loader.frame_texture(source.materials.water))
	Geometry.floor_patch(self,Rect2(-12,-2,50,4),0,water,true)
	waterfall = ShaderMaterial.new()
	waterfall.shader = preload("res://scripts/ride_world_waterfall.gdshader")
	waterfall.set_shader_parameter("water_texture",material_loader.frame_texture(source.materials.water))
	var flow_art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/ride-water-break-v1/manifest.json"))
	waterfall.set_shader_parameter("foam_texture",material_loader.frame_texture(flow_art.frames.inflow_foam))
	bed = ShaderMaterial.new()
	bed.shader = preload("res://scripts/ride_world_water.gdshader")
	bed.set_shader_parameter("water_texture",material_loader.frame_texture(source.materials.hole_wall))
	bed.set_shader_parameter("bed_surface",true)
	Geometry.floor_patch(self,Rect2(-12,-2,50,4),-.8,bed,true)
	far_wall = ShaderMaterial.new()
	far_wall.shader = preload("res://scripts/ride_world_wall.gdshader")
	far_wall.set_shader_parameter("wall_texture",material_loader.frame_texture(source.materials.channel))
	Geometry.slab(self,Rect2(-12,-2.4,50,.4),1.1,1.8,far_wall,far_wall)
	for child in get_children():
		if child is MeshInstance3D and child.material_override == far_wall:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	near_wall = far_wall.duplicate()
	Geometry.slab(self,Rect2(-12,2,50,.3),.12,.8,near_wall,near_wall)
	Geometry.floor_patch(self,Rect2(-12,-2,50,4),-2.0,materials.hole_wall,true)
	walkway = materials.hole_wall.duplicate() as StandardMaterial3D
	walkway.albedo_color = Color.WHITE
	Geometry.floor_patch(self,Rect2(-12,2.3,50,1.7),-.6,walkway,true)
	Geometry.floor_patch(self,Rect2(-12,-4,50,1.6),-.6,walkway,true)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("10242d")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d0d4d5")
	environment.environment.ambient_light_energy = .22
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-30,0)
	light.light_energy = .55
	light.shadow_enabled = true
	add_child(light)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.5
	camera.near = .1
	camera.far = 100
	add_child(camera)
	camera.current = true
	add_child(rider)
	add_child(fidget_view)
	fidget_view.configure()
	configured = true

func actor_signature(obstacle: Dictionary) -> String:
	var definition := obstacle.duplicate(true)
	definition.erase("visual_started")
	return JSON.stringify(definition)

func make_actor(obstacle: Dictionary) -> Node3D:
	var actor := Node3D.new()
	actor.visible = false
	actor.set_meta("pool_key",actor_signature(obstacle))
	actor.set_meta("obstacle",obstacle)
	add_child(actor)
	build_actor(actor,obstacle)
	pooled_mesh_savings += StaticBatches.compact(actor)
	actor_build_count += 1
	return actor

func prepare_actors() -> void:
	var start := Time.get_ticks_usec()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level-two-ride-showcase.json"))
	for encounter: Dictionary in source.encounters:
		for obstacle: Dictionary in encounter.obstacles:
			var key := actor_signature(obstacle)
			if not actor_pool.has(key): actor_pool[key] = []
			actor_pool[key].append(make_actor(obstacle))
	preparation_usec = Time.get_ticks_usec()-start

func warm_graphics() -> void:
	if DisplayServer.get_name() == "headless": return
	# Render into the hidden offscreen viewport during scene initialization. Merely allocating
	# hidden meshes does not compile first-draw shader variants on the compatibility renderer.
	var viewport := get_viewport() as SubViewport
	var old_mode := viewport.render_target_update_mode
	var old_size := camera.size
	camera.size = 20
	camera.position = Vector3(5,9,14)
	camera.look_at(Vector3(5,0,0))
	for pool: Array in actor_pool.values():
		for actor: Node3D in pool:
			actor.position = Vector3(5,0,0)
			actor.visible = true
	rebuild_rider()
	var effect_warmup := fidget_view.prepare_warmup()
	# force_draw does not flush newly added Node3D transforms from the scene tree.
	# Without this, the temporary effect quads remain occluded at their default origin.
	camera.force_update_transform()
	for node in effect_warmup: node.force_update_transform()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var start := Time.get_ticks_usec()
	RenderingServer.force_draw(false)
	RenderingServer.force_draw(false)
	graphics_warmup_usec = Time.get_ticks_usec()-start
	for node in effect_warmup:
		fidget_view.remove_child(node)
		node.free()
	for pool: Array in actor_pool.values():
		for actor: Node3D in pool:
			actor.visible = false
			actor.position = Vector3.ZERO
	camera.size = old_size
	viewport.render_target_update_mode = old_mode

func retire_actor(key: String) -> void:
	var actor: Node3D = actors[key]
	actor.visible = false
	var pool_key: String = actor.get_meta("pool_key")
	if not actor_pool.has(pool_key): actor_pool[pool_key] = []
	actor_pool[pool_key].append(actor)
	actors.erase(key)

func rebuild_rider() -> void:
	var mode: String = host.difficulty
	var key: String = host.employee.id+mode
	if key == hero_key: return
	hero_key = key
	for child in rider.get_children():
		rider.remove_child(child)
		child.queue_free()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Proof.MANIFEST))
	var contact: Array = source.rider_support_contacts[host.employee.id][mode]
	material_loader.rider = rider
	for frame: Dictionary in flush.art.manifest.landing[host.employee.id][mode].front:
		material_loader.add_rider_frame(frame,Vector2(contact[0],contact[1]))

func update_world() -> void:
	rebuild_rider()
	var riding: bool = flush.state == "ride"
	var model: RefCounted = flush.ride
	var point: Vector2 = model.position if riding else Vector2(300,330)
	var height: float = model.render_height if riding else 0.0
	var pitch: float = -model.render_pitch if riding else 0.0
	var focus := Vector3(5.2,1.05,0)
	camera.size = 5.5
	# Frame the full-width fracture during its telegraph/impact, then ease back after withdrawal.
	if riding and model.encounter_index == 10:
		var age: float = model.encounter_clock
		var framing := smoothstep(1.25,2.35,age)*(1-smoothstep(3.05,3.65,age))
		focus.y -= .68*framing
		camera.size = lerpf(5.5,7.4,framing)
	var angle := deg_to_rad(yaw)
	var tilt := deg_to_rad(35)
	focus.y -= (point.x/UNIT-focus.x)*sin(angle)*tan(tilt)
	camera.position = focus+Vector3(sin(angle)*cos(tilt),sin(tilt),cos(angle)*cos(tilt))*16
	camera.look_at(focus)
	# Preserve the billboard projection on a constant-bank plane. Camera-facing up vectors otherwise
	# lean the rider's head through the far wall in this narrow channel despite a valid ground footprint.
	var tangent := Vector3(cos(pitch),sin(pitch),0)
	var projected := Vector2(camera.basis.x.dot(tangent),camera.basis.y.dot(tangent))
	var facing := Basis(Vector3(1/cos(angle),tan(angle)*tan(tilt),0),Vector3(0,1/cos(tilt),0),Vector3.BACK)
	rider.basis = facing*Basis(Vector3.BACK,atan2(projected.y,projected.x))*Basis.from_scale(Vector3(projected.length(),1,1))
	if riding:
		height += sin(model.recovery_clock/.6*PI)*.2*UNIT
		if host.life_state != "alive" and model.events.has("fall"):
			var opening: Rect2 = model.fall_opening()
			if opening.has_area():
				var inset := Vector2(minf(55,opening.size.x*.5),minf(14,opening.size.y*.5))
				point = point.lerp(point.clamp(opening.position+inset,opening.end-inset),
					smoothstep(0,.22,float(host.death_time)))
			height -= pow(maxf(0,minf(float(host.death_time),model.FALL_DURATION)-.1),2)*460
	rider.position = world(point,height)
	rider.visible = not riding or model.rider_visible(host)
	update_actors(model if riding else null)
	fidget_view.update_effects(self,model if riding else null)
	waterfall.set_shader_parameter("flow_time",model.clock if riding else flush.landing_clock)
	# Use the continuous course clock, not encounter-local scroll, so banks do not snap at transitions.
	course_distance = model.clock*model.scroll_speed/UNIT if riding else flush.landing_clock*5.6
	for wall in [far_wall,near_wall]: wall.set_shader_parameter("course_distance",course_distance)
	walkway.uv1_offset.x = course_distance/4.0
	bed.set_shader_parameter("flow_offset",Vector2(course_distance/4.0,0))
	water.set_shader_parameter("flow_offset",Vector2(course_distance/4.0-
		(model.clock if riding else flush.landing_clock)*.14,0))

func update_actors(model: RefCounted) -> void:
	var live: Dictionary = {}
	var openings := PackedVector4Array()
	var hatches := PackedVector4Array()
	if model != null:
		for obstacle: Dictionary in model.visual_obstacles:
			live[str(obstacle.id)+":"+str(obstacle.get("visual_started",0))] = true
	# Return old instances before acquiring replacements, including checkpoint retries.
	for key: String in actors.keys():
		if not live.has(key): retire_actor(key)
	if model != null:
		for obstacle: Dictionary in model.visual_obstacles:
			var key := str(obstacle.id)+":"+str(obstacle.get("visual_started",0))
			if not actors.has(key):
				var pool_key := actor_signature(obstacle)
				var actor: Node3D
				if actor_pool.has(pool_key) and not actor_pool[pool_key].is_empty():
					actor = actor_pool[pool_key].pop_back()
				else:
					# Custom/debug courses remain supported; authored gameplay is fully prewarmed.
					actor = make_actor(obstacle)
				actors[key] = actor
			var actor: Node3D = actors[key]
			actor.set_meta("obstacle",obstacle)
			actor.visible = true
			var point: Vector2 = model.obstacle_position(obstacle)
			actor.position = world(point)
			if obstacle.kind in ["gap","long_pit"]:
				actor.get_node("opening").visible = model.obstacle_active(obstacle)
				if model.obstacle_active(obstacle):
					var half := Vector2(obstacle.width,obstacle.depth*BANK_SCALE)/200.0
					openings.append(Vector4(actor.position.x-half.x,actor.position.z-half.y,
						actor.position.x+half.x,actor.position.z+half.y))
			animate_actor(actor,obstacle,model)
			if actor.has_node("hand") and actor.get_node("hand").visible:
				var center: Vector3 = actor.get_node("hand").hatch_point+actor.position
				hatches.append(Vector4(center.x-.72,center.y-.48,center.x+.72,center.y+.48))
	far_wall.set_shader_parameter("hatch_count",mini(hatches.size(),8))
	hatches.resize(8)
	far_wall.set_shader_parameter("hatches",hatches)
	water.set_shader_parameter("opening_count",mini(openings.size(),32))
	var live_opening_count := openings.size()
	openings.resize(32)
	water.set_shader_parameter("openings",openings)
	bed.set_shader_parameter("opening_count",mini(live_opening_count,32))
	bed.set_shader_parameter("openings",openings)

func build_actor(actor: Node3D, obstacle: Dictionary) -> void:
	var width := float(obstacle.width)/UNIT
	var depth := float(obstacle.depth)/UNIT*BANK_SCALE
	var rect := Rect2(-width*.5,-depth*.5,width,depth)
	if obstacle.kind in ["gap","long_pit"]:
		var opening := Node3D.new()
		opening.name = "opening"
		actor.add_child(opening)
		var a := rect.position
		var b := rect.end
		var bank := (float(obstacle.y)-330)/UNIT*BANK_SCALE
		a.y = maxf(a.y,-WATER_HALF-bank)
		b.y = minf(b.y,WATER_HALF-bank)
		# Avoid coincident faces with channel walls; collision and water boundaries remain exact.
		a += Vector2(.006,.006)
		b -= Vector2(.006,.006)
		var rim: Array[Vector3] = [Vector3(a.x,0,a.y),Vector3(b.x,0,a.y),
			Vector3(b.x,0,b.y),Vector3(a.x,0,b.y)]
		for i in 4:
			Geometry.quad(opening,[rim[i],rim[(i+1)%4],rim[(i+1)%4]-Vector3.UP*2,rim[i]-Vector3.UP*2],
				materials.hole_wall)
		Geometry.floor_patch(opening,Rect2(a,b-a),-2,materials.hole_wall,true)
		# Water spills only from water-adjacent edges, never out of the solid channel banks.
		for edge in 4:
			if edge == 0 and a.y+bank <= -WATER_HALF+.02: continue
			if edge == 2 and b.y+bank >= WATER_HALF-.02: continue
			var p := rim[edge]
			var q := rim[(edge+1)%4]
			var inward := Vector3(-((q-p).z),0,(q-p).x).normalized()
			var length := p.distance_to(q)
			var previous_p := p-inward*.06+Vector3.UP*.008
			var previous_q := q-inward*.06+Vector3.UP*.008
			var previous_v := 0.0
			for step: Vector2 in [Vector2(.04,-.025),Vector2(.10,-.12),Vector2(.15,-.4),Vector2(.19,-1.9)]:
				var next_p := p+inward*step.x+Vector3.UP*step.y
				var next_q := q+inward*step.x+Vector3.UP*step.y
				Geometry.quad(opening,[previous_p,previous_q,next_q,next_p],waterfall,
					[Vector2(0,previous_v),Vector2(length,previous_v),Vector2(length,-step.y),Vector2(0,-step.y)])
				previous_p = next_p
				previous_q = next_q
				previous_v = -step.y
		if obstacle.has("activates_at"): build_fragments(actor,a,b)
		if str(obstacle.art_id) == "maintenance_hand_gap":
			var hand := Hand.new()
			hand.name = "hand"
			actor.add_child(hand)
			hand.configure(materials)
		if str(obstacle.art_id).begins_with("strainer_gap_"):
			var machine := Node3D.new()
			machine.name = "machine"
			actor.add_child(machine)
			Props.strainer(machine,width,depth,materials)
			for offset in [-8.0,8.0]:
				var support := Node3D.new()
				actor.add_child(support)
				support.position.x = offset
				gantry(support,obstacle)
	elif obstacle.kind == "deck":
		var top_height := float(obstacle.get("surface_height",12.0))/UNIT
		var metal: bool = str(obstacle.get("landing_material","porcelain")) == "metal"
		if metal:
			# A cover, collar, barrel and foot form one visible load path to the shaft floor.
			var radii := rect.size*.5
			Geometry.ellipse(actor,Vector2.ZERO,radii*.96,top_height-.18,-.28,
				materials.support_iron,materials.support_iron)
			Geometry.ellipse(actor,Vector2.ZERO,radii*.90,-.28,-1.90,
				materials.support_iron,materials.support_iron)
			Geometry.ellipse(actor,Vector2.ZERO,radii*.98,-1.90,-2,
				materials.support_iron,materials.support_iron)
			Geometry.ellipse(actor,Vector2.ZERO,radii*.92,-.61,-.69,
				materials.support_iron,materials.support_iron)
			for index in 8:
				var angle := TAU*index/8.0
				var point := Vector3(cos(angle)*radii.x*.91,-.65,sin(angle)*radii.y*.91)
				var bolt := Props.cylinder(actor,.035,.035,point,materials.brass_side)
				bolt.quaternion = Quaternion(Vector3.UP,Vector3(cos(angle)/radii.x,0,sin(angle)/radii.y).normalized())
			build_cap(actor,rect.size*.5,top_height)
		else:
			Geometry.slab(actor,rect,top_height,.18,materials.porcelain_top,materials.porcelain_side)
			for x in [-width*.3,width*.3]:
				Props.box(actor,Vector3(.34,.12,depth*.72),Vector3(x,top_height-.24,0),materials.support_iron)
				for z in [-depth*.28,depth*.28]:
					var post_top := top_height-.30
					Props.box(actor,Vector3(.26,post_top+2,.26),Vector3(x,(post_top-2)*.5,z),materials.support_iron)
					Props.box(actor,Vector3(.4,.10,.4),Vector3(x,-1.95,z),materials.support_iron)
			Geometry.ellipse(actor,Vector2(width*.28,0),Vector2(.14,.14),top_height+.003,top_height,
				materials.basin_drain,materials.porcelain_side)
	elif obstacle.kind == "ramp":
		build_ramp(actor,width,depth,float(obstacle.get("rise",40))/UNIT)
	else:
		build_prop(actor,obstacle)

func build_fragments(actor: Node3D, a: Vector2, b: Vector2) -> void:
	var debris := Node3D.new()
	debris.name = "debris"
	actor.add_child(debris)
	# A bounded deterministic fracture: irregular slab prisms retain the track's face/edge materials.
	for index in 18:
		var fragment := Node3D.new()
		debris.add_child(fragment)
		var angle := index*2.39996
		var radius := .08+float(index%4)*.025
		var points: Array[Vector3] = []
		for corner in 5:
			var turn := TAU*corner/5.0
			var scale := .75+float((index+corner)%3)*.15
			points.append(Vector3(cos(turn)*radius*scale,0,sin(turn)*radius*scale))
		for corner in 5:
			var p := points[corner]
			var q := points[(corner+1)%5]
			Geometry.mesh(fragment,PackedVector3Array([Vector3.ZERO,q,p]),
				PackedVector2Array([Vector2(.5,.5),Vector2(q.x,q.z)*3+Vector2.ONE*.5,
				Vector2(p.x,p.z)*3+Vector2.ONE*.5]),materials.channel)
			Geometry.quad(fragment,[p,q,q-Vector3.UP*.09,p-Vector3.UP*.09],materials.hole_wall)
		var start := Vector3(lerpf(a.x+.15,b.x-.15,float(index%3)/2),-.025,
			lerpf(a.y+.15,b.y-.15,float(index/3)/5))
		fragment.set_meta("start",start)
		fragment.set_meta("velocity",Vector3(cos(angle)*.55,.5+float(index%4)*.35,sin(angle)*.55))
		fragment.set_meta("spin",Vector3(sin(angle)*4,cos(angle)*3,2+float(index%3)))
		fragment.set_meta("bounds",Rect2(a+Vector2.ONE*.16,b-a-Vector2.ONE*.32))

func animate_fragments(actor: Node3D, age: float) -> void:
	var debris := actor.get_node("debris")
	debris.visible = age >= 0
	if age < 0: return
	for fragment: Node3D in debris.get_children():
		var start: Vector3 = fragment.get_meta("start")
		var velocity: Vector3 = fragment.get_meta("velocity")
		var bounds: Rect2 = fragment.get_meta("bounds")
		# Ballistic flight ends on the shaft floor; rubble remains until the whole opening departs.
		var landing := (velocity.y+sqrt(velocity.y*velocity.y+19.6*(start.y+1.9)))/9.8
		var time := minf(age,landing)
		var point := start+velocity*time-Vector3.UP*4.9*time*time
		point.x = clampf(point.x,bounds.position.x,bounds.end.x)
		point.z = clampf(point.z,bounds.position.y,bounds.end.y)
		fragment.position = point
		fragment.rotation = fragment.get_meta("spin")*time

func build_cap(actor: Node3D, radii: Vector2, top: float) -> void:
	# A physical shoulder catches light above the cylindrical wall; the top remains the model's 12cm plane.
	var inner := radii-Vector2.ONE*.015
	Geometry.ellipse(actor,Vector2.ZERO,inner,top-.015,top-.18,materials.brass_top,materials.brass_side,false)
	Geometry.ellipse(actor,Vector2.ZERO,radii,top,top-.001,materials.brass_top,materials.brass_side)
	for i in 96:
		var a := Vector2.from_angle(TAU*i/96.0)
		var b := Vector2.from_angle(TAU*(i+1)/96.0)
		Geometry.quad(actor,[Vector3(a.x*inner.x,top-.015,a.y*inner.y),
			Vector3(b.x*inner.x,top-.015,b.y*inner.y),Vector3(b.x*radii.x,top,b.y*radii.y),
			Vector3(a.x*radii.x,top,a.y*radii.y)],materials.brass_side)

func build_ramp(actor: Node3D, width: float, depth: float, rise: float) -> void:
	# Use the simulation's quadratic contact surface, with closed sides continuing to the bed.
	for i in 48:
		var a := float(i)/48
		var b := float(i+1)/48
		var x0 := (a-.5)*width
		var x1 := (b-.5)*width
		var h0 := rise*a*a
		var h1 := rise*b*b
		Geometry.quad(actor,[Vector3(x0,h0,-depth*.5),Vector3(x1,h1,-depth*.5),
			Vector3(x1,h1,depth*.5),Vector3(x0,h0,depth*.5)],materials.ramp_top,
			[Vector2(a*width,0),Vector2(b*width,0),Vector2(b*width,depth),Vector2(a*width,depth)])
		for z in [-depth*.5,depth*.5]:
			Geometry.quad(actor,[Vector3(x0,h0,z),Vector3(x1,h1,z),Vector3(x1,-.8,z),Vector3(x0,-.8,z)],
				materials.ramp_side,[Vector2(x0,h0),Vector2(x1,h1),Vector2(x1,-.8),Vector2(x0,-.8)])
	for x in [-width*.5,width*.5]:
		var top := rise if x > 0 else 0.0
		Geometry.quad(actor,[Vector3(x,top,-depth*.5),Vector3(x,top,depth*.5),
			Vector3(x,-.8,depth*.5),Vector3(x,-.8,-depth*.5)],materials.ramp_side)
	# Exposed stiffeners connect the inclined plate to a bed-level footing on both visible sides.
	for z in [-depth*.5,depth*.5]:
		Props.box(actor,Vector3(width,.10,.12),Vector3(0,-.75,z),materials.support_iron)
		for fraction in [.2,.5,.8]:
			# Use the lower edge of each rib's width, leaving clearance beneath the curved plate.
			var contact_fraction: float = maxf(0,fraction-.05/width)
			var height: float = rise*contact_fraction*contact_fraction-.035
			Props.box(actor,Vector3(.10,height+.7,.08),
				Vector3((fraction-.5)*width,(height-.7)*.5,z),materials.support_iron)

func build_prop(actor: Node3D, obstacle: Dictionary) -> void:
	Props.build(actor,obstacle,materials,BANK_SCALE)
	if obstacle.kind == "overhead": gantry(actor,obstacle)

func gantry(actor: Node3D, obstacle: Dictionary) -> void:
		var offset := -(float(obstacle.y)-330)/UNIT*BANK_SCALE
		var beam_height := 3.3 if str(obstacle.art_id).begins_with("strainer_gap_") else 2.4
		# A braced far-wall cantilever leaves the foreground play corridor unobstructed.
		Props.box(actor,Vector3(.18,.18,4.7),Vector3(0,beam_height,offset),materials.cast_iron)
		Props.box(actor,Vector3(.24,beam_height+.8,.24),Vector3(0,(beam_height-.8)*.5,-2.25+offset),materials.cast_iron)
		Props.rod(actor,Vector3(0,1.1,-2.25+offset),Vector3(0,beam_height,-.5+offset),.075,materials.cast_iron)

func animate_actor(actor: Node3D, obstacle: Dictionary, model: RefCounted) -> void:
	if actor.has_node("debris"):
		animate_fragments(actor,model.visual_age(obstacle)-float(obstacle.activates_at))
	if str(obstacle.art_id) == "maintenance_hand_gap":
		actor.get_node("hand").animate(model.visual_age(obstacle),model.obstacle_art.manifest.hand_timeline,camera)
	if str(obstacle.art_id) == "float_ball":
		var pivot := Vector3(0,.55,-WATER_HALF-actor.position.z)
		actor.get_node("pivot").position = pivot
		Props.align_rod(actor.get_node("arm"),pivot,Vector3(0,-.05,0))
	if str(obstacle.art_id).begins_with("strainer_gap_"):
		var machine: Node3D = actor.get_node("machine")
		var age: float = model.visual_age(obstacle)
		machine.visible = age >= 1.0
		if not machine.visible: return
		var assembly: Dictionary = model.hazard_assembly(obstacle)
		var source: Dictionary = model.obstacle_art.manifest
		for part: Dictionary in assembly.parts:
			if part.id not in [source.strainer_parts.basket,source.strainer_parts.clear_basket]: continue
			var bottom: Vector2 = part.transform.origin
			machine.position.x = bottom.x/UNIT-actor.position.x
			# Withdraw the cleared cage along its rail so its silhouette and shadow cannot hide the rider.
			var clear := float(source.strainer_timeline.clear)
			machine.position.x += 6.0*smoothstep(clear,clear+.45,age)
			# The basket travels beneath a fixed supported rail; the rail never follows the trolley.
			machine.get_node("rail").position.x = -machine.position.x
			var height := clampf((model.obstacle_position(obstacle).y+float(obstacle.depth)*.5-bottom.y)/UNIT,0,1.5)
			machine.get_node("basket").position.y = height
			for name in ["chain_left","chain_right"]:
				var links: Node3D = machine.get_node(name)
				links.position.y = height+.45
				links.scale.y = maxf(.01,3.24-height-.45)
			break
