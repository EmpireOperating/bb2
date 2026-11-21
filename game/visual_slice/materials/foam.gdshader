shader_type spatial;
render_mode cull_disabled, unshaded;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; VERTEX.y+=sin(TIME*1.4+world_position.z*6.0+world_position.x*3.0)*.008; }
void fragment() {
    float drift=sin(world_position.z*13.0-world_position.x*2.0-TIME*1.6);
    if (drift < -.7) { discard; }
    ALBEDO=mix(vec3(.30,.40,.37),vec3(.59,.64,.55),drift*.5+.5);
}
