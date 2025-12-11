#version 120

#include "/settings.glsl"

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex2;//normals
uniform sampler2D colortex3;//pbr data
uniform sampler2D depthtex0;

// data from minecraft we need
uniform float near; 
uniform float far; 
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform int worldTime; 

/*
const bool colortex0MipmapEnabled = true;
*/

float linearize_depth(in float d) {
    return 2. * near * far / (far + near - (2. * d - 1.) * (far - near));
}

// Will need later
float get_depth_at(vec2 uv)
{
#if defined IS_IRIS && defined DISTANT_HORIZONS 
	//replace this with handling both depth textures
	return linearize_depth(texture2D(depthtex0,uv).r);
#else
	return linearize_depth(texture2D(depthtex0,uv).r);
#endif

}

vec3 projectAndDivide(mat4 projectionMatrix, in vec3 position)
{
	vec4 position2= projectionMatrix*vec4(position,1.);
	return position2.xyz/position2.w;
}

void main()
 {
    //load and unpack data
	vec3 color = texture2D(colortex0, texcoord).rgb;
	vec4 normals = texture2D(colortex2, texcoord) *2.-1.;
	normals.xyz = normalize(normals.xyz);
	vec4 pbr_data = texture2D(colortex3, texcoord);
	float smoothness = pbr_data.r;
	float reflective_strength = pbr_data.g;
	float is_water = pbr_data.b;
	float f0 = pbr_data.a;

    float far_adjusted = far;//this would be different for distant horizons
    // if (is_water > EPSILON)
    if (is_water > EPSILON || 
        (smoothness * reflective_strength >= REFLECTION_THRESHHOLD)) 
    {
        // get position of pixel relative to camera from position on screen
        vec3 pos = vec3(texcoord, texture2D(depthtex0, texcoord).r) * 2. - 1.;
        vec3 last_ray_pos = pos*.5+.5;
        pos=  projectAndDivide(gbufferProjectionInverse,pos) ;

        //get reflected ray angle, from camera off of surface, to see what is reflected
		vec3 ray_spd = normalize(reflect(normalize(pos), normals.xyz));

        //calculate fresnel, for how strong reflection will be
        float f = pow(1. - max(0., dot(normals.xyz, ray_spd)) , FRESNEL_EXPONENT);
        f = f0 + (1 - f0) * f;

        //keep ray position seperate from starting position
        pos.x = pos.x + 0.05 * pos.x  * sin(worldTime * 0.01 * pos.y + pos.z * 0.0001 * worldTime);
		vec3 raypos = pos;
        

        // flags for raytacing 
        bool hit = false;
        bool oob = false;
        
        float tracing_distance =
			ray_spd.z > 0.? 
				abs(pos.z) : 	//go towards camera all the way
				far_adjusted // go away from camera all the way
				; 
        // ray trace
        for (float i = 1.; i < SSR_STEPS && !hit && !oob; i++) 
        {
            // move along line of reflection (move further each time)
            raypos = (pos + ray_spd.xyz * tracing_distance * pow(i / SSR_STEPS, 2.));

            // get position on screen space from cam space
            vec4 raypos2=gbufferProjection*vec4(raypos.xyz,1.);
					raypos2.xy/=raypos2.w;
    				raypos2.xy=raypos2.xy*.5+.5;
					raypos=raypos2.xyz;
            
            // check if off screen
            oob = raypos.x < 0. || raypos.y < 0. || raypos.x > 1. || raypos.y > 1. || raypos.z < 0.;
            
            // add bias
            float bias = 0.1 + abs(pos.z) * pow(1. - i / SSR_STEPS, 2.);

            float d = get_depth_at(raypos.xy);

            hit = d + bias < raypos.z && !oob && d + bias + raypos.z * 0.1 + abs(last_ray_pos.z - raypos.z) > raypos.z;
            last_ray_pos = !hit ? raypos : last_ray_pos;
        }

        if (hit || (!oob && ray_spd.z < -0.01)) {
            float d; 
            pos = raypos; 
            float reverse = -1.0;
            float refined = 1.;
            float rrayspeed = 1.;
            for (int rr = 0; rr < SSR_REFINEMENT_STEPS; rr++) {
                rrayspeed *= 0.5;
                refined += rrayspeed * reverse;
                raypos = mix(last_ray_pos, pos, refined);

                d = get_depth_at(raypos.xy);
                hit = d < raypos.z;

                reverse = hit ? -1. : 1.;
            }

            // fade reflection into edges
            f *= clamp(
                    min (
                        (1. - abs(raypos.x - 0.5) * 2.) * 5. , 
                        (1. - abs(raypos.y - 0.5) * 2.) * 1.
                    ), 
                    0., 
                    1.
            );
            //determine lod, for rough reflectios
			float raylod = 8.*(1.-smoothness);
            
            //sample reflection from screen
			vec3 reflection = textureLod(colortex0, raypos.xy, raylod).rgb;	
            // reflection += sin(worldTime);
            //apply metal tint
			// if(f0> 230./255.) reflection*= color.rgb,vec3(2.);
			// if(f0> 230./255.) reflection *= color;

            // blend onto screen
            color.rgb = mix(color.rgb,reflection,f * 0.85);

        }
        

    }
/* DRAWBUFFERS:0 */
    
    // color.rgb = normals.rgb * 0.5 + 0.5;
	gl_FragData[0] = vec4(color.rgb, 1.0);

}