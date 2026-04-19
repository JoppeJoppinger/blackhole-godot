shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 bh_screen_pos = vec2(0.5, 0.5);
uniform float bh_radius_screen = 0.05;
uniform float photon_sphere_screen = 0.075;
uniform float lens_strength = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 delta = uv - bh_screen_pos;
	float dist = length(delta);
	vec2 dir = (dist > 0.0001) ? normalize(delta) : vec2(1.0, 0.0);

	// Shadow region check
	bool in_shadow = dist < bh_radius_screen;

	// Normalized impact parameter (1.0 = photon sphere)
	float b = dist / max(photon_sphere_screen, 0.0001);

	// Lensing offset
	float offset_strength = lens_strength * bh_radius_screen * bh_radius_screen / max(dist * dist, 0.0001);
	offset_strength = clamp(offset_strength, 0.0, 0.4);
	vec2 lensed_uv = clamp(uv + dir * offset_strength * -1.0, vec2(0.0), vec2(1.0));

	vec4 primary = texture(screen_texture, lensed_uv);

	// Secondary Einstein ring
	if (b < 2.5) {
		vec2 secondary_uv = clamp(bh_screen_pos - dir * (dist * 0.7), vec2(0.0), vec2(1.0));
		vec4 secondary = texture(screen_texture, secondary_uv);
		float blend = smoothstep(2.5, 1.2, b) * 0.4;
		primary = mix(primary, secondary, blend);
	}

	// Gravitational blueshift
	float redshift_z = 1.0 / sqrt(max(0.01, 1.0 - 1.5 / max(b, 1.51))) - 1.0;
	primary.rgb *= 1.0 + redshift_z * 0.3;

	// Photon sphere bright ring
	float ring = smoothstep(0.05, 0.0, abs(b - 1.0)) * 3.0;
	primary.rgb += vec3(0.9, 0.8, 0.6) * ring;

	// Black hole shadow
	COLOR = in_shadow ? vec4(0.0, 0.0, 0.0, 1.0) : primary;
}
