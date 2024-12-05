shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, depth_test_disabled, cull_disabled;

// Uniforms to control the base color and alpha threshold
uniform vec3 base_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float alpha = 0.4;
uniform float min_alpha = 0.4;
uniform float max_alpha = 0.8;

// Fresnel effect control
uniform float fresnel_amount = 3.0;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void fragment() {
	ALPHA = clamp(alpha, min_alpha, max_alpha);

    float basic_fresnel = fresnel(fresnel_amount, NORMAL, VIEW);

    vec3 fresnel_color = base_color + basic_fresnel;

    // Clamp final color values to ensure they don't get washed out
    ALBEDO = clamp(fresnel_color, 0.0, 1.0);
}