// 柔和的黑色对话框背景，从中心向四周逐渐透明。
shader_type canvas_item;

// 面板中心的最大不透明度。
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.92;
// 纵向压缩渐变，使宽屏上的文字区域更容易阅读。
uniform float vertical_falloff : hint_range(0.1, 3.0, 0.01) = 2.0;
// 控制黑色块向透明过渡的快慢。
uniform float softness : hint_range(0.05, 1.0, 0.01) = 0.55;

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.1, vertical_falloff);
	float d = length(p);
	float alpha = (1.0 - smoothstep(softness, 1.15, d)) * strength;
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
