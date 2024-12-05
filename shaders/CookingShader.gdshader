shader_type spatial;

// Cooking level control
uniform float cooking_level = 0.0;
uniform float max_cooking_level = 2.0;

// Color control
uniform sampler2D base_albedo_texture: source_color;
uniform vec4 base_albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 cooked_color : source_color = vec3(0.4, 0.28, 0.15); // the color when fully cooked


// Roughness control
uniform sampler2D base_roughness_texture: source_color; // note this is actually the roughness-metallic texture, roughness is in the g channel
uniform float base_roughness = 0.5;
uniform float cooked_roughness = 0.8; // the roughness when fully cooked

void fragment() {
	// Ensure cooking level control
	float curr_cooking_level = clamp(cooking_level, 0.0, max_cooking_level);

    // Apply cooked color
    vec4 initial_color = texture(base_albedo_texture, UV) * base_albedo;
    ALBEDO = mix(initial_color.rgb, cooked_color, curr_cooking_level / max_cooking_level);

    // Apply cooked roughness
    float initial_roughness = texture(base_roughness_texture, UV).g * base_roughness;
    ROUGHNESS = mix(initial_roughness, cooked_roughness, curr_cooking_level / max_cooking_level);
}
