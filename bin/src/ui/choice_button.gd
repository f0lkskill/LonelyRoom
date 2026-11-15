## 对话选项卡按钮。
## 背景由带有左右渐变和上下割裂的 Shader 绘制。
extends Button

@onready var label: Label = $Label


func _ready() -> void:
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(_on_hover_changed.bind(false))


## 设置选项卡显示的文本。
func setup(text: String) -> void:
	label.text = text


func _on_hover_changed(hovered: bool) -> void:
	label.modulate = Color(1.0, 0.95, 0.8, 1.0) if hovered else Color(1.0, 1.0, 1.0, 1.0)
