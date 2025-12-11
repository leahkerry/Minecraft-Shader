#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]

#include "/settings.glsl"
// #include "/lib/color_adjustments.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform float viewWidth, viewHeight, aspectRatio;
float pw = 1.0 / viewWidth;
float ph = 1.0 / viewHeight;
// float weight[7] = float[7](1.0, 6.0, 15.0, 20.0, 15.0, 6.0, 1.0);
float weight[5] = float[5](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

#if MC_VERSION >= 11900
	uniform float darknessFactor;
#endif

const bool colortex0MipmapEnabled = true;


varying vec2 texcoord;

// Complementary shader functions
float Bayer2  (vec2 c) { c = 0.5 * floor(c); return fract(1.5 * fract(c.y) + c.x); }
float Bayer4  (vec2 c) { return 0.25 * Bayer2  (0.5 * c) + Bayer2(c); }
float Bayer8  (vec2 c) { return 0.25 * Bayer4  (0.5 * c) + Bayer2(c); }
float Bayer16 (vec2 c) { return 0.25 * Bayer8  (0.5 * c) + Bayer2(c); }
float Bayer32 (vec2 c) { return 0.25 * Bayer16 (0.5 * c) + Bayer2(c); }
float Bayer64 (vec2 c) { return 0.25 * Bayer32 (0.5 * c) + Bayer2(c); }

vec3 BrightPass(vec3 color, float threshold) {
    return max(color - vec3(threshold), vec3(0.0));
}

vec3 GetBloomTile(float lod, vec2 coord, vec2 offset, vec2 ditherAdd) {
	float scale = exp2(lod);
	vec2 bloomCoord = coord / scale + offset;
    // vec2 bloomCoord = coord + offset;
	// bloomCoord += ditherAdd;
	// bloomCoord = clamp(bloomCoord, offset, 1.0 / scale + offset);

	vec3 bloom = texture2D(colortex0, bloomCoord).rgb;
	bloom *= bloom;
	bloom *= bloom;
	return bloom * 16.0;
}
//     // Calculate the scale based on the level of detail
//     float scale = exp2(lod);

//     // Normalize the offset to the texture resolution
//     vec2 normalizedOffset = offset / vec2(viewWidth, viewHeight);

//     // Calculate the bloom coordinates
//     vec2 bloomCoord = (coord + normalizedOffset) / scale + ditherAdd;

//     // Clamp the coordinates to ensure they stay within bounds
//     bloomCoord = clamp(bloomCoord, vec2(0.0), vec2(1.0));

//     // Sample the texture
//     vec3 bloom = texture2D(colortex0, bloomCoord).rgb;

//     // Apply a bright pass to isolate highlights
//     // bloom = BrightPass(bloom, 0.8); // Adjust threshold as needed

//     // Apply a smoother scaling
//     // bloom = pow(bloom, vec3(3.)); // Gamma correction
//     // return bloom * 16.0; // Adjust intensity
//     bloom *= bloom;
// 	bloom *= bloom;
// 	return bloom * 16.0;
//     // return bloom;
// }

//Common Functions//
vec3 GetBloomTile2(float lod, vec2 offset, vec2 rescale) {
	vec3 bloom = vec3(0.0);
	float scale = exp2(lod);
	vec2 coord = (texcoord - offset) * scale;
	float padding = 0.5 + 0.005 * scale;

	if (abs(coord.x - 0.5) < padding && abs(coord.y - 0.5) < padding) {
		for(int i = -3; i <= 3; i++) {
			for(int j = -3; j <= 3; j++) {
				float wg = weight[i + 3] * weight[j + 3];
				vec2 pixelOffset = vec2(i, j) * rescale;
				vec2 bloomCoord = (texcoord - offset + pixelOffset) * scale;
				bloom += texture2D(colortex0, bloomCoord).rgb * wg;
			}
		}
		bloom /= 4096.0;
	}

	return pow(bloom / 128.0, vec3(0.25));
}

///////////////////////
void Bloom2(inout vec3 color, vec2 coord) {
    // #ifndef ANAMORPHIC_BLOOM
		vec2 rescale = 1.0 / vec2(1920.0, 1080.0);

        vec3 blur = GetBloomTile2(2.0, vec2(0.0      , 0.0   ), rescale);
            blur += GetBloomTile2(3.0, vec2(0.0      , 0.26  ), rescale);
            blur += GetBloomTile2(4.0, vec2(0.0135    , 0.26  ), rescale);
            blur += GetBloomTile2(5.0, vec2(0.02075   , 0.26  ), rescale) * 0.8;
            blur += GetBloomTile2(6.0, vec2(0.0135    , 0.3325), rescale) * 0.8;
            blur += GetBloomTile2(7.0, vec2(0.160625 , 0.3325), rescale) * 0.6;
            blur += GetBloomTile2(8.0, vec2(0.1784375, 0.3325), rescale) * 0.4;
        // blur *= 0.14;
	// #else
	// 	vec3 bloom = vec3(0.0);
	// 	float scale = 4.0;
	// 	vec2 coord = texcoord * scale;
	// 	float padding = 0.52;

	// 	if (abs(coord.x - 0.5) < padding && abs(coord.y - 0.5) < padding) {
	// 		for(int i = -27; i <= 27; i++) {
	// 			for(int j = -3; j <= 3; j++) {
	// 				float wg = pow(0.9, abs(2.0 * i) + 1.0);
	// 				float hg = weight[j + 3];
	// 				hg *= hg / 400.0;
	// 				vec2 pixelOffset = vec2(i * pw, j * ph);
	// 				vec2 bloomCoord = (texcoord + pixelOffset) * scale;
	// 				bloom += texture2D(colortex0, bloomCoord).rgb * wg * hg;
	// 			}
	// 		}
	// 		bloom /= 128.0;
	// 	}

	// 	vec3 blur = pow(bloom / 128.0, vec3(0.25));
	// 	blur = clamp(blur, vec3(0.0), vec3(1.0));
	// #endif
    float bloomStrength = BLOOM_STRENGTH;

	// bloomStrength *= 0.18;
	

	// #if MC_VERSION >= 11900
	// 	bloomStrength = mix(bloomStrength, 0.26, darknessFactor);
	// #endif

	color = mix(color, blur, bloomStrength);
    // color = color * vec3(1., 0., 0.);
    // color.rgb = vec3(blur);
}
///////////////////////


void Bloom(inout vec3 color, vec2 coord, float dither) {
	// #ifndef ANAMORPHIC_BLOOM
		// #if AA > 1
		// 	dither = fract(16.0 * frameTimeCounter + dither);
		// #endif

		vec2 rescale = 1.0 / vec2(1920.0, 1080.0);
		vec2 ditherAdd = vec2(0.0);
		float ditherM = dither - 0.5;
		if (rescale.x > pw) ditherAdd.x += ditherM * pw;
		if (rescale.y > ph) ditherAdd.y += ditherM * ph;
        
		vec3 blur1 = GetBloomTile(0.2, coord, vec2(0.0      , 0.0   ), ditherAdd);
		vec3 blur2 = GetBloomTile(0.3, coord, vec2(0.0      , 0.026  ), ditherAdd);
		vec3 blur3 = GetBloomTile(0.4, coord, vec2(0.0135    , 0.026  ), ditherAdd);
		vec3 blur4 = GetBloomTile(0.5, coord, vec2(0.02075   , 0.026  ), ditherAdd);
		vec3 blur5 = GetBloomTile(0.6, coord, vec2(0.0135    , 0.03325), ditherAdd);
		vec3 blur6 = GetBloomTile(0.7, coord, vec2(0.0160625 , 0.03325), ditherAdd);
		vec3 blur7 = GetBloomTile(0.8, coord, vec2(0.01784375, 0.03325), ditherAdd);
		// vec3 blur1 = GetBloomTile(2.0, coord, vec2(0.0      , 0.0   ), ditherAdd);
		// vec3 blur2 = GetBloomTile(3.0, coord, vec2(0.0      , 0.26  ), ditherAdd);
		// vec3 blur3 = GetBloomTile(4.0, coord, vec2(0.135    , 0.26  ), ditherAdd);
		// vec3 blur4 = GetBloomTile(5.0, coord, vec2(0.2075   , 0.26  ), ditherAdd);
		// vec3 blur5 = GetBloomTile(6.0, coord, vec2(0.135    , 0.3325), ditherAdd);
		// vec3 blur6 = GetBloomTile(7.0, coord, vec2(0.160625 , 0.3325), ditherAdd);
		// vec3 blur7 = GetBloomTile(8.0, coord, vec2(0.1784375, 0.3325), ditherAdd);

		vec3 blur = (blur1 + blur2 + blur3 + blur4 + blur5 + blur6 + blur7) * 0.14;
	// #else
	// 	vec3 blur = texture2D(colortex0, coord).rgb;
	// 	blur = clamp(blur, vec3(0.0), vec3(1.0));
	// 	blur *= blur;
	// 	blur *= blur * 128.0;
	// #endif
	

    float bloomStrength = BLOOM_STRENGTH;

	bloomStrength *= 0.18;
	

	#if MC_VERSION >= 11900
		bloomStrength = mix(bloomStrength, 0.26, darknessFactor);
	#endif

	color = mix(color, blur, bloomStrength);
}

void main() {
	// vec4 color = texture2D(colortex1, texcoord);
	vec3 color = texture2D(colortex0, texcoord).rgb;

    // #ifdef BLOOM
		// float dither = Bayer64(gl_FragCoord.xy);
		// Bloom(color, texcoord, dither);
		// Bloom2(color, texcoord);
    
	// #endif
	// color.rgb = texture2D(depthtex0, texcoord).r < 1.0 ? ground_color.rgb : color.rgb; // Corrected logic

	
	

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color.rgb, 1.0); //gcolor
}