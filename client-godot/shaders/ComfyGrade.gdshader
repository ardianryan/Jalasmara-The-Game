shader_type canvas_item;
render_mode unshaded;

uniform float daylight : hint_range(0.0, 1.0) = 1.0;
uniform float strength : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 color = source.rgb;
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float highlights = smoothstep(0.24, 0.86, luminance);
	float shadows = 1.0 - smoothstep(0.08, 0.48, luminance);
	float red_bias = smoothstep(-0.08, 0.18, color.r - color.g);
	vec3 shadow_tint = mix(vec3(0.965, 1.020, 1.035), vec3(1.018, 0.995, 1.026), red_bias);
	vec3 graded = color * mix(vec3(1.0), shadow_tint, shadows * 0.65);
	graded *= mix(vec3(1.0), vec3(1.040, 1.020, 0.980), highlights);
	float chroma = max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b));
	float gentle_vibrance = (1.0 - smoothstep(0.08, 0.60, chroma)) * 0.10;
	float graded_luminance = dot(graded, vec3(0.2126, 0.7152, 0.0722));
	graded = mix(vec3(graded_luminance), graded, 1.0 + gentle_vibrance);
	// A small night lift preserves dark paths without washing out illuminated windows.
	graded += vec3(0.0025, 0.0030, 0.0040) * shadows * (1.0 - daylight);
	COLOR = vec4(clamp(mix(color, graded, strength), 0.0, 1.0), source.a);
}
