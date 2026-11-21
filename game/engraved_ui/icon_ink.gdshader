shader_type canvas_item;
render_mode unshaded;
// Cut on the actual texture only. Ink follows its existing relief, never the
// screen, slot contents, neighbouring Control, tier, UID or frame history.
void fragment() {
 vec4 src = COLOR;
 float L = dot(src.rgb, vec3(.25,.62,.13));
 vec2 step_uv = max(TEXTURE_PIXEL_SIZE, fwidth(UV) * .72);
 vec4 lit = texture(TEXTURE, clamp(UV - step_uv * vec2(.82, .54), vec2(0.), vec2(1.)));
 float crease = smoothstep(.05,.32,dot(lit.rgb,vec3(.25,.62,.13)) - L) * lit.a;
 float pitch = (UV.x / max(fwidth(UV.x), .00001) + 1.8 * UV.y / max(fwidth(UV.y),.00001)) * 1.45;
 float hatch = smoothstep(.48,.97,cos(pitch)) * (1.-smoothstep(.13,.52,L));
 vec3 stock = mix(src.rgb, vec3(.065,.105,.078)+L*vec3(.89,.84,.70), .20);
 COLOR=vec4(mix(stock,vec3(.065,.095,.077),crease*.43+hatch*.15),src.a);
}
