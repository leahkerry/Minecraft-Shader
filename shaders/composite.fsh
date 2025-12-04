#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]
#include "/settings.glsl"

uniform float frameTimeCounter;
uniform sampler2D gcolor;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;

uniform sampler2D shadowtex1;

varying vec2 texcoord;

vec3 make_red(in vec3 color, in float amount) {
    color = mix(color, vec3(1.0,0.0,0.0), amount);
    return color; 
}

void main() {
	vec3 color = texture2D(DRAW_SHADOW_MAP, texcoord).rgb;
    // vec3 red = vec3(texcoord.x,0.0,texcoord.y);
    float amount = 0.5;
    // color = make_red(color, amount);
    // draw buffer 0 is main one at end
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color, 1.0); //gcolor
}