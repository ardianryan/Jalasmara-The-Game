shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
uniform sampler2D shoreline : filter_linear, repeat_disable;
uniform vec2 map_extent = vec2(2400.0, 1600.0);
uniform float clock = 0.0;
uniform float rain = 0.0;
uniform float wind = 0.2;
uniform float motion = 1.0;
uniform bool river = false;
varying vec2 water_uv;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 blend = fract(p);
	blend = blend * blend * (3.0 - 2.0 * blend);
	return mix(
		mix(hash(cell), hash(cell + vec2(1.0, 0.0)), blend.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), blend.x),
		blend.y
	);
}

void vertex() {
	water_uv = UV;
	vec2 p = UV * map_extent;
	float a = sin(p.x * 0.032 + p.y * 0.018 + clock * 1.45) * 1.65;
	float b = sin(p.y * 0.046 - p.x * 0.015 - clock * 1.05) * 1.15;
	VERTEX.z += (a + b) * motion * (0.68 + wind * 0.32);
	NORMAL = normalize(vec3(
		-cos(p.x * 0.032 + p.y * 0.018 + clock * 1.45) * 0.055,
		cos(p.y * 0.046 - p.x * 0.015 - clock * 1.05) * 0.048,
		1.0
	));
}

void fragment() {
	vec2 q = floor(water_uv * map_extent / 2.0) * 2.0;
	vec2 clamped_uv = clamp(water_uv, vec2(0.002), vec2(0.998));
	vec4 edge = texture(shoreline, clamped_uv);
	vec2 outside_px = max(vec2(0.0), max(-water_uv, water_uv - vec2(1.0))) * map_extent;
	float outside_dist = length(outside_px) / 110.0;
	float shore_dist = clamp(edge.g + outside_dist, 0.0, 1.0);
	float land_mask = outside_dist > 0.01 ? 0.0 : edge.r;
	vec2 outward = normalize(edge.ba * 2.0 - 1.0 + vec2(0.0001, 0.0001));
	float phase = clock * motion;

	// Local flow direction: river follows channel & bends around banks/piles; coast combines primary + cross swell
	vec2 river_tangent = vec2(-outward.y, outward.x);
	if (river_tangent.y < 0.0) {
		river_tangent = -river_tangent;
	}
	vec2 river_flow = normalize(mix(vec2(0.08, 0.996), river_tangent, (1.0 - smoothstep(0.0, 0.75, shore_dist)) * 0.65));
	vec2 coast_flow = normalize(mix(vec2(0.45, -0.89), -outward, (1.0 - smoothstep(0.0, 0.60, shore_dist)) * 0.55));
	vec2 flow = river ? river_flow : coast_flow;

	float flow_speed = river ? (14.5 + wind * 4.5) : (10.5 + wind * 5.0);
	vec2 advected = q - flow * phase * flow_speed;
	vec2 cross_dir = vec2(-flow.y, flow.x);
	vec2 advected_secondary = q - normalize(flow * 0.65 + cross_dir * 0.55) * phase * (flow_speed * 0.68);

	float primary_swell = sin(dot(advected, flow) * (river ? 0.058 : 0.068) + noise(advected / 78.0) * 3.1) * 0.5 + 0.5;
	float secondary_swell = sin(dot(advected_secondary, cross_dir) * (river ? 0.095 : 0.052) + noise(advected_secondary / 54.0) * 2.4) * 0.5 + 0.5;
	float cross_wave = noise(advected / vec2(river ? 18.0 : 24.0, river ? 76.0 : 42.0));
	float eddy = river ? sin(shore_dist * 26.0 - phase * 2.4 + noise(q / 28.0) * 4.0) * (1.0 - smoothstep(0.02, 0.42, shore_dist)) * 0.18 : 0.0;
	float combined_wave = clamp(primary_swell * 0.45 + secondary_swell * 0.25 + cross_wave * 0.30 + eddy, 0.0, 1.0);
	float pattern = floor(combined_wave * 6.0) / 5.0;

	// Shallow -> mid -> deep cozy tropical palette
	vec3 deep = river ? vec3(0.072, 0.255, 0.275) : vec3(0.070, 0.265, 0.305);
	vec3 mid_water = river ? vec3(0.118, 0.335, 0.335) : vec3(0.115, 0.345, 0.365);
	vec3 shallow = river ? vec3(0.185, 0.405, 0.365) : vec3(0.215, 0.435, 0.395);
	float bed = noise(q / 36.0) * 0.65 + noise(q / 12.0) * 0.35;
	vec3 shallow_tinted = shallow * (0.93 + bed * 0.14);
	vec3 water = mix(shallow_tinted, mid_water, smoothstep(0.02, 0.36, shore_dist));
	water = mix(water, deep, smoothstep(0.32, 0.88, shore_dist));
	water *= 0.93 + pattern * 0.14;

	// Asymmetric shore wash & recede cycle (advance -> crest hold -> recede with trailing foam flecks)
	float along_shore = dot(q, vec2(-outward.y, outward.x)) * 0.022;
	float raw_cycle = fract(phase * (river ? 0.34 : 0.27) + along_shore + noise(q / 64.0) * 0.22);
	float surge = smoothstep(0.0, 0.38, raw_cycle) * (1.0 - smoothstep(0.46, 0.96, raw_cycle));
	float wash_reach = (river ? 0.045 : 0.035) + (1.0 - surge) * (river ? 0.055 : 0.095 + wind * 0.025);
	float primary_foam = (1.0 - smoothstep(0.010, 0.048, abs(shore_dist - wash_reach))) * (1.0 - smoothstep(0.14, 0.34, shore_dist));

	// Trailing recede foam & broken shoreline flecks
	float recede_phase = smoothstep(0.42, 0.92, raw_cycle);
	float recede_band = (1.0 - smoothstep(0.008, 0.042, abs(shore_dist - (wash_reach * 0.58)))) * recede_phase * (1.0 - smoothstep(0.08, 0.22, shore_dist));
	float shore_fleck_mask = step(0.54, hash(floor((q + outward * phase * 6.0) / 6.0)));
	float foam = clamp(primary_foam + recede_band * shore_fleck_mask * 0.75, 0.0, 1.0);
	foam *= smoothstep(0.20, 0.68, noise(q / 21.0 + flow * phase * 0.12));
	foam *= 1.0 - land_mask * 0.85;

	// Open-water crest flecks & sun glints
	float fleck = hash(floor(advected / vec2(12.0, 29.0)));
	float glint = step(0.92, primary_swell) * step(0.66, cross_wave) * step(0.75, fleck) * 0.068;

	// Rain ripples
	vec2 rain_cell = floor(q / 43.0);
	float seed = hash(rain_cell);
	vec2 center = vec2(0.4 + seed * 0.2, 0.4 + hash(rain_cell + 7.0) * 0.2);
	float ring_age = fract(phase * (0.60 + seed * 0.45) + seed);
	float ring_dist = length(fract(q / 43.0) - center);
	float ring = (1.0 - smoothstep(0.014, 0.035, abs(ring_dist - ring_age * 0.33))) * (1.0 - ring_age) * rain * 0.22;

	vec3 foam_color = river ? vec3(0.46, 0.59, 0.52) : vec3(0.50, 0.63, 0.56);
	ALBEDO = mix(water, foam_color, foam * (river ? 0.36 : 0.44)) + vec3(glint + ring);
	NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(
		0.026 * sin(q.x * 0.048 + phase),
		0.034 * cos(q.y * 0.042 - phase),
		1.0,
		0.0
	)).xyz);
	ROUGHNESS = 0.72;
	SPECULAR = 0.22;
}
