extends Node3D
## Depth-tested surface decals and world-anchored airborne clouds.
const MANIFEST := "res://assets/world/ride-fidget-v1/manifest.json"
var instances: Dictionary = {}
var textures: Dictionary = {}
var uv_regions: Dictionary = {}
var shader: Shader
var cloud_texture: Texture2D
var cloud_material: ShaderMaterial
var cloud_mesh: QuadMesh
var cloud_size := Vector2.ONE
var cloud_pivot := Vector2(.5,.68)

func configure() -> void:
	var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for asset: Dictionary in definition.assets:
		var kind := "water" if asset.id == "water" else "solid"
		textures[kind] = load("res://"+str(asset.path))
		var bounds: Array = asset.visible_bounds_alpha64_px
		var size: Array = asset.dimensions_px
		uv_regions[kind] = Vector4((bounds[0]-20.0)/size[0],(bounds[1]-20.0)/size[1],
			(bounds[2]-bounds[0]+40.0)/size[0],(bounds[3]-bounds[1]+40.0)/size[1])
	var cloud: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/world/ride-fidget-cloud-v1/manifest.json"))
	cloud_texture = load("res://"+str(cloud.textures.airborne))
	var bounds: Array = cloud.visible_bounds_alpha64_px
	var dimensions: Array = cloud.dimensions_px
	cloud_size = Vector2(dimensions[0],dimensions[1])*(.9/float(bounds[2]-bounds[0]))
	cloud_pivot = Vector2(cloud.pivot_uv[0],cloud.pivot_uv[1])
	shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform sampler2D artwork : source_color, filter_linear_mipmap;
uniform float opacity = 1.0;
uniform vec4 uv_region = vec4(0.0,0.0,1.0,1.0);
void fragment() {
 vec2 uv = uv_region.xy + UV * uv_region.zw;
 // Diffusion is support-clipped by the model before this mesh is rendered.
 vec4 ink = texture(artwork, uv);
 ALBEDO = ink.rgb;
 ALPHA = ink.a * opacity;
}
"""
	cloud_mesh = QuadMesh.new()
	cloud_mesh.size = cloud_size
	cloud_mesh.center_offset = Vector3((.5-cloud_pivot.x)*cloud_size.x,(cloud_pivot.y-.5)*cloud_size.y,0)
	cloud_material = ShaderMaterial.new()
	cloud_material.shader = shader
	cloud_material.render_priority = 1
	cloud_material.set_shader_parameter("uv_region",Vector4(0,0,1,1))
	cloud_material.set_shader_parameter("artwork",cloud_texture)
	cloud_material.set_shader_parameter("opacity",.65)

func prepare_warmup() -> Array[MeshInstance3D]:
	# Upload all effect textures and compile the transparent shader before the first fire press.
	var nodes: Array[MeshInstance3D] = []
	for texture in [cloud_texture,textures.water,textures.solid]:
		var node := MeshInstance3D.new()
		node.mesh = QuadMesh.new()
		node.mesh.surface_get_arrays(0)
		var material := ShaderMaterial.new()
		material.shader = shader
		material.render_priority = 1
		material.set_shader_parameter("artwork",texture)
		material.set_shader_parameter("opacity",.65)
		material.set_shader_parameter("uv_region",Vector4(0,0,1,1))
		node.material_override = material
		if texture == cloud_texture:
			node.mesh = cloud_mesh
			node.material_override = cloud_material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.position = Vector3(3+nodes.size(),2,2)
		add_child(node)
		nodes.append(node)
	return nodes

func update_effects(view: Node3D, model: RefCounted) -> void:
	var live: Dictionary = {}
	var retired: Array[int] = []
	if model != null:
		for effect: Dictionary in model.fidget.effects:
			var id: int = effect.id
			live[id] = true
			if effect.material == "cloud":
				if update_cloud(view,model,effect): retired.append(id)
				continue
			if not instances.has(id):
				var instance := MeshInstance3D.new()
				var material := ShaderMaterial.new()
				material.shader = shader
				# Draw the transparent stain after the broad transparent water mesh, still depth-tested.
				material.render_priority = 1
				material.set_shader_parameter("artwork",textures.water if effect.material == "water" else textures.solid)
				material.set_shader_parameter("uv_region",uv_regions.water if effect.material == "water" else uv_regions.solid)
				instance.material_override = material
				instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(instance)
				instances[id] = instance
			var node: MeshInstance3D = instances[id]
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			for vertex_index: int in effect.indices:
				var point: Vector3 = effect.vertices[vertex_index]
				tool.set_uv(effect.uv[vertex_index])
				tool.add_vertex(view.world(Vector2(point.x-model.clock*model.scroll_speed,point.z),point.y)+Vector3.UP*.003)
			tool.generate_normals()
			node.mesh = tool.commit()
			node.material_override.set_shader_parameter("opacity",float(effect.alpha)*.8)
	for id in retired:
		model.fidget.retire_cloud(id)
		live.erase(id)
	for id in instances.keys():
		if live.has(id): continue
		remove_child(instances[id])
		instances[id].queue_free()
		instances.erase(id)

func update_cloud(view: Node3D, model: RefCounted, effect: Dictionary) -> bool:
	var id: int = effect.id
	if not instances.has(id):
		var node := MeshInstance3D.new()
		# Retain the exact mesh/material warmed during startup; new clouds only need a transform.
		node.mesh = cloud_mesh
		node.material_override = cloud_material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		instances[id] = node
	var node: MeshInstance3D = instances[id]
	var center: Vector2 = effect.center-Vector2(model.clock*model.scroll_speed,0)
	node.position = view.world(center,effect.height)
	node.basis = view.camera.global_basis.scaled(Vector3.ONE*(1.0+.15*(1.0-exp(-effect.age))))
	# Check the full billboard including transparent margins, not just its release point.
	var bounds := Rect2()
	var first := true
	for x in [-.5,.5]:
		for y in [-.5,.5]:
			var local: Vector3 = node.mesh.center_offset+Vector3(x*cloud_size.x,y*cloud_size.y,0)
			var screen: Vector2 = view.camera.unproject_position(node.to_global(local))
			if first:
				bounds = Rect2(screen,Vector2.ZERO)
				first = false
			else: bounds = bounds.expand(screen)
	return not bounds.intersects(Rect2(-24,-24,1008,588),true)
