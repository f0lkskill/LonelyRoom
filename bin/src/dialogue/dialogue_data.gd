## 以 .tres 文件保存的对话数据。
## 每个资源表示一个物体的独白或一段旁白。
class_name DialogueData
extends Resource

## 说话人角色资源，优先使用其中的显示名和名字颜色。
@export var speaker: Resource
## 兼容用文本直接指定说话人名字；没有角色资源时使用。
@export var speaker_name: String = ""
## 为 true 时隐藏说话人并居中显示文本。
@export var narration: bool = false
## 点击后逐条显示的对白。
@export var lines: Array[String] = []
