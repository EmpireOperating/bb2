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
uniform float work_wear = 0.0;
varying vec3 world_position;
varying vec3 world_normal;
varying float prop_height;
varying vec2 prop_xz;

void vertex() {
    world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal = normalize(mat3(MODEL_MATRIX)*NORMAL);
    prop_height = VERTEX.y;
    prop_xz = VERTEX.xz;
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

float work_distance(vec2 p, vec2 a, vec2 b) {
    vec2 line = b - a;
    return length(p - a - line * clamp(dot(p - a, line) / dot(line, line), 0.0, 1.0));
}

vec3 work_cut(vec3 base, vec3 local, float wear, int family) {
    // Match the Broken Gate's masonry yaw. Incisions stay on the actual
    // prop, depth/fade/shadow and fog remain the stock material's job.
    float x = dot(local.xz, vec2(.8660254,-.5));
    float front = dot(local.xz, vec2(.5,.8660254));
    if (family == 1 && front > -.055) {
        float w = mix(.084,.134,sqrt(wear));
        float tip = clamp((x + .024) / (2.0 * w) + .5, 0.0, 1.0);
        float y = local.y - (.76 + x * .27);
        float opening = mix(.079,.139,wear) * (1.0 - tip);
        float outline = max(abs(x + .024) - w,max(y - opening,-y - opening * .52));
        vec3 cut = mix(vec3(.99,.71,.34),vec3(.16,.075,.031),smoothstep(-.009,.021,y));
        return mix(base,cut,1.0 - smoothstep(-.004,.011,outline));
    }
    if (family == 0 && x < -.27 && front > .063) {
        // Same shifted flank as the exposed courses, not the fore pier.
        vec2 p = vec2(x + .72,local.y);
        float d = work_distance(p,vec2(-.27,1.47),vec2(-.084,1.08));
        d = min(d,work_distance(p,vec2(-.084,1.08),vec2(-.18,.91)));
        d = min(d,work_distance(p,vec2(-.18,.91),vec2(.055,.69)));
        d = min(d,work_distance(p,vec2(.055,.69),vec2(-.02,.50)));
        d = min(d,work_distance(p,vec2(-.02,.50),vec2(.18,.31)));
        if (wear > .44) {
            d = min(d,work_distance(p,vec2(.055,.69),vec2(.23,.78)));
            d = min(d,work_distance(p,vec2(.23,.78),vec2(.34,.68)));
        }
        float width = mix(.018,.037,wear);
        base = mix(base,vec3(.73,.68,.55),.65 * (1.0 - smoothstep(width, width + .026,d)));
        return mix(base,vec3(.08,.069,.057),1.0 - smoothstep(width - .012,width + .003,d));
    }
    return base;
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
    if (work_wear > 0.0) { ALBEDO = work_cut(ALBEDO, vec3(prop_xz.x,prop_height,prop_xz.y), work_wear, outdoor_family); }
    ROUGHNESS = .94;
    SPECULAR = .10;
}
