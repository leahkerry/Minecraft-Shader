
#include "/settings.glsl"
#include "/distort.glsl"

attribute vec4 mc_Entity;
attribute vec4 at_tangent;

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
in vec2 mc_midTexCoord; 

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec4 shadowPos;
varying vec2 vaUV2_v1;
varying vec3 vNormal;
varying vec3 vMoonPosition_v3;
varying vec3 viewPos_v3;
varying vec3 normals_face;
varying vec4 tangent_face;
varying float material_id;


void main()
{
    material_id = mc_Entity.x;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    normals_face = gl_NormalMatrix * gl_Normal;
    tangent_face = vec4(normalize(gl_NormalMatrix * at_tangent.xyz), at_tangent.w);

	float lightDot = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));
#ifdef EXCLUDE_FOLIAGE
	// when EXCLUDE_FOLIAGE is enabled, act as if foliage is always facing towards the sun.
	// in other words, don't darken the back side of it unless something else is casting a shadow on it.
	if (mc_Entity.x == 10000.0)
		lightDot = 1.0;
#endif

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	viewPos_v3 = viewPos.xyz;

	if (lightDot > 0.0)
	{ // vertex is facing towards the sun
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
	gl_Position = gl_ProjectionMatrix * viewPos;
    
    #if IS_TERRAIN 1
    if (mc_Entity.x == 10001) {
        float ypos = (gbufferModelViewInverse * viewPos).y;
        // gl_Position.xy = gl_Position.xy + (sin( worldTime * 0.1) * vec2(0.1 ));
        vec3 eyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;
        ypos = ypos + eyeCameraPosition.y;
        // gl_Position.y = gl_Position.y + eyeCameraPosition.y;
        gl_Position.x = gl_Position.x + sin(0.001 * worldTime * ypos) * 0.15;
        
    }
    #endif

    #if IS_ENTITY == 1
    if (entityId == 10010) {
        float xpos = (gbufferModelViewInverse * viewPos).x;
        // gl_Position.xy = gl_Position.xy + (sin( worldTime * 0.1) * vec2(0.1 ));
        vec3 eyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;
        xpos = xpos + eyeCameraPosition.x;
        // gl_Position.y = gl_Position.y + eyeCameraPosition.y;
        gl_Position.y = gl_Position.y + sin(0.001 * worldTime * xpos) * 0.15;
        
    }
    if (entityId == 10010) {
        float xpos = (gbufferModelViewInverse * viewPos).x;
        // gl_Position.xy = gl_Position.xy + (sin( worldTime * 0.1) * vec2(0.1 ));
        vec3 eyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz;
        xpos = xpos + eyeCameraPosition.x;
        // gl_Position.y = gl_Position.y + eyeCameraPosition.y;
        gl_Position.y = gl_Position.y + sin(0.001 * worldTime * xpos) * 0.15;
        
    }
    // exploding cows
    if (entityId == 10020) {
        // get position in world
        // move along normal
        // convert to cam sspace
        gl_Position.xyz = gl_Position.xyz + 0.2 * (sin(worldTime * 0.1) * 0.5 + 0.5) * 1. * normals_face;
        // gl_Position

    }
    #endif
}