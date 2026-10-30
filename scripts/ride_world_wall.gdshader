shader_type spatial;
render_mode cull_disabled;
uniform sampler2D wall_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float course_distance = 0.0;
uniform int hatch_count = 0;
uniform vec4 hatches[8];
varying vec3 world_position;
varying vec3 world_normal;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; world_normal = MODEL_NORMAL_MATRIX * NORMAL; }
void fragment() {
	for (int i = 0; i < hatch_count; i++) {
		vec4 rect = hatches[i];
		if (world_position.x > rect.x && world_position.x < rect.z &&
			world_position.y > rect.y && world_position.y < rect.w) discard;
	}
	ALBEDO = texture(wall_texture,vec2(world_position.x+course_distance,
		abs(world_normal.y) > .5 ? world_position.z : -world_position.y)/1.5).rgb*vec3(.52,.58,.56);
	ROUGHNESS = 1.0;
	SPECULAR = .1;
}
