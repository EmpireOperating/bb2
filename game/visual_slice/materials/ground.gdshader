shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform sampler2D earth : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D meadow : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paving : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_position;
float noise2(vec2 p) { return (sin(p.x*.69+sin(p.y*.81))*sin(p.y*.43+p.x*.29))*.5+.5; }
vec3 painted(sampler2D tex, vec2 uv) {
    vec2 mirrored = abs(fract(uv*.5)*2.0-1.0);
    vec3 a = texture(tex, mirrored).rgb;
    vec3 b = texture(tex, abs(fract((uv+vec2(.37,.61))*.37)*2.0-1.0)).rgb;
    return mix(a,b,.22);
}
void vertex() { world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 p = world_position.xz;
    float n = noise2(p);
    float meadow_mix = smoothstep(.15,.82,n+sin(p.x*.21-p.y*.31)*.16);
    vec3 base = mix(painted(earth,p*.30),painted(meadow,p*.29),meadow_mix*.79);
    float road = (1.0-smoothstep(.40,1.03,abs(p.y-6.0)+(n-.5)*.40))*smoothstep(2.4,4.1,p.x)*(1.0-smoothstep(17.7,19.1,p.x));
    base = mix(base,painted(paving,p*.42),road*.91);
    float gray = dot(base,vec3(.299,.587,.114));
    ALBEDO = mix(base,vec3(gray),.38)*vec3(.72,.78,.76);
    ROUGHNESS = .97;
    SPECULAR = .08;
}
