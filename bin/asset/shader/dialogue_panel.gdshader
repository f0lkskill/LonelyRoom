// 柔和的黑色对话框背景，使用内接椭圆渐变。
// 不透明度在面板中心最高，并在四条边之前自然衰减到零。
shader_type canvas_item;

// 面板中心的最大不透明度。
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.92;
// 椭圆中心保持完全不透明的范围，之后开始向外衰减。
uniform float softness : hint_range(0.05, 0.95, 0.01) = 0.7;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float d = length(p);
	float alpha = (1.0 - smoothstep(softness, 1.0, d)) * strength;
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
