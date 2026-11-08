shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
uniform sampler2D shoreline : filter_linear, repeat_disable;
uniform vec2 map_extent = vec2(2400.0,1600.0);
uniform float clock = 0.0;
uniform float rain = 0.0;
uniform float wind = 0.2;
uniform float motion = 1.0;
varying vec2 water_uv;

void vertex() {
	water_uv = UV;
	vec2 p = UV*map_extent;
	float a = sin(p.x*0.035+clock*1.5)*1.7;
	float b = sin(p.y*0.047-p.x*0.012-clock*1.1)*1.1;
	VERTEX.z += (a+b)*motion*(0.7+wind*0.3);
	NORMAL = normalize(vec3(-cos(p.x*0.035+clock*1.5)*0.06,cos(p.y*0.047-p.x*0.012-clock*1.1)*0.05,1.0));
}

void fragment() {
	vec2 q = floor(water_uv*map_extent/4.0)*4.0;
	vec4 edge = texture(shoreline,water_uv);
	float phase = clock*motion;
	float swells = sin(q.x*0.044+q.y*0.026-phase*1.9)*0.5+0.5;
	float cross_wave = sin(q.y*0.061-q.x*0.019+phase*1.3)*0.5+0.5;
	float pattern = floor((swells*0.65+cross_wave*0.35)*5.0)/4.0;
	vec3 deep = vec3(0.055,0.29,0.33);
	vec3 shallow = vec3(0.12,0.46,0.44);
	vec3 water = mix(shallow,deep,smoothstep(0.03,0.85,edge.g));
	water *= 0.86+pattern*0.24;
	float foam_front = 0.06+sin(phase*1.7+q.x*0.025+q.y*0.014)*0.035;
	float foam = (1.0-smoothstep(0.012,0.055,abs(edge.g-foam_front)))*(1.0-smoothstep(0.15,0.35,edge.g));
	float fleck = fract(sin(dot(floor(q/24.0),vec2(91.7,37.2)))*43758.5453);
	float glint = step(0.93,swells)*step(0.7,cross_wave)*step(0.82,fleck)*0.08;
	vec2 rain_cell = floor(q/34.0);
	float seed = fract(sin(dot(rain_cell,vec2(12.9898,78.233)))*43758.5453);
	float ring_age = fract(phase*0.7+seed);
	float ring_dist = length(fract(q/34.0)-vec2(0.5));
	float ring = (1.0-smoothstep(0.025,0.065,abs(ring_dist-ring_age*0.62)))*(1.0-ring_age)*rain*0.32;
	ALBEDO = mix(water,vec3(0.47,0.66,0.62),foam*0.62)+vec3(glint+ring);
	NORMAL = normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(0.025*sin(q.x*0.05+phase),0.035*cos(q.y*0.04-phase),1.0,0.0)).xyz);
	ROUGHNESS = 0.74;
	SPECULAR = 0.2;
}
