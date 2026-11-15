// 对话选项卡的黑色渐变块。
// 左右两侧逐渐透明，上下两半使用不同偏移并在中缝处割裂。
shader_type canvas_item;

// 黑色块整体不透明度。
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.85;
// 左右渐变的宽度。
uniform float edge_softness : hint_range(0.0, 0.5, 0.01) = 0.16;
// 上下两半的横向撕裂幅度。
uniform float tear_amount : hint_range(0.0, 0.1, 0.001) = 0.05;
// 撕裂动画速度。
uniform float speed : hint_range(0.0, 2.0, 0.01) = 0.4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float side = step(0.5, uv.y);
	float tear = (hash(vec2(floor(TIME * speed * 10.0), side)) - 0.5) * tear_amount;
	uv.x += tear;

	float left = smoothstep(0.0, edge_softness, uv.x);
	float right = smoothstep(0.0, edge_softness, 1.0 - uv.x);
	float grain = (hash(floor(FRAGCOORD.xy * 0.5)) - 0.5) * 0.05;

	float alpha = strength * left * right + grain * 0.25;
	COLOR = vec4(0.0, 0.0, 0.0, clamp(alpha, 0.0, 1.0));
}
