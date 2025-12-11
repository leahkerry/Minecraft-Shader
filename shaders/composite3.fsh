#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]
#include "/settings.glsl"

uniform float frameTimeCounter;
uniform sampler2D gcolor;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

varying vec2 texcoord;

void main() {
    vec4 color = texture2D(colortex1, texcoord);
    vec3 ground_color = texture2D(colortex0, texcoord).rgb;

    if (texture2D(depthtex0, texcoord).r < 1.0) {
        color.rgb = ground_color;
    }

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(color); //gcolor
}
