shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform sampler2D water_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 water_tint : source_color = vec4(0.32, 0.55, 0.54, 0.78);
uniform vec2 flow_offset = vec2(0.0);

void fragment() {
	vec2 uv = UV + flow_offset;
	vec2 edge_distance = min(fract(uv), vec2(1.0) - fract(uv));
	vec2 blend = vec2(1.0) - smoothstep(vec2(0.0), vec2(0.18), edge_distance);
	// At each tile edge, sample the continuous middle of a shifted copy of the authored water.
	vec4 a = texture(water_texture, uv);
	vec4 b = texture(water_texture, uv + vec2(0.5, 0.0));
	vec4 c = texture(water_texture, uv + vec2(0.0, 0.5));
	vec4 d = texture(water_texture, uv + vec2(0.5, 0.5));
	vec4 water = mix(mix(a, b, blend.x), mix(c, d, blend.x), blend.y);
	ALBEDO = water.rgb * water_tint.rgb;
	ALPHA = water.a * water_tint.a;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
