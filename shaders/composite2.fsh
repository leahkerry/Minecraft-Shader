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

#if MC_VERSION >= 11900
	uniform float darknessFactor;
#endif

varying vec2 texcoord;

// Complementary shader functions
float Bayer2  (vec2 c) { c = 0.5 * floor(c); return fract(1.5 * fract(c.y) + c.x); }
float Bayer4  (vec2 c) { return 0.25 * Bayer2  (0.5 * c) + Bayer2(c); }
float Bayer8  (vec2 c) { return 0.25 * Bayer4  (0.5 * c) + Bayer2(c); }
float Bayer16 (vec2 c) { return 0.25 * Bayer8  (0.5 * c) + Bayer2(c); }
float Bayer32 (vec2 c) { return 0.25 * Bayer16 (0.5 * c) + Bayer2(c); }
float Bayer64 (vec2 c) { return 0.25 * Bayer32 (0.5 * c) + Bayer2(c); }

vec3 GetBloomTile(float lod, vec2 coord, vec2 offset, vec2 ditherAdd) {
	float scale = exp2(lod);
	vec2 bloomCoord = coord / scale + offset;
	bloomCoord += ditherAdd;
	bloomCoord = clamp(bloomCoord, offset, 1.0 / scale + offset);

	vec3 bloom = texture2D(colortex0, bloomCoord).rgb;
	bloom *= bloom;
	bloom *= bloom;
	return bloom * 128.0;
}

void Bloom(inout vec3 color, vec2 coord, float dither) {
	#ifndef ANAMORPHIC_BLOOM
		// #if AA > 1
		// 	dither = fract(16.0 * frameTimeCounter + dither);
		// #endif

		vec2 rescale = 1.0 / vec2(1920.0, 1080.0);
		vec2 ditherAdd = vec2(0.0);
		float ditherM = dither - 0.5;
		if (rescale.x > pw) ditherAdd.x += ditherM * pw;
		if (rescale.y > ph) ditherAdd.y += ditherM * ph;

		vec3 blur1 = GetBloomTile(2.0, coord, vec2(0.0      , 0.0   ), ditherAdd);
		vec3 blur2 = GetBloomTile(3.0, coord, vec2(0.0      , 0.26  ), ditherAdd);
		vec3 blur3 = GetBloomTile(4.0, coord, vec2(0.135    , 0.26  ), ditherAdd);
		vec3 blur4 = GetBloomTile(5.0, coord, vec2(0.2075   , 0.26  ), ditherAdd);
		vec3 blur5 = GetBloomTile(6.0, coord, vec2(0.135    , 0.3325), ditherAdd);
		vec3 blur6 = GetBloomTile(7.0, coord, vec2(0.160625 , 0.3325), ditherAdd);
		vec3 blur7 = GetBloomTile(8.0, coord, vec2(0.1784375, 0.3325), ditherAdd);

		vec3 blur = (blur1 + blur2 + blur3 + blur4 + blur5 + blur6 + blur7) * 0.14;
	#else
		vec3 blur = texture2D(colortex0, coord / 4.0).rgb;
		blur = clamp(blur, vec3(0.0), vec3(1.0));
		blur *= blur;
		blur *= blur * 128.0;
	#endif
	

    float bloomStrength = BLOOM_STRENGTH;

	bloomStrength *= 0.18;
	

	// #if MC_VERSION >= 11900
	// 	bloomStrength = mix(bloomStrength, 0.26, darknessFactor);
	// #endif

	color = mix(color, blur, 0.1 * (bloomStrength));
}

void main() {
	// vec4 color = texture2D(colortex1, texcoord);
	vec3 color = texture2D(colortex0, texcoord).rgb;

    #ifdef BLOOM
		float dither = Bayer64(gl_FragCoord.xy);
		Bloom(color, texcoord, dither);
	#endif
	// color.rgb = texture2D(depthtex0, texcoord).r < 1.0 ? ground_color.rgb : color.rgb; // Corrected logic

	
	

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color.rgb, 1.0); //gcolor
}