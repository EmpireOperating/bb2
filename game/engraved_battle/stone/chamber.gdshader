shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// Local stone prints only. map_visibility/fog appends its knowledge test last.
uniform sampler2D paint : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float opacity = 1.0;
uniform float scale = 0.16;
uniform bool masonry = false;
varying vec3 p_world;
varying vec3 n_world;
void vertex() {
    p_world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
    n_world = normalize(mat3(MODEL_MATRIX) * NORMAL);
}
void fragment() {
    if (opacity < 1.0 && fract(sin(dot(floor(FRAGCOORD.xy),vec2(12.9898,78.233)))*43758.5453)>opacity) { discard; }
    vec3 p = p_world*scale;
    vec3 print_color = texture(paint,p.xz).rgb;
    if (masonry) {
        vec3 w = pow(abs(n_world),vec3(5.0));
        w /= max(w.x+w.y+w.z,0.001);
        print_color = w.y*print_color + w.x*texture(paint,p.zy).rgb + w.z*texture(paint,p.xy).rgb;
        // Dark damp at the plinth, pale rubbed arrises on the upper courses.
        print_color *= mix(vec3(.65,.74,.70),vec3(.95,.95,.87),smoothstep(.0,1.4,p_world.y));
    } else {
        print_color *= vec3(.65,.74,.80);
    }
    // Vertex colour is authored by the native tile (including retreat side).
    ALBEDO = clamp(print_color*COLOR.rgb,vec3(0.0),vec3(1.0));
    ROUGHNESS = .96;
    SPECULAR = .09;
}
