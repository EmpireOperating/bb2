shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// COLOR channels are descriptor-bound road / forest / wet / rubble masks.
// No position-specific road stripe or river, no tonemapper/exposure changes.
uniform sampler2D earth : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D meadow : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paving : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool woodland = false;
varying vec3 terrain_position;
void vertex() { terrain_position = VERTEX; }
void fragment() {
    vec2 p = terrain_position.xz;
    float field = smoothstep(-.55,.60,sin(p.x*.18+p.y*.11)+sin(p.y*.24-p.x*.07)*.6);
    vec3 grass = woodland ? vec3(.255,.345,.275) : vec3(.315,.375,.265);
    vec3 soil = woodland ? vec3(.265,.285,.235) : vec3(.365,.345,.275);
    vec3 base = mix(soil,grass,field*.85+.12);
    vec3 paint = mix(texture(earth,p*.16).rgb,texture(meadow,p*.16).rgb,field);
    float grain = dot(paint,vec3(.299,.587,.114));
    base *= mix(.90,1.09,grain);
    base = mix(base,vec3(.235,.275,.225),COLOR.g*.6);
    base = mix(base,vec3(.19,.235,.215),COLOR.b*.73);
    vec3 stone = texture(paving,p*.38).rgb;
    float stone_value = dot(stone,vec3(.299,.587,.114));
    vec3 road = vec3(.44,.405,.325) * mix(.88,1.08,stone_value);
    float worn = smoothstep(.18,.78,COLOR.r + (grain-.5)*.09);
    base = mix(base,road,worn);
    base = mix(base,vec3(.365,.375,.335)*mix(.92,1.07,grain),COLOR.a*.58);
    ALBEDO = base;
    ROUGHNESS = .98;
    SPECULAR = .07;
}
