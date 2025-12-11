#version 120

// Uniforms for texture and screen resolution
uniform sampler2D screenTexture;
uniform vec2 resolution;

// Varying texture coordinates
varying vec2 texcoord;

// Gaussian weights for a 5x5 kernel
const float weight[5] = float[5](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

void main() {
    vec3 color = vec3(0.0);

    // Calculate the pixel size based on resolution
    vec2 texOffset = 1.0 / resolution;

    // Apply Gaussian blur in both horizontal and vertical directions
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(float(x), float(y)) * texOffset;
            color += texture2D(screenTexture, texcoord + offset).rgb * weight[abs(x)] * weight[abs(y)];
        }
    }

    // Output the blurred color
    gl_FragColor = vec4(color, 1.0);
}