shader_type spatial;
render_mode blend_mix, cull_disabled, fog_disabled;
uniform float water_time = 0.0;
varying vec3 world_pos;
void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float phase=VERTEX.y*2.2+VERTEX.x*3.0+water_time*3.2;
 VERTEX.x += sin(phase)*.055 + sin(phase*2.1)*.018;
 VERTEX.z += cos(phase*1.4)*.035;
}
void fragment(){
 float sheet=sin(UV.y*32.0+UV.x*7.0+water_time*4.0)*.5+.5;
 float breakup=smoothstep(.05,.30,UV.x)*smoothstep(.95,.70,UV.x);
 float edge=1.0-smoothstep(.0,.08,abs(UV.x-.5));
 float alpha=(.58+sheet*.30)*breakup;
 vec3 deep=vec3(.02,.53,.80); vec3 light=vec3(.55,.95,1.0);
 ALBEDO=mix(deep,light,sheet*.72+edge*.15);
 EMISSION=ALBEDO*.10;
 ROUGHNESS=.12; SPECULAR=.72; ALPHA=alpha;
}
