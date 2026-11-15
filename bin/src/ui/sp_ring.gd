## 左下角 SP 环形进度条。
## 四分之一圆弧带有沿弧线的颜色渐变，中心为立绘占位，数值显示在圆环下方。
extends Control

## 圆环半径。
@export var radius: float = 104.0
## 圆环宽度。
@export var thickness: float = 12.0
## 圆弧起始角度。
@export var start_angle: float = PI
## 圆弧总角度，默认四分之一个圆。
@export var sweep_angle: float = PI * 0.5
## 未填充部分的颜色。
@export var track_color: Color = Color(0.22, 0.24, 0.3, 0.35)
## 正常 SP 的填充颜色。
@export var fill_color: Color = Color(0.63, 0.86, 1.0, 1.0)
## 低 SP 的警示颜色。
@export var danger_color: Color = Color(0.9, 0.28, 0.32, 1.0)
## 中央立绘占位背景。
@export var portrait_background: Color = Color(0.04, 0.045, 0.06, 0.6)

@onready var value_label: Label = $ValueLabel

var _ratio: float = 1.0


func _ready() -> void:
	GameState.sp_changed.connect(_on_sp_changed)
	_on_sp_changed(GameState.sp, GameState.max_sp)


func _on_sp_changed(value: float, max_value: float) -> void:
	_ratio = clampf(value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	value_label.text = "SP %d" % roundi(_ratio * 100.0)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 140.0)
	var portrait_radius := radius - thickness - 10.0

	draw_circle(center, portrait_radius, portrait_background)
	draw_circle(center + Vector2(0.0, -18.0), 24.0, Color(0.18, 0.2, 0.24, 0.85))
	draw_circle(center + Vector2(0.0, 38.0), 40.0, Color(0.18, 0.2, 0.24, 0.85))
	draw_arc(center, portrait_radius, 0.0, TAU, 64, Color(0.5, 0.56, 0.66, 0.25), 2.0, true)

	draw_arc(center, radius, start_angle, start_angle + sweep_angle, 48, track_color, thickness, true)

	var base_color := fill_color.lerp(danger_color, 1.0 - _ratio)
	var start_color := Color(base_color.r * 0.6, base_color.g * 0.6, base_color.b * 0.6, 0.12)
	var end_color := Color(base_color.r, base_color.g, base_color.b, 1.0)
	var fill_end := start_angle + sweep_angle * _ratio
	_draw_arc_gradient(center, radius, start_angle, fill_end, thickness, start_color, end_color)

	if _ratio < 0.3:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		var glow := Color(danger_color.r, danger_color.g, danger_color.b, 0.18 * pulse)
		_draw_arc_gradient(center, radius, start_angle, fill_end, thickness + 8.0, glow, glow)


func _draw_arc_gradient(center: Vector2, arc_radius: float, from_angle: float, to_angle: float, width: float, start_color: Color, end_color: Color) -> void:
	if to_angle <= from_angle:
		return

	var segments := maxi(2, int((to_angle - from_angle) * 32.0))
	for i in segments:
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)
		var a0 := lerpf(from_angle, to_angle, t0)
		var a1 := lerpf(from_angle, to_angle, t1) + 0.002
		var color := start_color.lerp(end_color, t0)
		draw_arc(center, arc_radius, a0, a1, 2, color, width, true)
