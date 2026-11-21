shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform sampler2D paint : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; VERTEX.y+=sin(world_position.z*6.0+world_position.x*3.0-TIME*1.4)*.008; }
void fragment() {
    vec2 p=world_position.xz;
    float grain=texture(paint,vec2(p.x*.76,p.y*.30-TIME*.045)).g;
    float wave=sin(p.x*13.0+sin(p.y*1.7-TIME*.7)*1.1)+sin(p.y*16.0-p.x*1.5-TIME*2.0)*.28;
    float streak=smoothstep(.92,1.18,wave)*smoothstep(.35,.70,grain);
    ALBEDO=mix(vec3(.105,.19,.185),vec3(.23,.32,.30),grain);
    ALBEDO=mix(ALBEDO,vec3(.48,.55,.49),streak*.45);
    ROUGHNESS=.38;
    SPECULAR=.5;
}
