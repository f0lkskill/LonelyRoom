## 左下角 SP 环形进度条。
## 使用四分之一圆弧表示精神值，中心预留角色立绘位置。
extends Control

## 圆环半径。
@export var radius: float = 104.0
## 圆环宽度。
@export var thickness: float = 12.0
## 圆弧起始角度。
@export var start_angle: float = -PI * 0.5
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

@onready var percent_label: Label = $Info/PercentLabel

var _ratio: float = 1.0


func _ready() -> void:
	GameState.sp_changed.connect(_on_sp_changed)
	_on_sp_changed(GameState.sp, GameState.max_sp)


func _on_sp_changed(value: float, max_value: float) -> void:
	_ratio = clampf(value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	percent_label.text = "%d%%" % roundi(_ratio * 100.0)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var portrait_radius := radius - thickness - 10.0

	draw_circle(center, portrait_radius, portrait_background)
	draw_circle(center + Vector2(0.0, -18.0), 24.0, Color(0.18, 0.2, 0.24, 0.85))
	draw_circle(center + Vector2(0.0, 38.0), 40.0, Color(0.18, 0.2, 0.24, 0.85))
	draw_arc(center, portrait_radius, 0.0, TAU, 64, Color(0.5, 0.56, 0.66, 0.25), 2.0, true)

	draw_arc(center, radius, start_angle, start_angle + sweep_angle, 48, track_color, thickness, true)

	var current_color := fill_color.lerp(danger_color, 1.0 - _ratio)
	var fill_end := start_angle + sweep_angle * _ratio
	draw_arc(center, radius, start_angle, fill_end, 48, current_color, thickness, true)

	if _ratio < 0.3:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		var glow := Color(danger_color.r, danger_color.g, danger_color.b, 0.22 * pulse)
		draw_arc(center, radius, start_angle, fill_end, 48, glow, thickness + 8.0, true)
