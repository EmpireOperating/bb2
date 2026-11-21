shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D pigment : repeat_enable, filter_linear_mipmap;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	// Opaque dither avoids Compatibility's per-instance transparency limitation.
	float screen_grain = fract(dot(floor(FRAGCOORD.xy), vec2(0.75487766, 0.56984029)));
	if (screen_grain > opacity) { discard; }
	vec3 ink = texture(pigment, vec2(world_position.x + world_position.z, world_position.y + world_position.z * 0.35) * 1.6).rgb;
	ALBEDO = COLOR.rgb * (0.76 + ink.r * 0.30 + ink.b * 0.08);
	ROUGHNESS = 0.94;
	SPECULAR = 0.16;
}
