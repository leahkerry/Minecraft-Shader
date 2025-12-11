#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]

#include "/settings.glsl"
// #include "/lib/color_adjustments.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D gaux2; 

uniform float aspectRatio; 
uniform float viewWidth;                     
uniform float viewHeight;                     

varying vec2 texcoord;
vec2 resolution = vec2(800, 600);
// float resolution = width / height;

// const float weight[5] = float[5](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
// const float weight[5] = float[5](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
const float weight[10] = float[10](0.227027, 0.227027,0.1945946, 0.1945946,0.1216216, 0.1216216,0.054054,0.054054, 0.016216, 0.016216);
// const float weight[5] = float[5](0.2, 0.2, 0.2, 0.2, 0.2);
// const float weight[7] = float[7](1.0, 6.0, 15.0, 20.0, 15.0, 6.0, 1.0);


void main() {
	vec4 color = texture2D(colortex0, texcoord);
	// // vec3 ground_color = texture2D(colortex0, texcoord).rgb;
	// vec4 color = vec4(0.0);
	// color.rgb = texture2D(depthtex0, texcoord).r < 1.0 ? color.rgb : ground_color.rgb; // Corrected logic
    //     // vec3 color = vec3(0.0);
    // float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    // if (brightness > 0.8) {
        // Calculate the pixel size based on resolution
        vec2 texOffset = 1.0 / resolution;

        // // Apply Gaussian blur in both horizontal and vertical directions
        vec3 bloom = vec3(0.0);
        int blooms = 0;
        for (int x = -2; x <= 7; x++) {
            for (int y = -2; y <= 7; y++) {
                vec2 offset = vec2(float(x) * 1., 1. * float(y)) * texOffset;
                vec3 offsetcolor = texture2D(colortex0, clamp(texcoord + offset, 0., 1.)).xyz;
                float brightness = dot(offsetcolor, vec3(0.2126, 0.7152, 0.0722));
                if (brightness > 0.85) {
                    bloom +=  offsetcolor * weight[x + 2] * weight[y + 2];
                    // bloom += offsetcolor;
                    blooms += 1;
                }
                // bloom += vec3(1.) * weight[x + 2] * weight[y + 2];
                // bloom += vec3(1.);
            }
        }
        // if (blooms > 0) {
        //     bloom /= float(blooms);
        // }
        
        //////// simple
        // calculate float intensity and cover (0-1)
        float bloomIntensity = 0.5;
        float bloomCover = 0.5;
        vec2 aspectcorrect = vec2(1., aspectRatio);

        // add for 4-9
        vec3 bloomColor = vec3(0.);
        bloomColor = bloom;
        // bloomColor += 10. * max(vec3(0.0), texture2D(colortex0, texcoord, 4.0).rgb - bloomCover);
        // bloomColor += max(vec3(0.0), texture2D(colortex0, texcoord.st, 4.0).rgb - bloomCover);

        // divide by 6
        // bloomColor /= 10.;

        // desaturate
        // float luma = dot(bloomColor, vec3(1.));
        
        // vec3 chroma = bloomColor - luma; 
        // bloomColor = (chroma * (1.0 - bloomCover)) + luma;

        // prevent overexopsure 
        // color.rgb *= 1.0 - length(bloomColor) + bloomIntensity;
        color.rgb += bloomColor * bloomIntensity;
        color.rgb = clamp(color.rgb, 0., 1.);
    // }
    // return color;
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color.rgb, 1.0); //gcolor
}