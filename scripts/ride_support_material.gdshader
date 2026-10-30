shader_type spatial;
render_mode cull_disabled;
uniform sampler2D iron_texture : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 local_position;
varying vec3 local_normal;
void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}
void fragment() {
	vec3 weights = pow(abs(local_normal),vec3(4.0));
	weights /= max(dot(weights,vec3(1.0)),0.001);
	vec3 p = local_position * (256.0/619.0);
	vec3 texture_color = texture(iron_texture,p.yz).rgb*weights.x
		+ texture(iron_texture,p.xz).rgb*weights.y + texture(iron_texture,p.xy).rgb*weights.z;
	float grain = dot(texture_color,vec3(0.2126,0.7152,0.0722));
	// Preserve authored chipped detail, but distinguish iron from chalky diffuse stone.
	float detail = smoothstep(0.01,0.22,grain);
	float rust = smoothstep(0.015,0.12,texture_color.r-texture_color.b);
	vec3 iron = mix(vec3(0.18,0.19,0.20),vec3(0.36,0.38,0.39),detail);
	vec3 oxide = mix(vec3(0.15,0.09,0.055),vec3(0.28,0.17,0.095),detail);
	ALBEDO = mix(iron,oxide,rust*0.5);
	// Moderate metalness retains readable diffuse form in the dim sewer environment.
	METALLIC = mix(0.38,0.12,rust);
	ROUGHNESS = mix(0.46,0.76,rust)+0.04*(1.0-detail);
	SPECULAR = 0.45;
}
