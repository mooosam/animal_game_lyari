shader_type spatial;
render_mode cull_disabled;
varying vec3 world_point;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void vertex() { world_point = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_point.xz*0.34;
 float macro=noise(p*.32); float detail=noise(p*2.6); float pores=noise(p*9.0);
 float shade=.76+macro*.20+detail*.12+pores*.035;
 ALBEDO=COLOR.rgb*shade;
 ROUGHNESS=.82+pores*.12;
 SPECULAR=0.08;
 float nx=noise(p*3.2+vec2(.03,0.0))-noise(p*3.2-vec2(.03,0.0));
 float ny=noise(p*3.2+vec2(0.0,.03))-noise(p*3.2-vec2(0.0,.03));
 NORMAL_MAP=normalize(vec3(nx*.8,ny*.8,1.0));
}
