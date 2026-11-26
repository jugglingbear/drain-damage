extends RefCounted
## Project the cabinet and its articulated Level 1 parts onto the ride's water plane.
const SCALE := 0.84
var layers: Dictionary = {}
var textures: Dictionary = {}
const ART_MANIFEST := "res://assets/world/ride-checkpoint-v1/manifest.json"

func prepare() -> void:
	layers = JSON.parse_string(FileAccess.get_file_as_string(ART_MANIFEST)).entries
	for layer: Dictionary in layers.values():
		textures[layer.path] = load("res://"+str(layer.path))

func layer(host: Node2D, key: String, point: Vector2, size: float, visible_fraction := 1.0, alpha := 1.0) -> void:
	if visible_fraction <= 0 or size <= 0: return
	var spec: Dictionary = layers[key]
	var texture: Texture2D = textures[spec.path]
	var native_size := texture.get_size()
	var scale_factor := size/native_size.x
	var pivot := Vector2(spec.anchor_px[0],spec.anchor_px[1])
	var clipped := Vector2(native_size.x,native_size.y*visible_fraction)
	host.draw_texture_rect_region(texture,Rect2(point-pivot*scale_factor,clipped*scale_factor),Rect2(Vector2.ZERO,clipped),Color(1,1,1,alpha))

func projected(view: Node3D, point: Vector2, height := 0.0) -> Vector2:
	return view.camera.unproject_position(view.world(point,height))

func body_on_board(cp: RefCounted) -> bool:
	return cp.phase == "replacement" or (cp.phase == "departure" and not cp.rocket_cleared) \
		or (cp.phase == "runout" and not cp.rocket_cleared and cp.age < 0.65 and not cp.restored)

func exhaust_above_screen(transform: Transform2D) -> bool:
	var pod: Dictionary = layers["booster-deployed"]
	var plume: Dictionary = layers["exhaust-long"]
	var nozzle := Vector2(pod.nozzle_px[0]-pod.anchor_px[0],pod.nozzle_px[1]-pod.anchor_px[1])
	nozzle *= float(pod.display_width)/(SCALE*pod.source_size[0])
	var bottom: float = 139 + nozzle.y + 17.0/SCALE*plume.source_size[1]/plume.source_size[0]
	return maxf((transform*Vector2(23-nozzle.x,bottom)).y,(transform*Vector2(151+nozzle.x,bottom)).y) < 0

func balance_arm(host: Node2D, d: RefCounted, mount: Vector2, point: Vector2, bend: float) -> void:
	var wrist := point+Vector2(0,-4)
	var elbow: Vector2 = d.elbow(mount,wrist,65,63.05,bend)
	d.articulated_part(host,Vector2.ZERO,"holding_upper","mount",mount,(elbow-mount).angle())
	d.articulated_part(host,Vector2.ZERO,"holding_fore","elbow",elbow,(wrist-elbow).angle()-PI)
	d.articulated_part(host,Vector2.ZERO,"hand_open","grip",point)

