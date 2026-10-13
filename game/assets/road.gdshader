shader_type spatial;
render_mode fog_disabled;
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(41.7,113.9)))*43758.5);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float n=noise(UV*vec2(8.0,48.0));
 float streak = sin(UV.x * 50.0 + sin(UV.y * 14.0)*0.25) * 0.5 + 0.5;
 float ruts = 0.0;
 for (int i=0; i<3; i++) { float lane=float(i)/3.0+.167; ruts += exp(-pow((UV.x-lane)*65.0,2.0)); }
 vec3 base=mix(vec3(.52,.26,.065),vec3(.88,.53,.19),streak*.28+.40);
 ALBEDO=base*(.88+n*.14)*(1.0-ruts*.13);
 float view_distance=distance(world_pos,INV_VIEW_MATRIX[3].xyz);
 ALBEDO=mix(ALBEDO,vec3(.31,.86,.67),smoothstep(28.0,85.0,view_distance));
 ROUGHNESS=.9; SPECULAR=.10;
 NORMAL_MAP=normalize(vec3((n-.5)*.16,(streak-.5)*.10,1.0));
}
