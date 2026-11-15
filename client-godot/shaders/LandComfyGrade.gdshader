shader_type canvas_item;
render_mode unshaded;

uniform float daylight : hint_range(0.0, 1.0) = 1.0;
uniform float dusk : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 color = source.rgb;
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float shadows = 1.0 - smoothstep(0.09, 0.47, luminance);
	float highlights = smoothstep(0.45, 0.86, luminance);
	vec3 shaded = color * vec3(0.88, 0.96, 1.05) + vec3(0.0, 0.009, 0.012);
	vec3 sunlit = color * vec3(1.055, 1.035, 0.96) + vec3(0.010, 0.004, 0.0);
	vec3 graded = mix(color, shaded, shadows * 0.43);
	graded = mix(graded, sunlit, highlights * 0.36);
	float graded_luminance = dot(graded, vec3(0.2126, 0.7152, 0.0722));
	float chroma = max(graded.r, max(graded.g, graded.b)) - min(graded.r, min(graded.g, graded.b));
	float vibrance = (1.0 - smoothstep(0.08, 0.60, chroma)) * 0.07;
	graded = mix(vec3(graded_luminance), graded, 1.08 + vibrance);
	float sunset = dusk * smoothstep(0.17, 0.60, luminance);
	graded = mix(graded, graded * vec3(1.18, 0.99, 0.78), sunset * 0.82);
	graded += vec3(0.003, 0.004, 0.006) * shadows * (1.0 - daylight);
	COLOR = vec4(clamp(mix(color, graded, strength), 0.0, 1.0), source.a);
}
