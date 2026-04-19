shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform float inner_radius = 0.09;
uniform float outer_radius = 0.8;
uniform float disk_thickness = 0.04;
uniform float spin_direction = 1.0;

vec3 blackbody_color(float temp_K) {
	temp_K = clamp(temp_K, 1000.0, 40000.0);
	vec3 color;
	float t = temp_K / 1000.0;
	color.r = (temp_K <= 6600.0) ? 1.0 : clamp(pow(t - 6.0, -0.1332) * 1.292, 0.0, 1.0);
	color.g = (temp_K <= 6600.0) ? clamp(log(t) * 0.3913 - 0.6318, 0.0, 1.0) : clamp(pow(t - 6.0, -0.0755) * 1.1406, 0.0, 1.0);
	color.b = (temp_K >= 6600.0) ? 1.0 : ((temp_K <= 1900.0) ? 0.0 : clamp(log(t - 1.0) * 0.5432 - 1.196, 0.0, 1.0));
	return color;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.1;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	// UV on torus: u = around ring (longitude), v = tube cross-section
	// We use VERTEX in local space for accurate radial coordinate
	vec3 lpos = (inverse(MODEL_MATRIX) * vec4(VERTEX, 1.0)).xyz;
	float r = length(vec2(lpos.x, lpos.z));

	bool in_disk = (r >= inner_radius) && (r <= outer_radius);

	if (in_disk) {
		float r_norm = clamp((r - inner_radius) / (outer_radius - inner_radius), 0.0, 1.0);
		float temp = mix(10000000.0, 3000.0, pow(r_norm, 0.75));

		float angle = atan(lpos.z, lpos.x);
		float v_orbital = sqrt(1.0 / max(r, inner_radius)) * 0.3;
		float cos_angle = cos(angle);
		float doppler = pow(1.0 / max(1.0 - v_orbital * cos_angle * spin_direction, 0.1), 4.0);
		doppler = clamp(doppler, 0.1, 8.0);

		float flow_angle = angle + TIME * 0.3 / max(r * 3.0, 0.001) * spin_direction;
		vec2 flow_uv = vec2(cos(flow_angle), sin(flow_angle)) * r * 8.0 + vec2(TIME * 0.1);
		float turbulence = fbm(flow_uv);
		float plasma = 0.7 + 0.3 * turbulence;

		// height fade along tube: UV.y goes 0-1 around tube cross section
		float tube_angle = UV.y * TAU;
		float height_in_tube = sin(tube_angle);
		float thickness_falloff = exp(-height_in_tube * height_in_tube * 8.0);

		vec3 color = blackbody_color(temp * plasma);
		float brightness = (1.0 / (r_norm + 0.05)) * doppler * plasma * thickness_falloff;
		brightness = clamp(brightness * 0.4, 0.0, 12.0);

		EMISSION = color * brightness;
		ALBEDO = vec3(0.0);
		ALPHA = clamp(thickness_falloff * brightness * 0.25, 0.0, 1.0);
	} else {
		ALBEDO = vec3(0.0);
		ALPHA = 0.0;
	}
}
