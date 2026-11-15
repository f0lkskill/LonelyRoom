// 圆角矩形对话框背景，边缘使用柔和渐变。
// 内部保持深色以包裹文字，圆角和四周自然淡出。
shader_type canvas_item;

// 面板中心的最大不透明度。
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.92;
// 圆角半径，单位像素。
uniform float corner_radius : hint_range(0.0, 120.0, 1.0) = 32.0;
// 边缘淡出的宽度，单位像素。
uniform float edge_softness : hint_range(0.0, 80.0, 1.0) = 28.0;
// 从上到下的轻微明暗渐变。
uniform float vertical_fade : hint_range(0.0, 0.5, 0.01) = 0.08;
// 面板实际尺寸，由 DialogueBox 在运行时同步。
uniform vec2 rect_size = vec2(880.0, 200.0);

float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 half_size = rect_size * 0.5;
	vec2 p = (UV - 0.5) * rect_size;
	float d = rounded_box(p, half_size, corner_radius);
	float mask = 1.0 - smoothstep(-edge_softness, 0.0, d);
	float vertical = 1.0 - vertical_fade * UV.y;
	COLOR = vec4(0.0, 0.0, 0.0, strength * mask * vertical);
}
