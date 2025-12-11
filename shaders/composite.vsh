#version 120

attribute vec4 mc_Entity;

varying vec2 texcoord;
varying vec2 lmcoord;
varying float material_id;

void main() {
	gl_Position = ftransform();
    material_id = mc_Entity.x;
    
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}
