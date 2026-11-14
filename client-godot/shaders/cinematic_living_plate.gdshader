shader_type canvas_item;

uniform float elapsed = 0.0;
uniform int plate = 0;
uniform float motion_strength = 1.0;

void fragment() {
	vec2 uv = UV;
	float water_mask = 0.0;
	float soft_mask = 0.0;
	float glow = 0.0;
	vec3 tint = vec3(0.37, 0.86, 0.82);
	if (plate == 1) {
		water_mask = smoothstep(0.47, 0.60, uv.y) * smoothstep(0.18, 0.34, uv.x);
		water_mask *= 1.0 - smoothstep(0.84, 0.94, uv.x);
		// The distant factory plume has its own slow plane of motion.
		soft_mask = smoothstep(0.68, 0.80, uv.x) * (1.0 - smoothstep(0.20, 0.31, uv.y));
		glow = exp(-distance(uv, vec2(0.17, 0.34)) * 62.0) * 0.12;
	} else if (plate == 2) {
		water_mask = smoothstep(0.30, 0.59, uv.y);
		soft_mask = smoothstep(0.76, 0.92, uv.x) * smoothstep(0.60, 0.81, uv.y);
		soft_mask += (1.0 - smoothstep(0.09, 0.19, uv.x)) * smoothstep(0.66, 0.85, uv.y);
		tint = vec3(0.35, 0.89, 0.91);
	} else if (plate == 3) {
		water_mask = smoothstep(0.43, 0.58, uv.x) * smoothstep(0.25, 0.34, uv.y);
		water_mask *= 1.0 - smoothstep(0.62, 0.75, uv.y);
		soft_mask = (1.0 - smoothstep(0.32, 0.43, uv.x)) * (1.0 - smoothstep(0.24, 0.38, uv.y));
		soft_mask += smoothstep(0.70, 0.87, uv.x) * smoothstep(0.53, 0.72, uv.y);
		glow = exp(-distance(uv, vec2(0.21, 0.10)) * 51.0) * 0.12;
		glow += exp(-distance(uv, vec2(0.47, 0.29)) * 56.0) * 0.10;
	}
	float wave = sin(uv.y * 129.0 + elapsed * 1.8) * 0.0016 * water_mask;
	float sway = sin(uv.y * 21.0 + elapsed * 0.75) * 0.0018 * soft_mask;
	vec2 shifted = clamp(uv + vec2((wave + sway) * motion_strength, 0.0), vec2(0.0), vec2(1.0));
	vec3 shifted_color = texture(TEXTURE, shifted).rgb;
	float bands = sin(uv.y * 170.0 + uv.x * 28.0 - elapsed * 2.1);
	float caustic = smoothstep(0.72, 0.92, bands) * 0.09 * water_mask * motion_strength;
	float lantern = glow * (0.74 + 0.26 * sin(elapsed * 2.3)) * motion_strength;
	vec3 color = mix(shifted_color, tint, caustic);
	color += vec3(1.0, 0.65, 0.24) * lantern;
	COLOR = vec4(color, clamp(max(water_mask, soft_mask) * 0.72 + glow, 0.0, 0.8) * motion_strength);
}
