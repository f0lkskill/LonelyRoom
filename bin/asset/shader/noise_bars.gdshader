// 仅在极高解离强度下出现的全屏灰色噪声条。
shader_type canvas_item;

// 当前解离强度，由 Main 驱动。
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.65;
// 强度必须超过该值后噪声条才会出现。
uniform float threshold : hint_range(0.0, 1.0, 0.01) = 0.8;
// 滚动和颗粒动画速度。
uniform float speed : hint_range(0.0, 4.0, 0.01) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float activation = smoothstep(threshold, 1.0, strength);
	if (activation <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		float t = TIME * speed;

		float row = floor(UV.y * 70.0 + t * 18.0);
		float row_rand = hash(vec2(row, floor(t * 14.0)));
		float bar = smoothstep(0.78, 0.86, row_rand);

		float band = floor(UV.y * 12.0 - t * 3.0);
		float band_rand = hash(vec2(band, floor(t * 7.0)));
		float tear = smoothstep(0.9, 0.98, band_rand);

		float mask = max(bar, tear);

		vec2 cell = floor(FRAGCOORD.xy * 0.5) + vec2(floor(t * 30.0) * 7.0, floor(t * 30.0) * 3.0);
		float grain = hash(cell);
		float gray = mix(0.35, 0.75, grain);
		float alpha = activation * mask * (0.25 + 0.6 * grain);

		COLOR = vec4(vec3(gray), clamp(alpha, 0.0, 0.85));
	}
}
