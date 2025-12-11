// composite fragment shader file for clouds

#version 120

#include "/settings.glsl"

// 2D clouds
#if CLOUD_STYLE == 1
    #include "/clouds1.glsl"
#endif

// 3D clouds
#if CLOUD_STYLE == 2
    #include "/clouds2.glsl"
#endif