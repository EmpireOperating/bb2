shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D pigment : repeat_enable, filter_linear_mipmap;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 flow = world_position.xz * vec2(0.8, 0.28) + vec2(0.0, -TIME * 0.065);
	float deep = texture(pigment, flow).r;
	float ripple = texture(pigment, flow * vec2(2.6, 3.8) + vec2(TIME * 0.013, -TIME * 0.026)).g;
	float threads = smoothstep(0.79, 0.93, sin(world_position.z * 21.0 - TIME * 2.1 + ripple * 8.0) * 0.5 + 0.5);
	vec3 water = mix(vec3(0.055, 0.13, 0.13), vec3(0.22, 0.34, 0.30), deep);
	ALBEDO = mix(water, vec3(0.57, 0.64, 0.54), threads * ripple * 0.20);
	ROUGHNESS = 0.29 + ripple * 0.12;
	METALLIC = 0.12;
	SPECULAR = 0.65;
	NORMAL_MAP = vec3(0.5 + (ripple - 0.5) * 0.12, 0.5 + (threads - 0.5) * 0.035, 1.0);
	NORMAL_MAP_DEPTH = 0.35;
}
