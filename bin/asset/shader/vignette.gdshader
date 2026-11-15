// 随强度增强的整体变暗和径向边缘暗幕。
// 用于模拟隧道视野和逐渐失明的感觉。
shader_type canvas_item;

// 当前解离强度，由 Main 驱动。
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.65;
// 全屏均匀增加的不透明度。
uniform float center_darkness : hint_range(0.0, 1.0, 0.01) = 0.3;
// 屏幕边缘额外增加的不透明度。
uniform float edge_darkness : hint_range(0.0, 1.0, 0.01) = 0.75;
// 边缘暗幕开始的中心距离。
uniform float edge_start : hint_range(0.0, 1.0, 0.01) = 0.28;
// 边缘暗幕完全变暗的中心距离。
uniform float edge_end : hint_range(0.0, 1.0, 0.01) = 0.68;
// 暗幕颜色。
uniform vec4 darkness_color : source_color = vec4(0.005, 0.006, 0.012, 1.0);

void fragment() {
	float d = length(UV - 0.5);
	float edge = smoothstep(edge_start, edge_end, d);
	float alpha = clamp(strength * (center_darkness + edge * edge_darkness), 0.0, 0.96);
	COLOR = vec4(darkness_color.rgb, alpha);
}
