shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// Moss & Ochre daylight. Existing masks: road, woodland, wet ground, rubble.
// Keep these continuous across hexes. The camera, battle lighting and fog
// still own their independent presentation, including hidden-space edges.
uniform sampler2D earth : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D meadow : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paving : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool woodland = false;
varying vec3 plate_position;

float seed21(vec2 p) { return fract(sin(dot(p,vec2(37.23,81.79)))*4375.173); }
float incision(vec2 uv, float length_cut, float aa) {
    float d = length(vec2(max(abs(uv.x)-length_cut,0.),uv.y));
    return 1.-smoothstep(.012,.032+aa*.4,d);
}
void vertex() { plate_position = VERTEX; }
void fragment() {
    vec2 p = plate_position.xz;
    float fiber = texture(meadow,p*.39).g;
    float soil = texture(earth,vec2(p.x*.22+p.y*.095,p.y*.22)).r;
    float grit = texture(paving,p*.61).r;
    float fold = sin(dot(p,vec2(.29,.18))+sin(p.y*.41)*.64) + .56*sin(dot(p,vec2(-.17,.44)));
    float wash = smoothstep(-.86,.94,fold+(soil-.42)*.84);
    float edge = clamp(COLOR.g,0.,1.);
    float wet = clamp(COLOR.b,0.,1.);
    float stony = clamp(COLOR.a,0.,1.);
    float path = smoothstep(.12,.76,COLOR.r+(soil-.43)*.12);

    // Broad, warm daylight swathes; the walkable centers stay quiet.
    vec3 low = woodland ? vec3(.350,.409,.226) : vec3(.363,.420,.216);
    vec3 high = woodland ? vec3(.442,.480,.254) : vec3(.463,.490,.251);
    vec3 grass = mix(low,high,wash)*mix(.87,1.105,fiber);
    vec3 moss = mix(vec3(.193,.273,.174),vec3(.281,.361,.194),wash*.58+fiber*.30);
    grass = mix(grass,moss,smoothstep(.20,.91,edge)*.69);
    vec3 bank = mix(vec3(.143,.211,.169),vec3(.228,.289,.184),soil);
    grass = mix(grass,bank,wet*.82);
    vec3 slate = mix(vec3(.207,.255,.270),vec3(.322,.355,.340),grit*.80+wash*.18);
    slate = mix(slate,moss,.35*smoothstep(.11,.82,edge+fiber*.55));
    grass = mix(grass,slate,smoothstep(.13,.87,stony)*.89);

    // Warm ochre, not pink paper. Fine gravel and a shallow dark shoulder
    // follow the actual road mask; no decorative path through blocked ground.
    vec3 ochre = mix(vec3(.338,.274,.185),vec3(.480,.412,.287),grit*.73+soil*.27);
    float shoulder = (smoothstep(.10,.35,COLOR.r)-smoothstep(.36,.66,COLOR.r));
    vec3 pigment = mix(grass,ochre,path)*mix(1.,.88,shoulder*(.60+soil*.40));

    // Sparse ink at transitions, fading out before it breaks the grid read.
    vec2 uv = mat2(vec2(.91,.414),vec2(-.414,.91))*p*4.1;
    vec2 box = floor(uv);
    vec2 local = fract(uv)-.5;
    local -= vec2(seed21(box),seed21(box+8.3))*.44-.22;
    local.y -= local.x*(.24+.38*seed21(box+12.));
    float aa = max(fwidth(uv.x),fwidth(uv.y));
    float mark = incision(local,.064+.105*seed21(box+2.5),aa);
    float active = step(.33,seed21(box+19.));
    float accent = max(max(edge*.72,stony*.83),shoulder*.67);
    float ink = mark*active*(1.-smoothstep(.12,.34,aa))*(.19+.67*accent);
    ALBEDO = pigment*mix(1.,.63,ink);
    ROUGHNESS = .97;
    SPECULAR = .045;
}
