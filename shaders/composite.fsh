#version 120

#define DRAW_SHADOW_MAP gcolor // Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]
#define SHADES 16.0 // level of definition

#include "/settings.glsl"

uniform float frameTimeCounter;
uniform float satBoost = SATURATION;
uniform sampler2D gcolor;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform int worldTime;
uniform int heldItemId;
uniform vec3 cameraPosition;
uniform float viewWidth;
uniform float  viewHeight;

varying vec2 texcoord;

vec4 colorA = vec4(0.1,0.0,0.1,0.2);

vec3 make_red(in vec3 color, in float amount)
{
    color = mix(color, vec3(1.0, 1.0, 1.0), amount);
    return color;
}

vec3 ditter_effect(in vec3 color, in vec2 texCoord)
{
    mat4 bayerMat4 = mat4(
        vec4(0.0, 8.0, 2.0, 10.0),
        vec4(12.0, 4.0, 14.0, 6.0),
        vec4(3.0, 11.0, 1.0, 9.0),
        vec4(15.0, 7.0, 13.0, 5.0));

    int x = int(texCoord.x) % 4;
    int y = int(texCoord.y) % 4;
    float ditter = bayerMat4[y][x] / 16.0;
    // addition = brighter (to white)
    // subtraction = darker (to black)
    // ditter = -0.5;

    // vec3 ditteredColor = step(0.5, color + bayerValue);
    return floor(color * SHADES + ditter) / SHADES;
}

vec3 mix_over_time(in vec3 color){
    float pct = abs(sin(worldTime * 0.05));
    vec4 newColor = mix(colorA, vec4(color, 1.0), pct);
    return newColor.rgb;
}

vec3 adjust_sat(vec3 color, float satBoost)
{
    float lum = dot(color, vec3(0.5, 0.0, 0.5));
    return mix(vec3(lum), color, satBoost);
}

vec3 torchHandLight(vec3 color){
    vec2 screenCenter = vec2(0.5, 0.5);
    float dist = distance(texcoord, screenCenter);
    
    // higher the dist multiplier = smaller the focused circle of light
    float falloff = max(0.0, 1.0 - (dist * 3.0)); 
    
    vec3 torchLight = vec3(1.0, 0.6, 0.2) * falloff * 0.3;
    color += torchLight;
    return color;
}

vec3 sobel_effect(vec3 color) {
    vec2 pixelSize = vec2(1.0 / viewWidth, 1.0 / viewHeight);

    // horizontal gaussian smoothing
    mat3 gx = mat3(
        vec3(-1.0, 0.0, 1.0), 
        vec3(-2.0, 0.0, 2.0), 
        vec3(-1.0, 0.0, 1.0)
    );

    // vertical gaussian smoothing
    mat3 gy = mat3(
        vec3(-1.0, -2.0, -1.0), 
        vec3(0.0, 0.0, 0.0), 
        vec3(1.0, 2.0, 1.0)
    );

    vec3 edgeX = vec3(0.0);
    vec3 edgeY = vec3(0.0);
    
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            vec3 sample = texture2D(DRAW_SHADOW_MAP, texcoord + vec2(i, j) * pixelSize).rgb;
            edgeX += sample * gx[i+1][j+1];
            edgeY += sample * gy[i+1][j+1];
        }
    }
    
    float edgeMagnitude = length(sqrt(edgeX * edgeX + edgeY * edgeY));
    float threshold = 0.8; // between 0 and 1
    
    if(edgeMagnitude > threshold) {
        color += vec3(0.1); // White for edges
    }

    return color;
}

void main()
{
    vec3 color = texture2D(DRAW_SHADOW_MAP, texcoord).rgb;
    // vec3 red = vec3(texcoord.x,0.0,texcoord.y);
    float amount = 0.5;
    // color = ditter_effect(color, texcoord);
    color = adjust_sat(color, satBoost);
    // color = mix_over_time(color);
    // color = make_red(color, amount);
    if (heldItemId == 1003) {
        color = torchHandLight(color);
    }

    #ifdef SOBEL_EFFECT
    color = sobel_effect(color);
    #endif
    // draw buffer 0 is main one at end
    /* DRAWBUFFERS:0 */

    gl_FragData[0] = vec4(color, 1.0); // gcolor
}
