// 毛玻璃对话框阴影。
// 采样屏幕背景进行模糊，再叠加低透明度的暗色圆角渐变。
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// 阴影中心最大不透明度，越低越通透。
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.3;
// 圆角半径，单位像素。
uniform float corner_radius : hint_range(0.0, 160.0, 1.0) = 48.0;
// 阴影边缘淡出宽度，单位像素。
uniform float edge_softness : hint_range(0.0, 160.0, 1.0) = 24.0;
// 从上到下的轻微明暗渐变。
uniform float vertical_fade : hint_range(0.0, 0.5, 0.01) = 0.04;
// 面板实际尺寸，由 DialogueBox 在运行时同步。
uniform vec2 rect_size = vec2(800.0, 180.0);
// 毛玻璃模糊半径，单位 UV。
uniform float blur_radius : hint_range(0.0, 0.05, 0.001) = 0.03;
// 暗色染色比例。
uniform float tint_amount : hint_range(0.0, 1.0, 0.01) = 0.25;
// 毛玻璃的暗色染色。
uniform vec4 tint_color : source_color = vec4(0.08, 0.09, 0.12, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

vec3 sample_blur(vec2 uv) {
	vec2 texel = vec2(blur_radius);
	vec3 color = texture(screen_texture, uv).rgb * 0.2;
	color += texture(screen_texture, uv + vec2(texel.x, 0.0)).rgb * 0.1;
	color += texture(screen_texture, uv - vec2(texel.x, 0.0)).rgb * 0.1;
	color += texture(screen_texture, uv + vec2(0.0, texel.y)).rgb * 0.1;
	color += texture(screen_texture, uv - vec2(0.0, texel.y)).rgb * 0.1;
	color += texture(screen_texture, uv + texel * 0.7).rgb * 0.1;
	color += texture(screen_texture, uv - texel * 0.7).rgb * 0.1;
	color += texture(screen_texture, uv + vec2(texel.x, -texel.y) * 0.7).rgb * 0.1;
	color += texture(screen_texture, uv + vec2(-texel.x, texel.y) * 0.7).rgb * 0.1;
	return color;
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

	vec3 blurred = sample_blur(SCREEN_UV);
	float luma = dot(blurred, vec3(0.299, 0.587, 0.114));
	blurred = mix(blurred, vec3(luma), 0.2);
	blurred = mix(blurred, tint_color.rgb, tint_amount);
	blurred += (hash(floor(FRAGCOORD.xy * 0.6)) - 0.5) * 0.06;

	float alpha = clamp(strength * mask * vertical, 0.0, 0.9);
	COLOR = vec4(blurred, alpha);
}
