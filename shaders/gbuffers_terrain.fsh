#version 120

#define COLORED_SHADOWS 1 //0: Stained glass will cast ordinary shadows. 1: Stained glass will cast colored shadows. 2: Stained glass will not cast any shadows. [0 1 2]
#define SHADOW_BRIGHTNESS 0.75 //Light levels are multiplied by this number when the surface is in shadows [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

uniform sampler2D lightmap;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D texture;

uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform float far; // far render distance
uniform int heldItemId;

uniform vec3 skyColor;

uniform float sunAngle; 
uniform vec3 shadowLightPosition; // sun or moon

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec4 shadowPos;
varying vec3 viewPos_v3;
varying vec3 normals_face;

//fix artifacts when colored shadows are enabled
const bool shadowcolor0Nearest = true;
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;

//only using this include for shadowMapResolution,
//since that has to be declared in the fragment stage in order to do anything.
#include "/distort.glsl"

vec3 adjust_sat2(vec3 color, float satBoost)
{
    float lum = dot(color + vec3(1.0, 1.0, 0.0), vec3(1.0, 0.0, 1.0));
    return mix(color, vec3(lum), satBoost);
}

void main() {
    vec3 new_skyColor = skyColor;
    #if PURPLE_SKY == 1
        new_skyColor = vec3(0.60, 0.45, 0.83);
    #endif

	vec4 color = texture2D(texture, texcoord) * glcolor;
	// vec4 color = glcolor;
	vec2 lm = lmcoord; // light map: for shadows, torches, time of day
    // lm.x = torch
    //lm.y = sky light

    // applies darkness, night, shadow
    #if LIGHTING_STYLE == 0
        if (shadowPos.w > 0.0) {
            //surface is facing towards shadowLightPosition
            #if COLORED_SHADOWS == 0
                //for normal shadows, only consider the closest thing to the sun,
                //regardless of whether or not it's opaque.
                if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
            #else
                //for invisible and colored shadows, first check the closest OPAQUE thing to the sun.
                if (texture2D(shadowtex1, shadowPos.xy).r < shadowPos.z) {
            #endif
                //surface is in shadows. reduce light level.
                lm.y *= SHADOW_BRIGHTNESS;
            }
            else {
                //surface is in direct sunlight. increase light level.
                lm.y = mix(31.0 / 32.0 * SHADOW_BRIGHTNESS, 31.0 / 32.0, sqrt(shadowPos.w));
                #if COLORED_SHADOWS == 1
                    //when colored shadows are enabled and there's nothing OPAQUE between us and the sun,
                    //perform a 2nd check to see if there's anything translucent between us and the sun.
                    if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
                        //surface has translucent object between it and the sun. modify its color.
                        //if the block light is high, modify the color less.
                        vec4 shadowLightColor = texture2D(shadowcolor0, shadowPos.xy);
                        //make colors more intense when the shadow light color is more opaque.
                        shadowLightColor.rgb = mix(vec3(1.0), shadowLightColor.rgb, shadowLightColor.a);
                        //also make colors less intense when the block light level is high.
                        shadowLightColor.rgb = mix(shadowLightColor.rgb, vec3(1.0), lm.x);
                        //apply the color.
                        color.rgb *= shadowLightColor.rgb;
                    }
                #endif
            }
        }
    

	    color *= texture2D(lightmap, lm);
    #endif 
    #if LIGHITNG_STYLE == 1 
        float light = dot(normalize(shadowPos), normalize(normals_face));
        color.rgb = color.rgb + light; 
        // vec3 torch_color = vec3(1., 1., 0.);
        // // color *= texture2D(lightmap, lm); // black, white, colored
        // vec3 torch_color = vec3(1., 1., 0.);
        // vec3 sky_color = vec3(0., 0., 1.);
        // if (sunAngle >= 0.5) {
        //     sky_color = 0.0;
        // }
        // color.rgb = color.rgb * (torch_color * lm.x + sky_color * lm.y)  ;  // x is torch value of lightmap
    #endif 
	// Fog Color
	#ifdef ENABLE_FOG
		float borderFogAmount = clamp((distance(vec3(0.0), viewPos_v3) - (BORDER_FOG_START * far))/((1 - BORDER_FOG_START) * far), 0.0, 1.0);	
		float fogAmount = 
		max(
			clamp((distance(vec3(0.0), viewPos_v3) - FOG_START)/(FOG_END - FOG_START), 0.0, FOG_MAX),
			borderFogAmount
		);
		// float fogAmount = clamp((distance(vec3(0.0), viewPos_v3) - FOG_START)/(FOG_END - FOG_START), 0.0, FOG_MAX);
        
        // Default fog color (from minecraft)
        color.rgb = mix(color.rgb, fogColor, fogAmount);
        
        // Fog color replaced with sky color - buggy
        // color.rgb = mix(color.rgb, new_skyColor, fogAmount);
	#endif
	
	if (heldItemId == 1003) {
		// bloom torch perimeter
		float customFog = clamp(
			(distance(vec3(0.0), viewPos_v3) - (BORDER_FOG_START * far))/(1 - BORDER_FOG_START * far), 
			0.0, 
			1.0
		);
		color.rgb = mix(color.rgb, (color.rgb + vec3(0.4, 0.3, 0.0)), customFog);
	}

	// change whole terrain of textures
	// if (heldItemId == 1002) {
	// 	color.rgb = vec3(1.0, 1.0, 1.0);
	// }

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}
