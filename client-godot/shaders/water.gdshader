shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float depth_m : hint_range(0.0, 300.0) = 0.0;
uniform float refraction_strength : hint_range(0.0, 0.005) = 0.0015;
uniform float daylight : hint_range(0.0, 1.0) = 0.9;

void fragment() {
	vec2 wave = vec2(
		sin(SCREEN_UV.y * 31.0 + TIME * 0.72),
		sin(SCREEN_UV.x * 23.0 - TIME * 0.54) * 0.45
	);
	vec2 sample_uv = clamp(SCREEN_UV + wave * refraction_strength, SCREEN_PIXEL_SIZE, vec2(1.0) - SCREEN_PIXEL_SIZE);
	vec4 water = texture(screen_texture, sample_uv);
	vec2 pattern = SCREEN_UV * vec2(38.0, 27.0);
	float intersection = abs(sin(pattern.x + sin(pattern.y + TIME * 0.23)) + sin(pattern.y - TIME * 0.31));
	float caustic = pow(1.0 - smoothstep(0.0, 0.14, intersection), 2.0);
	float shallow_light = (1.0 - smoothstep(20.0, 110.0, depth_m)) * daylight;
	water.rgb += vec3(0.55, 0.92, 0.78) * caustic * shallow_light * 0.025;
	COLOR = vec4(water.rgb, 1.0);
}
