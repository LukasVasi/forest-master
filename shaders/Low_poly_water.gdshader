shader_type spatial;

// Uniforms related to triangle animation
uniform float triangleHeight: hint_range(0.2, 5.0, 0.1) = 0.8;
uniform float triangleSpeed: hint_range(0.1, 5.0, 0.1) = 1;

// Surface properties
uniform vec3 primaryColor : source_color;
uniform vec3 secondaryColor : source_color;
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;

// Normal textures for surface distortion
uniform sampler2D normalTexture1;
uniform sampler2D normalTexture2;

// Wave direction for surface distortion
uniform vec2 waveDirection1 = vec2(2.0, 0.0);
uniform vec2 waveDirection2 = vec2(0.0, 1.0);
uniform float timeScale : hint_range(0.0, 0.2, 0.005) = 0.025;

// Water color and depth parameters
uniform vec4 deepWaterColor : source_color;
uniform vec4 shallowWaterColor : source_color;
uniform float attenuationCoefficient = 2.0;
uniform float depthOffset = -0.75;

// Depth and screen textures for depth effects
uniform sampler2D depthTexture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screenTexture : hint_screen_texture, filter_linear_mipmap;

// Edge detection for depth difference
uniform float edgeScale = 0.1;
uniform float nearPlane = 1.0;
uniform float farPlane = 100.0;
uniform vec3 edgeColor : source_color;

// Function to generate vertex offset for distortion effect
float generateVertexOffset(float x, float z, float modX, float modZ, float time) {
    float waveX = ((mod(x + z * x * modX, triangleHeight) / triangleHeight) + 
                   (time * triangleSpeed) * mod(x * 0.8 + z, 1.5)) * 2.0 * 3.14;
    float waveZ = ((mod(modZ * (z * x + x * z), triangleHeight) / triangleHeight) + 
                   (time * triangleSpeed) * 2.0 * mod(x, 2.0)) * 2.0 * 3.14;
    
    return triangleHeight * 0.5 * (sin(waveZ) * cos(waveX));
}

// Applying distortion to the vertex position
vec3 applyDistortion(vec3 vertexPosition, float time) {
    float xDistortion = generateVertexOffset(vertexPosition.x, vertexPosition.z, 0.2, 0.1, time);
    float yDistortion = generateVertexOffset(vertexPosition.x, vertexPosition.z, 0.1, 0.3, time);
    float zDistortion = generateVertexOffset(vertexPosition.x, vertexPosition.z, 0.15, 0.2, time);
    
    return vertexPosition + vec3(xDistortion, yDistortion, zDistortion);
}

// Fresnel effect for reflection intensity
float calculateFresnelEffect(float intensity, vec3 normal, vec3 viewDirection) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(viewDirection)), 0.0, 1.0)), intensity);
}

// Calculating edge depth for depth blending
float calculateEdgeDepth(float depthValue) {
    depthValue = 2.0 * depthValue - 1.0;
    return nearPlane * farPlane / (farPlane + depthValue * (nearPlane - farPlane));
}

// Vertex shader
void vertex() {
    VERTEX = applyDistortion(VERTEX, TIME * 0.1);
}

// Fragment shader
void fragment() {
    float rawDepth = texture(depthTexture, SCREEN_UV).r * 2.0 - 1.0;
    float depth = PROJECTION_MATRIX[3][2] / (rawDepth + PROJECTION_MATRIX[2][2]);
    float depthBlend = exp((depth + VERTEX.z + depthOffset) * -attenuationCoefficient);
    depthBlend = clamp(1.0 - depthBlend, 0.0, 1.0);
    float depthPower = clamp(pow(depthBlend, 2.5), 0.0, 1.0);
    
    vec3 screenColor = textureLod(screenTexture, SCREEN_UV, depthPower * 2.5).rgb;
	vec3 waterColor = mix(shallowWaterColor.rgb, deepWaterColor.rgb, depthPower);
    vec3 finalColor = mix(screenColor * waterColor, waterColor * 0.25, depthPower * 0.5);

    float depthFromTexture = calculateEdgeDepth(texture(depthTexture, SCREEN_UV).x);
    float fragmentDepth = calculateEdgeDepth(FRAGCOORD.z);
    float depthDifference = depthFromTexture - fragmentDepth;

    vec2 timeAdjusted1 = (TIME * waveDirection1) * timeScale;
    vec2 timeAdjusted2 = (TIME * waveDirection2) * timeScale;

    vec3 normal1 = texture(normalTexture1, VERTEX.xy + timeAdjusted1).rgb;
    vec3 normal2 = texture(normalTexture2, VERTEX.xy + timeAdjusted2).rgb;
    vec3 blendedNormals = mix(normal1, normal2, 0.5);

    float fresnelEffect = calculateFresnelEffect(5.0, NORMAL, VIEW);
    vec3 surfaceColor = mix(primaryColor, secondaryColor, fresnelEffect);

    vec3 adjustedDepthColor = mix(edgeColor, finalColor, step(edgeScale, depthDifference));

    NORMAL = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
    ALBEDO = clamp(surfaceColor + adjustedDepthColor, vec3(0.0), vec3(1.0));
    METALLIC = metallic;
    ROUGHNESS = roughness;
}
