shader_type canvas_item;

uniform float strength : hint_range(0.0, 8.0) = 2.5;
uniform float wind_speed : hint_range(0.0, 3.0) = 1.2;
uniform float wind_phase : hint_range(0.0, 6.2832) = 0.0;

void vertex() {
	float canopy_weight = clamp(-VERTEX.y / 120.0, 0.0, 1.0);
	VERTEX.x += sin(TIME * wind_speed + VERTEX.y * 0.02 + wind_phase) * strength * canopy_weight;
}
