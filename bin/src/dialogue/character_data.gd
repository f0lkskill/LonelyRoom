## 角色数据资源。
## 保存说话人的显示名、名字颜色和预留的立绘信息。
class_name CharacterData
extends Resource

## 对话中显示的说话人名字。
@export var display_name: String = ""
## 说话人名字使用的字体；为空时使用对话框默认字体。
@export var name_font: Font
## 说话人名字字号。
@export var name_font_size: int = 42
## 说话人名字颜色。
@export var name_color: Color = Color(0.63, 0.86, 1.0, 1.0)
## 说话人名字描边颜色。
@export var name_outline_color: Color = Color(0.0, 0.0, 0.0, 1.0)
## 说话人名字描边宽度。
@export var name_outline_size: int = 10
## 立绘贴图，暂时可以为空。
@export var portrait: Texture2D
## 立绘相对对话框的偏移，后续接入立绘时使用。
@export var portrait_offset: Vector2 = Vector2.ZERO
