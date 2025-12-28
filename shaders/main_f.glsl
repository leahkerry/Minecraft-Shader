
#define COLORED_SHADOWS 1 //0: Stained glass will cast ordinary shadows. 1: Stained glass will cast colored shadows. 2: Stained glass will not cast any shadows. [0 1 2]
#define SHADOW_BRIGHTNESS 0.75 //Light levels are multiplied by this number when the surface is in shadows [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

uniform sampler2D lightmap;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform int entityId; 
uniform float aspectratio; 

uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform float far; // far render distance
uniform int heldItemId;
uniform float wetness;
uniform float sunAngle; 
uniform vec3 shadowLightPosition; // sun or moon
uniform int currentRenderedItemId;
uniform int worldTime;
uniform vec3 skyColor;
uniform sampler2D gaux1;
uniform sampler2D gaux2;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec4 shadowPos;
varying vec3 viewPos_v3;
varying vec3 normals_face;
varying vec4 tangent_face;
varying float material_id;

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
	vec4 specular_texture = texture2D(specular, texcoord);

	vec2 lm = lmcoord; // light map: for shadows, torches, time of day
    
    float ao_texture;

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
    // Lighting style 1: no shadows
    #if LIGHITNG_STYLE == 1 
        float light = dot(normalize(shadowPos), normalize(normals_face));
        color.rgb = color.rgb + light; 
    #endif 


    // PBR lighting effects
    #ifdef ENABLE_PBR
        vec3 bitangent = cross(tangent_face.xyz, normals_face.xyz) * tangent_face.w;
        mat3 tbn_matrix = mat3(tangent_face.xyz, bitangent.xyz, normals_face.xyz);
        vec4 normals_texture = texture2D(normals, texcoord);
        float texture_ao = normals_texture.b;
        normals_texture.xy = normals_texture.xy *2.-1.;
		
		normals_texture.z = sqrt(1.0-dot(normals_texture.xy, normals_texture.xy)); //Reconstruct Z
		
		normals_texture.xyz = normalize( tbn_matrix * normals_texture.xyz );

        float porosity = 0.;
        vec3 albedo = color.rgb; 
        float sss = 0.;
        float roughness = 0.;
        float f0 = 1.;
        float smoothness = 0.;
        bool metal = false;
        float emmisive = 0.;

        //ipbr
        if (abs(material_id-10003. ) < EPSILON) //porous
        {
            if (normals_face.y > 0.0) {
                porosity = 1.;
                // smoothness = 1.;
            } 
        } 
        if (abs(material_id-10002.) < EPSILON) //grass
        {
            sss = 0.;
        }
        if (abs(material_id-10006.) < EPSILON) //water
        {
            f0 = 0.5;
            smoothness = 1.;
        }
        if (abs(material_id-10007.) < EPSILON) //metal
        {
            f0 = 0.5;
            smoothness = 0.5;
        }

        // porisity effects
        // float actual_wetness = wetness * (lmcoord.y > .96?1.:0.);
        float actual_wetness = wetness * (1. - clamp(0.1 * lmcoord.y, 0., 1.));
        float wet_shine = clamp(1.5 * actual_wetness  * porosity, 0., 1.);
        f0 += (1.-f0) * wet_shine * 0.7;
        
        smoothness += (1. - smoothness) * wet_shine;


        color.rgb *= 1. - porosity * actual_wetness*0.7;
        
        vec3 ray_dir = normalize(viewPos_v3.xyz);

        float fresnel = pow(clamp(1. + dot(normals_texture.xyz, ray_dir), 0., 1.), 2.) * FRESNEL;
        float reflective_strength = f0 + (1. - f0) * fresnel * smoothness;
        vec3 sun_dir = normalize(shadowLightPosition);
        float lightDot = clamp(dot(sun_dir, normals_texture.xyz),0.,1.);
        if (abs(material_id - 10006.) < EPSILON) {
            color.rgb = color.rgb + color.rgb * clamp(lightDot*(1. - reflective_strength), 0., 1.);
        }
        // SPECULAR
        vec3 reflected_ray = reflect(ray_dir, normals_texture.xyz);
        float sun_reflection = 
        pow(clamp(dot(reflected_ray, sun_dir), 0., 1.), 1. + 11. * smoothness);

        // limit by face
        sun_reflection *= clamp(dot(normals_face.xyz, sun_dir) * 100., 0., 1.);

        // only do this for water
        if (abs(material_id - 10006.) < EPSILON) {
            color.rgb += reflective_strength * sun_reflection * (metal? albedo:vec3(1.));
            color.a = color.a >= 1./255. ? min(1., color.a + reflective_strength * sun_reflection) : color.a;
            color.rgb = clamp(color.rgb + albedo * emmisive, 0., 1.);
        }
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
		color.rgb = mix(color.rgb, fogColor, fogAmount);
        // Fog color replaced with sky color - buggy
        // color.rgb = mix(color.rgb, new_skyColor, fogAmount);
	#endif
	
	if (heldItemId == 1003 || (abs(material_id-10008. ) < EPSILON)) 
    {
        // color.rgb = calculate_bloom(color.rgb);
		// bloom torch perimeter
		float customAmount = clamp(
			(distance(vec3(0.0), viewPos_v3) - (BORDER_FOG_START * far))/(1 - BORDER_FOG_START * far), 
			0.0, 
			1.0
		);
		color.rgb = mix(color.rgb, (color.rgb + vec3(0.4, 0.3, 0.0)), 0.85 * customAmount);
	}
    // color.rgb = calculate_bloom(color.rgb);


    // #if IS_ENTITY == 1
    //     // color.rgb *= vec3(1., 0., 1.);
    //     if (entityId == 10020) {
    //         color.rgb = normals_face;
    //     }
    //     color.rgb = normals_face;
    // #endif


    

    /// ---- general directional lighting
    
    vec3 baseColor = color.rgb * 0.5;
    vec3 skylightDir = normalize(shadowLightPosition);
    float lightDot2 = dot(skylightDir, normals_face);
    float specular = pow(lightDot2, 16.0);

    vec3 metallic = baseColor * (
        lightDot2 + specular + 0.9
    );

    color.rgb = mix(color.rgb, metallic, 0.7);

    float lightMix = clamp(sin(sunAngle), 0.0, 1.0);
    color.rgb += texture2D(lightmap, lm).rgb * color.rgb * lm.x * mix(0.3, 0.8, lightMix);
    // ----

    /* DRAWBUFFERS:0 */
    /* RENDERTARGETS: 0,2,3 */
    #if HIGH_QUALITY_NORMALS == 1
		/*
			const int colortex2Format = RGBA16F;
		*/
	#endif
    gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(normals_texture.xyz*.5+.5, 1.); 
	gl_FragData[2] = vec4(smoothness,reflective_strength,(abs(material_id-10006.) < .5 || abs(material_id-10007.) < .5?1.:0.) ,f0); 

}
