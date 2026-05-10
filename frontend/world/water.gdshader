// https://docs.godotengine.org/en/3.1/tutorials/shading/your_first_shader/your_second_spatial_shader.html
// https://gameidea.org/2026/02/01/creating-a-stylized-3d-water-shader/
// Generative AI 
shader_type spatial;
render_mode depth_draw_opaque;

uniform vec3 shallow_color : source_color = vec3(0.0, 0.8, 0.8);
uniform vec3 deep_color : source_color = vec3(0.263, 0.675, 0.89);
uniform float depth_distance = 4.0;
uniform float water_alpha = 1;

uniform sampler2D color_noise_map;
uniform vec2 color_noise_uv_scale = vec2(0.002, 0.002);
uniform float color_noise_strength = 0.08;

uniform float wave_speed = 1.0;
uniform sampler2D wave_normal_map : hint_normal;
uniform float normal_strength = 0.7;
uniform vec2 normal_uv_scale = vec2(0.05, 0.05);
uniform vec2 normal_scroll_dir_a = vec2(0.08, 0.03);
uniform vec2 normal_scroll_dir_b = vec2(-0.05, 0.06);

uniform vec3 foam_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float foam_range = 1;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Normal waves
    float t = TIME * wave_speed;
    vec2 normal_uv = world_pos.xz * normal_uv_scale;
    vec3 normal_a = texture(wave_normal_map, normal_uv + t * normal_scroll_dir_a).rgb;
    vec3 normal_b = texture(wave_normal_map, normal_uv + t * normal_scroll_dir_b).rgb;
    NORMAL_MAP = normalize(normal_a + normal_b - 1.0) * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = normal_strength;

    // Get camera depth
    vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, texture(depth_texture, SCREEN_UV).x * 2.0 - 1.0, 1.0);
    view.xyz /= view.w;
    float depth_diff = VERTEX.z - view.z;

    // Mix depth color
    float color_factor = clamp(depth_diff / depth_distance, 0.0, 1.0);
    vec3 water_base = mix(shallow_color, deep_color, color_factor);

    // Add color noise
    float color_noise = smoothstep(0.25, 0.75, texture(color_noise_map, world_pos.xz * color_noise_uv_scale).r);
    water_base *= 1.0 + ((color_noise * 2.0 - 1.0) * color_noise_strength);

    // Foam
    float foam_mask = clamp(1.0 - (depth_diff / foam_range), 0.0, 1.0);

    ALBEDO = mix(water_base, foam_color, foam_mask);
    ALPHA = mix(0.3, water_alpha, color_factor) + (foam_mask * 0.5);
    RIM = 0.2;
    METALLIC = 0.0;
    ROUGHNESS = 0.25;
}
