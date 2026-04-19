shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 tint : source_color = vec4(0.1, 0.3, 0.5, 0.15);
uniform float fresnel_power = 3.0;

void fragment() {
	vec3 normal = NORMAL;
	vec3 view = normalize(VIEW);
	float fresnel = pow(1.0 - abs(dot(normal, view)), fresnel_power);
	ALBEDO = tint.rgb;
	ALPHA = tint.a + fresnel * 0.2;
	EMISSION = tint.rgb * fresnel * 0.5;
}
