shader_type spatial;
render_mode cull_disabled;
uniform vec4 rock_color : source_color = vec4(0.55,0.58,0.60,1.0);
uniform float strata_strength = 0.08;
varying vec3 p;
float noise3(vec3 q) {
 return sin(q.x*3.3+sin(q.z*2.7))*sin(q.y*4.1+cos(q.x*2.1));
}
void vertex() { p = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float grain = noise3(p*2.8)*0.055 + noise3(p*12.0)*0.028;
 float band = sin(p.y*9.0 + noise3(p*0.55)*1.5);
 float fissure = pow(max(0.0,band),18.0)*strata_strength;
 ALBEDO = rock_color.rgb * (0.92 + grain - fissure);
 ROUGHNESS = 0.9;
 SPECULAR = 0.18;
}
