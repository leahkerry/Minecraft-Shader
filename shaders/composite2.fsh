// composite fragment shader file for clouds

#version 120

#include "/settings.glsl"

uniform float frameTimeCounter;
uniform float satBoost = SATURATION;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float rainStrength;

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

vec3 projectanddivide (mat4 projectionMatrix, vec3 pos) {
    vec4 hp = projectionMatrix * vec4(pos, 1.0);
    return hp.xyz / hp.w;
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;

    if (depth == 1.0) {
        // color.rgb = vec3(0., 0., 1.);

        vec4 pos = vec4(texcoord, depth, 1.) * 2.0 - 1.0; // ndc
        // convert to view position/camera coordinates
        pos.xyz = projectanddivide(gbufferProjectionInverse, pos.xyz);
        // player feet position
        pos = gbufferModelViewInverse * vec4(pos.xyz, 1.0);

        // get direction of each pixel
        vec3 raydir = normalize(pos.xyz);
        vec2 uv = raydir.xz * 1.0 / raydir.y + 0.2 * frameTimeCounter * CLOUD_SPEED;
        vec2 uv2 = raydir.xz * 3.0 * 1.0 / raydir.y - 0.2 * frameTimeCounter * (0.5 * CLOUD_SPEED); // different size + speed than first batch of clouds

        // add clouds
        vec4 clouds;
        if (raydir.y > 0) {
            clouds = vec4(fractal_noise(uv) * fractal_noise(uv2));
        } else {
            // Don't draw clouds if not in the sky
            clouds = vec4(0.0);
        }
        float cloud_fog = 1.0 + 1.0 / raydir.y;

        // making holes and density (change number of clouds)
        clouds.a = clamp((clouds.a - (0.3 * (1.0 - rainStrength))) * 4.0, 0.0, 2.0);

        // white clouds
        clouds.rgb = vec3(1.0); // white clouds

        // shading
        clouds.rgb -= clamp((clouds.a - 0.5) * 0.1, 0.0, 0.25);

        // blending
        color.rgb = mix(color.rgb, clouds.rgb, min(clouds.a, 1.) / max(1.0, cloud_fog * CLOUD_FOG));

        // color.rgb += vec3(fractal_noise(uv) * fractal_noise(uv2));
    }

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0); //gcolor
}
