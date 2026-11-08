shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
uniform sampler2D shoreline : filter_linear, repeat_disable;
uniform vec2 map_extent = vec2(2400.0,1600.0);
uniform float clock = 0.0;
uniform float rain = 0.0;
uniform float wind = 0.2;
uniform float motion = 1.0;
uniform bool river = false;
varying vec2 water_uv;

float hash(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}

float noise(vec2 p) {
	vec2 cell=floor(p);
	vec2 blend=fract(p);
	blend=blend*blend*(3.0-2.0*blend);
	return mix(mix(hash(cell),hash(cell+vec2(1.0,0.0)),blend.x),mix(hash(cell+vec2(0.0,1.0)),hash(cell+vec2(1.0)),blend.x),blend.y);
}

void vertex() {
	water_uv = UV;
	vec2 p = UV*map_extent;
	float a = sin(p.x*0.035+clock*1.5)*1.7;
	float b = sin(p.y*0.047-p.x*0.012-clock*1.1)*1.1;
	VERTEX.z += (a+b)*motion*(0.7+wind*0.3);
	NORMAL = normalize(vec3(-cos(p.x*0.035+clock*1.5)*0.06,cos(p.y*0.047-p.x*0.012-clock*1.1)*0.05,1.0));
}

void fragment() {
	vec2 q = floor(water_uv*map_extent/2.0)*2.0;
	vec4 edge = texture(shoreline,water_uv);
	float phase = clock*motion;
	vec2 flow=river ? vec2(0.10,1.0) : vec2(0.75,0.22);
	vec2 advected=q-flow*phase*(11.0+wind*5.0);
	float swells=sin(advected.y*0.073+noise(advected/85.0)*3.5)*0.5+0.5;
	float cross_wave=noise(advected/vec2(19.0,river ? 83.0 : 39.0));
	float pattern=floor((swells*0.35+cross_wave*0.65)*6.0)/5.0;
	vec3 deep=vec3(0.075,0.27,0.30);
	vec3 shallow=vec3(0.19,0.39,0.36);
	float bed=noise(q/38.0)*0.65+noise(q/11.0)*0.35;
	vec3 water=mix(shallow*(0.92+bed*0.14),deep,smoothstep(0.02,0.85,edge.g));
	water*=0.94+pattern*0.13;
	float foam_front = 0.06+sin(phase*1.7+q.x*0.025+q.y*0.014)*0.035;
	float foam = (1.0-smoothstep(0.012,0.055,abs(edge.g-foam_front)))*(1.0-smoothstep(0.15,0.35,edge.g));
	float fleck=hash(floor(advected/vec2(12.0,31.0)));
	float glint=step(0.93,swells)*step(0.68,cross_wave)*step(0.76,fleck)*0.065;
	vec2 rain_cell=floor(q/43.0);
	float seed=hash(rain_cell);
	vec2 center=vec2(0.4+seed*0.2,0.4+hash(rain_cell+7.0)*0.2);
	float ring_age=fract(phase*(0.60+seed*0.45)+seed);
	float ring_dist=length(fract(q/43.0)-center);
	float ring=(1.0-smoothstep(0.014,0.035,abs(ring_dist-ring_age*0.33)))*(1.0-ring_age)*rain*0.22;
	foam*=smoothstep(0.23,0.70,noise(q/23.0+flow*phase*0.1));
	ALBEDO=mix(water,vec3(0.43,0.56,0.49),foam*0.38)+vec3(glint+ring);
	NORMAL = normalize((VIEW_MATRIX*MODEL_MATRIX*vec4(0.025*sin(q.x*0.05+phase),0.035*cos(q.y*0.04-phase),1.0,0.0)).xyz);
	ROUGHNESS = 0.74;
	SPECULAR = 0.2;
}
