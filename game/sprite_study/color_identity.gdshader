shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_disabled;

// Bounded to Godot 4.4.1 Compatibility, Filmic, exposure=white=1,
// unscaled SDR, no fog/glow/adjustments. See RENDERING.md for upstream proof.
// The inherited Illustration basis already faces the camera; do not move vertices.
uniform sampler2D source_texture : source_color, filter_linear_mipmap, repeat_disable;

// SCALAR_BEGIN
float compatibility_decode(float value) {
	return value * (value * (value * 0.305306011 + 0.682171111) + 0.012522878);
}

float filmic_raw(float value) {
	return (value * (0.88 * value + 0.06) + 0.002) / (value * (0.88 * value + 0.60) + 0.06) - 0.01 / 0.30;
}

float identity_albedo(float value) {
	// Exact black has multiple preimages under the output clamp; choose zero.
	if (value <= 0.0) {
		return 0.0;
	}
	// Invert the actual Compatibility output approximation, NOT IEC sRGB.
	float target = pow((value + 0.055) / 1.055, 1.0 / 0.416666667);
	// Invert the white-normalized rational Filmic curve via its positive root.
	float shifted = target * filmic_raw(1.0) + 0.01 / 0.30;
	float a = 0.88 * (1.0 - shifted);
	float b = 0.60 * (0.10 - shifted);
	float c = 0.20 * (0.01 - 0.30 * shifted);
	float discriminant = sqrt(max(b * b - 4.0 * a * c, 0.0));
	float linear = 0.0;
	if (b >= 0.0) {
		// Rationalized root avoids subtractive cancellation in dark channels.
		linear = (-2.0 * c) / (b + discriminant);
	}
	else {
		linear = (-b + discriminant) / (2.0 * a);
	}
	// scene.glsl polynomial-decodes ALBEDO even for unshaded materials.
	// Invert that monotonic polynomial on [0,1], not a different sRGB curve.
	float encoded = sqrt(max(linear, 0.0));
	for (int i = 0; i < 6; i++) {
		float derivative = 3.0 * 0.305306011 * encoded * encoded + 2.0 * 0.682171111 * encoded + 0.012522878;
		encoded = clamp(encoded - (compatibility_decode(encoded) - linear) / derivative, 0.0, 1.0);
	}
	return encoded;
}
// SCALAR_END

void fragment() {
	vec4 source = texture(source_texture, UV);
	ALBEDO = vec3(identity_albedo(source.r), identity_albedo(source.g), identity_albedo(source.b));
	ALPHA = source.a;
}
