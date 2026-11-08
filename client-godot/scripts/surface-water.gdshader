shader_type canvas_item;
uniform sampler2D raster_texture : filter_nearest, repeat_disable;
uniform sampler2D region_mask : filter_nearest, repeat_disable;
uniform vec2 raster_texel;
uniform float phase = 0.0;
uniform float motion = 1.0;
uniform float sea_state = 0.3;
uniform float daylight = 0.9;
uniform float rain = 0.0;
uniform vec2 flow = vec2(0.35,0.0);
uniform bool river = false;

float water_color(vec3 color) {
	return step(0.125,color.g)*step(color.r+0.004,color.g*0.88)*step(color.g*0.62+0.004,color.b)*step(color.r*1.06+0.004,color.b);
}
float wet(vec2 uv) {
	return step(0.5,texture(region_mask,uv).r)*water_color(texture(raster_texture,uv).rgb);
}
void fragment() {
	vec4 base = texture(raster_texture,UV);
	if (texture(region_mask,UV).r < 0.5 || water_color(base.rgb) < 0.5) discard;
	vec2 pixel = floor(UV/raster_texel);
	float time = phase*motion;
	vec2 direction = river ? normalize(vec2(0.45,0.9)+flow*0.2) : normalize(vec2(1.0,0.35)+flow*0.3);
	float swell = sin(dot(pixel,direction)*0.095-time*(1.4+sea_state));
	float cross_wave = sin(pixel.x*0.061-pixel.y*0.145+time*1.15);
	vec2 shift = vec2(swell,cross_wave)*raster_texel*motion*(0.85+sea_state*1.15);
	vec2 displaced = UV+shift;
	vec3 refracted = wet(displaced) > 0.5 ? texture(raster_texture,displaced).rgb : base.rgb;
	vec3 color = mix(base.rgb,refracted,0.72);
	color += vec3(0.014,0.031,0.032)*(swell+cross_wave)*motion;
	float broken = sin(pixel.x*0.23+pixel.y*0.11+time*0.6);
	float glint = smoothstep(0.94,1.0,swell)*smoothstep(0.55,0.92,broken);
	color += vec3(0.15,0.18,0.16)*glint*daylight*(0.6+sea_state)*motion;
	float shore = 1.0-min(min(wet(UV+vec2(raster_texel.x*4.0,0.0)),wet(UV-vec2(raster_texel.x*4.0,0.0))),min(wet(UV+vec2(0.0,raster_texel.y*4.0)),wet(UV-vec2(0.0,raster_texel.y*4.0))));
	float foam = shore*smoothstep(0.35,0.95,swell)*0.12*motion;
	color = mix(color,vec3(0.73,0.88,0.80),foam);
	float drops = pow(max(0.0,sin(pixel.x*0.37+pixel.y*0.59-time*3.0)),24.0)*rain*0.035*motion;
	COLOR = vec4(clamp(color+vec3(drops),vec3(0.0),vec3(1.0)),base.a);
}
