shader_type spatial;
render_mode cull_disabled, fog_disabled;
uniform vec3 deep_color : source_color = vec3(0.015, 0.48, 0.78);
uniform vec3 shallow_color : source_color = vec3(0.025, 0.83, 0.96);
uniform float bank_foam = 1.0;
uniform float water_time = 0.0;
varying vec3 world_pos;
void vertex() {
 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 float a = world_pos.x * 1.3 + world_pos.z * 0.6 + water_time * 1.6;
 float b = world_pos.z * 2.1 - water_time * 2.0;
 VERTEX.y += sin(a) * 0.055 + sin(b) * 0.025;
 NORMAL = normalize(vec3(-cos(a)*0.0715, 1.0, -cos(a)*0.033-cos(b)*0.0525));
}
void fragment() {
 vec2 p = world_pos.xz;
 float wave = sin(p.x * 2.4 + p.y * 1.6 + water_time * 1.4) * sin(p.y * 3.1 - water_time * 1.9 + sin(p.x * 1.4));
 float glint = pow(max(0.0, wave), 12.0);
 float edge = min(min(UV.x, 1.0-UV.x), min(UV.y, 1.0-UV.y));
 float foam = (1.0-smoothstep(0.0, 0.045 + wave * 0.008, edge)) * bank_foam;
 float shallows = 1.0-smoothstep(0.0,0.20,edge);
 ALBEDO = mix(deep_color, shallow_color, 0.34 + shallows*0.48 + wave * 0.12);
 ALBEDO = mix(ALBEDO, vec3(0.78, 0.98, 1.0), max(foam * 0.85, glint * 0.65));
 float view_distance = distance(world_pos, INV_VIEW_MATRIX[3].xyz);
 ALBEDO = mix(ALBEDO, vec3(0.31,0.86,0.67), smoothstep(30.0,85.0,view_distance));
 ROUGHNESS = 0.22;
 SPECULAR = 0.65;
}
