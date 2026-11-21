shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform sampler2D pigment : repeat_enable, filter_linear_mipmap;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float wind_strength = 0.022;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wind = sin(TIME * 1.2 + world_position.x * 1.1 + world_position.z * 0.7);
	VERTEX.x += wind * wind_strength * clamp(VERTEX.y, 0.0, 2.0);
	VERTEX.z += cos(TIME * 0.9 + world_position.z) * wind_strength * 0.35;
}
void fragment() {
	float screen_grain = fract(dot(floor(FRAGCOORD.xy), vec2(0.75487766, 0.56984029)));
	if (screen_grain > opacity) { discard; }
	vec3 ink = texture(pigment, world_position.xz * 4.0 + vec2(world_position.y * 1.8)).rgb;
	float leaves = smoothstep(0.31, 0.65, ink.g);
	ALBEDO = COLOR.rgb * (0.70 + ink.r * 0.25 + leaves * 0.28);
	ROUGHNESS = 1.0;
}
