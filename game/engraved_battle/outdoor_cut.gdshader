shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// BB2_OUTDOOR_CUT: pigment only. Keep the same depth, fade and inherited wind.
uniform sampler2D paint : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float opacity = 1.0;
uniform float scale = .8;
uniform float wind_strength = 0.0;
uniform float painted_mix = .85;
uniform int outdoor_family = 0; // slate, bark, leaf
uniform float shelf_moss = 0.0;
uniform float contact_height = 0.0;
varying vec3 world_position;
varying vec3 world_normal;
varying float prop_height;

void vertex() {
    world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal = normalize(mat3(MODEL_MATRIX)*NORMAL);
    prop_height = VERTEX.y;
    VERTEX.x += sin(TIME*1.45+world_position.x*2.1+world_position.z)*wind_strength*max(VERTEX.y,0.0);
}

float cut_hash(vec2 p) {
    vec3 v = fract(p.xyx*vec3(.1031,.1030,.0973));
    v += dot(v,v.yzx+33.33);
    return fract((v.x+v.y)*v.z);
}

float cut_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 t = fract(p);
    t = t*t*(3.0-2.0*t);
    return mix(mix(cut_hash(cell),cut_hash(cell+vec2(1,0)),t.x),
               mix(cut_hash(cell+vec2(0,1)),cut_hash(cell+vec2(1,1)),t.x),t.y);
}

void fragment() {
    if (opacity < 1.0 && fract(sin(dot(floor(FRAGCOORD.xy),vec2(12.9898,78.233)))*43758.5453)>opacity) { discard; }
    vec3 normal_world = normalize(world_normal);
    vec3 weights = pow(abs(normal_world),vec3(6.0));
    weights /= max(weights.x+weights.y+weights.z,.001);
    vec3 p = world_position*scale;
    vec3 tex = texture(paint,p.zy).rgb*weights.x+texture(paint,p.xz).rgb*weights.y+texture(paint,p.xy).rgb*weights.z;
    float gray = dot(tex,vec3(.299,.587,.114));
    float authored = dot(COLOR.rgb,vec3(.299,.587,.114));
    float grain = (gray-.5)*painted_mix;
    float contact = 1.0;
    if (contact_height > 0.0) {
        contact = mix(.59,1.0,smoothstep(0.0,contact_height,prop_height));
    }
    if (outdoor_family == 1) {
        // Warm cut timber, smoke-brown at the meeting of roots and soil.
        float fiber = cut_noise(vec2((world_position.x+world_position.z*.71)*21.0,world_position.y*2.2));
        vec3 bark = mix(vec3(.279,.210,.159),vec3(.484,.386,.303),
                        clamp(.44+(authored-.4)*1.2+(fiber-.5)*.37+grain*.68,0.0,1.0));
        ALBEDO = bark*contact;
    } else if (outdoor_family == 2) {
        // Keep the existing leaf-card tint variation; lift crown tips, not the whole canopy.
        float crown = smoothstep(1.95,3.18,prop_height);
        vec3 leaf = mix(vec3(.192,.279,.165),vec3(.427,.498,.309),
                        clamp(.24+crown*.49+(authored-.40)*1.25+grain*.67,0.0,1.0));
        ALBEDO = mix(leaf,COLOR.rgb,.30);
    } else {
        // Broad planes carry the value. Broken, nearly horizontal seams sit underneath the moss.
        float up = max(normal_world.y,0.0);
        float chip = cut_noise(world_position.xz*2.15+vec2(world_position.y*.6));
        float ledge = smoothstep(.34,.94,up);
        vec3 slate = mix(vec3(.352,.399,.437),vec3(.430,.459,.471),ledge);
        float layer = dot(world_position,vec3(.34,5.25,-.45))+(chip-.5)*.35;
        float width = fwidth(layer);
        float seam = (1.0-smoothstep(.065,.175+width,abs(fract(layer)-.5)))
                   * (1.0-smoothstep(.15,.48,width)) * (1.0-ledge*.8);
        slate *= (1.0+(authored-.60)*.32+(chip-.5)*.20+grain*.67)
                 * (1.0-seam*(.035+chip*.13));
        if (shelf_moss > 0.0) {
            float clump = cut_noise(world_position.xz*3.4+vec2(1.7,5.1));
            float edge = cut_noise(world_position.xz*10.8);
            float patches = smoothstep(.39,.66,clump*.73+edge*.27);
            vec3 moss = mix(vec3(.255,.301,.194),vec3(.365,.406,.253),clamp(clump+grain*.9,0.0,1.0));
            slate = mix(slate,moss,smoothstep(.48,.95,up)*patches*shelf_moss);
        }
        ALBEDO = slate*contact;
    }
    ROUGHNESS = .94;
    SPECULAR = .10;
}
