shader_type spatial;
render_mode unshaded, cull_back;

void fragment() {
	ALBEDO = vec3(0.02, 0.02, 0.04);
	EMISSION = vec3(0.01, 0.01, 0.02);
}
