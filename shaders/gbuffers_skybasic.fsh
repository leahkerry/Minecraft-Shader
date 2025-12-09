#version 120
#include "/settings.glsl"

uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

const float sunPathRotation = 30.0;

float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos, vec3 custom_skyColor) {
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
    vec3 skyColor = mix(custom_skyColor, fogColor, fogify(max(upDot, 0.0), 0.25)); 

	return skyColor;
}

void main() {
	vec3 color = skyColor;
	
    #if BLACK_SKY == 1
        color = vec3(0.0);
    #endif

    #if PURPLE_SKY == 1
        color = vec3(0.60, 0.45, 0.83);
    #endif

    if (starData.a > 0.5) {
		color = starData.rgb;
	} else {
		vec4 pos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
		pos = gbufferProjectionInverse * pos;
		color = calcSkyColor(normalize(pos.xyz), color);
	}

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}