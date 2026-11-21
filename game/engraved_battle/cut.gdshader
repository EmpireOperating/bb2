shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// MUSTER_CUT: grounded woodcut facets; preserve opacity, paint variation and native occluder fade.
uniform sampler2D paint : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float opacity = 1.0;
uniform float scale = .8;
uniform float wind_strength = 0.0;
uniform float painted_mix = .85;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
    world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal = normalize(mat3(MODEL_MATRIX)*NORMAL);
    VERTEX.x += sin(TIME*1.45+world_position.x*2.1+world_position.z)*wind_strength*max(VERTEX.y,0.0);
}
void fragment() {
    if (opacity < 1.0 && fract(sin(dot(floor(FRAGCOORD.xy),vec2(12.9898,78.233)))*43758.5453)>opacity) { discard; }
    vec3 weights = pow(abs(world_normal),vec3(6.0));
    weights /= max(weights.x+weights.y+weights.z,.001);
    vec3 p=world_position*scale;
    vec3 tex=texture(paint,p.zy).rgb*weights.x+texture(paint,p.xz).rgb*weights.y+texture(paint,p.xy).rgb*weights.z;
    float gray=dot(tex,vec3(.299,.587,.114));
    tex=mix(tex,vec3(gray),.36);
    vec3 pigment=COLOR.rgb*mix(vec3(1.0),tex*1.10,painted_mix);
    float light=dot(pigment,vec3(.30,.59,.11));
    vec3 paper=mix(vec3(.19,.22,.17),vec3(.81,.80,.64),clamp(light*1.25,0.,1.));
    float groove=dot(world_position,vec3(7.1,9.0,-3.8));
    float cut=1.-smoothstep(.06,.12+fwidth(groove),abs(fract(groove+gray*.4)-.5));
    cut*=(1.-smoothstep(.15,.5,fwidth(groove)))*(1.-smoothstep(.25,.88,light));
    ALBEDO=mix(paper,pigment,.40)*mix(1.,.59,cut);
    ROUGHNESS=.95;
    SPECULAR=.12;
}