func draw(host: Node2D, flush: RefCounted) -> void:
	var ride: RefCounted = flush.ride
	var cp: RefCounted = ride.checkpoint
	if cp.phase in ["","finished"] or cp.phase == "runout" and not body_on_board(cp): return
	var d: RefCounted = host.dispenser
	var view: Node3D = flush.world_view
	var board: Dictionary = layers["empty-board"]
	var board_width := 88.0
	var deck_offset: float = (board.anchor_px[1]-board.seat_surface_px[1])*board_width/board.source_size[0]
	var dock := projected(view,ride.position)-Vector2(0,deck_offset)
	if body_on_board(cp) and ride.jump_age < 0:
		host.draw_set_transform(Vector2.ZERO)
		layer(host,"empty-board",projected(view,ride.position),board_width)
	if view.checkpoint_cabinet == null: return
	var transform: Transform2D = view.checkpoint_cabinet.front_transform
	var local_feet := transform.affine_inverse()*dock
	var hero: String = host.employee.id
	if cp.phase == "runout":
		if ride.jump_age >= 0: return
		host.draw_set_transform(Vector2.ZERO)
		placed_hero(host,d,hero,dock,true)
		return
	host.draw_set_transform_matrix(transform)
	d.ride_canvas = transform
	var inspecting: bool = cp.phase == "replacement"
	if inspecting:
		inspection(host,d,cp,local_feet,transform)
	if cp.phase == "departure":
		var deploy := smoothstep(0,.24,cp.age)
		var pod := "booster-stowed" if cp.age < .2 else "booster-deployed"
		var spec: Dictionary = layers[pod]
		for side in [-1,1]:
			var mount := Vector2(23 if side == -1 else 151,139)
			host.draw_set_transform_matrix(transform*Transform2D(0,Vector2(side,1),0,mount))
			var width: float = spec.display_width/SCALE*deploy
			if cp.age > .2:
				var nozzle: Vector2 = (d.vector(spec.nozzle_px)-d.vector(spec.anchor_px))*width/float(spec.source_size[0])
				layer(host,"exhaust-long" if sin(cp.age*48)>0 else "exhaust-short",nozzle,17/SCALE)
			layer(host,pod,Vector2.ZERO,width)
		host.draw_set_transform(Vector2.ZERO)
		if not cp.rocket_cleared: placed_hero(host,d,hero,dock,cp.age >= cp.LIFT_DELAY + 0.65)
	d.ride_canvas = Transform2D.IDENTITY
	host.draw_set_transform(Vector2.ZERO)

func inspection(host: Node2D, d: RefCounted, cp: RefCounted, feet: Vector2, transform: Transform2D) -> void:
	var t: Dictionary = d.inspection.timing_seconds
	var elapsed: float = d.elapsed
	cp.throw_origin_screen = transform*d.throw_origin_grip()
	if not cp.injured or elapsed < t.throw[0]:
		var pose: Dictionary = d.held_pose(host,Vector2.ZERO,feet)
		d.draw_holding_arm(host,Vector2.ZERO,pose.grip,false)
		if pose.has("previous"): d.draw_frame(host,pose.previous,pose.previous_origin,1,1-pose.blend)
		d.draw_frame(host,pose.frame,pose.origin,1,pose.blend)
		d.draw_holding_arm(host,Vector2.ZERO,pose.grip,true)
		d.draw_inspection_arm(host,Vector2.ZERO)
		d.draw_diagnosis(host,Vector2.ZERO)
		return
	var pocket := Vector2(74,115)
	var grip: Vector2 = d.throw_origin_grip().lerp(pocket,smoothstep(t.throw[0],t.slide_vend[1],elapsed))
	var place := smoothstep(t.emerge[0],t.look_left[1],elapsed)
	var target: Vector2 = feet-Vector2(0,33)
	grip = grip.lerp(target,place)
	var clasp := smoothstep(t.slide_vend[0],t.slide_vend[1],elapsed)*(1-smoothstep(t.look_left[1],t.look_right[1],elapsed))
	d.draw_holding_arm(host,Vector2.ZERO,grip,false,1,clasp)
	if elapsed >= t.emerge[0]:
		host.draw_set_transform(Vector2.ZERO)
		placed_hero(host,d,host.employee.id,transform*(grip+Vector2(0,33)),false)
		host.draw_set_transform_matrix(transform)
	d.draw_holding_arm(host,Vector2.ZERO,grip,true,1-smoothstep(t.look_left[1],t.look_right[1],elapsed),clasp)

func placed_hero(host: Node2D, d: RefCounted, hero: String, feet: Vector2, shrug: bool) -> void:
	if hero == "sean":
		var pose := "sean-shrug" if shrug else "sean-confused"
		layer(host,pose,feet,layers[pose].display_width*.88)
	else:
		var pose: Dictionary = d.art.heroes[hero].states["shrug" if shrug else "look_right"]
		d.draw_frame(host,pose,feet-Vector2(64,104),1)
