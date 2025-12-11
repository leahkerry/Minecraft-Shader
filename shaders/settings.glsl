#define EPSILON 0.5
#define BLUE_AMOUNT 0.0
#define RED_AMOUNT 0.0 //[0.0 0.25 0.75 0.90]
#define BLACK_SKY 0 //[0 1]
#define PURPLE_SKY 1 //[0 1]
#define SCARY_SUN 1 //[0 1]
#define PINK_CLOUDS 0 //[0 1]
//Increase this if you get shadow acne. Decrease this if you get peter panning.
#define SHADOW_BIAS 7.00 //[0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.60 0.70 0.80 0.90 1.00 1.50 2.00 2.50 3.00 3.50 4.00 4.50 5.00 6.00 7.00 8.00 9.00 10.00]

#define ENABLE_FOG
#define ENABLE_PBR
#define FOG_START 10.0 //[10.0 20.0 100.0]
#define FOG_END 100.0 //[20.0 50.0 100.0 200.0 1000.0]
#define FOG_MAX 0.5 //[0.0 0.25 0.5 0.75 1.0]
#define BORDER_FOG_START 0.075 //[0.075 0.08 0.09]

#define SATURATION 1.5 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define LIGHTING_STYLE 2 //[0 1 2]
#define SOBEL_EFFECT
#define DITTER_EFFECT
#define DITTER_PRECISION 16.0 //[4.0 16.0 64.0 128.0]
#define BACKGROUND_RESOLUTION_DIVIDER 1 //[1 2 4 10]

// reflections
#define FRESNEL 1.0 //[0.0 0.25 0.5 0.75 1.0]
#define REFLECTION_THRESHHOLD 0.25 //[0.0 0.25 0.5 0.75]
#define FRESNEL_EXPONENT 3.0 //[1.0 3.0 6.0]
#define SSR_STEPS 10 //[5 10 20 30]
#define SSR_REFINEMENT_STEPS 5 //[0 1 2 3 4 5 6 7 8 9 10]
#define REFLECTIONS 1 //[0 1]
#define BLOOM
#define BLOOM_STRENGTH 0.5 //[0.0 0.25 0.5 0.75 0.85 1.0]
#define HIGH_QUALITY_NORMALS 1 //[0 1]

// #if CLOUD_STYLE == 0
//     program.composite2.enabled = false
// #endif

#if BLOOM < 2 
    // program.composite2.enabled=false
    program.composite3.enabled=false
#endif

#if REFLECTIONS < 1 
	program.composite4.enabled=false
#endif

// clouds
#define CLOUD_STYLE 1 //[0 1 2]
#define CLOUD_FOG 0.5 // [0.0 0.25 0.5 0.75 1.0]
#define CLOUD_SPEED 0.5 // [0.0 0.25 0.5. 0.75 1.0 1.2 1.5 1.7 2.0]
#define CLOUD_COLOR_CHANGE 0 // [0, 1]

#define BACKGROUND_RESOLUTION_DIVIDER 1 // [0 1 2 4 10]
#define CLOUD_SAMPLES 20.0 // [10.0 20.0 30.0 100.0]