shader_type spatial;
render_mode fog_disabled, cull_disabled;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float variation = 0.98 + sin(world_pos.x*0.14 + sin(world_pos.z*0.2))*0.02;
 ALBEDO = vec3(0.40,0.55,0.14)*variation;
 ALBEDO = mix(ALBEDO, vec3(0.31,0.86,0.67), smoothstep(24.0,80.0,distance(world_pos,INV_VIEW_MATRIX[3].xyz)));
 ROUGHNESS = 1.0;
}
