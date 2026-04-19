shader_type spatial;
render_mode unshaded, cull_front, skip_vertex_transform;

uniform float ship_speed_fraction = 0.0;
uniform vec3 ship_velocity_dir = vec3(0.0, 0.0, -1.0);

float hash13(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}
vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yzz) * p.zyx);
}

vec3 spectral_color(float class_val) {
	if (class_val < 0.05) return vec3(0.6, 0.7, 1.0) * 3.0;
	if (class_val < 0.15) return vec3(0.7, 0.8, 1.0) * 2.0;
	if (class_val < 0.25) return vec3(0.9, 0.95, 1.0) * 1.5;
	if (class_val < 0.40) return vec3(1.0, 1.0, 0.9) * 1.2;
	if (class_val < 0.60) return vec3(1.0, 0.95, 0.7) * 1.0;
	if (class_val < 0.80) return vec3(1.0, 0.8, 0.5) * 0.8;
	return vec3(1.0, 0.5, 0.3) * 0.6;
}

vec3 aberrate(vec3 dir, vec3 vel_dir, float beta) {
	if (beta < 0.001) return dir;
	float gamma = 1.0 / sqrt(1.0 - beta * beta);
	float cos_theta = dot(dir, vel_dir);
	float cos_theta_prime = (cos_theta - beta) / (1.0 - beta * cos_theta);
	float sin_theta = sqrt(max(0.0, 1.0 - cos_theta * cos_theta));
	float sin_theta_prime = sin_theta / (gamma * (1.0 - beta * cos_theta));
	vec3 perp = dir - cos_theta * vel_dir;
	if (length(perp) > 0.001) perp = normalize(perp);
	return cos_theta_prime * vel_dir + sin_theta_prime * perp;
}

float milky_way(vec3 dir) {
	float lat = asin(clamp(dir.y, -1.0, 1.0)) / 3.14159;
	float lon = atan(dir.z, dir.x) / 3.14159;
	float band = exp(-lat * lat * 80.0);
	float noise_val = 0.0;
	for (int i = 0; i < 4; i++) {
		float s = pow(2.0, float(i));
		noise_val += (sin(lon * s * 12.0 + lat * s * 7.0) * 0.5 + 0.5) / s;
	}
	return band * (0.3 + 0.7 * noise_val);
}

void vertex() {
	POSITION = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	POSITION.z = POSITION.w;
}

void fragment() {
	vec3 dir = normalize(VERTEX);
	dir = aberrate(dir, ship_velocity_dir, ship_speed_fraction);

	vec3 sky_color = vec3(0.0);

	float cell_size = 0.02;
	vec3 cell = floor(dir / cell_size);
	for (int dx = -1; dx <= 1; dx++) {
		for (int dy = -1; dy <= 1; dy++) {
			for (int dz = -1; dz <= 1; dz++) {
				vec3 c = cell + vec3(float(dx), float(dy), float(dz));
				vec3 h = hash33(c);
				if (h.x > 0.85) {
					vec3 star_dir = normalize(c * cell_size + h * cell_size);
					float ang = acos(clamp(dot(dir, star_dir), -1.0, 1.0));
					float star_size = 0.0003 + h.z * 0.0008;
					float brightness = exp(-ang * ang / (star_size * star_size));
					if (brightness > 0.001) {
						float spectral_class = hash13(c + vec3(7.3));
						vec3 star_color = spectral_color(spectral_class);
						star_color = mix(star_color, star_color * vec3(0.7, 0.8, 1.2), ship_speed_fraction * 2.0);
						sky_color += star_color * brightness * (0.3 + h.y * 0.7);
					}
				}
			}
		}
	}

	sky_color += vec3(0.2, 0.25, 0.4) * milky_way(dir) * 0.15;
	float neb = sin(dir.x * 3.0) * sin(dir.y * 5.0) * sin(dir.z * 4.0);
	neb = max(0.0, neb);
	sky_color += vec3(0.3, 0.1, 0.5) * neb * neb * 0.05;
	sky_color += vec3(0.002, 0.001, 0.001);

	ALBEDO = sky_color;
	EMISSION = sky_color;
}
