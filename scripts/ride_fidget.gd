extends RefCounted
## Cosmetic surface deposits only; input mapping, audio and rendering belong to the host.
const COOLDOWN := 0.5
const WATER_LIFETIME := 1.4
const DRY_LIFETIME := 3.5
const FADE_TIME := 1.0
const MAX_EFFECTS := 24
const HALF_WIDTH := 6.25
const CELL_LENGTH := 5.0
var effects: Array[Dictionary] = []
var held := false
var cooldown := 0.0
var last_clock := -1.0
var next_id := 0

func sync_input(held_fire: bool) -> void:
	held = held_fire

func reset(held_fire := false) -> void:
	effects.clear()
	held = held_fire
	cooldown = 0
	last_clock = -1

func surfaces(model: RefCounted) -> Array:
	return model.visual_obstacles if "visual_obstacles" in model else model.course.obstacles

func origin(model: RefCounted, obstacle: Dictionary) -> float:
	return float(obstacle.visual_started)*model.scroll_speed if obstacle.has("visual_started") else model.clock*model.scroll_speed-model.encounter_scroll

func pose(model: RefCounted, obstacle: Dictionary) -> Vector2:
	var birth := float(obstacle.get("visual_started",model.clock-model.encounter_clock))
	return Vector2(float(obstacle.x)+origin(model,obstacle),float(obstacle.y))+model.motion_offset(obstacle,model.clock-birth)

func contains(obstacle: Dictionary, local: Vector2) -> bool:
	var half := Vector2(float(obstacle.width),float(obstacle.depth))*.5
	if absf(local.x) > half.x or absf(local.y) > half.y: return false
	if str(obstacle.get("surface_shape","ellipse" if str(obstacle.get("art_id","")).begins_with("cleanout_deck_") else "rect")) == "ellipse":
		return (local/half).length_squared() <= 1
	return true

