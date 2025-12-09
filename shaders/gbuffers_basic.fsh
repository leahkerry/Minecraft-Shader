#version 120

uniform sampler2D lightmap;

varying vec2 lmcoord;
varying vec4 glcolor;
// uniform int heldItemId;

void main() {
	vec4 color = glcolor;
	color *= texture2D(lightmap, lmcoord);

	// if (heldItemId == 1002) {
	// 	color.rgb = vec3(1.0, 1.0, 1.0);
	// }

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}