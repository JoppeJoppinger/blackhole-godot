shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never;

uniform float star_density : hint_range(0.0, 1.0) = 0.97;
uniform float star_brightness : hint_range(0.0, 5.0) = 2.0;
uniform vec3 ship_velocity_dir = vec3(0.0, 0.0, -1.0);
uniform float ship_speed_fraction : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = UV * 200.0;
    vec2 cell = floor(uv);
    vec2 local = fract(uv);

    float star = 0.0;
    vec3 star_color = vec3(1.0);

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 neighbor = cell + vec2(float(x), float(y));
            float h = hash(neighbor);
            if (h > star_density) {
                vec2 star_pos = vec2(hash(neighbor + 0.1), hash(neighbor + 0.2));
                vec2 diff = local - vec2(float(x), float(y)) - star_pos;
                float dist = length(diff);
                float size = mix(0.02, 0.06, hash(neighbor + 0.3));
                star += smoothstep(size, 0.0, dist) * star_brightness;
                // Color variation: some blue-white, some yellow-white
                float temp = hash(neighbor + 0.5);
                star_color = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.95, 0.8), temp);
            }
        }
    }

    // Relativistic aberration at high speed
    float aberration = ship_speed_fraction * 0.3;
    star += aberration * 0.05;

    ALBEDO = star_color * star;
    ALPHA = clamp(star, 0.0, 1.0);
}
