shader_type spatial;
varying vec3 local_point;
float grain(vec3 p) { return sin(p.y*11.0 + sin(p.x*7.0+p.z*5.0)*1.2); }
void vertex() { local_point=VERTEX; }
void fragment() {
 float g=grain(local_point)*.5+.5;
 float rings=sin(atan(local_point.z,local_point.x)*18.0+local_point.y*3.0)*.5+.5;
 ALBEDO=COLOR.rgb*(.70+g*.18+rings*.08);
 ROUGHNESS=.86;
 SPECULAR=.05;
 NORMAL_MAP=normalize(vec3(sin(local_point.y*10.0)*.08,cos(local_point.x*8.0)*.08,1.0));
}
