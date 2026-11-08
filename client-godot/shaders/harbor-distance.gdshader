shader_type canvas_item;
void fragment() {
	vec4 town = texture(TEXTURE, UV);
	float sides = smoothstep(0.0, 0.13, UV.x) * (1.0 - smoothstep(0.82, 1.0, UV.x));
	float bottom = 1.0 - smoothstep(0.68, 1.0, UV.y);
	COLOR = vec4(mix(town.rgb, vec3(0.39, 0.58, 0.59), 0.30), town.a * sides * bottom * 0.78);
}
