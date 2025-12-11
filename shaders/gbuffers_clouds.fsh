#version 120
#include "/settings.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec3 color = texture2D(texture, texcoord).rgb * glcolor.rgb;
    #if PINK_CLOUDS == 1
        vec3 pink = vec3(0.98, 0.78, 0.81);
        color = color * pink;
    #endif

    /* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}