## 所有可交互房间物体的基类。
## 负责悬停描边、可选的浮起动画以及对话数据。
extends Sprite2D

class_name BaseObj

## 点击该物体时显示的对话资源；为 null 时仅作为装饰。
@export var dialogue_data: Resource
## 是否启用悬停浮起动画，适合垃圾袋、药瓶等小物件。
@export var can_float := false
## 悬停时向上浮起的像素距离。
@export var float_height := 10.0
## 是否在悬停时启用 Shader 描边，背景物体可以关闭。
@export var hover_outline := true

var _hovered := false
var _hover_amount := 0.0
var _base_position := Vector2.ZERO


## 记录场景中设置的初始位置，作为浮起动画的回落点。
func _ready() -> void:
	_base_position = position


## 平滑更新悬停描边和可选的垂直浮起动画。
func _process(delta: float) -> void:
	var target_hover := 1.0 if _hovered else 0.0
	_hover_amount = move_toward(_hover_amount, target_hover, delta * 6.0)

	var mat := material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("hover", _hover_amount * (1.0 if hover_outline else 0.0))

	if can_float:
		var target_y := _base_position.y - (float_height if _hovered else 0.0)
		position.y = lerpf(position.y, target_y, 1.0 - exp(-12.0 * delta))


## 由主控制器在鼠标进入或离开物体时调用。
func set_hovered(value: bool) -> void:
	_hovered = value
