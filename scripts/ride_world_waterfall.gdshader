shader_type spatial;
render_mode blend_mix, cull_disabled;
uniform sampler2D water_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D foam_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float flow_time = 0.0;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	// V measures distance down the lip: negative time makes texture features fall.
	vec2 uv = vec2(UV.x*.85,UV.y*.12-flow_time*.7);
	vec3 stream = texture(water_texture,uv).rgb;
	float depth = max(0.0,-world_position.y);
	float crest = 1.0-smoothstep(.03,.24,depth);
	vec4 foam = texture(foam_texture,vec2(fract(UV.x*.35+flow_time*.06),clamp(UV.y*3.0,0.0,1.0)));
	ALBEDO = mix(stream*vec3(.55,.85,.82),foam.rgb,crest*foam.a*.7);
	EMISSION = ALBEDO*.15;
	float ribbons = smoothstep(.22,.65,texture(water_texture,vec2(UV.x*1.4,flow_time*.08)).g);
	ALPHA = (.25+ribbons*.35+crest*.2)*(1.0-smoothstep(.35,1.9,depth));
	ROUGHNESS = .65;
	SPECULAR = .25;
}
