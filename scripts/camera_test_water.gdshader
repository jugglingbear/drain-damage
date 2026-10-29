shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform sampler2D water_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 water_tint : source_color = vec4(0.32, 0.55, 0.54, 0.78);
uniform vec2 flow_offset = vec2(0.0);
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec3 foundation_min = vec3(0.0);
uniform vec3 foundation_max = vec3(0.0);

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
	// Reveal only the actual opaque ramp surface beneath this pixel, never a clear rectangular patch.
	float depth = textureLod(scene_depth, SCREEN_UV, 0.0).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
#endif
	vec4 hit = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world = hit.xyz / hit.w;
	bool foundation = all(greaterThanEqual(world, foundation_min - vec3(0.005)))
		&& all(lessThanEqual(world, foundation_max + vec3(0.005)));
	float submerged = smoothstep(0.0, 0.08, -world.y) * (1.0 - smoothstep(0.45, 0.65, -world.y));
	float opacity = mix(water_tint.a, 0.50, foundation ? submerged : 0.0);
	ALPHA = water.a * opacity;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
