#version 120
#include "/settings.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec4 color = texture2D(texture, texcoord) * glcolor;

    #if SCARY_SUN == 1 
        if (color.a > 0.5)
            color.rgb = vec3(1., 1., 0.);
    #endif

    #if FUN_SUN == 1
        
    #endif
/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}