#version 120

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform vec3 moonPosition;
uniform vec2 vaUV2;
uniform vec3 vaNormal;
uniform vec3 cameraPosition; 
uniform int worldTime;
uniform int entityId; 

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec4 shadowPos;
varying vec2 vaUV2_v1;
varying vec3 vNormal;
varying vec3 vMoonPosition_v3;
varying vec3 viewPos_v3;

#include "/distort.glsl"

void main()
{
	// Testing!!
	vaUV2_v1 = vaUV2;								  // light (x = block, y = skylight)
	vNormal = normalize(gl_NormalMatrix * gl_Normal); // face normal
	vMoonPosition_v3 = normalize(gl_ModelViewMatrix * vec4(moonPosition, 0.0)).xyz;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	viewPos_v3 = viewPos.xyz;

	float lightDot = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));
	if (lightDot > 0.0)
	{ // vertex is facing towards the sun.
		vec4 playerPos = gbufferModelViewInverse * viewPos;
		shadowPos = shadowProjection * (shadowModelView * playerPos); // convert to shadow ndc space.
		float bias = computeBias(shadowPos.xyz);
		shadowPos.xyz = distort(shadowPos.xyz);	   // apply shadow distortion
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; // convert from -1 ~ +1 to 0 ~ 1
// apply shadow bias.
#ifdef NORMAL_BIAS
												   // we are allowed to project the normal because shadowProjection is purely a scalar matrix.
		// a faster way to apply the same operation would be to multiply by shadowProjection[0][0].
		vec4 normal = shadowProjection * vec4(mat3(shadowModelView) * (mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal)), 1.0);
		shadowPos.xyz += normal.xyz / normal.w * bias;
#else
		shadowPos.z -= bias / abs(lightDot);
#endif
	}
	else
	{									// vertex is facing away from the sun
		lmcoord.y *= SHADOW_BRIGHTNESS; // guaranteed to be in shadows. reduce light level immediately.
		shadowPos = vec4(0.0);			// mark that this vertex does not need to check the shadow map.
	}
	shadowPos.w = lightDot;
	// use consistent transforms for entities and hand so that armor glint doesn't have z-fighting issues.
	gl_Position = gl_ProjectionMatrix * viewPos;

    if (entityId == 10010) {
        float xpos = (gbufferModelViewInverse * viewPos).x;
        // gl_Position.xy = gl_Position.xy + (sin( worldTime * 0.1) * vec2(0.1 ));
        vec3 eyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;
        xpos = xpos + eyeCameraPosition.x;
        // gl_Position.y = gl_Position.y + eyeCameraPosition.y;
        gl_Position.y = gl_Position.y + sin(0.001 * worldTime * xpos) * 0.15;
        
    }
}