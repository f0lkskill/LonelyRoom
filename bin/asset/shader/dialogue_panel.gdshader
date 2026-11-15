// 自适应阴影对话框背景。
// 使用多层圆角矩形边缘衰减，尺寸由 DialogueBox 根据文本长度同步。
shader_type canvas_item;

// 面板中心的最大不透明度。
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.8;
// 圆角半径，单位像素。
uniform float corner_radius : hint_range(0.0, 160.0, 1.0) = 96.0;
// 最外层阴影的淡出宽度，单位像素。
uniform float edge_softness : hint_range(0.0, 160.0, 1.0) = 96.0;
// 从上到下的轻微明暗渐变。
uniform float vertical_fade : hint_range(0.0, 0.5, 0.01) = 0.1;
// 面板实际尺寸，由 DialogueBox 在运行时同步。
uniform vec2 rect_size = vec2(800.0, 180.0);

float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 half_size = rect_size * 0.5;
	vec2 p = (UV - 0.5) * rect_size;
	float d = rounded_box(p, half_size, corner_radius);

	float core = 1.0 - smoothstep(-edge_softness * 0.12, 0.0, d);
	float inner = 1.0 - smoothstep(-edge_softness * 0.32, 0.0, d);
	float mid = 1.0 - smoothstep(-edge_softness * 0.6, 0.0, d);
	float outer = 1.0 - smoothstep(-edge_softness, 0.0, d);
	float mask = core * 0.2 + inner * 0.25 + mid * 0.25 + outer * 0.3;
	float vertical = 1.0 - vertical_fade * UV.y;

	COLOR = vec4(0.0, 0.0, 0.0, strength * mask * vertical);
}
