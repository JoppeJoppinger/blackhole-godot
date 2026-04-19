shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform vec3 glow_color = vec3(0.3, 0.8, 1.0);
uniform float glow_intensity = 1.0;

void fragment() {
	float dist = length(UV - vec2(0.5)) * 2.0;
	float glow = exp(-dist * dist * 3.0) * glow_intensity;
	EMISSION = glow_color * glow;
	ALPHA = glow * 0.5;
	ALBEDO = vec3(0.0);
}
