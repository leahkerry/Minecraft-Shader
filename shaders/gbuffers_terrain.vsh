#version 120

attribute vec4 mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform int worldTime; 
uniform vec3 cameraPosition;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec4 shadowPos;
varying vec3 normals_face;

#include "/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    normals_face = gl_NormalMatrix * gl_Normal;

	float lightDot = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));
	#ifdef EXCLUDE_FOLIAGE
		//when EXCLUDE_FOLIAGE is enabled, act as if foliage is always facing towards the sun.
		//in other words, don't darken the back side of it unless something else is casting a shadow on it.
		if (mc_Entity.x == 10000.0) lightDot = 1.0;
	#endif

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	if (lightDot > 0.0) { //vertex is facing towards the sun
		vec4 playerPos = gbufferModelViewInverse * viewPos;
		shadowPos = shadowProjection * (shadowModelView * playerPos); //convert to shadow ndc space.
		float bias = computeBias(shadowPos.xyz);
		shadowPos.xyz = distort(shadowPos.xyz); //apply shadow distortion
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
		//apply shadow bias.
		#ifdef NORMAL_BIAS
			//we are allowed to project the normal because shadowProjection is purely a scalar matrix.
			//a faster way to apply the same operation would be to multiply by shadowProjection[0][0].
			vec4 normal = shadowProjection * vec4(mat3(shadowModelView) * (mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal)), 1.0);
			shadowPos.xyz += normal.xyz / normal.w * bias;
		#else
			shadowPos.z -= bias / abs(lightDot);
		#endif
	}
	else { //vertex is facing away from the sun
		lmcoord.y *= SHADOW_BRIGHTNESS; //guaranteed to be in shadows. reduce light level immediately.
		shadowPos = vec4(0.0); //mark that this vertex does not need to check the shadow map.
	}
	shadowPos.w = lightDot;
	gl_Position = gl_ProjectionMatrix * viewPos;
    if (mc_Entity.x == 10001) {
        float ypos = (gbufferModelViewInverse * viewPos).y;
        // gl_Position.xy = gl_Position.xy + (sin( worldTime * 0.1) * vec2(0.1 ));
        vec3 eyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;
        ypos = ypos + eyeCameraPosition.y;
        // gl_Position.y = gl_Position.y + eyeCameraPosition.y;
        gl_Position.x = gl_Position.x + sin(0.001 * worldTime * ypos) * 0.15;
        
    }
}