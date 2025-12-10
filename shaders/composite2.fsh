// composite fragment shader file for clouds

#version 120

#include "/settings.glsl"

uniform float frameTimeCounter;
uniform float satBoost = SATURATION;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform int worldTime;
uniform int heldItemId;
uniform vec3 cameraPosition;

varying vec2 texcoord;

float random(in vec2 p) {
    return fract(sin((p.x * 456. + p.y * 312. * 100)) * 100.);
    // return fract(sin((p.x * 456. + p.y * 312. + mod(frameTimeCounter, 10.) * 100)) * 100.);
}

vec2 smooth_vec2(in vec2 v) {
    return v * v * (3.-2.*v);
}

float smooth_noise(in vec2 p) {
    vec2 f = smooth_vec2(fract(p));
    float a = random(floor(p)); // top left corner
    float b = random(vec2(ceil(p.x), floor(p.y))); // top right corner
    float c = random(vec2(floor(p.x), ceil(p.y))); // bottom left corner
    float d = random(ceil(p)); // bottom right corner

    return mix(
        mix(a, b, f.x),
        mix(c, d, f.x),
        f.y
    );
}

// Create smaller waves
float fractal_noise(in vec2 p) {
    float total = 0.5; // seems to change brightness?
    float amplitude = 1.;
    float frequency = 1.;
    int iterations = 4;

    for (int i = 0; i < iterations; i++) {
        total += (smooth_noise(p * frequency) - 0.5) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return total;
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;

    if (depth == 1.0) {
        // color.rgb = vec3(0., 0., 1.);

        vec2 uv = texcoord * 10.;
        vec2 uv2 = texcoord * 14. + frameTimeCounter * 0.2;

        // add clouds
        vec4 clouds = vec4(fractal_noise(uv) * fractal_noise(uv2));
        
        // making holes and density
        clouds.a = clamp((clouds.a - 0.3) * 4.0, 0.0, 2.0);

        // white clouds
        clouds.rgb = vec3(1.0); // white clouds

        // shading
        clouds.rgb -= clamp((clouds.a - 0.5) * 0.1, 0.0, 0.25);

        // blending
        color.rgb = mix(color.rgb, clouds.rgb, min(clouds.a, 1.));

        // color.rgb += vec3(fractal_noise(uv) * fractal_noise(uv2));
    }

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0); //gcolor
}
