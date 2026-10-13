shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;
void vertex() { VERTEX += NORMAL * 0.012; }
void fragment() { ALBEDO = vec3(0.10, 0.095, 0.08); }
