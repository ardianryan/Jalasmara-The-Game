vec2 reef_hash(vec2 cell) {
	return fract(sin(vec2(dot(cell, vec2(127.1,311.7)), dot(cell, vec2(269.5,183.3)))) * 43758.5453);
}

vec3 reef_patch(sampler2D atlas, vec2 point, vec2 cell, float column) {
	vec2 seed = reef_hash(cell);
	vec2 crop = vec2(0.5) + (point - cell) * 0.46;
	if (seed.x > 0.5) { crop.x = 1.0 - crop.x; }
	crop += (seed - vec2(0.5)) * 0.18;
	crop = clamp(crop, vec2(0.015), vec2(0.985));
	vec3 color = texture(atlas, (vec2(column, 0.0) + crop) / vec2(3.0, 2.0)).rgb;
	return color * mix(0.94, 1.06, seed.x);
}

// Overlapping crops share continuous weights across cell edges. The material
// never restarts a complete, identical coral-rock picture at a visible seam.
vec3 reef_variation(sampler2D atlas, vec2 point, float column) {
	vec2 cell = floor(point);
	vec2 weight = smoothstep(vec2(0.23), vec2(0.77), fract(point));
	vec3 lower = mix(reef_patch(atlas, point, cell, column), reef_patch(atlas, point, cell + vec2(1.0, 0.0), column), weight.x);
	vec3 upper = mix(reef_patch(atlas, point, cell + vec2(0.0, 1.0), column), reef_patch(atlas, point, cell + vec2(1.0, 1.0), column), weight.x);
	return mix(lower, upper, weight.y);
}
