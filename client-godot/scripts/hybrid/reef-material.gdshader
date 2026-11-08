shader_type spatial;
render_mode cull_disabled;
uniform sampler2D rock_atlas : source_color, filter_nearest, repeat_disable;
uniform float material_column = 0.0;
uniform vec3 rock_tint : source_color = vec3(1.0);
varying vec4 surface_tint;
void vertex() {
	surface_tint = COLOR;
}
void fragment() {
	vec2 pixel_tile = fract(UV);
	vec2 atlas_uv = (vec2(material_column, 0.0) + mix(vec2(0.003), vec2(0.997), pixel_tile)) / vec2(3.0, 2.0);
	ALBEDO = texture(rock_atlas, atlas_uv).rgb * surface_tint.rgb * rock_tint;
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
}
