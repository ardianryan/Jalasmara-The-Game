shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/reef-variation.gdshaderinc"
uniform sampler2D rock_atlas : source_color, filter_nearest, repeat_disable;
uniform float material_column = 0.0;
uniform vec3 rock_tint : source_color = vec3(1.0);
varying vec4 surface_tint;
void vertex() {
	surface_tint = COLOR;
}
void fragment() {
	ALBEDO = reef_variation(rock_atlas, UV, material_column) * surface_tint.rgb * rock_tint;
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
}
