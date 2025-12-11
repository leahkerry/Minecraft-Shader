uniform float frameTimeCounter;
uniform float satBoost = SATURATION;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float rainStrength;
uniform vec3 skyColor;
varying vec4 glcolor;

uniform int worldTime;
uniform int heldItemId;
uniform vec3 cameraPosition;

varying vec2 texcoord;

float random3d(in vec3 p) {
    return fract(sin((p.x * 456. + p.y * 312. + p.z * 56.)) * 100.);
    // return fract(sin((p.x * 456. + p.y * 312. + mod(frameTimeCounter, 10.) * 100)) * 100.);
}

vec3 smooth_vec3(in vec3 v) {
    return v * v * (3.-2.*v);
}

float smooth_noise3d(in vec3 p) {
    vec3 f = smooth_vec3(fract(p));

    float a = random3d(floor(p)); // top left corner
    float b = random3d(vec3(ceil(p.x), floor(p.y), floor(p.z))); // top right corner
    float c = random3d(vec3(floor(p.x), ceil(p.y), floor(p.z))); // bottom left corner
    float d = random3d(vec3(ceil(p.xy), floor(p.z))); // bottom right corner

    float bottom = mix(
        mix(a, b, f.x),
        mix(c, d, f.x),
        f.y
    );

    a = random3d(vec3(floor(p.x), floor(p.y), ceil(p.z))); // top left corner
    b = random3d(vec3(ceil(p.x), floor(p.y), ceil(p.z))); // top right corner
    c = random3d(vec3(floor(p.x), ceil(p.y), ceil(p.z))); // bottom left corner
    d = random3d(ceil(p)); // bottom right corner

    float top = mix(
        mix(a, b, f.x),
        mix(c, d, f.x),
        f.y
    );

    return mix(bottom, top, f.z);
}

// Create smaller waves
float fractal_noise3d(in vec3 p) {
    float total = 0.5; // seems to change brightness?
    float amplitude = 1.;
    float frequency = 1.;
    int iterations = 4;

    for (int i = 0; i < iterations; i++) {
        total += (smooth_noise3d(p * frequency) - 0.5) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return total;
}

vec3 projectanddivide(mat4 projectionMatrix, vec3 pos) {
    vec4 hp = projectionMatrix * vec4(pos, 1.0);
    return hp.xyz / hp.w;
}

void main() {
    vec3 color = texture2D(colortex2, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;
    float world_seconds = worldTime * 0.05;

    // sky mask
    #if BACKGROUND_RESOLUTION_DIVIDER == 1
        if (depth == 1.0)
    #endif
    {
        // color.rgb = vec3(0., 0., 1.);

        vec4 pos = vec4(texcoord, depth, 1.) * 2.0 - 1.0; // ndc
        // convert to view position/camera coordinates
        pos.xyz = projectanddivide(gbufferProjectionInverse, pos.xyz);
        // player feet position
        pos = gbufferModelViewInverse * vec4(pos.xyz, 1.0);

        // get direction of each pixel
        vec3 raydir = normalize(pos.xyz);

        float starting_distance = 1.0 / raydir.y;

        vec2 uv = raydir.xz * starting_distance + 0.2 * world_seconds * CLOUD_SPEED;
        vec2 uv2 = raydir.xz * 3.0 * starting_distance - 0.2 * world_seconds * (0.5 * CLOUD_SPEED); // different size + speed than first batch of clouds

        vec3 sky_color = color;
        // add clouds
        vec4 clouds = vec4(vec3(1.0), 0.0);
        // vec4 clouds = vec4(mix(vec3(1.0), sky_color, pow(1.0 - raydir.y, 4.0)), pow(1.0 - raydir.y, 4.0));
        float scale = 0.1;

        if (raydir.y > 0.0) {
            vec3 player_pos = vec3(uv, 0.0);
            vec3 player_pos2 = vec3(uv2, 0.0);
            float sky_density = 0.0;

            for (float s = 0.0; s < CLOUD_SAMPLES && clouds.a < 0.99; s++) {
                // Goopy clouds hehe
                vec3 ray_pos = player_pos + raydir * s * scale;
                // vec3 ray_pos2 = player_pos2 + raydir * s * 3.0 * scale;
                vec3 ray_pos2 = player_pos2 + raydir * (s - random3d(world_seconds + vec3(texcoord, s))) * 3.0 * scale;

                // Jittery/Noisy clouds
                // vec3 ray_pos = player_pos + raydir * (s - random3d(world_seconds + vec3(texcoord, s))) * scale;
                // vec3 ray_pos2  = player_pos2 + raydir * (s - random3d(world_seconds + vec3(texcoord, s))) * 3.0 * scale;
                
                vec4 cloud = vec4(fractal_noise3d(ray_pos) * fractal_noise3d(ray_pos2));
                
                // Control cloud colors
                float r_cloud = 0.9;
                float g_cloud = 0.6;
                float b_cloud = 0.9;

                // float r_cloud = 1.0;
                // float g_cloud = 1.0;
                // float b_cloud = 1.0;

                #if CLOUD_COLOR_CHANGE == 1
                    r_cloud = sin(0.5 * world_seconds);
                    g_cloud = cos(0.1 * world_seconds);
                    b_cloud = sin(0.2 * world_seconds);
                #endif

                // making holes and density (change number of clouds)
                clouds.a = clamp((clouds.a - (0.3 * (1.0 - rainStrength))) * 4.0, sky_density, 2.0);
                clouds.rgb = mix(vec3(r_cloud, g_cloud, b_cloud), sky_color, min(1.0, s / CLOUD_SAMPLES + sky_density * (1.0 - clouds.a)));

                // blend clouds
                clouds.rgb = mix(clouds.rgb, cloud.rgb, (1.0 - clouds.a) * cloud.a) * skyColor;
                // clouds.rgb = mix(clouds.rgb, skyColor, (1.0 - clouds.a) * cloud.a);
                clouds.a = clamp(clouds.a + (1.0 - clouds.a) * cloud.a, 0.0, 1.0);
            }

            clouds.rgb = mix(clouds.rgb, sky_color, pow(1.0 - raydir.y, 4.0));

        } else {
            // Don't draw clouds if not in the sky
            clouds = vec4(0.0);
        }

        float cloud_fog = 1.0 + 1.0 / raydir.y;

        // shading
        // clouds.rgb -= clamp((clouds.a - 0.5) * 0.1, 0.0, 0.25);

        // blending
        color.rgb = mix(color.rgb, clouds.rgb, min(clouds.a, 1.0)); // / max(1.0, cloud_fog * CLOUD_FOG));

        // color.rgb += vec3(fractal_noise(uv) * fractal_noise(uv2));
    }

    depth = depth == 1.0 ? 1.0 : 0.0;

    /* DRAWBUFFERS:1 */
    gl_FragData[0] = vec4(color, depth); //gcolor
}
