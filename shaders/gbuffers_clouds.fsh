#version 120
#include "/settings.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec3 color = texture2D(texture, texcoord).rgb;

    // Pink clouds
    // color.rgb = vec3(0.98, 0.78, 0.81);
    // Want to add shadows back to clouds?
    color = mix(color, vec3(0.98, 0.78, 0.81), 0.7);

    /* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}