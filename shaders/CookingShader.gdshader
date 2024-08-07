shader_type spatial;

uniform sampler2D base_texture: source_color;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 raw_color : source_color = vec3(0.8, 0.7, 0.6);
uniform vec3 cooked_color : source_color = vec3(0.75, 0.6, 0.5);
uniform vec3 overcooked_color : source_color = vec3(0.175,0.115,0.05);
uniform float cooking_level = 0.0;

void fragment() {
    vec3 cooking_effect_color;
    if (cooking_level < 1.0) {
        cooking_effect_color = mix(raw_color, cooked_color, cooking_level);
    } else {
        cooking_effect_color = mix(cooked_color, overcooked_color, cooking_level - 1.0);
    }

    vec4 tex_color = texture(base_texture, UV) * base_color;
    vec3 combined_color = mix(tex_color.rgb, cooking_effect_color, clamp(cooking_level / 2.0, 0.0, 1.0));

    ALBEDO = mix(tex_color.rgb, combined_color, clamp(cooking_level, 0.0, 1.0));
}