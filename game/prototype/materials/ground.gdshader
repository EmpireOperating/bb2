shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D pigment : repeat_enable, filter_linear_mipmap;
uniform vec4 earth_light : source_color = vec4(0.49, 0.44, 0.29, 1.0);
uniform vec4 earth_dark : source_color = vec4(0.28, 0.29, 0.18, 1.0);
uniform bool cliff = false;
uniform bool paved = false;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_position.xz * 0.32;
	if (cliff) {
		uv = vec2(world_position.x + world_position.z, world_position.y * 2.4) * 0.34;
	}
	vec3 ink = texture(pigment, uv).rgb;
	float wash = clamp(ink.r * 0.82 + ink.g * 0.28, 0.0, 1.0);
	ALBEDO = mix(earth_dark.rgb, earth_light.rgb, wash) * (0.89 + ink.b * 0.22);
	if (paved) {
		// Weathered, staggered setts; soft chipped joints, not a tile-grid overlay.
		vec2 stone = world_position.xz * vec2(2.8, 3.6) + (ink.gb - vec2(0.5)) * 0.24;
		stone.x += mod(floor(stone.y), 2.0) * 0.5;
		vec2 edge = min(fract(stone), vec2(1.0) - fract(stone));
		float joint = smoothstep(0.016, 0.075, min(edge.x, edge.y));
		float slab = fract(sin(dot(floor(stone), vec2(71.7, 29.3))) * 43758.54);
		ALBEDO = mix(earth_dark.rgb * 0.82, ALBEDO * (0.91 + slab * 0.17), joint);
	}
	if (cliff) {
		float stratum = smoothstep(0.12, 0.22, abs(sin(world_position.y * 13.0 + ink.g * 1.5)));
		ALBEDO *= 0.78 + stratum * 0.22;
	}
	ROUGHNESS = 0.96;
	SPECULAR = 0.12;
}
