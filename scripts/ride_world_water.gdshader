shader_type spatial;
render_mode blend_mix, cull_disabled;
uniform sampler2D water_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 flow_offset = vec2(0.0);
uniform bool bed_surface = false;
uniform int opening_count = 0;
uniform vec4 openings[32];
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	// A pit removes the water surface completely; solid platforms supply their own geometry.
	for (int i = 0; i < opening_count; i++) {
		vec4 rect = openings[i];
		if (world_position.x > rect.x && world_position.x < rect.z &&
			world_position.z > rect.y && world_position.z < rect.w) discard;
	}
	vec2 uv = UV + flow_offset;
	vec2 blend = 1.0 - smoothstep(vec2(0.0), vec2(0.18), min(fract(uv), 1.0-fract(uv)));
	vec4 a = texture(water_texture, uv);
	vec4 b = texture(water_texture, uv+vec2(0.5,0.0));
	vec4 c = texture(water_texture, uv+vec2(0.0,0.5));
	vec4 d = texture(water_texture, uv+vec2(0.5,0.5));
	ALBEDO = mix(mix(a,b,blend.x),mix(c,d,blend.x),blend.y).rgb*vec3(0.32,0.55,0.54);
	if (bed_surface) {
		ALBEDO = texture(water_texture, UV+flow_offset).rgb*vec3(0.45,0.48,0.46);
	}
	ALPHA = bed_surface ? 1.0 : 0.78;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
