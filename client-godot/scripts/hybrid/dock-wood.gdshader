shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform sampler2D wood_atlas : source_color, filter_nearest, repeat_disable;
uniform vec4 wood_patch;
uniform vec4 wood_tint : source_color = vec4(1.0);
void fragment() {
	vec2 local_uv = clamp(UV, vec2(0.005), vec2(0.995));
	ALBEDO = texture(wood_atlas, wood_patch.xy + local_uv * wood_patch.zw).rgb * wood_tint.rgb;
	ROUGHNESS = 0.98;
	SPECULAR = 0.0;
}