func sample_surface(model: RefCounted, point: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var opening := false
	for obstacle: Dictionary in surfaces(model):
		var local := point-pose(model,obstacle)
		if not contains(obstacle,local): continue
		var kind := str(obstacle.kind)
		var birth := float(obstacle.get("visual_started",model.clock-model.encounter_clock))
		if kind in ["gap","long_pit"] and model.clock-birth >= float(obstacle.get("activates_at",0)):
			opening = true
		if kind not in ["deck","ramp"]: continue
		var height := float(obstacle.get("surface_height",12))
		var normal := Vector3.UP
		if kind == "ramp":
			var u := (local.x+float(obstacle.width)*.5)/float(obstacle.width)
			var rise := float(obstacle.get("rise",40))
			height = rise*u*u
			normal = Vector3(-2*rise*u/float(obstacle.width),1,0).normalized()
		if best.is_empty() or height > float(best.height):
			best = {"height":height,"normal":normal,"material":str(obstacle.get("landing_material","metal")),
				"surface_id":str(obstacle.id)+":"+str(origin(model,obstacle)),"obstacle":obstacle,"kind":kind}
	if not best.is_empty(): return best
	if opening or point.y < 230 or point.y > 430: return {}
	return {"height":0.0,"normal":Vector3.UP,"material":"water","surface_id":"water","obstacle":{},"kind":"water"}

func water_cell_clear(model: RefCounted, bounds: Rect2) -> bool:
	for obstacle: Dictionary in surfaces(model):
		if obstacle.kind not in ["gap","long_pit"]: continue
		var birth := float(obstacle.get("visual_started",model.clock-model.encounter_clock))
		if model.clock-birth < float(obstacle.get("activates_at",0)): continue
		var size := Vector2(float(obstacle.width),float(obstacle.depth))
		if bounds.intersects(Rect2(pose(model,obstacle)-size*.5,size),true): return false
	return true

func mesh_at(model: RefCounted, center: Vector2, surface_id: String, length_scale := 1.0, width_scale := 1.0) -> Dictionary:
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var uv: Array[Vector2] = []
	var indices: Array[int] = []
	for cell in range(12):
		var cell_length := CELL_LENGTH*length_scale
		var half_width := HALF_WIDTH*width_scale
		var left := center.x-45-60*length_scale+cell*cell_length
		var corners: Array[Vector2] = [Vector2(left,center.y-half_width),Vector2(left+cell_length,center.y-half_width),
			Vector2(left+cell_length,center.y+half_width),Vector2(left,center.y+half_width)]
		var samples: Array[Dictionary] = []
		for point in corners:
			var surface := sample_surface(model,point)
			if surface.is_empty() or str(surface.surface_id) != surface_id: break
			samples.append(surface)
		if samples.size() != 4: continue
		if surface_id == "water" and not water_cell_clear(model,Rect2(corners[0],Vector2(cell_length,half_width*2))): continue
		var start := vertices.size()
		for i in 4:
			vertices.append(Vector3(corners[i].x,samples[i].height,corners[i].y))
			normals.append(samples[i].normal)
		uv.append_array([Vector2(cell/12.0,0),Vector2((cell+1)/12.0,0),Vector2((cell+1)/12.0,1),Vector2(cell/12.0,1)])
		indices.append_array([start,start+2,start+1,start,start+3,start+2])
	return {"vertices":vertices,"normals":normals,"uv":uv,"indices":indices}

func step(model: RefCounted, held_fire: bool, delta: float, enabled := true, paused := false, alive := true) -> Dictionary:
	var edge := held_fire and not held
	held = held_fire
	if not enabled or not alive:
		reset(held_fire)
		return {"triggered":false,"effects":effects}
	if last_clock >= 0 and model.clock < last_clock:
		reset(held_fire)
		edge = false
	last_clock = model.clock
	if paused: return {"triggered":false,"effects":effects}
	var dt := maxf(0,delta)
	cooldown = maxf(0,cooldown-dt)
	for index in range(effects.size()-1,-1,-1):
		var effect := effects[index]
		effect.age += dt
		if effect.material == "cloud":
			# Course-space X/bank remain fixed at release; only a small buoyant rise is allowed.
			effect.height = effect.release_height+minf(25.0,effect.age*8.0)
			continue
		if effect.age >= effect.lifetime:
			effects.remove_at(index)
			continue
		var center: Vector2 = effect.center
		if not effect.obstacle.is_empty():
			# Retain the surface's own clock/origin across encounter teardown.
			var source: Dictionary = effect.obstacle
			center = Vector2(source.x+effect.course_origin,source.y)+model.motion_offset(source,model.clock-effect.birth)+effect.local_center
		var progress: float = effect.age/effect.lifetime
		var length_scale := 1.0
		var width_scale := 1.0
		if effect.material == "water":
			center.x -= effect.age*10
			length_scale += .25*progress
			width_scale += .5*progress
		var mesh := mesh_at(model,center,effect.surface_id,length_scale,width_scale)
		if mesh.indices.is_empty():
			effects.remove_at(index)
			continue
		effect.merge(mesh,true)
		effect.alpha = 1-progress if effect.material == "water" else clampf((effect.lifetime-effect.age)/FADE_TIME,0,1)
	var triggered := false
	if edge and cooldown <= .00000001 and model.jump_age >= 0 and not model.complete:
		next_id += 1
		var center: Vector2 = model.position+Vector2(model.clock*model.scroll_speed-45,0)
		effects.append({"id":next_id,"age":0.0,"alpha":1.0,"material":"cloud","center":center,
			"release_height":model.render_height+8.0,"height":model.render_height+8.0})
		while effects.size() > MAX_EFFECTS: effects.pop_front()
		cooldown = COOLDOWN
		triggered = true
	elif edge and cooldown <= .00000001 and not model.complete:
		var center: Vector2 = model.position+Vector2(model.clock*model.scroll_speed,0)
		var surface := sample_surface(model,center)
		if not surface.is_empty() and (model.ramp_active and surface.kind == "ramp" or not model.ramp_active and absf(float(surface.height)-model.ground_height) < .1):
			var mesh := mesh_at(model,center,surface.surface_id)
			if not mesh.indices.is_empty():
				next_id += 1
				var source: Dictionary = surface.obstacle
				var record := {"id":next_id,"age":0.0,"alpha":1.0,"lifetime":WATER_LIFETIME if surface.material == "water" else DRY_LIFETIME,"center":center,"material":surface.material,
					"surface_id":surface.surface_id,"obstacle":source,"course_origin":origin(model,source) if not source.is_empty() else 0.0,
					"birth":float(source.get("visual_started",model.clock-model.encounter_clock)),
					"local_center":center-pose(model,source) if not source.is_empty() else Vector2.ZERO}
				record.merge(mesh)
				effects.append(record)
				while effects.size() > MAX_EFFECTS: effects.pop_front()
				cooldown = COOLDOWN
				triggered = true
	return {"triggered":triggered,"effects":effects}

func retire_cloud(id: int) -> void:
	# The renderer retires a cloud only after its complete projected silhouette leaves the viewport.
	for index in range(effects.size()-1,-1,-1):
		if effects[index].id == id and effects[index].material == "cloud": effects.remove_at(index)
