// 单物体解离效果。
// 包含随时间变化的色差、边缘模糊、随机线性撕裂和悬停描边。
// 强度会驱动全部效果，撕裂和噪声只在接近最大值时出现。
shader_type canvas_item;

// 总强度，通常由 Main.dissociation_strength 驱动。
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.65;
// 以纹理像素为单位的最大色差偏移。
uniform float aberration : hint_range(0.0, 12.0, 0.1) = 4.0;
// 以纹理像素为单位的边缘模糊半径。
uniform float blur : hint_range(0.0, 12.0, 0.1) = 2.0;
// 水平故障条带的位移强度。
uniform float tearing : hint_range(0.0, 1.0, 0.01) = 0.35;
// 动画速度倍率。
uniform float speed : hint_range(0.0, 4.0, 0.01) = 1.0;
// 由 Main 分配的独立随机种子，让每个物体拥有不同的撕裂角度。
uniform float object_seed : hint_range(0.0, 1.0, 0.001) = 0.37;
// 由 BaseObj 动画控制的悬停描边强度。
uniform float hover : hint_range(0.0, 1.0, 0.01) = 0.0;
// 悬停时使用的轮廓颜色。
uniform vec4 outline_color : source_color = vec4(0.63, 0.9, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 px = TEXTURE_PIXEL_SIZE;
	float t = TIME * speed;

	vec4 center = texture(TEXTURE, uv);
	float center_luma = dot(center.rgb, vec3(0.299, 0.587, 0.114));

	vec4 left = texture(TEXTURE, uv - vec2(px.x, 0.0));
	vec4 right = texture(TEXTURE, uv + vec2(px.x, 0.0));
	vec4 up = texture(TEXTURE, uv - vec2(0.0, px.y));
	vec4 down = texture(TEXTURE, uv + vec2(0.0, px.y));

	float alpha_edge = length(vec2(right.a - left.a, down.a - up.a)) * 1.8;
	float luma_edge = length(vec2(
		dot(right.rgb, vec3(0.299, 0.587, 0.114)) - dot(left.rgb, vec3(0.299, 0.587, 0.114)),
		dot(down.rgb, vec3(0.299, 0.587, 0.114)) - dot(up.rgb, vec3(0.299, 0.587, 0.114))
	)) * 1.2;
	float edge = clamp(max(alpha_edge, luma_edge), 0.0, 1.0);

	float breath = 0.65 + 0.35 * sin(t * 1.7 + center_luma * 6.0);
	float spike = smoothstep(0.82, 1.0, sin(t * 2.3 + uv.y * 43.0 + hash(vec2(floor(t * 2.0), 7.0)) * 6.2831));

	float band_id = floor(uv.y * 32.0 + t * 4.0);
	float band_rand = hash(vec2(band_id, floor(t * 6.0)));
	float band_tear = (band_rand * 2.0 - 1.0) * step(0.72, hash(vec2(band_id, 3.7)));
	float band_offset = band_tear * tearing * strength * 0.012;

	float fracture = smoothstep(0.82, 1.0, strength);
	float cycle = floor(t * 0.8 + object_seed * 3.0);
	float tear_angle = 6.2831 * (object_seed + cycle * 0.37);
	vec2 tear_dir = vec2(cos(tear_angle), sin(tear_angle));
	vec2 tear_normal = vec2(-tear_dir.y, tear_dir.x);
	float cut_offset = (hash(vec2(object_seed, cycle)) - 0.5) * 0.65;
	float cut_distance = dot(uv - 0.5, tear_normal) - cut_offset;
	float cut_side = smoothstep(-0.004, 0.004, cut_distance);
	float slip = (hash(vec2(object_seed, cycle + 7.0)) - 0.5) * 2.0;
	vec2 fracture_uv = uv + tear_dir * cut_side * slip * fracture * 0.16;
	fracture_uv += tear_normal * sin(dot(uv - 0.5, tear_normal) * 45.0 + t * 6.0) * fracture * 0.02;

	vec2 base_uv = fracture_uv + vec2(band_offset, 0.0);
	vec4 col = texture(TEXTURE, base_uv);

	float ab = aberration * px.x * (0.15 + edge * breath) * strength + spike * strength * px.x * 2.5;
	col.r = texture(TEXTURE, base_uv + vec2(ab, 0.0)).r;
	col.b = texture(TEXTURE, base_uv - vec2(ab * 0.8, 0.0)).b;

	vec2 blur_step = px * blur * strength * (0.25 + edge);
	vec4 blurred = texture(TEXTURE, base_uv + vec2(blur_step.x, 0.0)) * 0.2;
	blurred += texture(TEXTURE, base_uv - vec2(blur_step.x, 0.0)) * 0.2;
	blurred += texture(TEXTURE, base_uv + vec2(0.0, blur_step.y)) * 0.2;
	blurred += texture(TEXTURE, base_uv - vec2(0.0, blur_step.y)) * 0.2;
	blurred += texture(TEXTURE, base_uv + blur_step * vec2(0.7, 0.7)) * 0.05;
	blurred += texture(TEXTURE, base_uv - blur_step * vec2(0.7, 0.7)) * 0.05;
	blurred += texture(TEXTURE, base_uv + blur_step * vec2(0.7, -0.7)) * 0.05;
	blurred += texture(TEXTURE, base_uv - blur_step * vec2(0.7, -0.7)) * 0.05;

	float blur_mix = clamp(edge * strength * breath * 0.85, 0.0, 1.0);
	vec4 result = mix(col, blurred, blur_mix);
	result.a = max(col.a, blurred.a * blur_mix);

	float cut_gap = 1.0 - smoothstep(0.0, 0.006, abs(cut_distance));
	result.a *= 1.0 - cut_gap * fracture * 0.95;
	result.rgb *= 1.0 - cut_gap * fracture * 0.35;

	float gray = dot(result.rgb, vec3(0.299, 0.587, 0.114));
	result.rgb = mix(result.rgb, vec3(gray), strength * 0.28);
	result.rgb *= mix(vec3(1.0), vec3(0.92, 0.96, 1.06), strength * 0.5);

	vec4 left_wide = texture(TEXTURE, uv - vec2(px.x * 3.0, 0.0));
	vec4 right_wide = texture(TEXTURE, uv + vec2(px.x * 3.0, 0.0));
	vec4 up_wide = texture(TEXTURE, uv - vec2(0.0, px.y * 3.0));
	vec4 down_wide = texture(TEXTURE, uv + vec2(0.0, px.y * 3.0));
	float outline_edge = max(alpha_edge, length(vec2(right_wide.a - left_wide.a, down_wide.a - up_wide.a)) * 1.4);
	float outline_shape = clamp(outline_edge * 2.0, 0.0, 1.0);
	float outline_pulse = 0.7 + 0.3 * sin(t * 4.0);
	result.rgb = mix(result.rgb, outline_color.rgb, outline_shape * hover * outline_pulse * 0.9 + hover * 0.06);
	result.a = max(result.a, outline_shape * hover * 0.45);

	COLOR = result;
}
